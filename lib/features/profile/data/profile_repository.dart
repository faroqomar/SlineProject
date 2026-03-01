import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../services/avatar_service.dart';
import '../services/profile_summary_service.dart';

import '../../tasks/services/task_service.dart';
import '../../tasks/models/task_model.dart';
import '../../portfolio/data/portfolio_repository.dart';
import '../../portfolio/models/portfolio_item.dart';
import '../models/profile_model.dart';
import '../models/freelancer_profile.dart';

/// Repository layer for Profile feature.
/// Encapsulates all Supabase and storage calls.
///
/// Note: Portfolio operations are delegated to PortfolioRepository
/// to maintain single source of truth for portfolio CRUD.
class ProfileRepository {
  ProfileRepository(SupabaseClient client)
    : _client = client,
      _avatarService = AvatarService(client),
      _taskService = TaskService(client),
      _profileSummaryService = ProfileSummaryService(client),
      _portfolioRepository = PortfolioRepository(client);

  final SupabaseClient _client;
  final AvatarService _avatarService;
  final TaskService _taskService;
  final ProfileSummaryService _profileSummaryService;
  final PortfolioRepository _portfolioRepository;

  User? get currentUser => _client.auth.currentUser;

  Future<ProfileModel> fetchProfile(String userId) async {
    final res = await _client
        .from('profiles')
        .select(
          'id, full_name, email, avatar_url, bio, active_role, skills, created_at, seller_level',
        )
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(res);
  }

