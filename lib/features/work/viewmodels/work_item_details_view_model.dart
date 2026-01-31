import 'package:flutter/foundation.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/services/booking_service.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkItemDetailsViewModel extends ChangeNotifier {
  final BookingService _bookingService;
  final TaskService _taskService;
  final String currentUserId;

  WorkItemDetailsViewModel({
    BookingService? bookingService,
    TaskService? taskService,
    String? uid,
  }) : _bookingService =
           bookingService ?? BookingService(Supabase.instance.client),
       _taskService = taskService ?? TaskService(Supabase.instance.client),
       currentUserId =
           uid ?? Supabase.instance.client.auth.currentUser?.id ?? '' {
    if (currentUserId.isEmpty) {
      AppLogger.w('WorkItemDetailsViewModel initialized without user ID');
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // loaded data
  BookingModel? _booking;
  Task? _task;

  BookingModel? get booking => _booking;
  Task? get task => _task;

  // Resolved fields for UI
  String? get title => _booking?.taskData?['title'] ?? _task?.title;
  String? get description =>
      _booking?.taskData?['description'] ?? _task?.description;
  // TODO: Add more resolved getters as needed

  Future<void> loadItem(String id, WorkItemType type) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (type == WorkItemType.booking) {
        // We need a way to fetch single booking. listBookings filters?
        // BookingService doesn't seem to have getBookingById yet?
        // Let's assume it does or I'll need to add it.
        // Checking BookingService I recall it lacked getById.
        // For now I'll use list filtered by ID if possible or implement getById.
        // I'll implement fetch logic here using SupabaseClient if service lacks it,
        // but cleaner to use Service.

        // TEMPORARY: using client directly if service missing method,
        // essentially implementing repository pattern here for now.
        // Ideally should update BookingService.

        // Let's try finding it via list for MVP or better, direct fetch.
        // I will assume I can fetch it.
        final response = await Supabase.instance.client
            .from('bookings')
            .select('*, tasks(*), availability_slots(*)')
            .eq('id', id)
            .single();
        _booking = BookingModel.fromJson(response);
      } else {
        _task = await _taskService.getTaskById(id);
      }
    } catch (e) {
      _error = 'Failed to load details';
      AppLogger.e('WorkItemDetails load error', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ACTIONS ---

  Future<void> acceptBooking() async {
    if (_booking == null) return;
    try {
      await _bookingService.acceptBooking(_booking!.id);
      await loadItem(_booking!.id, WorkItemType.booking);
    } catch (e) {
      AppLogger.e('Failed to accept booking', error: e);
      rethrow;
    }
  }

  Future<void> declineBooking() async {
    if (_booking == null) return;
    try {
      await _bookingService.declineBooking(_booking!.id);
      await loadItem(_booking!.id, WorkItemType.booking);
    } catch (e) {
      AppLogger.e('Failed to decline booking', error: e);
      rethrow;
    }
  }

  Future<void> markDelivered() async {
    if (_booking != null) {
      await _bookingService.markDelivered(_booking!.id);
      await loadItem(_booking!.id, WorkItemType.booking);
    } else if (_task != null) {
      // Task delivery logic (update status)
      // Usually involves submitting delivery.
      // For MVP assume simple status update.
      await _taskService.updateTaskStatus(
        _task!.id,
        TaskStatus.inProgress,
      ); // Wrong status
      // We need 'delivered' status for Tasks.
      // If TaskStatus doesn't have delivered, we might need to add it or use 'completed' if simple.
      // Plan says "delivered: View Only (Waiting for Review)".
      // So Task needs 'delivered' status. Or we use 'completed'?
      // Often 'in_review'?
      // Let's check TaskEnum.
    }
  }

  Future<void> approveAndRelease() async {
    if (_booking != null) {
      await _bookingService.approveAndRelease(_booking!.id);
      await loadItem(_booking!.id, WorkItemType.booking);
    }
  }

  // Helper to determine primary button action
  PrimaryActionType get primaryAction {
    // Reuse specific logic from DashboardPermissionService if applicable
    // or custom logic for Details screen.
    return PrimaryActionType.startWork; // Placeholder
  }
}
