import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';

/// Single orchestration path for tender award → payment.
/// Used by dashboard InboxTab and task-request flows.
/// Ensures: payment confirmation then ledger + pay RPC; no state advance on failure.
class TenderPaymentCoordinator {
  TenderPaymentCoordinator({
    required TaskService taskService,
    required PaymentService paymentService,
  })  : _taskService = taskService,
        _paymentService = paymentService;

  final TaskService _taskService;
  final PaymentService _paymentService;

  /// Runs payment confirmation (e.g. QiCard) then completes escrow + pay.
  /// Throws on expiry, payment failure, or ledger/RPC failure.
  Future<Map<String, dynamic>> executePayment({
    required String requestId,
    required double amount,
    required String currency,
    required String description,
  }) async {
    AppLogger.i(
      'TenderPaymentCoordinator: starting payment for request $requestId',
      tag: 'TenderPaymentCoordinator',
    );

    await _paymentService.processPayment(
      amount: amount,
      currency: currency,
      description: description,
    );

    final result = await _taskService.payAwardedOffer(requestId);
    AppLogger.i(
      'TenderPaymentCoordinator: pay completed for $requestId',
      tag: 'TenderPaymentCoordinator',
    );
    return result;
  }
}
