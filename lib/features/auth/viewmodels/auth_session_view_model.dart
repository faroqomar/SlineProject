import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/constants/auth_messages.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/auth/data/auth_repository.dart';
import 'package:sline_app/core/models/user_profile.dart';

class AuthSessionViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final Stream<AuthState> _authStateChanges;
  StreamSubscription<AuthState>? _authSubscription;

  bool _pendingSessionExpired = false;
  VoidCallback? _onSessionExpired;

  bool _pendingPasswordRecovery = false;
  VoidCallback? _onPasswordRecovery;

  UserProfile? _currentUserProfile;
  UserProfile? get currentUserProfile => _currentUserProfile;

  set onSessionExpired(VoidCallback? callback) {
    _onSessionExpired = callback;
    if (_pendingSessionExpired && callback != null) {
      AppLogger.i('Processing pending session expiry', tag: 'Auth');
      _pendingSessionExpired = false;
      callback();
    }
  }

  VoidCallback? get onSessionExpired => _onSessionExpired;

  set onPasswordRecovery(VoidCallback? callback) {
    _onPasswordRecovery = callback;
    if (_pendingPasswordRecovery && callback != null) {
      AppLogger.i('Processing pending password recovery', tag: 'Auth');
      _pendingPasswordRecovery = false;
      callback();
    }
  }

  VoidCallback? get onPasswordRecovery => _onPasswordRecovery;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String? get currentUserId => _authRepo.currentUser?.id;
  String? get currentUserEmail => _authRepo.currentUser?.email;
  bool get isAuthenticated => _authRepo.currentUser != null;

  AuthSessionViewModel({
    AuthRepository? authRepo,
    Stream<AuthState>? authStateChanges,
  }) : _authRepo = authRepo ?? AuthRepository(),
       _authStateChanges =
           authStateChanges ?? Supabase.instance.client.auth.onAuthStateChange {
    _initAuthListener();
    _loadInitialProfile();
  }

  void _initAuthListener() {
    _authSubscription = _authStateChanges.listen(
      (AuthState state) async {
        AppLogger.d('Auth state changed: ${state.event}', tag: 'Auth');

        switch (state.event) {
          case AuthChangeEvent.signedIn:
            await _loadInitialProfile();
            break;
          case AuthChangeEvent.signedOut:
            AppLogger.i('User signed out', tag: 'Auth');
            _currentUserProfile = null;
            notifyListeners();
            break;
          case AuthChangeEvent.tokenRefreshed:
            AppLogger.d('Token refreshed successfully', tag: 'Auth');
            break;
          case AuthChangeEvent.passwordRecovery:
            AppLogger.i('Password recovery session established', tag: 'Auth');
            if (_onPasswordRecovery != null) {
              _onPasswordRecovery!();
            } else {
              _pendingPasswordRecovery = true;
            }
            break;
          case AuthChangeEvent.userUpdated:
            AppLogger.i('User profile updated', tag: 'Auth');
            await _loadInitialProfile();
            break;
          default:
            break;
        }
      },
      onError: (error) {
        AppLogger.e('Auth state error', tag: 'Auth', error: error);
        if (_onSessionExpired != null) {
          _onSessionExpired!();
        } else {
          AppLogger.w('Session expiry queued', tag: 'Auth');
          _pendingSessionExpired = true;
        }
      },
    );
  }

  Future<void> _loadInitialProfile() async {
    if (!isAuthenticated) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentUserProfile = await _authRepo.getCurrentUserProfileWithRetry();
      if (_currentUserProfile == null && isAuthenticated) {
        AppLogger.w(
          'Profile not found after retries - signing out',
          tag: 'Auth',
        );
        await logout();
        _error = AuthMessages.profileProvisioningFailed;
      }
    } catch (e, st) {
      AppLogger.e(
        'Failed to load profile',
        tag: 'Auth',
        error: e,
        stackTrace: st,
      );
      await logout();
      _error = AuthMessages.sessionInvalid;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    clearError();
    notifyListeners();
    try {
      await _authRepo.signOut();
      _currentUserProfile = null;
    } catch (e) {
      AppLogger.e('Logout failed', tag: 'Auth', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
