import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/avatar_service.dart';

import '../../tasks/services/task_service.dart';
import '../../tasks/models/task_model.dart';
import '../models/profile_model.dart';
import '../models/freelancer_profile.dart';

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

  Future<ProfileModel> fetchProfile(String userId) async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(res);
  }

  Future<void> updateProfileFields({
    required String userId,
    required String fullName,
    required String bio,
  }) async {
    await _client
        .from('profiles')
        .update({'full_name': fullName, 'bio': bio})
        .eq('id', userId);
  }

  Future<void> updateProfileSkills({
    required String userId,
    required List<String> skills,
  }) async {
    await _client.from('profiles').update({'skills': skills}).eq('id', userId);
  }

  Future<void> updateUserEmail(String email) async {
    await _client.auth.updateUser(UserAttributes(email: email));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> changeRole({
    required String userId,
    required String newRole,
  }) async {
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
    await _client
        .from('profiles')
        .update({'avatar_url': path})
        .eq('id', userId);
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
  Future<List<Task>> getTasksByUser(String userId) =>
      _taskService.getTasksByUser(userId);
  Future<void> deleteTask(String taskId) => _taskService.deleteTask(taskId);
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) =>
      _taskService.updateTask(taskId, updates);

  // Portfolio related
  Future<List<Map<String, dynamic>>> getPortfolioItems(String userId) async {
    final res = await _client
        .from('portfolio_items')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> addPortfolioItem({
    required String userId,
    required String title,
    String? description,
    String? imageUrl,
  }) async {
    await _client.from('portfolio_items').insert({
      'owner_id': userId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
    });
  }

  Future<void> updatePortfolioItem({
    required String itemId,
    Map<String, dynamic>? updates,
  }) async {
    if (updates == null || updates.isEmpty) return;
    await _client.from('portfolio_items').update(updates).eq('id', itemId);
  }

  Future<void> deletePortfolioItem(String itemId) async {
    await _client.from('portfolio_items').delete().eq('id', itemId);
  }

  Future<String> uploadPortfolioImage({
    required String userId,
    required Uint8List bytes,
    required String contentType,
    required String fileExt,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final path = '$userId/$fileName';

    await _client.storage
        .from('portfolio')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
    return path;
  }

  Future<FreelancerProfile> getPublicProfile(String userId) async {
    // 1. Fetch Profile Data (SECURE: Explicit column selection)
    // REQ-SEC-001: Do NOT select(*). Exclude email/phone/metadata.
    final profileData = await _client
        .from('profiles')
        .select(
          'id, full_name, avatar_url, bio, active_role, skills, created_at, title, location, verified',
        )
        .eq('id', userId)
        .single();

    // Note: ProfileModel.fromJson handles missing fields (like email) gracefully
    final profileModel = ProfileModel.fromJson(profileData);

    // 2. Fetch Portfolio Items
    final portfolioData = await _client
        .from('portfolio_items')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    final portfolioItems = (portfolioData as List)
        .map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // 3. Mock Reviews (for now, as table doesn't exist)
    // TODO: Implement reviews table and fetching
    final reviews = [
      ReviewItem(
        client: 'Previous Client',
        rating: 5.0,
        comment: 'Great to work with! Delivered on time.',
        date: '1 month ago',
      ),
    ];

    // 4. Fetch History (Completed Tasks) - SECURE & EFFICIENT
    // REQ-SEC-005: Only fetch completed/closed tasks. Limit to 20.
    final historyData = await _client
        .from('tasks')
        .select('''
          id, title, description, budget, user_id, status, task_type, created_at, 
          deadline, skills, category_id, category, assigned_freelancer_id, 
          image_paths, packages, offers,
          profiles!tasks_user_id_fkey(full_name, avatar_url)
        ''')
        .in_('status', ['completed', 'closed'])
        .or('freelancer_id.eq.$userId,assigned_freelancer_id.eq.$userId')
        .order('created_at', ascending: false)
        .limit(20);

    final history = (historyData as List)
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();

    // 5. Construct FreelancerProfile
    return FreelancerProfile.fromModel(
      profile: profileModel,
      portfolio: portfolioItems,
      reviews: reviews,
      history: history,
    );
  }
}
