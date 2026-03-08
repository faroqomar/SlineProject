import 'package:sline_app/core/services/demo_payment_service.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/core/services/qicard_payment_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';

/// Single orchestration path for tender award → payment.
/// Used by dashboard InboxTab and task-request flows.
/// Ensures: payment confirmation then ledger + pay RPC; no state advance on failure.
/// Tender flow is fail-closed when using demo payment: we never advance to ledger/pay.
class TenderPaymentCoordinator {
  TenderPaymentCoordinator({
    required TaskService taskService,
    required PaymentService paymentService,
  }) : _taskService = taskService,
       _paymentService = paymentService;

  final TaskService _taskService;
  final PaymentService _paymentService;

  /// True when the current payment provider can complete tender:
  /// QiCard via server-backed create → WebView → recovery, or other real provider.
  /// False for Demo (no server-backed tender flow).
  bool get isTenderPaymentAvailable =>
      _paymentService is QiCardPaymentService ||
      _paymentService is! DemoPaymentService;

  /// Runs payment: for QiCard returns open_webview + form_url for WebView;
  /// for other providers runs processPayment then ledger + pay.
  /// Throws on expiry, payment failure, or when create returns error.
  Future<Map<String, dynamic>> executePayment({
    required String requestId,
    required double amount,
    required String currency,
    required String description,
    String? finishUrl,
  }) async {
    AppLogger.i(
      'TenderPaymentCoordinator: starting payment for request $requestId',
      tag: 'TenderPaymentCoordinator',
    );

    if (_paymentService is DemoPaymentService) {
      AppLogger.w(
        'Tender payment skipped: demo payment cannot advance tender state (fail-closed)',
        tag: 'TenderPaymentCoordinator',
      );
      throw Exception(
        'Tender payment requires real payment. Demo mode cannot complete this flow.',
      );
    }

    if (_paymentService is QiCardPaymentService) {
      final result = await _paymentService.createPaymentForTenderOffer(
        requestId: requestId,
        amount: amount,
        currency: currency,
        description: description,
        finishUrl: finishUrl,
      );
      if (!result.isSuccess) {
        throw Exception(result.error ?? 'Payment could not be created.');
      }
      if (result.formUrl == null ||
          result.requestId == null ||
          result.paymentRequestId == null) {
        throw Exception('Payment created but form URL or ids missing.');
      }
      return <String, dynamic>{
        'open_webview': true,
        'form_url': result.formUrl,
        'request_id': result.requestId,
        'payment_request_id': result.paymentRequestId,
      };
    }

    await _paymentService.processPayment(
      amount: amount,
      currency: currency,
      description: description,
    );

    AppLogger.i(
      'TenderPaymentCoordinator: payment confirmed, calling ledger + pay for $requestId',
      tag: 'TenderPaymentCoordinator',
    );
    final result = await _taskService.payAwardedOffer(requestId);
    AppLogger.i(
      'TenderPaymentCoordinator: pay completed for $requestId',
      tag: 'TenderPaymentCoordinator',
    );
    return result;
  }

  /// Recover tender payment after WebView callback (QiCard success).
  Future<QiCardTenderRecoveryResult> recoverTenderPayment({
    required String requestId,
    required String paymentRequestId,
  }) async {
    return _paymentService.recoverTenderPaymentAfterCallback(
      requestId: requestId,
      paymentRequestId: paymentRequestId,
    );
  }
}
