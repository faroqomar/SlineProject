import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/avatar_service.dart';
import '../../tasks/services/task_service.dart';
import '../../tasks/models/task_model.dart';

/// Repository layer for Profile feature.
/// Encapsulates all Supabase and storage calls.
class ProfileRepository {
  ProfileRepository(SupabaseClient client)
      : _client = client,
        _avatarService = AvatarService(client),
        _taskService = TaskService();

  final SupabaseClient _client;
  final AvatarService _avatarService;
  final TaskService _taskService;

  User? get currentUser => _client.auth.currentUser;

  Future<Map<String, dynamic>> fetchProfile(String userId) async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return (res as Map<String, dynamic>);
  }

  Future<void> updateProfileFields({
    required String userId,
    required String fullName,
    required String bio,
  }) async {
    await _client.from('profiles').update({
      'full_name': fullName,
      'bio': bio,
    }).eq('id', userId);
  }

  Future<void> updateUserEmail(String email) async {
    await _client.auth.updateUser(UserAttributes(email: email));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> changeRole({required String userId, required String newRole}) async {
    await _client.from('profiles').update({'role': newRole}).eq('id', userId);
  }

  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String contentType,
    required String fileExt,
  }) async {
    final path = await _avatarService.uploadAvatar(
      userId: userId,
      bytes: bytes,
      contentType: contentType,
      fileExt: fileExt,
    );
    await _client.from('profiles').update({'avatar_url': path}).eq('id', userId);
    return path;
  }

  Future<String?> getAvatarPath(String userId) async {
    final row = await _client
        .from('profiles')
        .select('avatar_url')
        .eq('id', userId)
        .maybeSingle();
    return row?['avatar_url'] as String?;
  }

  Future<String> createSignedAvatarUrl(String storagePath) async {
    return _avatarService.createSignedUrl(storagePath);
  }

  // Tasks related
  Future<List<Task>> getTasksByUser(String userId) => _taskService.getTasksByUser(userId);
  Future<void> deleteTask(String taskId) => _taskService.deleteTask(taskId);
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) => _taskService.updateTask(taskId, updates);
}
