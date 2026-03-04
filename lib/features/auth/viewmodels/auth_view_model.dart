// AuthViewModel: MVVM state holder for authentication flows.
//
// Architecture: This ViewModel manages login, register, and logout state.
// It uses AuthRepository for data access and exposes state to the UI.
//
// Design Decision: Navigation and SnackBar callbacks are passed from the View
// rather than holding BuildContext, making this ViewModel testable and avoiding
// context-related lifecycle issues.
//
// Session Handling: Listens to Supabase auth state changes to detect session
// expiry and trigger logout/navigation as needed.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/account_guard_service.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/auth/data/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final AccountGuardService? _accountGuardService;
  final Stream<AuthState> _authStateChanges;
  StreamSubscription<AuthState>? _authSubscription;

  /// Tracks if a session error occurred before callback was set.
  /// Ensures errors during startup aren't silently ignored.
  bool _pendingSessionExpired = false;

  /// Callback to trigger when session expires (set by app wrapper).
  /// UI should set this to navigate to login screen.
  VoidCallback? _onSessionExpired;

  /// Setter that processes any queued session expiry events.
  set onSessionExpired(VoidCallback? callback) {
    _onSessionExpired = callback;
    // Process any pending session expiry that occurred before callback was set
    if (_pendingSessionExpired && callback != null) {
      AppLogger.i('Processing pending session expiry', tag: 'Auth');
      _pendingSessionExpired = false;
      callback();
    }
  }

  VoidCallback? get onSessionExpired => _onSessionExpired;

  AuthViewModel({
    AuthRepository? authRepo,
    Stream<AuthState>? authStateChanges,
    AccountGuardService? accountGuardService,
  }) : _authRepo = authRepo ?? AuthRepository(),
       _accountGuardService =
           accountGuardService ?? _buildDefaultGuardService(),
       _authStateChanges =
           authStateChanges ?? Supabase.instance.client.auth.onAuthStateChange {
    _initAuthListener();
  }

  /// Initialize auth state listener to handle session expiry.
  void _initAuthListener() {
    _authSubscription = _authStateChanges.listen(
      (AuthState state) {
        AppLogger.d('Auth state changed: ${state.event}', tag: 'Auth');

        switch (state.event) {
          case AuthChangeEvent.signedOut:
            AppLogger.i('User signed out', tag: 'Auth');
            notifyListeners();
            break;
          case AuthChangeEvent.tokenRefreshed:
            AppLogger.d('Token refreshed successfully', tag: 'Auth');
            break;
          case AuthChangeEvent.userUpdated:
            AppLogger.i('User profile updated', tag: 'Auth');
            notifyListeners();
            break;
          default:
            break;
        }
      },
      onError: (error) {
        AppLogger.e('Auth state error', tag: 'Auth', error: error);
        // On auth errors, trigger session expired callback or queue for later
        if (_onSessionExpired != null) {
          _onSessionExpired!();
        } else {
          // Queue the expiry for when callback is set
          AppLogger.w(
            'Session expiry queued - callback not yet set',
            tag: 'Auth',
          );
          _pendingSessionExpired = true;
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // --- State ---
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Current authenticated user (null if logged out)
  String? get currentUserId => _authRepo.currentUser?.id;
  String? get currentUserEmail => _authRepo.currentUser?.email;
  bool get isAuthenticated => _authRepo.currentUser != null;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Login user with email and password.
  ///
  /// Returns true on success, false on failure.
  /// UI should check [error] for failure details and handle navigation.
  ///
  /// Why callbacks instead of BuildContext: Keeps ViewModel framework-agnostic
  /// and testable. UI provides callbacks for success/failure handling.
  Future<bool> login({required String email, required String password}) async {
    _setError(null);
    _setLoading(true);
    try {
      await _authRepo.signIn(email: email, password: password);
      final profile = await _authRepo.getCurrentUserProfile();
      if (profile != null) {
        AppLogger.i("User profile loaded: ${profile['full_name']}");
      }
      if (_accountGuardService != null) {
        final guard = await _accountGuardService.evaluateCurrentUser();
        if (guard.isRestricted) {
          await _authRepo.signOut();
          _setError(
            guard.accountStatus == 'banned'
                ? 'Your account has been banned.'
                : 'Your account is temporarily suspended.',
          );
          return false;
        }
        if (guard.isRevoked) {
          await _authRepo.signOut();
          _setError('Your session is no longer valid. Please sign in again.');
          return false;
        }
      }
      return true;
    } catch (e) {
      final errorMessage = _mapAuthError(e);
      _setError(errorMessage);
      AppLogger.e('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  static AccountGuardService? _buildDefaultGuardService() {
    try {
      return AccountGuardService(client: Supabase.instance.client);
    } catch (_) {
      // In widget tests Supabase can be intentionally uninitialized.
      return null;
    }
  }

  /// Register new user with email, password, and full name.
  ///
  /// Returns true on success, false on failure.
  /// UI should check [error] for failure details and handle navigation.
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _setError(null);
    _setLoading(true);
    try {
      await _authRepo.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      return true;
    } catch (e) {
      final errorMessage = _mapAuthError(e);
      _setError(errorMessage);
      AppLogger.e('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email.
  ///
  /// Returns true on success, false on failure.
  Future<bool> resetPassword(String email) async {
    _setError(null);
    _setLoading(true);
    try {
      await _authRepo.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      final errorMessage = _mapAuthError(e);
      _setError(errorMessage);
      AppLogger.e('Password reset failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout current user.
  ///
  /// Returns true on success, false on failure.
  Future<bool> logout() async {
    _setLoading(true);
    try {
      await _authRepo.signOut();
      return true;
    } catch (e) {
      final errorMessage = _mapAuthError(e);
      _setError(errorMessage);
      AppLogger.e('Logout failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Map technical auth errors to user-friendly messages.
  ///
  /// Why this mapping: Raw Supabase errors are technical and not user-friendly.
  /// This provides clear, actionable messages for common auth failures.
  String _mapAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid_credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (errorString.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    if (errorString.contains('user already registered') ||
        errorString.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (errorString.contains('weak password') ||
        errorString.contains('password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (errorString.contains('invalid email') ||
        errorString.contains('email')) {
      return 'Please enter a valid email address.';
    }
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your connection.';
    }

    // Fallback to generic message
    return 'An error occurred. Please try again.';
  }
}
