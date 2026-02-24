import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/qicard_payment_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/booking/view/payment_webview_screen.dart';

/// Payment screen for completing payment on an awarded tender.
///
/// Flow:
/// 1. Client awards freelancer (creates "Awarded - Pending Payment")
/// 2. Client opens this screen via "Pay Now" button
/// 3. Client completes payment via QiCard gateway
/// 4. On success, escrow is held and work becomes ACTIVE
class TenderPaymentScreen extends StatefulWidget {
  const TenderPaymentScreen({
    super.key,
    required this.requestId,
    required this.taskId,
    required this.taskTitle,
    required this.freelancerName,
    required this.amount,
    required this.paymentDeadline,
    required this.clientId,
  });

  final String requestId;
  final String taskId;
  final String taskTitle;
  final String freelancerName;
  final double amount;
  final DateTime paymentDeadline;
  final String clientId;

  @override
  State<TenderPaymentScreen> createState() => _TenderPaymentScreenState();
}

class _TenderPaymentScreenState extends State<TenderPaymentScreen> {
  bool _isProcessing = false;
  String? _errorMessage;
  late final QiCardPaymentService _paymentService;
  late final TaskService _taskService;

  @override
  void initState() {
    super.initState();
    _paymentService = QiCardPaymentService();
    _taskService = TaskService();
  }

  Duration get _timeRemaining => widget.paymentDeadline.difference(DateTime.now());
  bool get _isExpired => _timeRemaining.isNegative;

  Future<void> _processPayment() async {
    if (_isExpired) {
      setState(() => _errorMessage = 'Payment deadline expired. Award has been cancelled.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Initiate payment with QiCard gateway
      final paymentResult = await _paymentService.initiatePayment(
        amount: widget.amount,
        currency: 'IQD',
        bookingId: widget.requestId, // Using requestId as bookingId for tender
        clientId: widget.clientId,
        description: 'Payment for "${widget.taskTitle}"',
      );

      if (!paymentResult.isSuccess || paymentResult.formUrl == null) {
        throw Exception(paymentResult.error ?? 'Failed to initiate payment');
      }

      // Step 2: Open WebView for external payment (QiCard)
      final webViewResult = await Navigator.of(context).push<PaymentWebViewResult>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(initialUrl: paymentResult.formUrl!),
        ),
      );

      if (webViewResult == null || webViewResult.status != 'SUCCESS') {
        setState(() {
          _isProcessing = false;
          _errorMessage = webViewResult?.status == 'CANCELED'
              ? 'Payment was cancelled.'
              : 'Payment was not completed. Please try again.';
        });
        return;
      }

      // Step 3: Complete the payment (create escrow + activate work)
      final result = await _taskService.payAwardedOffer(widget.requestId);

      if (result['success'] == true) {
        AppLogger.i('Tender payment completed: ${widget.requestId}');

        if (mounted) {
          // Show success and navigate to work detail
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Work is now active.'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to dashboard
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        throw Exception(result['error'] ?? 'Payment failed');
      }
    } catch (e) {
      AppLogger.e('Tender payment failed', error: e);
      setState(() {
        _errorMessage = 'Payment failed: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeRemaining = _timeRemaining;
    final hours = timeRemaining.inHours.clamp(0, 999);
    final minutes = (timeRemaining.inMinutes % 60).clamp(0, 59);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Deadline warning
              Container(
                padding: const EdgeInsets.all(AppDimens.p12),
                decoration: BoxDecoration(
                  color: _isExpired ? Colors.red.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                  border: Border.all(
                    color: _isExpired ? Colors.red.shade200 : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isExpired ? Icons.timer_off : Icons.timer,
                      color: _isExpired ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: AppDimens.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isExpired ? 'Payment Deadline Expired' : 'Payment Required',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isExpired ? Colors.red : Colors.orange.shade800,
                            ),
                          ),
                          if (!_isExpired)
                            Text(
                              'Complete payment in ${hours}h ${minutes}m to activate work',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.p24),

              // Order summary
              Text(
                'Order Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimens.p16),

              _buildSummaryRow('Task', widget.taskTitle),
              _buildSummaryRow('Freelancer', widget.freelancerName),
              _buildSummaryRow(
                'Amount',
                PriceFormatter.formatPrice(widget.amount),
                isBold: true,
              ),

              const Divider(height: AppDimens.p32),

              // Payment method
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimens.p12),

              Container(
                padding: const EdgeInsets.all(AppDimens.p12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.credit_card, color: colorScheme.primary),
                    const SizedBox(width: AppDimens.p12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QiCard / Credit Card',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Secure payment via QiCard gateway',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, color: colorScheme.primary),
                  ],
                ),
              ),

              const Spacer(),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(AppDimens.p12),
                  margin: const EdgeInsets.only(bottom: AppDimens.p16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(AppDimens.r8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: AppDimens.p8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              // Pay button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isProcessing || _isExpired ? null : _processPayment,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Pay ${PriceFormatter.formatPrice(widget.amount)}'),
                ),
              ),

              const SizedBox(height: AppDimens.p8),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Pay Later'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
