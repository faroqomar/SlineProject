
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/task_repository.dart';
import '../models/task_model.dart';
import '../services/task_image_service.dart';
import '../../../core/services/logger_service.dart';

/// TaskViewModel — MVVM state holder for Tasks feature.
class TaskViewModel extends ChangeNotifier {
  TaskViewModel({SupabaseClient? client})
      : _repo = TaskRepository(client ?? Supabase.instance.client);

  final TaskRepository _repo;

  final List<Task> _tasks = [];
  bool _isLoading = false;

  final List<XFile> _pickedImages = [];
  bool _uploadingImages = false;

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;

  List<XFile> get pickedImages => List.unmodifiable(_pickedImages);
  bool get uploadingImages => _uploadingImages;

  String? get currentUserId => _repo.currentUser?.id;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  // ----- Images helpers (migrated from TaskController) -----
  Future<void> pickTaskImages() async {
    final ImagePicker picker = ImagePicker();
    final images = await picker.pickMultiImage();
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

  void setPickedImages(List<XFile> images) {
    _pickedImages
      ..clear()
      ..addAll(images.take(5));
    notifyListeners();
  }

  void removePickedImageAt(int index) {
    if (index >= 0 && index < _pickedImages.length) {
      _pickedImages.removeAt(index);
      notifyListeners();
    }
  }

  Future<List<String>> uploadPickedImages({
    required String userId,
    required String taskId,
  }) async {
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

  Future<List<String>> finalizeTaskImages({
    required String userId,
    required String taskId,
  }) async {
    final paths = await uploadPickedImages(userId: userId, taskId: taskId);
    clearPickedImages();
    return paths;
  }

  // ----- Tasks CRUD -----
  Future<void> loadTasks() async {
    _setLoading(true);
    try {
      final list = await _repo.getTasks();
      _tasks
        ..clear()
        ..addAll(list);
      notifyListeners();
    } catch (e) {
      AppLogger.e('Error loading tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Task> createTask(Task task) async {
    _setLoading(true);
    try {
      final created = await _repo.createTask(task);
      _tasks.insert(0, created);
      notifyListeners();
      return created;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    await _repo.updateTask(taskId, updates);
    // optimistic update for fields that may be shown in lists (title/desc/budget)
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final t = _tasks[idx];
      _tasks[idx] = t.copyWith(
        title: updates['title'] as String? ?? t.title,
        description: updates['description'] as String? ?? t.description,
        budget: (updates['budget'] as num?)?.toDouble() ?? t.budget,
      );
      notifyListeners();
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    await _repo.updateTaskStatus(taskId, status);
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(status: status);
      notifyListeners();
    }
  }
}
