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
  })  : _coordinator = coordinator,
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

  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get success => _success;
  String get taskTitle => _taskTitle;
  String get freelancerName => _freelancerName;
  double get amount => _amount;
  Duration get timeRemaining =>
      _paymentDeadline.difference(DateTime.now());
  bool get isExpired => timeRemaining.isNegative;

  /// Submit payment: run payment flow then ledger + pay.
  Future<void> submit() async {
    if (_isProcessing || isExpired) return;

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _coordinator.executePayment(
        requestId: _requestId,
        amount: _amount,
        currency: 'IQD',
        description: 'Payment for "$_taskTitle"',
      );
      _success = true;
      AppLogger.i(
        'Tender payment completed: $_requestId',
        tag: 'TenderPaymentViewModel',
      );
    } catch (e, st) {
      AppLogger.e(
        'Tender payment failed',
        tag: 'TenderPaymentViewModel',
        error: e,
        stackTrace: st,
      );
      _errorMessage = 'Payment failed: ${e.toString()}';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
