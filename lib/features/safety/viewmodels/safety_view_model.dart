import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/features/safety/services/dispute_service.dart';
import 'package:sline_app/features/safety/services/report_service.dart';

class SafetyViewModel extends ChangeNotifier {
  SafetyViewModel({
    ReportService? reportService,
    DisputeService? disputeService,
  }) : _reportService = reportService ?? ReportService(),
       _disputeService = disputeService ?? DisputeService();

  final ReportService _reportService;
  final DisputeService _disputeService;

  bool isSubmitting = false;
  String? error;

  Future<bool> submitReport({
    required String entityType,
    required String entityId,
    required String reason,
    String? category,
  }) async {
    isSubmitting = true;
    error = null;
    notifyListeners();
    try {
      await _reportService.submitReport(
        entityType: entityType,
        entityId: entityId,
        reason: reason,
        category: category,
      );
      return true;
    } on Exception catch (e, st) {
      error = _mapError(e);
      AppLogger.e(
        'Submit report failed',
        tag: 'SafetyVM',
        error: e,
        stackTrace: st,
      );
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  /// True if there is an open or active dispute for the given task (used to hide Approve & Release in UI).
  Future<bool> hasOpenDisputeForTask(String taskId) async {
    return _disputeService.hasOpenDisputeForTask(taskId);
  }

  /// True if there is an open or active dispute for the given direct offer.
  Future<bool> hasOpenDisputeForDirectOffer(String offerId) async {
    return _disputeService.hasOpenDisputeForDirectOffer(offerId);
  }

  /// True if there is an open or active dispute for the given booking (via its task).
  Future<bool> hasOpenDisputeForBooking(String bookingId) async {
    return _disputeService.hasOpenDisputeForBooking(bookingId);
  }

  /// Dispute status 'open' or 'active' for task; null if none.
  Future<String?> getDisputeStatusForTask(String taskId) async {
    return _disputeService.getDisputeStatusForTask(taskId);
  }

  /// Dispute status 'open' or 'active' for direct offer; null if none.
  Future<String?> getDisputeStatusForDirectOffer(String offerId) async {
    return _disputeService.getDisputeStatusForDirectOffer(offerId);
  }

  /// Dispute status 'open' or 'active' for booking (via task); null if none.
  Future<String?> getDisputeStatusForBooking(String bookingId) async {
    return _disputeService.getDisputeStatusForBooking(bookingId);
  }

  Future<bool> submitDispute({
    String? taskId,
    String? directOfferId,
    required String reason,
    String? defendantId,
  }) async {
    isSubmitting = true;
    error = null;
    notifyListeners();
    try {
      await _disputeService.submitDispute(
        taskId: taskId,
        directOfferId: directOfferId,
        reason: reason,
        defendantId: defendantId,
      );
      return true;
    } on Exception catch (e, st) {
      error = _mapError(e);
      AppLogger.e(
        'Submit dispute failed',
        tag: 'SafetyVM',
        error: e,
        stackTrace: st,
        json: <String, dynamic>{
          'event_name': 'safety_dispute_submit_failed',
          'task_id': ?taskId,
          'direct_offer_id': ?directOfferId,
        },
      );
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  String _mapError(Object error) {
    final friendly = ErrorMapper.map(error);
    if (friendly != 'An error occurred. Please try again.') return friendly;
    final raw = error.toString().toLowerCase();
    if (raw.contains('permission') || raw.contains('rls')) {
      return 'Not allowed. Please sign in again.';
    }
    if (raw.contains('signed in')) {
      return 'Please sign in to continue.';
    }
    if (raw.contains('reason')) {
      return 'Please provide a reason.';
    }
    return 'Something went wrong. Please try again.';
  }
}
