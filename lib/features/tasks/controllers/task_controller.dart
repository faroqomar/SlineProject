import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../models/task_model.dart';
import '../services/task_image_service.dart';


/// Controller for managing task functionality
class TaskController extends ChangeNotifier {
  final List<Task> _tasks = [];
  bool _isLoading = false;

  final List<XFile> _pickedImages = [];
  bool _uploadingImages = false;

  /// List of tasks
  List<Task> get tasks => List.unmodifiable(_tasks);

  /// Current loading state
  bool get isLoading => _isLoading;

  List<XFile> get pickedImages => List.unmodifiable(_pickedImages);
  bool get uploadingImages => _uploadingImages;

  /// Set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> pickTaskImages() async {
    final ImagePicker picker = ImagePicker();
    final images = await picker.pickMultiImage();
    // Keep max 5 and only update state if something changed
    final limited = images.take(5).toList();
    _pickedImages
      ..clear()
      ..addAll(limited);
    notifyListeners();
  }

  void clearPickedImages() {
    _pickedImages.clear();
    notifyListeners();
  }

  /// Replace currently picked images and notify listeners. Limits to 5.
  void setPickedImages(List<XFile> images) {
    _pickedImages
      ..clear()
      ..addAll(images.take(5));
    notifyListeners();
  }

  /// Remove a picked image by index (safe no-op if out of range).
  void removePickedImageAt(int index) {
    if (index >= 0 && index < _pickedImages.length) {
      _pickedImages.removeAt(index);
      notifyListeners();
    }
  }

  Future<List<String>> uploadPickedImages(String userId, String taskId) async {
    if (_pickedImages.isEmpty) return [];
    _uploadingImages = true;
    notifyListeners();

    final List<String> uploadedPaths = [];
    try {
      for (final img in _pickedImages) {
        final bytes = await img.readAsBytes();
        final ext = img.path.split('.').last;
        final path = await TaskImageService()
            .uploadBytes(bytes: bytes, fileExt: ext, userId: userId, taskId: taskId);
        uploadedPaths.add(path);
      }
    } catch (e) {
      AppLogger.e('Error uploading task images: $e');
    } finally {
      _uploadingImages = false;
      notifyListeners();
    }
    return uploadedPaths;
  }

  /// Upload selected images, return storage paths, then clear selection.
  Future<List<String>> finalizeTaskImages({
    required String userId,
    required String taskId,
  }) async {
    final paths = await uploadPickedImages(userId, taskId);
    clearPickedImages();
    return paths;
  }

  /// Load all tasks
  Future<void> loadTasks() async {
    _setLoading(true);
    try {
      // TODO: Implement loading tasks from Supabase
      // final tasks = await _taskService.getTasks();
      // _tasks.clear();
      // _tasks.addAll(tasks);
      
      // Mock data for now
      _tasks.clear();
      _tasks.addAll([
        Task(
          id: '1',
          title: 'Website Development',
          description: 'Need a modern website for my business',
          budget: 500.0,
          userId: 'client1',
          status: TaskStatus.open,
          createdAt: DateTime.now().subtract(const Duration(days: 2)), category: '',
        ),
        Task(
          id: '2',
          title: 'Mobile App Design',
          description: 'Design UI/UX for mobile application',
          budget: 800.0,
          userId: 'client2',
          status: TaskStatus.open,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)), category: '',
        ),
      ]);
      
      notifyListeners();
    } catch (e) {
      // Error: Failed to load tasks
      AppLogger.e('Error loading tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new task
  Future<void> createTask(Task task) async {
    _setLoading(true);
    try {
      // TODO: Implement task creation in Supabase
      // await _taskService.createTask(task);
      
      _tasks.add(task);
      notifyListeners();
    } catch (e) {
      // Error: Failed to create task
      AppLogger.e('Error creating task: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(status: status);
        notifyListeners();
        
        // TODO: Update in Supabase
        // await _taskService.updateTaskStatus(taskId, status);
      }
    } catch (e) {
      // Error: Failed to update task status
      AppLogger.e('Error updating task status: $e');
    }
  }

  /// Get tasks by status
  List<Task> getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }
}
