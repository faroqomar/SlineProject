import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _client = Supabase.instance.client;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
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
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
}