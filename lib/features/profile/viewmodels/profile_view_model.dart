import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../../tasks/models/task_model.dart';
import '../data/profile_repository.dart';

/// ProfileViewModel — MVVM state holder for Profile feature.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({SupabaseClient? client})
      : _repo = ProfileRepository(client ?? Supabase.instance.client);

  final ProfileRepository _repo;

  // Form controllers and keys
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final bioController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Avatar state
  String? avatarSignedUrl;
  bool avatarUploading = false;

  // Tasks state
  final List<Task> myTasks = [];
  bool isLoadingMyTasks = false;

  // Load current user data into controllers
  Future<void> loadUserData() async {
    final user = _repo.currentUser;
    if (user == null) return;

    final profile = await _repo.fetchProfile(user.id);
    nameController.text = (profile['full_name'] as String?) ?? '';
    emailController.text = user.email ?? '';
    bioController.text = (profile['bio'] as String?) ?? '';

    await refreshAvatarSignedUrl();
  }

  // Update profile with form data
  Future<void> updateProfile() async {
    final user = _repo.currentUser;
    if (user == null) return;

    if (formKey.currentState?.validate() ?? false) {
      await _repo.updateProfileFields(
        userId: user.id,
        fullName: nameController.text.trim(),
        bio: bioController.text.trim(),
      );
      await _repo.updateUserEmail(emailController.text.trim());
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

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    avatarUploading = true;
    notifyListeners();

    try {
      final bytes = await pickedFile.readAsBytes();
      final fileExt = pickedFile.path.split('.').last.toLowerCase();
      final contentType = fileExt == 'png'
          ? 'image/png'
          : (fileExt == 'jpg' || fileExt == 'jpeg')
              ? 'image/jpeg'
              : 'application/octet-stream';

      final storagePath = await _repo.uploadAvatar(
        userId: user.id,
        bytes: bytes,
        contentType: contentType,
        fileExt: fileExt,
      );

      avatarSignedUrl = await _repo.createSignedAvatarUrl(storagePath);
      AppLogger.i('Avatar uploaded and profile updated');
    } catch (e) {
      AppLogger.e('Error uploading avatar: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload avatar: $e')),
        );
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
}
