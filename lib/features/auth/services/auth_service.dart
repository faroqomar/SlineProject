import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling authentication operations with Supabase
class AuthService {
  final _client = Supabase.instance.client;

  /// Sign up a new user with email, password, and full name
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(email: email, password: password);

    // Ensure session exists, if not, sign in
    final session = response.session;
    if (session == null) {
      await _client.auth.signInWithPassword(email: email, password: password);
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated");

    // Create user profile in profiles table
    await _client.from('profiles').insert({
      'id': userId,
      'full_name': fullName,
      'email': email,
    });
  }

  /// Sign in user with email and password
  Future<AuthResponse> signIn({
    required String email, 
    required String password
  }) async {
    return await _client.auth.signInWithPassword(
      email: email, 
      password: password
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get current authenticated user
  User? get currentUser => _client.auth.currentUser;

  /// Get current user's profile data from profiles table
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
