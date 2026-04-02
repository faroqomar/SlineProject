// What: Repository that wraps Supabase auth/profile calls used by auth flows.
// Why: Keeps data access isolated from UI/controllers to follow repository pattern.
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/auth_config.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/models/user_profile.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // Info: Starting user registration process
    AppLogger.i('Starting user registration for: ${_maskEmail(email)}');
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'active_role': 'client'},
    );

    // Ensure session exists.
    final session = response.session;
    if (session == null) {
      await _client.auth.signInWithPassword(email: email, password: password);
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Info: User registration completed successfully
    AppLogger.i('User registration completed for: ${_maskEmail(email)}');
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    // Info: User attempting to sign in
    AppLogger.i('User attempting to sign in: ${_maskEmail(email)}');
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    // Info: User signed in successfully
    AppLogger.i('User signed in successfully: ${_maskEmail(email)}');
    return response;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    AppLogger.i('Sending password reset email to: ${_maskEmail(email)}');
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.sline://login-callback',
    );
    AppLogger.i('Password reset email sent to: ${_maskEmail(email)}');
  }

  Future<void> updatePassword(String newPassword) async {
    AppLogger.i('Updating user password');
    await _client.auth.updateUser(UserAttributes(password: newPassword));
    AppLogger.i('User password updated successfully');
  }

  Future<void> signOut() async {
    final userEmail = _client.auth.currentUser?.email;
    // Info: User signing out
    AppLogger.i(
      'User signing out: ${userEmail != null ? _maskEmail(userEmail) : 'Unknown'}',
    );
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  /// Single attempt to fetch current user profile (no retry).
  /// Returns null if no profile row exists (e.g. trigger not yet committed).
  Future<UserProfile?> _fetchProfileOnce() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response != null ? UserProfile.fromMap(response) : null;
  }

  /// Fetches current user profile with retry for race condition handling.
  /// Retries up to [maxRetries] with [retryDelay] between attempts.
  Future<UserProfile?> getCurrentUserProfileWithRetry({
    int? maxRetries,
    Duration? retryDelay,
  }) async {
    final retries = maxRetries ?? AuthConfig.profileFetchMaxRetries;
    final delay =
        retryDelay ??
        const Duration(milliseconds: AuthConfig.profileFetchRetryDelayMs);

    if (!AuthConfig.enableProfileFetchRetry) {
      return _fetchProfileOnce();
    }

    for (int attempt = 1; attempt <= retries; attempt++) {
      AppLogger.d('Profile fetch attempt $attempt of $retries', tag: 'Auth');
      try {
        final profile = await _fetchProfileOnce();
        if (profile != null) {
          AppLogger.i(
            'Profile fetch succeeded on attempt $attempt',
            tag: 'Auth',
          );
          return profile;
        }
      } on Exception catch (e) {
        AppLogger.w(
          'Profile fetch attempt $attempt failed',
          tag: 'Auth',
          json: <String, dynamic>{'error': e.toString()},
        );
      }

      if (attempt < retries) {
        AppLogger.d(
          'Waiting ${delay.inMilliseconds}ms before retry',
          tag: 'Auth',
        );
        await Future.delayed(delay);
      }
    }

    AppLogger.w('Profile fetch failed after $retries attempts', tag: 'Auth');
    return null;
  }

  /// Fetches current user profile (single attempt, for backward compatibility).
  /// Prefer [getCurrentUserProfileWithRetry] for signup/session load.
  Future<UserProfile?> getCurrentUserProfile() async {
    return _fetchProfileOnce();
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return '***';
    final parts = email.split('@');
    if (parts.length != 2) return '***';
    final name = parts[0];
    if (name.length <= 2) return '***@${parts[1]}';
    return '${name.substring(0, 2)}***@${parts[1]}';
  }
}
