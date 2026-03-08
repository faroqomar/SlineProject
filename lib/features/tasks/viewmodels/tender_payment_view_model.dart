import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/tasks/services/tender_payment_coordinator.dart';

/// ViewModel for the tender payment screen.
/// Owns loading, error, and success state; delegates execution to [TenderPaymentCoordinator].
class TenderPaymentViewModel extends ChangeNotifier {
  TenderPaymentViewModel({
    required TenderPaymentCoordinator coordinator,
    required String requestId,
    required String taskTitle,
    required String freelancerName,
    required double amount,
    required DateTime paymentDeadline,
  }) : _coordinator = coordinator,
       _requestId = requestId,
       _taskTitle = taskTitle,
       _freelancerName = freelancerName,
       _amount = amount,
       _paymentDeadline = paymentDeadline;

  final TenderPaymentCoordinator _coordinator;
  final String _requestId;
  final String _taskTitle;
  final String _freelancerName;
  final double _amount;
  final DateTime _paymentDeadline;

  bool _isProcessing = false;
  String? _errorMessage;
  bool _success = false;
  String? _pendingFormUrl;
  String? _pendingRequestId;
  String? _pendingPaymentRequestId;

  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get success => _success;

  /// When set, the screen should push PaymentWebViewScreen and on return call [completeRecovery].
  String? get pendingFormUrl => _pendingFormUrl;
  String? get pendingRequestId => _pendingRequestId;
  String? get pendingPaymentRequestId => _pendingPaymentRequestId;
  bool get hasPendingWebPayment =>
      _pendingFormUrl != null &&
      _pendingRequestId != null &&
      _pendingPaymentRequestId != null;

  /// True when the current payment provider can complete this flow (QiCard or other real provider).
  bool get isTenderPaymentAvailable => _coordinator.isTenderPaymentAvailable;
  String get taskTitle => _taskTitle;
  String get freelancerName => _freelancerName;
  double get amount => _amount;
  Duration get timeRemaining => _paymentDeadline.difference(DateTime.now());
  bool get isExpired => timeRemaining.isNegative;

  /// Submit payment: for QiCard returns pending WebView URL; for others completes ledger + pay.
  Future<void> submit({String? finishUrl}) async {
    if (_isProcessing || isExpired) return;

    _isProcessing = true;
    _errorMessage = null;
    _pendingFormUrl = null;
    _pendingRequestId = null;
    _pendingPaymentRequestId = null;
    notifyListeners();

    try {
      final result = await _coordinator.executePayment(
        requestId: _requestId,
        amount: _amount,
        currency: 'IQD',
        description: 'Payment for "$_taskTitle"',
        finishUrl: finishUrl,
      );

      final openWebView = result['open_webview'] == true;
      final formUrl = result['form_url'] as String?;
      final requestId = result['request_id'] as String?;
      final paymentRequestId = result['payment_request_id'] as String?;

      if (openWebView &&
          formUrl != null &&
          requestId != null &&
          paymentRequestId != null) {
        _pendingFormUrl = formUrl;
        _pendingRequestId = requestId;
        _pendingPaymentRequestId = paymentRequestId;
        AppLogger.i(
          'Tender payment: open WebView for request=$requestId',
          tag: 'TenderPaymentViewModel',
        );
      } else {
        _success = true;
        AppLogger.i(
          'Tender payment completed: $_requestId',
          tag: 'TenderPaymentViewModel',
        );
      }
    } catch (e, st) {
      AppLogger.e(
        'Tender payment failed',
        tag: 'TenderPaymentViewModel',
        error: e,
        stackTrace: st,
      );
      _errorMessage = _userFriendlyPaymentError(e.toString());
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  static String _userFriendlyPaymentError(String raw) {
    if (raw.contains('INVALID_STATE') ||
        raw.contains('must be awarded and unpaid')) {
      return 'This tender is not in a state that allows payment. It may already be paid or expired.';
    }
    if (raw.contains('PAYMENT_NOT_SUCCESS') || raw.contains('cannot recover')) {
      return 'Payment was not completed. Please try again or pay from the payment page.';
    }
    if (raw.contains('PAYMENT_DEADLINE_EXPIRED')) {
      return 'The payment deadline has passed.';
    }
    if (raw.contains('FORBIDDEN') || raw.contains('Only the task owner')) {
      return 'Only the task owner can complete this payment.';
    }
    if (raw.contains('TASK_REQUEST_NOT_FOUND') ||
        raw.contains('TASK_NOT_FOUND')) {
      return 'This tender or task could not be found. Please refresh and try again.';
    }
    if (raw.contains('Payment failed:')) return raw;
    return 'Payment failed. Please try again.';
  }

  /// Call after WebView returns with success. Runs recovery then sets success.
  Future<void> completeRecovery({
    required String requestId,
    required String paymentRequestId,
  }) async {
    if (_isProcessing) return;

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    AppLogger.i(
      'Tender recovery starting requestId=$requestId paymentRequestId=$paymentRequestId',
      tag: 'TenderPaymentViewModel',
    );

    try {
      final recovery = await _coordinator.recoverTenderPayment(
        requestId: requestId,
        paymentRequestId: paymentRequestId,
      );
      if (recovery.isSuccess) {
        _success = true;
        _pendingFormUrl = null;
        _pendingRequestId = null;
        _pendingPaymentRequestId = null;
        AppLogger.i(
          'Tender recovery completed: $requestId',
          tag: 'TenderPaymentViewModel',
        );
      } else {
        AppLogger.w(
          'Tender recovery rejected requestId=$requestId',
          tag: 'TenderPaymentViewModel',
          error: recovery.error ?? 'Recovery failed.',
        );
        _errorMessage = _userFriendlyPaymentError(
          recovery.error ?? 'Recovery failed.',
        );
        _pendingFormUrl = null;
        _pendingRequestId = null;
        _pendingPaymentRequestId = null;
      }
    } catch (e, st) {
      AppLogger.e(
        'Tender recovery failed requestId=$requestId',
        tag: 'TenderPaymentViewModel',
        error: e,
        stackTrace: st,
      );
      _errorMessage = _userFriendlyPaymentError(e.toString());
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Clear pending WebView state (e.g. user closed WebView without paying).
  void clearPendingWebPayment() {
    if (_pendingFormUrl != null ||
        _pendingRequestId != null ||
        _pendingPaymentRequestId != null) {
      _pendingFormUrl = null;
      _pendingRequestId = null;
      _pendingPaymentRequestId = null;
      notifyListeners();
    }
  }
}
