import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/tasks/viewmodels/tender_payment_view_model.dart';

/// Payment screen for completing payment on an awarded tender.
/// Bound to [TenderPaymentViewModel] only; no backend services in widget.
///
/// Parent must push with ChangeNotifierProvider for TenderPaymentViewModel.
class TenderPaymentScreen extends StatefulWidget {
  const TenderPaymentScreen({super.key});

  @override
  State<TenderPaymentScreen> createState() => _TenderPaymentScreenState();
}

class _TenderPaymentScreenState extends State<TenderPaymentScreen> {
  bool _successHandled = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<TenderPaymentViewModel>(
      builder: (context, vm, _) {
        if (vm.success && !_successHandled && mounted) {
          _successHandled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment successful! Work is now active.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          });
        }
        final timeRemaining = vm.timeRemaining;
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
                  _buildDeadlineSection(context, vm, hours, minutes),
                  const SizedBox(height: AppDimens.p24),
                  _buildOrderSummary(context, vm),
                  const Divider(height: AppDimens.p32),
                  _buildPaymentMethod(context),
                  const Spacer(),
                  if (vm.errorMessage != null)
                    _buildErrorSection(context, vm.errorMessage!),
                  _buildPayButton(context, vm),
                  const SizedBox(height: AppDimens.p8),
                  _buildPayLaterButton(context, vm),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeadlineSection(
    BuildContext context,
    TenderPaymentViewModel vm,
    int hours,
    int minutes,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p12),
      decoration: BoxDecoration(
        color: vm.isExpired ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(
          color: vm.isExpired
              ? Colors.red.shade200
              : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            vm.isExpired ? Icons.timer_off : Icons.timer,
            color: vm.isExpired ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.isExpired
                      ? 'Payment Deadline Expired'
                      : 'Payment Required',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: vm.isExpired
                        ? Colors.red
                        : Colors.orange.shade800,
                  ),
                ),
                if (!vm.isExpired)
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
    );
  }

  Widget _buildOrderSummary(BuildContext context, TenderPaymentViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimens.p16),
        _buildSummaryRow('Task', vm.taskTitle),
        _buildSummaryRow('Freelancer', vm.freelancerName),
        _buildSummaryRow(
          'Amount',
          PriceFormatter.formatPrice(vm.amount),
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimens.p12),
        Container(
          padding: const EdgeInsets.all(AppDimens.p12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppDimens.r12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.credit_card, color: colorScheme.primary),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Card Payment',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Secure payment confirmation',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.check_circle, color: colorScheme.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection(BuildContext context, String message) {
    return Container(
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
              message,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(BuildContext context, TenderPaymentViewModel vm) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: vm.isProcessing || vm.isExpired ? null : () => vm.submit(),
        child: vm.isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text('Pay ${PriceFormatter.formatPrice(vm.amount)}'),
      ),
    );
  }

  Widget _buildPayLaterButton(BuildContext context, TenderPaymentViewModel vm) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: vm.isProcessing ? null : () => Navigator.of(context).pop(),
        child: const Text('Pay Later'),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
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
