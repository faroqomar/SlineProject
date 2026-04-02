import 'package:flutter/foundation.dart';
import 'package:sline_app/core/constants/auth_messages.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/features/auth/data/auth_repository.dart';
import 'package:sline_app/core/services/account_guard_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthFormViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final AccountGuardService? _accountGuardService;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthFormViewModel({
    AuthRepository? authRepo,
    AccountGuardService? accountGuardService,
  }) : _authRepo = authRepo ?? AuthRepository(),
       _accountGuardService =
           accountGuardService ?? _buildDefaultGuardService();

  static AccountGuardService? _buildDefaultGuardService() {
    try {
      return AccountGuardService(client: Supabase.instance.client);
    } on Exception catch (_) {
      return null;
    } on Error catch (_) {
      // Supabase not initialized (e.g., in tests) — guard is optional
      return null;
    }
  }

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

  Future<bool> login({required String email, required String password}) async {
    _setError(null);
    _setLoading(true);
    try {
      await _authRepo.signIn(email: email, password: password);
      // Let the session view model load the profile, but we check guard here
      if (_accountGuardService != null) {
        final guard = await _accountGuardService.evaluateCurrentUser();
        if (guard.isRestricted) {
          await _authRepo.signOut();
          _setError(
            guard.accountStatus == 'banned'
                ? AuthMessages.accountBanned
                : AuthMessages.accountSuspended,
          );
          return false;
        }
        if (guard.isRevoked) {
          await _authRepo.signOut();
          _setError(AuthMessages.sessionInvalid);
          return false;
        }
      }
      return true;
    } on Exception catch (e) {
      _setError(ErrorMapper.map(e));
      AppLogger.e('Login failed', tag: 'Auth', error: e);
      return false;
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

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
      final profile = await _authRepo.getCurrentUserProfileWithRetry();
      if (profile == null) {
        AppLogger.w(
          'Profile creation failed after signup - signing out',
          tag: 'Auth',
        );
        await _authRepo.signOut();
        _setError(AuthMessages.profileProvisioningFailed);
        return false;
      }
      return true;
    } on Exception catch (e) {
      _setError(ErrorMapper.map(e));
      AppLogger.e('Registration failed', tag: 'Auth', error: e);
      return false;
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  Future<bool> resetPassword(String email) async {
    _setError(null);
    _setLoading(true);
    try {
      await _authRepo.sendPasswordResetEmail(email);
      return true;
    } on Exception catch (e) {
      _setError(ErrorMapper.map(e));
      AppLogger.e('Password reset failed', tag: 'Auth', error: e);
      return false;
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    _setError(null);
    _setLoading(true);
    try {
      await _authRepo.updatePassword(newPassword);
      return true;
    } on Exception catch (e) {
      _setError(ErrorMapper.map(e));
      AppLogger.e('Password update failed', tag: 'Auth', error: e);
      return false;
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }
}
