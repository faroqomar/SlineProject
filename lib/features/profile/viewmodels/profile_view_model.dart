import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../../tasks/models/task_model.dart';
import '../data/profile_repository.dart';
import '../models/profile_model.dart';

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

  // Form controllers and keys
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final bioController = TextEditingController();
  final formKey = GlobalKey<FormState>();

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
  String? get fullName =>
      nameController.text.isEmpty ? null : nameController.text;

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

      nameController.text = _profile?.fullName ?? '';
      emailController.text = user.email ?? '';
      bioController.text = _profile?.bio ?? '';

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
    } catch (e) {
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

      nameController.text = _profile?.fullName ?? '';
      emailController.text = user.email ?? '';
      bioController.text = _profile?.bio ?? '';

      _skills.clear();
      if (_profile?.skills != null) {
        _skills.addAll(_profile!.skills);
      }

      await Future.wait([refreshAvatarSignedUrl(), fetchPortfolio()]);
      // await fetchMyTasks(); // Optional: load tasks here if needed immediately
    } catch (e) {
      AppLogger.e('Error loading profile: $e');
      _profileError = 'Failed to load profile. Please try again.';
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  // Update profile with form data
  Future<void> updateProfile() async {
    final user = _repo.currentUser;
    if (user == null) return;

    if (formKey.currentState?.validate() ?? false) {
      _isLoadingUpdate = true;
      notifyListeners();

      try {
        await _repo.updateProfileFields(
          userId: user.id,
          fullName: nameController.text.trim(),
          bio: bioController.text.trim(),
        );
        // await _repo.updateUserEmail(emailController.text.trim()); // TODO: Handle email change separately (re-auth required)
        await _repo.updateProfileSkills(userId: user.id, skills: _skills);

        await loadUserData(); // Refresh local state
        AppLogger.i('Profile updated successfully');
      } catch (e) {
        AppLogger.e('Error updating profile: $e');
        _profileError = 'Failed to update profile. Please try again.';
      } finally {
        _isLoadingUpdate = false;
        notifyListeners();
      }
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

  // Portfolio management
  Future<void> fetchPortfolio() async {
    final user = _repo.currentUser;
    if (user == null) return;

    isLoadingPortfolio = true;
    notifyListeners();

    try {
      final items = await _repo.getPortfolioItems(user.id);
      _portfolioItems.clear();
      _portfolioItems.addAll(items);
    } catch (e) {
      AppLogger.e('Error loading portfolio: $e');
    } finally {
      isLoadingPortfolio = false;
      notifyListeners();
    }
  }

  // --- Portfolio CRUD Operations ---

  bool isUploadingPortfolioImage = false;

  Future<String?> pickAndUploadPortfolioImage(BuildContext context) async {
    final user = _repo.currentUser;
    if (user == null) return null;

    try {
      // Use FilePicker instead of ImagePicker for better iOS stability
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Get bytes directly
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      Uint8List? bytes = file.bytes;

      // If bytes not available, read from path (shouldn't happen with withData: true)
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) {
        AppLogger.e('Failed to read file bytes');
        return null;
      }

      // Compress image to prevent OOM and reduce upload size
      Uint8List? compressedBytes;
      try {
        compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 1920,
          minHeight: 1920,
          quality: 80,
        );
      } catch (e) {
        AppLogger.w('Compression failed, using original: $e');
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
      AppLogger.i('Portfolio image uploaded: $path');
      return path;
    } catch (e, st) {
      AppLogger.e('Error uploading portfolio image', error: e, stackTrace: st);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
      return null;
    }
  }

  Future<void> addPortfolioItem({
    required String title,
    String? description,
    String? imageUrl,
  }) async {
    final user = _repo.currentUser;
    if (user == null) return;

    try {
      await _repo.addPortfolioItem(
        userId: user.id,
        title: title,
        description: description,
        imageUrl: imageUrl,
      );
      await fetchPortfolio();
      AppLogger.i('Portfolio item added successfully');
    } catch (e) {
      AppLogger.e('Error adding portfolio item: $e');
      rethrow;
    }
  }

  Future<void> updatePortfolioItem({
    required String itemId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _repo.updatePortfolioItem(itemId: itemId, updates: updates);
      await fetchPortfolio();
      AppLogger.i('Portfolio item updated successfully');
    } catch (e) {
      AppLogger.e('Error updating portfolio item: $e');
      rethrow;
    }
  }

  Future<void> deletePortfolioItem(String itemId) async {
    try {
      await _repo.deletePortfolioItem(itemId);
      await fetchPortfolio();
      AppLogger.i('Portfolio item deleted successfully');
    } catch (e) {
      AppLogger.e('Error deleting portfolio item: $e');
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
    } catch (e) {
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
    } catch (e) {
      AppLogger.e('Error deleting task: $e');
    }
  }

  // Update a task
  Future<void> updateMyTask(String taskId, Map<String, dynamic> updates) async {
    try {
      await _repo.updateTask(taskId, updates);
      await fetchMyTasks();
    } catch (e) {
      AppLogger.e('Error updating task: $e');
    }
  }

  // Sign out the current user
  Future<void> signOut(BuildContext context) async {
    await _repo.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  // Change user role (toggle between client and freelancer)
  Future<void> changeRole(String newRole) async {
    final user = _repo.currentUser;
    if (user == null) return;
    await _repo.changeRole(userId: user.id, newRole: newRole);
    notifyListeners();
  }

  // Send password reset email
  Future<void> changePassword() async {
    final user = _repo.currentUser;
    if (user == null) return;
    await _repo.resetPasswordForEmail(user.email!);
  }

  Future<void> pickAndUploadAvatar(BuildContext context) async {
    final user = _repo.currentUser;
    if (user == null) return;

    // Use FilePicker instead of ImagePicker for better iOS stability
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    avatarUploading = true;
    notifyListeners();

    try {
      final file = result.files.first;
      Uint8List? bytes = file.bytes;

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
      } catch (e) {
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
    } catch (e) {
      AppLogger.e('Error uploading avatar: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload avatar: $e')));
      }
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
    } catch (e) {
      AppLogger.e('Failed to refresh avatar signed url: $e');
    }
  }
}
