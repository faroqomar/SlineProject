import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/task_repository.dart';
import '../models/task_model.dart';
import '../services/task_image_service.dart';

import '../../../core/services/logger_service.dart';
import '../../../core/app_enums.dart';
import '../../../core/mixins/role_switch_aware.dart';
import '../../../core/services/role_switch_coordinator.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/models/category_model.dart';

/// TaskViewModel — MVVM state holder for Tasks feature.
///
/// Performance: Optimized to minimize redundant notifyListeners() calls.
/// Each state-changing method calls notifyListeners() only once at the end.
class TaskViewModel extends ChangeNotifier with RoleSwitchAware {
  TaskViewModel({
    TaskRepository? repo,
    SupabaseClient? client,
    CategoriesRepository? categoriesRepo,
  }) : _repo = repo ?? TaskRepository(client ?? Supabase.instance.client),
       _categoriesRepo =
           categoriesRepo ??
           CategoriesRepository(client ?? Supabase.instance.client) {
    // Register with role switch coordinator
    RoleSwitchCoordinator().register(this);
  }

  final TaskRepository _repo;
  final CategoriesRepository _categoriesRepo;

  final List<Task> _tasks = [];
  bool _isLoading = false;

  final List<XFile> _pickedImages = [];
  bool _uploadingImages = false;

  // ----- Categories state -----
  List<CategoryModel> _categories = [];
  bool _categoriesLoading = false;

  List<CategoryModel> get categories => List.unmodifiable(_categories);
  bool get categoriesLoading => _categoriesLoading;

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;

  List<XFile> get pickedImages => List.unmodifiable(_pickedImages);
  bool get uploadingImages => _uploadingImages;

  String? get currentUserId => _repo.currentUser?.id;

  // ----- Categories helpers -----
  /// Loads all categories from the repository.
  /// Called by CreateTaskScreen to populate the category picker.
  Future<List<CategoryModel>> loadCategories() async {
    _categoriesLoading = true;
    // Do not call notifyListeners() synchronously here — this method may be
    // invoked during didChangeDependencies which runs inside the build phase.
    // The finally block notifies after the async gap completes.
    try {
      _categories = await _categoriesRepo.getAll();
      AppLogger.d(
        'Loaded ${_categories.length} categories',
        tag: 'TaskViewModel',
      );
      return _categories;
    } on Exception catch (e, stackTrace) {
      AppLogger.e(
        'Failed to load categories',
        tag: 'TaskViewModel',
        error: e,
        stackTrace: stackTrace,
      );
      _categories = [];
      return _categories;
    } finally {
      _categoriesLoading = false;
      notifyListeners();
    }
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
    if (_pickedImages.isEmpty) return; // Skip if nothing to clear
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
        final path = await TaskImageService().uploadBytes(
          bytes: bytes,
          fileExt: ext,
          userId: userId,
          taskId: taskId,
        );
        uploadedPaths.add(path);
      }
    } on Exception catch (e) {
      AppLogger.e('Error uploading task images: $e');
    } finally {
      _uploadingImages = false;
      notifyListeners();
    }
    return uploadedPaths;
  }

  /// Upload and clear picked images in one operation.
  /// Optimized to minimize notifyListeners() calls.
  Future<List<String>> finalizeTaskImages({
    required String userId,
    required String taskId,
  }) async {
    final paths = await uploadPickedImages(userId: userId, taskId: taskId);
    // Clear picked images after upload and notify if there were any to clear
    // Note: uploadPickedImages already notified about uploading state changes
    final hadImages = _pickedImages.isNotEmpty;
    _pickedImages.clear();
    if (hadImages) {
      notifyListeners();
    }
    return paths;
  }

  // ----- Tasks CRUD -----
  Future<void> loadTasks() async {
    if (_isLoading) return; // Prevent duplicate loads

    _isLoading = true;
    notifyListeners();

    try {
      final list = await _repo.getTasks();
      _tasks
        ..clear()
        ..addAll(list);
    } on Exception catch (e) {
      AppLogger.e('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Single notification at end
    }
  }

  Future<Task> createTask(Task task) async {
    _isLoading = true;
    notifyListeners();

    try {
      final created = await _repo.createTask(task);
      _tasks.insert(0, created);
      return created;
    } finally {
      _isLoading = false;
      notifyListeners(); // Single notification at end
    }
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    await _repo.updateTask(taskId, updates);
    // Optimistic update for fields that may be shown in lists
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

  Future<Task?> getTaskById(String taskId) async {
    return _repo.getTaskById(taskId);
  }

  @override
  void dispose() {
    RoleSwitchCoordinator().unregister(this);
    super.dispose();
  }

  /// RoleSwitchAware implementation: Teardown during role switch.
  @override
  Future<void> teardownForRoleSwitch() async {
    AppLogger.i('task_teardown_role_switch', tag: 'TaskVM');

    // Clear all cached task data
    _tasks.clear();
    _pickedImages.clear();
    _isLoading = false;
    _uploadingImages = false;

    AppLogger.i('task_teardown_complete', tag: 'TaskVM');
    notifyListeners();
  }
}
