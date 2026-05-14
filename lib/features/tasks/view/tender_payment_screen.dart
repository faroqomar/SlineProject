import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/config/payment_runtime_config.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/booking/models/payment_return_args.dart';
import 'package:sline_app/features/booking/view/payment_webview_screen.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
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
  bool _webViewPushed = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<TenderPaymentViewModel>(
      builder: (context, vm, _) {
        if (vm.success && !_successHandled && mounted) {
          _successHandled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            final successColor = context.colorScheme.success;
            try {
              final dashboardVm = context.read<DashboardViewModel>();
              await dashboardVm.refresh();
            } on Exception catch (_) {}
            messenger.showSnackBar(
              SnackBar(
                content: const Text('Payment successful! Work is now active.'),
                backgroundColor: successColor,
              ),
            );
            navigator.popUntil((route) => route.isFirst);
          });
        }

        if (vm.hasPendingWebPayment &&
            !_webViewPushed &&
            vm.pendingFormUrl != null &&
            vm.pendingRequestId != null &&
            vm.pendingPaymentRequestId != null) {
          _webViewPushed = true;
          final requestId = vm.pendingRequestId!;
          final paymentRequestId = vm.pendingPaymentRequestId!;
          final formUrl = vm.pendingFormUrl!;
          final callbackHosts = buildQiCardCallbackHosts();
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final result = await Navigator.of(context).push<PaymentReturnArgs>(
              MaterialPageRoute<PaymentReturnArgs>(
                builder: (context) => PaymentWebViewScreen(
                  initialUrl: formUrl,
                  callbackHosts: callbackHosts,
                  expectedRequestId: requestId,
                ),
              ),
            );
            if (!mounted) return;
            if (result != null && result.isSuccess) {
              await vm.completeRecovery(
                requestId: requestId,
                paymentRequestId: paymentRequestId,
              );
            } else {
              vm.clearPendingWebPayment();
            }
            if (mounted) setState(() => _webViewPushed = false);
          });
        }
        final timeRemaining = vm.timeRemaining;
        final hours = timeRemaining.inHours.clamp(0, 999);
        final minutes = (timeRemaining.inMinutes % 60).clamp(0, 59);

        return Scaffold(
          key: const Key('proposal_payment_screen'),
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
                  if (!vm.isTenderPaymentAvailable)
                    _buildTenderUnavailableBanner(context),
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
    final colorScheme = context.colorScheme;
    final statusColor = vm.isExpired ? colorScheme.danger : colorScheme.warning;
    final statusMuted = vm.isExpired
        ? colorScheme.dangerMuted
        : colorScheme.warningMuted;

    return Container(
      padding: const EdgeInsets.all(AppDimens.p12),
      decoration: BoxDecoration(
        color: statusMuted,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            vm.isExpired ? Icons.timer_off : Icons.timer,
            color: statusColor,
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
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (!vm.isExpired)
                  Text(
                    'Complete payment in ${hours}h ${minutes}m to activate work',
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.textSecondary,
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
          style: AppTypography.h5.copyWith(color: context.colorScheme.text),
        ),
        const SizedBox(height: AppDimens.p16),
        _buildSummaryRow(context, 'Task', vm.taskTitle),
        _buildSummaryRow(context, 'Freelancer', vm.freelancerName),
        _buildSummaryRow(
          context,
          'Amount',
          PriceFormatter.formatPrice(vm.amount),
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(BuildContext context) {
    final appColors = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: AppTypography.h6.copyWith(color: appColors.text),
        ),
        const SizedBox(height: AppDimens.p12),
        Container(
          padding: const EdgeInsets.all(AppDimens.p12),
          decoration: BoxDecoration(
            color: appColors.cardBackground,
            borderRadius: BorderRadius.circular(AppDimens.r12),
            border: Border.all(color: appColors.cardBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.credit_card, color: appColors.primary),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Card Payment',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: appColors.text,
                      ),
                    ),
                    Text(
                      'Secure payment confirmation',
                      style: AppTypography.bodySmall.copyWith(
                        color: appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.check_circle, color: appColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection(BuildContext context, String message) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppDimens.p12),
      margin: const EdgeInsets.only(bottom: AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.dangerMuted,
        borderRadius: BorderRadius.circular(AppDimens.r8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.danger),
          const SizedBox(width: AppDimens.p8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenderUnavailableBanner(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppDimens.p12),
      margin: const EdgeInsets.only(top: AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.warningMuted,
        borderRadius: BorderRadius.circular(AppDimens.r8),
        border: Border.all(color: colorScheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.warning),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Text(
              'Card payment for this flow is not yet available. Use Pay Later and complete payment when server-backed payment is enabled.',
              style: AppTypography.bodySmall.copyWith(color: colorScheme.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(BuildContext context, TenderPaymentViewModel vm) {
    final canPay =
        vm.isTenderPaymentAvailable && !vm.isProcessing && !vm.isExpired;
    final finishUrl = buildQiCardFinishUrlForRuntime();
    final colorScheme = context.colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: canPay ? () => vm.submit(finishUrl: finishUrl) : null,
        child: vm.isProcessing
            ? SizedBox(
                height: AppDimens.p20,
                width: AppDimens.p20,
                child: CircularProgressIndicator(
                  strokeWidth: AppDimens.hairlineDivider * 4,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.text),
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

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
    final colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: colorScheme.text,
            ),
          ),
        ],
      ),
    );
  }
}