  Future<ProfileModel> fetchProfileSummary(String userId) async {
    AppLogger.d(
      'profile_summary_fetch_started',
      tag: 'ProfileRepo',
      json: {'user_id': userId},
    );
    try {
      final res = await _client
          .from('profiles')
          .select(
            'id, full_name, avatar_url, bio, active_role, skills, created_at, seller_level',
          )
          .eq('id', userId)
          .single();
      final profile = ProfileModel.fromJson(res);
      AppLogger.i(
        'profile_summary_fetch_succeeded',
        tag: 'ProfileRepo',
        json: {'user_id': userId},
      );
      return profile;
    } catch (error, stackTrace) {
      AppLogger.e(
        'profile_summary_fetch_failed',
        tag: 'ProfileRepo',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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
    await _client
        .from('profiles')
        .update({'active_role': newRole})
        .eq('id', userId);
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

  // ============================================================================
  // PORTFOLIO OPERATIONS
  // ============================================================================
  // Delegated to PortfolioRepository to maintain single source of truth.
  // See: lib/features/portfolio/data/portfolio_repository.dart

  /// Gets portfolio items for a user.
  /// Delegates to PortfolioRepository.
  Future<List<PortfolioItem>> getPortfolioItems(String userId) async {
    AppLogger.d('Delegating getPortfolioItems to PortfolioRepository', tag: 'ProfileRepo');
    return _portfolioRepository.listItems(ownerId: userId);
  }

    /// Adds a portfolio item.
  /// Delegates to PortfolioRepository.
  /// If imagePath is provided (existing storage path), creates item with that path.
  Future<PortfolioItem> addPortfolioItem({
    required String userId,
    required String title,
    String? description,
    Uint8List? imageBytes,
    String? imageFilename,
    String? imagePath, // Existing storage path (when upload already done)
  }) async {
    AppLogger.d('Delegating addPortfolioItem to PortfolioRepository', tag: 'ProfileRepo', json: {
      'hasImagePath': imagePath != null,
      'hasImageBytes': imageBytes != null,
    });
    
    // If we have an existing image path, create item directly
    if (imagePath != null) {
      // Insert with the existing path
      final row = await _client
          .from('portfolio_items')
          .insert({
            'owner_id': userId,
            'title': title,
            'description': description,
            'image_path': imagePath,
          })
          .select()
          .single();
      return PortfolioItem.fromJson(row as Map<String, dynamic>);
    }
    
    // Otherwise, use the normal flow with upload
    return _portfolioRepository.addItem(
      ownerId: userId,
      title: title,
      description: description,
      imageBytes: imageBytes,
      imageFilename: imageFilename,
    );
  }

  /// Updates a portfolio item.
  /// Delegates to PortfolioRepository.
  Future<void> updatePortfolioItem({
    required String itemId,
    required String title,
    String? description,
  }) async {
    AppLogger.d('Delegating updatePortfolioItem to PortfolioRepository', tag: 'ProfileRepo');
    return _portfolioRepository.updateItem(
      id: itemId,
      title: title,
      description: description,
    );
  }

  /// Deletes a portfolio item.
  /// Delegates to PortfolioRepository.
  Future<void> deletePortfolioItem(String itemId) async {
    AppLogger.d('Delegating deletePortfolioItem to PortfolioRepository', tag: 'ProfileRepo');
    return _portfolioRepository.deleteItem(id: itemId);
  }

  /// Uploads a portfolio image.
  /// Uses PortfolioService via PortfolioRepository for consistent handling.
  Future<String> uploadPortfolioImage({
    required String userId,
    required Uint8List bytes,
    required String contentType,
    required String fileExt,
  }) async {
    AppLogger.d('Delegating uploadPortfolioImage to PortfolioRepository', tag: 'ProfileRepo');
    // Use a temporary item addition that only uploads the image
    // Since PortfolioService handles upload internally, we create a dummy item
    // This is a workaround - ideally, the upload should be a separate service method
    final filename = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final result = await _portfolioRepository.addItem(
      ownerId: userId,
      title: '_temp_upload_$filename', // Temporary title
      imageBytes: bytes,
      imageFilename: filename,
    );
    // Return just the image path from the created item
    if (result.imagePath != null) {
      // Delete the temporary item, keeping the image for reuse
      await _portfolioRepository.deleteItem(id: result.id, alsoDeleteImage: false);
      return result.imagePath!;
    }
    throw StateError('Image upload failed - no path returned');
  }

  /// Resolves a storage path or URL to a displayable image URL.
  /// Handles both full URLs (legacy) and storage paths (requires signed URL).
  Future<String?> resolvePortfolioImageUrl(String? pathOrUrl) async {
    if (pathOrUrl == null || pathOrUrl.isEmpty) {
      return null;
    }
    // Already a full URL
    if (pathOrUrl.startsWith('http')) {
      return pathOrUrl;
    }
    // Generate signed URL for storage path
    try {
      final signed = await _client.storage
          .from('portfolio')
          .createSignedUrl(pathOrUrl, 7200); // 2 hours
      return signed;
    } catch (e) {
      AppLogger.w('Failed to resolve portfolio image URL', tag: 'ProfileRepo', json: {'path': pathOrUrl, 'error': e.toString()});
      return null;
    }
  }

  Future<FreelancerProfile> getPublicProfile(String userId) async {
    final profileData = await _profileSummaryService.fetchById(userId);
    if (profileData == null) {
      throw StateError('Public profile not found');
    }
    final profileModel = ProfileModel.fromJson(profileData);

    // 2. Fetch Portfolio Items (delegated to PortfolioRepository)
    final portfolioItems = await _portfolioRepository.listItems(ownerId: userId);

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
          id, title, description, budget, user_id, client_id, status, task_type, created_at,
          deadline, skills, category_id, category, freelancer_id, assigned_freelancer_id,
          image_paths, packages
        ''')
        .in_('status', ['completed', 'closed'])
        .or('freelancer_id.eq.$userId,assigned_freelancer_id.eq.$userId')
        .order('created_at', ascending: false)
        .limit(20);

    final historyRows = (historyData as List)
        .cast<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList();
    final historyProfileIds = historyRows
        .map((row) => (row['client_id'] ?? row['user_id']) as String?)
        .whereType<String>()
        .toSet();
    final historyProfiles = await _profileSummaryService.fetchByIds(
      historyProfileIds,
    );

    final history = historyRows.map((row) {
      final summaryUserId = (row['client_id'] ?? row['user_id']) as String?;
      final summary = summaryUserId != null
          ? historyProfiles[summaryUserId]
          : null;
      if (summary != null) {
        row['profiles'] = summary;
      }
      return Task.fromJson(row);
    }).toList();

    // 5. Construct FreelancerProfile
    return FreelancerProfile.fromModel(
      profile: profileModel,
      portfolio: portfolioItems,
      reviews: reviews,
      history: history,
    );
  }
}
