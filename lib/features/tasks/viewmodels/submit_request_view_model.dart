import 'package:flutter/foundation.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/core/utils/format_price.dart' as price_utils;
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';

/// ViewModel for bid submission / replacement logic.
///
/// Extracted from `submit_request_sheet.dart` to make business logic testable
/// independently of the UI. Used via a scoped `ChangeNotifierProvider` inside
/// the bottom sheet builder.
class SubmitRequestViewModel extends ChangeNotifier {
  static const _kTag = 'SubmitRequestSheet';

  final TaskService _taskService;
  final TaskRequestsService _requestsService;
  final TaskRequestsViewModel _controller;
  final String taskId;
  final String? userId;
  final String budget;

  SubmitRequestViewModel({
    required TaskService taskService,
    required TaskRequestsService requestsService,
    required TaskRequestsViewModel controller,
    required this.taskId,
    required this.userId,
    required this.budget,
  }) : _taskService = taskService,
       _requestsService = requestsService,
       _controller = controller;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _guardError;
  String? get guardError => _guardError;

  String? _submitError;
  String? get submitError => _submitError;

  BidReplaceabilityResult? _replaceabilityResult;
  TaskRequest? _existingBid;
  TaskRequest? get existingBid => _existingBid;

  bool _isReplaceMode = false;
  bool get isReplaceMode => _isReplaceMode;

  /// Whether there's a non-pending existing bid (rejected/withdrawn) that
  /// requires resubmission via the replace RPC instead of a fresh insert.
  bool get isResubmitMode => _existingBid != null && !_isReplaceMode;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Validates the task is open and user is not the owner.
  /// Returns true if the sheet should be shown, false otherwise.
  Future<bool> validateTask() async {
    try {
      final task = await _taskService.getTaskById(taskId);
      if (task == null) {
        _guardError = 'Task not found.';
        return false;
      }
      if (task.status != TaskStatus.open) {
        _guardError = 'This task is no longer accepting offers.';
        return false;
      }
      if (userId != null && task.userId == userId) {
        _guardError = 'You cannot bid on your own task.';
        return false;
      }
      return true;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to check task before opening submit sheet',
        tag: _kTag,
        error: e,
        stackTrace: st,
      );
      _guardError = 'Unable to load task. Please try again.';
      return false;
    }
  }

  /// Checks if the user has an existing bid and determines replace mode.
  /// Returns pre-fill values for the form (price, days, note) if replacing.
  Future<({String price, String days, String note})?>
  checkReplaceability() async {
    try {
      AppLogger.d('Checking bid replaceability for task $taskId', tag: _kTag);
      _replaceabilityResult = await _controller.checkBidReplaceability();
      _existingBid = _replaceabilityResult?.existingBid;

      if (_existingBid != null) {
        AppLogger.i(
          'Found existing bid ${_existingBid!.id} for task $taskId - replace mode',
          tag: _kTag,
        );
        _isReplaceMode = _replaceabilityResult?.isReplaceable ?? false;
        return (
          price: _existingBid!.price.toString(),
          days: _existingBid!.days.toString(),
          note: _existingBid!.note ?? '',
        );
      }
      AppLogger.d(
        'No existing bid found for task $taskId - new bid mode',
        tag: _kTag,
      );
      return null;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to check bid replaceability',
        tag: _kTag,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Price comparison
  // ---------------------------------------------------------------------------

  /// Computes the diff between the existing bid and new values.
  /// Returns null if there's no existing bid.
  /// UI should map priceDiffSign / daysDiffSign to colors.
  ({String priceDiff, int priceDiffSign, String daysDiff, int daysDiffSign})?
  computeComparison({required int newPriceIqd, required int newDays}) {
    final existing = _existingBid;
    if (existing == null) return null;

    final priceDiffVal = newPriceIqd - existing.price;
    final daysDiffVal = newDays - existing.days;

    final priceDiffText = priceDiffVal > 0
        ? '+${price_utils.PriceFormatter.formatPrice(priceDiffVal.toDouble())}'
        : priceDiffVal < 0
        ? '-${price_utils.PriceFormatter.formatPrice(priceDiffVal.abs().toDouble())}'
        : 'No change';
    final daysDiffText = daysDiffVal > 0
        ? '+$daysDiffVal days'
        : daysDiffVal < 0
        ? '-${daysDiffVal.abs()} days'
        : 'No change';

    return (
      priceDiff: priceDiffText,
      priceDiffSign: priceDiffVal.sign,
      daysDiff: daysDiffText,
      daysDiffSign: daysDiffVal.sign,
    );
  }

  // ---------------------------------------------------------------------------
  // Submission
  // ---------------------------------------------------------------------------

  /// Submits a new bid (first-time, no existing bid).
  /// Returns true on success.
  Future<bool> submitNewBid({
    required double price,
    required int days,
    String? note,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();
    try {
      AppLogger.i(
        'Submitting new bid for task $taskId',
        tag: _kTag,
        json: {'price': price.round(), 'currency': 'IQD', 'days': days},
      );

      final ok = await _controller.submitOfferUI(
        taskId: taskId,
        price: price,
        days: days,
        note: note,
      );

      if (ok) {
        AppLogger.i(
          'New bid submitted successfully for task $taskId',
          tag: _kTag,
        );
      } else {
        AppLogger.w(
          'Bid submission failed for task $taskId: ${_controller.errorMessage}',
          tag: _kTag,
        );
        _submitError = _controller.errorMessage;
      }
      return ok;
    } on Exception catch (e, st) {
      AppLogger.e('Failed to submit bid', tag: _kTag, error: e, stackTrace: st);
      _submitError = ErrorMapper.map(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Replaces an existing bid (or resubmits a non-pending bid).
  /// Returns the new TaskRequest on success, null on failure.
  Future<TaskRequest?> replaceBid({
    required double price,
    required int days,
    String? note,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();
    try {
      AppLogger.i(
        'Replacing bid for task $taskId',
        tag: _kTag,
        json: {
          'existingBidId': _existingBid?.id,
          'newPrice': price.round(),
          'currency': 'IQD',
          'newDays': days,
        },
      );

      final replaced = await _requestsService.replaceOffer(
        taskId: taskId,
        price: price,
        days: days,
        note: note,
      );

      AppLogger.i('Bid replaced successfully: ${replaced.id}', tag: _kTag);
      await _controller.loadForTask(taskId);
      return replaced;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to replace bid for task $taskId',
        tag: _kTag,
        error: e,
        stackTrace: st,
      );
      _submitError = _mapSubmitError(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Maps known error patterns to user-friendly messages.
  String _mapSubmitError(Exception e) {
    final msg = e.toString();
    if (msg.contains('cannot bid on your own task')) {
      return 'You cannot bid on your own task.';
    }
    if (msg.contains('no longer open')) {
      return 'This task is no longer accepting offers.';
    }
    return 'Failed to submit bid. Please try again.';
  }

  /// Whether the error indicates the task was closed (triggers list refresh).
  /// Returns false for ownership errors — those don't mean the task closed.
  bool get isTaskClosedError {
    final err = _submitError ?? '';
    return err.contains('no longer accepting offers') &&
        !err.contains('cannot bid on your own');
  }
}
