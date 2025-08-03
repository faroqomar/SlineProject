import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/services/task_service.dart';
/// Controller for managing profile functionality
class ProfileController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final bioController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  final TaskService _taskService = TaskService();
  List<Task> myTasks = [];
  bool isLoadingMyTasks = false;

  /// Load current user data into controllers
  Future<void> loadUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    nameController.text = profile['full_name'] ?? '';
    emailController.text = user.email ?? '';
    bioController.text = profile['bio'] ?? '';
  }

  /// Update profile with form data
  Future<void> updateProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (formKey.currentState!.validate()) {
      await _supabase.from('profiles').update({
        'full_name': nameController.text.trim(),
        'bio': bioController.text.trim(),
      }).eq('id', user.id);

      // Optionally update email
      await _supabase.auth.updateUser(
        UserAttributes(email: emailController.text.trim()),
      );
    }
  }

  /// Sign out the current user
  Future<void> signOut(BuildContext context) async {
    await _supabase.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  /// Change user role (toggle between client and freelancer)
  Future<void> changeRole(String newRole) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('profiles').update({
      'role': newRole,
    }).eq('id', user.id);

    notifyListeners();
  }

  /// Send password reset email
  Future<void> changePassword() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.auth.resetPasswordForEmail(user.email!);
  }

  /// Upload profile image and update avatar URL
  Future<void> uploadProfileImage(XFile imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final fileExt = imageFile.path.split('.').last;
    final filePath = 'avatars/${user.id}.$fileExt';
    final file = File(imageFile.path);

    await _supabase.storage
        .from('avatars')
        .upload(filePath, file, fileOptions: FileOptions(upsert: true));

    final publicUrl =
        _supabase.storage.from('avatars').getPublicUrl(filePath);
    await _supabase
        .from('profiles')
        .update({'avatar_url': publicUrl}).eq('id', user.id);

    notifyListeners();
  }

  /// Fetch tasks created by the current user
  Future<void> fetchMyTasks() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    isLoadingMyTasks = true;
    notifyListeners();

    try {
      final tasks = await _taskService.getTasksByUser(user.id);
      myTasks = tasks;
    } catch (e) {
      // Error: Failed to fetch user tasks
      AppLogger.e('Error fetching user tasks: $e');
    } finally {
      isLoadingMyTasks = false;
      notifyListeners();
    }
  }

  /// Delete one of the user's tasks
  Future<void> deleteMyTask(String taskId) async {
    try {
      await _taskService.deleteTask(taskId);
      myTasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
    } catch (e) {
      // Error: Failed to delete task
      AppLogger.e('Error deleting task: $e');
    }
  }

  /// Update a task
  Future<void> updateMyTask(String taskId, Map<String, dynamic> updates) async {
    try {
      await _taskService.updateTask(taskId, updates);
      await fetchMyTasks(); // refresh list
    } catch (e) {
      // Error: Failed to update task
      AppLogger.e('Error updating task: $e');
    }
  }
}
