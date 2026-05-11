import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/role_switch_coordinator.dart';
import 'package:sline_app/features/profile/data/profile_repository.dart';
import 'package:sline_app/features/profile/models/profile_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ProfileViewModel — MVVM state holder for Profile feature.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({SupabaseClient? client, ProfileRepository? repository})
    : _repo =
          repository ?? ProfileRepository(client ?? Supabase.instance.client);

  final ProfileRepository _repo;

  // State
  ProfileModel? _profile;
  ProfileModel? get profile => _profile;

  // Loading & Error States for Profile fetching
  bool _isLoadingProfile = false;
  bool get isLoadingProfile => _isLoadingProfile;

  bool _isLoadingUpdate = false;
  bool get isLoadingUpdate => _isLoadingUpdate;

  String? _profileError;
  String? get profileError => _profileError;

  // Skills state
  final List<String> _skills = [];
  List<String> get skills => List.unmodifiable(_skills);

  // Portfolio state
  final List<Map<String, dynamic>> _portfolioItems = [];
  List<Map<String, dynamic>> get portfolioItems =>
      List.unmodifiable(_portfolioItems);
  bool isLoadingPortfolio = false;

  // Avatar state
  String? avatarSignedUrl;
  bool avatarUploading = false;

  // Getters for UI convenience
  String? get avatarUrl => avatarSignedUrl;
  String? get fullName => _profile?.fullName;
  String? get loadedName => _profile?.fullName;
  String? get loadedBio => _profile?.bio;
  String? get loadedEmail => _repo.currentUser?.email;

  // Tasks state
  final List<Task> myTasks = [];
  bool isLoadingMyTasks = false;

  // Alias for loadUserData to match HomeScreen usage
  Future<void> loadProfile() => loadUserData();

  Future<void> loadHeaderProfile() async {
    final user = _repo.currentUser;
    if (user == null) return;

    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();

    try {
      AppLogger.i(
        'profile_header_load_started',
        tag: 'Profile',
        json: {'user_id': user.id},
      );
      _profile = await _repo.fetchProfileSummary(user.id);

      _skills
        ..clear()
        ..addAll(_profile?.skills ?? const []);

      await refreshAvatarSignedUrl();
      AppLogger.i(
        'profile_header_load_succeeded',
        tag: 'Profile',
        json: {
          'user_id': user.id,
          'has_avatar': avatarSignedUrl != null && avatarSignedUrl!.isNotEmpty,
        },
      );
    } on Exception catch (e) {
      AppLogger.e('Error loading profile header: $e');
      _profileError = 'Failed to load profile. Please try again.';
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  // Load current user data into controllers
  Future<void> loadUserData() async {
    final user = _repo.currentUser;
    if (user == null) return;

    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();

    try {
      _profile = await _repo.fetchProfile(user.id);

      _skills.clear();
      if (_profile?.skills != null) {
        _skills.addAll(_profile!.skills);
      }

      await Future.wait([refreshAvatarSignedUrl(), fetchPortfolio()]);
      // await fetchMyTasks(); // Optional: load tasks here if needed immediately
    } on Exception catch (e) {
      AppLogger.e('Error loading profile: $e');
      _profileError = 'Failed to load profile. Please try again.';
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  // Update profile with form data
  Future<void> updateProfile({
    required String name,
    required String bio,
  }) async {
    AppLogger.d('Profile update requested', tag: 'ProfileVM');

    final user = _repo.currentUser;
    if (user == null) return;

    _isLoadingUpdate = true;
    notifyListeners();

    try {
      await _repo.updateProfileFields(
        userId: user.id,
        fullName: name,
        bio: bio,
      );
      // Email changes require a separate re-authenticated flow.
      // await _repo.updateUserEmail(email);
      await _repo.updateProfileSkills(userId: user.id, skills: _skills);

      await loadUserData(); // Refresh local state
      AppLogger.i('Profile updated successfully');
    } on Exception catch (e) {
      AppLogger.e('Error updating profile: $e');
      _profileError = 'Failed to update profile. Please try again.';
    } finally {
      _isLoadingUpdate = false;
      notifyListeners();
    }
  }

  // Skills management
  void addSkill(String skill) {
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      _skills.add(skill);
      notifyListeners();
    }
  }

  void removeSkill(String skill) {
    if (_skills.contains(skill)) {
      _skills.remove(skill);
      notifyListeners();
    }
  }

  // ============================================================================
  // PORTFOLIO MANAGEMENT (Delegated to PortfolioRepository)
  // ============================================================================

  Future<void> fetchPortfolio() async {
    final user = _repo.currentUser;
    if (user == null) {
      AppLogger.w(
        'Cannot fetch portfolio - not authenticated',
        tag: 'ProfileVM',
      );
      return;
    }

    isLoadingPortfolio = true;
    notifyListeners();

    AppLogger.i(
      'Fetching portfolio',
      tag: 'ProfileVM',
      json: {'userId': user.id},
    );

    try {
      final items = await _repo.getPortfolioItems(user.id);
      _portfolioItems.clear();
      // Resolve all image URLs in parallel
      final resolvedItems = await Future.wait(
        items.map((item) async {
          final resolvedUrl = await _repo.resolvePortfolioImageUrl(
            item.effectiveImageRef,
          );
          return {
            'id': item.id,
            'title': item.title,
            'description': item.description,
            'image_url': resolvedUrl,
            'created_at': item.createdAt.toIso8601String(),
          };
        }).toList(),
      );
      _portfolioItems.addAll(resolvedItems);
      AppLogger.i(
        'Portfolio fetched',
        tag: 'ProfileVM',
        json: {'count': items.length},
      );
    } on Exception catch (e, st) {
      AppLogger.e(
        'Error loading portfolio',
        tag: 'ProfileVM',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoadingPortfolio = false;
      notifyListeners();
    }
  }

  // --- Portfolio CRUD Operations ---

  bool isUploadingPortfolioImage = false;

  /// Picks and uploads a portfolio image.
  /// Returns the storage path for use in addPortfolioItem.
  /// Returns null on cancel or error. Check [portfolioUploadError] for error details.
  String? _portfolioUploadError;
  String? get portfolioUploadError => _portfolioUploadError;

  Future<String?> pickAndUploadPortfolioImage() async {
    final user = _repo.currentUser;
    if (user == null) {
      AppLogger.w('Cannot upload image - not authenticated', tag: 'ProfileVM');
      return null;
    }

    _portfolioUploadError = null;
    isUploadingPortfolioImage = true;
    notifyListeners();

    try {
      // Use FilePicker instead of ImagePicker for better iOS stability
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Get bytes directly
      );

      if (result == null || result.files.isEmpty) {
        AppLogger.d('User cancelled image picker', tag: 'ProfileVM');
        return null;
      }

      final file = result.files.first;
      var bytes = file.bytes;

      // If bytes not available, read from path (shouldn't happen with withData: true)
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) {
        AppLogger.e('Failed to read file bytes', tag: 'ProfileVM');
        return null;
      }

      AppLogger.i(
        'Uploading portfolio image',
        tag: 'ProfileVM',
        json: {'filename': file.name, 'size': bytes.length},
      );

      // Compress image to prevent OOM and reduce upload size
      Uint8List? compressedBytes;
      try {
        compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 1920,
          minHeight: 1920,
          quality: 80,
        );
        AppLogger.i(
          'Image compressed',
          tag: 'ProfileVM',
          json: {
            'originalSize': bytes.length,
            'compressedSize': compressedBytes.length,
          },
        );
      } on Exception catch (e) {
        AppLogger.w('Compression failed, using original: $e', tag: 'ProfileVM');
        compressedBytes = bytes;
      }

      final fileExt = file.extension?.toLowerCase() ?? 'jpg';
      final contentType = fileExt == 'png'
          ? 'image/png'
          : (fileExt == 'jpg' || fileExt == 'jpeg')
          ? 'image/jpeg'
          : 'application/octet-stream';

      final path = await _repo.uploadPortfolioImage(
        userId: user.id,
        bytes: compressedBytes,
        contentType: contentType,
        fileExt: fileExt,
      );
      AppLogger.i(
        'Portfolio image uploaded',
        tag: 'ProfileVM',
        json: {'path': path},
      );
      return path;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Error uploading portfolio image',
        tag: 'ProfileVM',
        error: e,
        stackTrace: st,
      );
      _portfolioUploadError = 'Failed to upload image. Please try again.';
      notifyListeners();
      return null;
    } finally {
      isUploadingPortfolioImage = false;
      notifyListeners();
    }
  }

  /// Adds a new portfolio item with optional image.
  /// [imagePath] is the storage path returned from pickAndUploadPortfolioImage.
  Future<void> addPortfolioItem({
    required String title,
    String? description,
    String? imagePath,
  }) async {
    final user = _repo.currentUser;
    if (user == null) {
      AppLogger.w('Cannot add item - not authenticated', tag: 'ProfileVM');
      return;
    }

    AppLogger.i(
      'Adding portfolio item',
      tag: 'ProfileVM',
      json: {'title': title, 'hasImage': imagePath != null},
    );

    try {
      // Note: This is a workaround since the repository expects bytes
      // The upload already happened in pickAndUploadPortfolioImage
      // We create the item without re-uploading the image
      await _repo.addPortfolioItem(
        userId: user.id,
        title: title,
        description: description,
        imagePath: imagePath,
      );
      await fetchPortfolio();
      AppLogger.i('Portfolio item added successfully', tag: 'ProfileVM');
    } on Exception catch (e, st) {
      AppLogger.e(
        'Error adding portfolio item',
        tag: 'ProfileVM',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates a portfolio item.
  Future<void> updatePortfolioItem({
    required String itemId,
    required String title,
    String? description,
  }) async {
    AppLogger.i(
      'Updating portfolio item',
      tag: 'ProfileVM',
      json: {'itemId': itemId, 'title': title},
    );

    try {
      await _repo.updatePortfolioItem(
        itemId: itemId,
        title: title,
        description: description,
      );
      await fetchPortfolio();
      AppLogger.i('Portfolio item updated successfully', tag: 'ProfileVM');
    } on Exception catch (e, st) {
      AppLogger.e(
        'Error updating portfolio item',
        tag: 'ProfileVM',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Deletes a portfolio item.
  Future<void> deletePortfolioItem(String itemId) async {
    AppLogger.i(
      'Deleting portfolio item',
      tag: 'ProfileVM',
      json: {'itemId': itemId},
    );

    try {
      await _repo.deletePortfolioItem(itemId);
      await fetchPortfolio();
      AppLogger.i('Portfolio item deleted successfully', tag: 'ProfileVM');
    } on Exception catch (e, st) {
      AppLogger.e(
        'Error deleting portfolio item',
        tag: 'ProfileVM',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // Fetch tasks created by the current user
  Future<void> fetchMyTasks() async {
    final user = _repo.currentUser;
    if (user == null) return;

    isLoadingMyTasks = true;
    notifyListeners();

    try {
      final tasks = await _repo.getTasksByUser(user.id);
      myTasks
        ..clear()
        ..addAll(tasks);
    } on Exception catch (e) {
      AppLogger.e('Error fetching user tasks: $e');
    } finally {
      isLoadingMyTasks = false;
      notifyListeners();
    }
  }

  // Delete one of the user's tasks
  Future<void> deleteMyTask(String taskId) async {
    try {
      await _repo.deleteTask(taskId);
      myTasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
    } on Exception catch (e) {
      AppLogger.e('Error deleting task: $e');
    }
  }

  // Update a task
  Future<void> updateMyTask(String taskId, Map<String, dynamic> updates) async {
    try {
      await _repo.updateTask(taskId, updates);
      await fetchMyTasks();
    } on Exception catch (e) {
      AppLogger.e('Error updating task: $e');
    }
  }

  // Sign out the current user. Returns true on success.
  // The caller (View) is responsible for navigating to /login after signOut.
  Future<bool> signOut() async {
    try {
      await _repo.signOut();
      AppLogger.i('User signed out', tag: 'ProfileVM');
      return true;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Sign out failed',
        tag: 'ProfileVM',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Enhanced role change with atomic protection, session refresh, and teardown.
  ///
  /// This is the NEW implementation that replaces the naive changeRole().
  /// It uses the atomic RPC, refreshes the session for JWT claims, and executes
  /// the teardown contract across all registered ViewModels.
  Future<bool> changeRole(String newRole) async {
    final user = _repo.currentUser;
    if (user == null) {
      AppLogger.w('change_role_no_user', tag: 'ProfileVM');
      return false;
    }

    // Get current role for expected_old_role guard
    final currentRole = _profile?.activeRole ?? 'client';
    if (currentRole == newRole) {
      AppLogger.d('change_role_same_role', tag: 'ProfileVM');
      return true; // Nothing to do
    }

    _isLoadingUpdate = true;
    _profileError = null;
    notifyListeners();

    AppLogger.i(
      'role_switch_initiated',
      tag: 'ProfileVM',
      json: {'from': currentRole, 'to': newRole},
    );

    try {
      // 1. Check rate limit
      final rateLimitOk = await _repo.roleSwitch.checkRateLimit();
      if (!rateLimitOk) {
        _profileError = 'Too many role switches. Please wait a minute.';
        AppLogger.w('role_switch_rate_limited', tag: 'ProfileVM');
        _isLoadingUpdate = false;
        notifyListeners();
        return false;
      }

      // 2. Call atomic RPC
      final result = await _repo.roleSwitch.switchRole(
        expectedOldRole: currentRole,
        newRole: newRole,
      );

      if (!result.success) {
        _profileError = result.displayError;
        AppLogger.w(
          'role_switch_rpc_failed: ${result.errorCode}',
          tag: 'ProfileVM',
        );
        _isLoadingUpdate = false;
        notifyListeners();
        return false;
      }

      // 3. Session refresh - HARD BLOCKER
      AppLogger.d('role_switch_refreshing_session', tag: 'ProfileVM');
      final refreshSuccess = await _repo.roleSwitch.refreshSession(
        maxRetries: 3,
      );
      if (!refreshSuccess) {
        _profileError = 'Session refresh failed. Please log in again.';
        AppLogger.e('role_switch_session_refresh_failed', tag: 'ProfileVM');
        _isLoadingUpdate = false;
        notifyListeners();
        return false;
      }

      // 4. Verify JWT role matches
      final jwtMatches = _repo.roleSwitch.verifyJwtRole(newRole);
      if (!jwtMatches) {
        AppLogger.w(
          'role_switch_jwt_mismatch, retrying once',
          tag: 'ProfileVM',
        );
        // Retry session refresh once
        await Future.delayed(const Duration(milliseconds: 500));
        final retrySuccess = await _repo.roleSwitch.refreshSession(
          maxRetries: 1,
        );
        if (!retrySuccess || !_repo.roleSwitch.verifyJwtRole(newRole)) {
          _profileError = 'Role sync failed. Please log in again.';
          AppLogger.e('role_switch_jwt_verification_failed', tag: 'ProfileVM');
          _isLoadingUpdate = false;
          notifyListeners();
          return false;
        }
      }

      // 5. Execute teardown contract via coordinator
      AppLogger.i('role_switch_teardown_begin', tag: 'ProfileVM');
      try {
        await RoleSwitchCoordinator().teardownAll();
        AppLogger.i('role_switch_teardown_complete', tag: 'ProfileVM');
      } on Exception catch (e) {
        AppLogger.e('role_switch_teardown_failed: $e', tag: 'ProfileVM');
        // Continue even if teardown has errors - better to proceed with warnings
      }

      // 6. Update local profile state (note: ProfileModel.activeRole is immutable via copyWith)
      // We reload the profile in step 7 to get fresh data from the server

      // 7. Reload profile to confirm
      await loadUserData();

      AppLogger.i('role_switch_success', tag: 'ProfileVM');
      _isLoadingUpdate = false;
      notifyListeners();
      return true;
    } on Exception catch (e, stackTrace) {
      AppLogger.e(
        'role_switch_exception',
        tag: 'ProfileVM',
        error: e,
        stackTrace: stackTrace,
      );
      _profileError = 'Failed to switch role. Please try again.';
      _isLoadingUpdate = false;
      notifyListeners();
      return false;
    }
  }

  /// Legacy role change - DEPRECATED.
  /// Use [changeRole] with the new atomic implementation.
  @Deprecated('Use changeRole() for atomic role switching with full teardown')
  Future<void> changeRoleLegacy(String newRole) async {
    final user = _repo.currentUser;
    if (user == null) return;
    AppLogger.w('change_role_legacy_called', tag: 'ProfileVM');
    await _repo.changeRole(userId: user.id, newRole: newRole);
    notifyListeners();
  }

  // Send password reset email
  Future<void> changePassword() async {
    final user = _repo.currentUser;
    if (user == null) return;
    await _repo.resetPasswordForEmail(user.email!);
  }

  /// Picks and uploads an avatar image.
  /// Check [avatarUploadError] for error details after completion.
  String? _avatarUploadError;
  String? get avatarUploadError => _avatarUploadError;

  Future<void> pickAndUploadAvatar() async {
    final user = _repo.currentUser;
    if (user == null) return;

    // Use FilePicker instead of ImagePicker for better iOS stability
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    _avatarUploadError = null;
    if (result == null || result.files.isEmpty) return;

    avatarUploading = true;
    notifyListeners();

    try {
      final file = result.files.first;
      var bytes = file.bytes;

      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) {
        AppLogger.e('Failed to read avatar bytes');
        return;
      }

      // Compress avatar
      Uint8List compressedBytes;
      try {
        compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 512,
          minHeight: 512,
          quality: 85,
        );
      } on Exception catch (e) {
        AppLogger.w('Avatar compression failed, using original: $e');
        compressedBytes = bytes;
      }

      final fileExt = file.extension?.toLowerCase() ?? 'jpg';
      final contentType = fileExt == 'png'
          ? 'image/png'
          : (fileExt == 'jpg' || fileExt == 'jpeg')
          ? 'image/jpeg'
          : 'application/octet-stream';

      final storagePath = await _repo.uploadAvatar(
        userId: user.id,
        bytes: compressedBytes,
        contentType: contentType,
        fileExt: fileExt,
      );

      avatarSignedUrl = await _repo.createSignedAvatarUrl(storagePath);
      AppLogger.i('Avatar uploaded and profile updated');
    } on Exception catch (e) {
      AppLogger.e('Error uploading avatar: $e');
      _avatarUploadError = 'Failed to upload avatar. Please try again.';
    } finally {
      avatarUploading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAvatarSignedUrl() async {
    final user = _repo.currentUser;
    if (user == null) return;
    try {
      final path = await _repo.getAvatarPath(user.id);
      if (path != null && path.isNotEmpty) {
        avatarSignedUrl = await _repo.createSignedAvatarUrl(path);
        notifyListeners();
      }
    } on StorageException catch (e) {
      avatarSignedUrl = null;
      notifyListeners();
      // 404 = file missing in storage (deleted or path stale); expected, no user-facing log
      if (e.statusCode == '404' ||
          e.message.toLowerCase().contains('not found')) {
        AppLogger.d(
          'Avatar object not found in storage, showing placeholder',
          tag: 'Profile',
          json: {'error': e.message},
        );
      } else {
        AppLogger.e('Failed to refresh avatar signed url: $e');
      }
    } on Exception catch (e) {
      avatarSignedUrl = null;
      notifyListeners();
      AppLogger.e('Failed to refresh avatar signed url: $e');
    }
  }
}
