import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/orders/services/orders_service.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';

class OrdersViewModel extends ChangeNotifier {
  final OrdersService _ordersService;

  OrdersViewModel({OrdersService? ordersService})
    : _ordersService = ordersService ?? OrdersService();

  // State
  List<Task> _allOrders = [];
  bool _isLoading = false;
  String _activeTab = 'Open'; // Open, In Progress, Completed, Cancelled

  // Getters
  bool get isLoading => _isLoading;
  String get activeTab => _activeTab;

  List<Task> get filteredOrders {
    switch (_activeTab) {
      case 'Open':
        return _allOrders.where((t) => t.status == TaskStatus.open).toList();
      case 'In Progress':
        return _allOrders
            .where(
              (t) =>
                  t.status == TaskStatus.inProgress ||
                  t.status == TaskStatus.assigned,
            )
            .toList();
      case 'Completed':
        return _allOrders.where((t) => t.status == TaskStatus.closed).toList();
      case 'Cancelled':
        return _allOrders
            .where((t) => t.status == TaskStatus.canceled)
            .toList();
      default:
        return _allOrders;
    }
  }

  // Actions
  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allOrders = await _ordersService.getMyPublishedTasks();
    } catch (e) {
      AppLogger.e('Failed to load orders', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setActiveTab(String tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _ordersService.deleteTask(taskId);
      _allOrders.removeWhere((t) => t.id == taskId);
      notifyListeners();
    } catch (e) {
      AppLogger.e('Failed to delete task', error: e);
      rethrow;
    }
  }

  // Offers Logic (pass-through for UI to call easily)
  Future<List<TaskRequest>> fetchOffers(String taskId) async {
    return _ordersService.getTaskOffers(taskId);
  }

  Future<void> acceptOffer(String taskId, String offerId) async {
    try {
      await _ordersService.acceptOffer(offerId);
      // Optimistically update the task status to Assigned/InProgress
      final index = _allOrders.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        // Ideally we fetch the updated task, but for now generic update:
        // Note: TaskModel is immutable, need copyWith
        // But status is complicated. Easier to reload all or just rely on refresh.
        // We'll reload for safety.
        await loadOrders();
      }
    } catch (e) {
      AppLogger.e('Failed to accept offer', error: e);
      rethrow;
    }
  }

  Future<void> rejectOffer(String offerId) async {
    try {
      await _ordersService.rejectOffer(offerId);
      // No task status change needed usually
    } catch (e) {
      AppLogger.e('Failed to reject offer', error: e);
      rethrow;
    }
  }
}
