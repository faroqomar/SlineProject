import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';
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
    } catch (e, st) {
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

  Future<bool> submitDispute({
    required String taskId,
    required String reason,
    String? defendantId,
  }) async {
    isSubmitting = true;
    error = null;
    notifyListeners();
    try {
      await _disputeService.submitDispute(
        taskId: taskId,
        reason: reason,
        defendantId: defendantId,
      );
      return true;
    } catch (e, st) {
      error = _mapError(e);
      AppLogger.e(
        'Submit dispute failed',
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

  String _mapError(Object error) {
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
