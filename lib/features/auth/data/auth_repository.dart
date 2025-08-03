import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';

class AuthRepository {
  final _client = Supabase.instance.client;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // Info: Starting user registration process
    AppLogger.i('Starting user registration for: $email');
    final response = await _client.auth.signUp(email: email, password: password);

    // تأكد من وجود session، إذا لا، قم بتسجيل الدخول
    final session = response.session;
    if (session == null) {
      await _client.auth.signInWithPassword(email: email, password: password);
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated");

    await _client.from('profiles').insert({
      'id': userId,
      'full_name': fullName,
      'email': email,
    });
    
    // Info: User registration completed successfully
    AppLogger.i('User registration completed for: $email');
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    // Info: User attempting to sign in
    AppLogger.i('User attempting to sign in: $email');
    final response = await _client.auth.signInWithPassword(email: email, password: password);
    // Info: User signed in successfully
    AppLogger.i('User signed in successfully: $email');
    return response;
  }

  Future<void> signOut() async {
    final userEmail = _client.auth.currentUser?.email;
    // Info: User signing out
    AppLogger.i('User signing out: ${userEmail ?? 'Unknown'}');
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return response;
  }
}