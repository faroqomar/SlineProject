import 'package:flutter/material.dart';
import '../../tasks/models/task_model.dart';

/// Controller for managing home screen functionality
class HomeController extends ChangeNotifier {
  final List<Task> _featuredTasks = [];
  bool _isLoading = false;

  /// List of featured tasks for home screen
  List<Task> get featuredTasks => List.unmodifiable(_featuredTasks);

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Load featured tasks for home screen
  Future<void> loadFeaturedTasks() async {
    _setLoading(true);
    try {
      // TODO: Implement loading featured tasks from Supabase
      // final tasks = await _taskService.getFeaturedTasks();
      // _featuredTasks.clear();
      // _featuredTasks.addAll(tasks);
      
      // Mock data for now
      _featuredTasks.clear();
      _featuredTasks.addAll([
        Task(
          id: '1',
          title: 'Website Development',
          description: 'Need a modern website for my business',
          budget: 500.0,
          postedBy: 'client1',
          status: TaskStatus.open,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          skills: ['Flutter', 'Web Development'],
        ),
        Task(
          id: '2',
          title: 'Mobile App Design',
          description: 'Design UI/UX for mobile application',
          budget: 800.0,
          postedBy: 'client2',
          status: TaskStatus.open,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          skills: ['UI/UX', 'Mobile Design'],
        ),
        Task(
          id: '3',
          title: 'Logo Design',
          description: 'Create a professional logo for startup',
          budget: 200.0,
          postedBy: 'client3',
          status: TaskStatus.open,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          skills: ['Graphic Design', 'Branding'],
        ),
      ]);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading featured tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh home data
  Future<void> refresh() async {
    await loadFeaturedTasks();
  }
}
