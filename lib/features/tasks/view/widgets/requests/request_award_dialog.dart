import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:sline_app/features/proposals/routes/proposal_payment_route.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';

const int _kPaymentDeadlineHours = 24;

/// Shows the award confirmation dialog and handles the award + payment flow.
Future<void> showAwardDialog({
  required BuildContext context,
  required TaskRequest request,
  required TaskRequestsViewModel vm,
  required String? budget,
  required void Function(bool) onAwardingChanged,
}) async {
  final expectedPriceCents = request.price * 100;

  AppLogger.i(
    'Award dialog opened',
    tag: 'TaskRequests',
    json: {'surface': 'award_dialog'},
  );

  final paymentDeadline = DateTime.now().add(
    const Duration(hours: _kPaymentDeadlineHours),
  );
  final formattedDeadline = DateFormat('MMM d, h:mm a').format(paymentDeadline);

  final budgetValue = double.tryParse(budget ?? '0') ?? 0;
  final bidPrice = request.price.toDouble();
  final budgetDiff = bidPrice - budgetValue;
  final isUnderBudget = budgetDiff < 0;
  final isAtBudget = budgetDiff.abs() < 0.01;

  const amberColors = AmberDuskTokens.colors;
  Color budgetColor;
  IconData budgetIcon;
  String budgetMessage;

  if (isUnderBudget) {
    budgetColor = amberColors.forest;
    budgetIcon = Icons.trending_down;
    budgetMessage =
        'Under budget by ${PriceFormatter.formatPrice(budgetDiff.abs())}';
  } else if (isAtBudget) {
    budgetColor = amberColors.warning;
    budgetIcon = Icons.check_circle;
    budgetMessage = 'At budget limit';
  } else {
    budgetColor = amberColors.danger;
    budgetIcon = Icons.trending_up;
    budgetMessage = 'Over budget by ${PriceFormatter.formatPrice(budgetDiff)}';
  }

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: amberColors.background,
      title: Row(
        children: [
          Icon(Icons.emoji_events, color: amberColors.warning),
          const SizedBox(width: AppDimens.p8),
          Expanded(
            child: Text(
              'Award ${request.bidderName ?? "Freelancer"}?',
              style: AppTypography.h5.copyWith(color: amberColors.text),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PriceComparisonSection(
              budgetValue: budgetValue,
              bidPrice: bidPrice,
              budgetIcon: budgetIcon,
              budgetColor: budgetColor,
              budgetMessage: budgetMessage,
              amberColors: amberColors,
            ),
            const SizedBox(height: AppDimens.p16),
            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: amberColors.muted),
                const SizedBox(width: AppDimens.p8),
                Text(
                  'Delivery: ${request.days} days',
                  style: AppTypography.bodySmall.copyWith(
                    color: amberColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.p16),
            _PaymentDeadlineSection(
              formattedDeadline: formattedDeadline,
              amberColors: amberColors,
            ),
            const SizedBox(height: AppDimens.p16),
            const _WhatHappensNextSection(amberColors: amberColors),
            const SizedBox(height: AppDimens.p12),
            const _RiskAcknowledgmentSection(amberColors: amberColors),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            AppLogger.i(
              'Award dialog cancelled by user',
              tag: 'TaskRequests',
              json: {'surface': 'award_dialog'},
            );
            Navigator.pop(ctx, false);
          },
          icon: const Icon(Icons.close),
          label: const Text('Cancel'),
          style: TextButton.styleFrom(foregroundColor: amberColors.muted),
        ),
        ElevatedButton.icon(
          onPressed: () {
            AppLogger.i(
              'Award dialog confirmed by user',
              tag: 'TaskRequests',
              json: {'surface': 'award_dialog'},
            );
            Navigator.pop(ctx, true);
          },
          icon: const Icon(Icons.check),
          label: const Text('Award Freelancer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: amberColors.primary,
            foregroundColor: amberColors.textInverse,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p20,
              vertical: AppDimens.p12,
            ),
            textStyle: AppTypography.captionBold,
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(
        AppDimens.p16,
        0,
        AppDimens.p16,
        AppDimens.p16,
      ),
    ),
  );

  if ((confirmed ?? false) && context.mounted) {
    AppLogger.i(
      'Award attempt started',
      tag: 'TaskRequests',
      json: {'surface': 'requests_list'},
    );
    await _executeAward(
      context: context,
      request: request,
      vm: vm,
      expectedPriceCents: expectedPriceCents,
      onAwardingChanged: onAwardingChanged,
    );
  }
}

/// Executes the award RPC and navigates to payment on success.
Future<void> _executeAward({
  required BuildContext context,
  required TaskRequest request,
  required TaskRequestsViewModel vm,
  required int expectedPriceCents,
  required void Function(bool) onAwardingChanged,
}) async {
  onAwardingChanged(true);
  try {
    final result = await vm.award(
      request.id,
      expectedPriceCents: expectedPriceCents,
    );
    if (!context.mounted) return;
    onAwardingChanged(false);

    if (result != null && result['success'] == true) {
      final deadline = result['payment_deadline'] != null
          ? DateTime.tryParse(result['payment_deadline'] as String)
          : null;
      final summary = ProposalPaymentSummary(
        requestId: request.id,
        taskId: request.taskId,
        taskTitle: request.taskTitle ?? 'Task',
        freelancerName: request.bidderName ?? 'Freelancer',
        amount: request.price.toDouble(),
        paymentDeadline: deadline,
      );
      await openProposalPayment(
        context,
        summary: summary,
        launcherSource: 'requests_list',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to award offer. Please refresh and try again.',
          ),
          backgroundColor: AmberDuskTokens.colors.danger,
        ),
      );
    }
  } on PriceMismatchException catch (e) {
    if (!context.mounted) return;
    onAwardingChanged(false);
    await showPriceMismatchDialog(context: context, exception: e);
  } on OfferAlreadyAcceptedException {
    if (!context.mounted) return;
    onAwardingChanged(false);
    await vm.loadInitial();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This offer has already been awarded.'),
        backgroundColor: AmberDuskTokens.colors.warning,
      ),
    );
  } on Exception catch (e, st) {
    if (!context.mounted) return;
    onAwardingChanged(false);
    AppLogger.e('Award failed', error: e, stackTrace: st, tag: 'TaskRequests');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Award failed. Please refresh and try again.'),
        backgroundColor: AmberDuskTokens.colors.danger,
      ),
    );
  }
}

/// Shows the client budget beside the selected bid and the budget delta state.
class _PriceComparisonSection extends StatelessWidget {
  const _PriceComparisonSection({
    required this.budgetValue,
    required this.bidPrice,
    required this.budgetIcon,
    required this.budgetColor,
    required this.budgetMessage,
    required this.amberColors,
  });

  final double budgetValue;
  final double bidPrice;
  final IconData budgetIcon;
  final Color budgetColor;
  final String budgetMessage;
  final AmberDuskColorTokens amberColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: amberColors.surface,
        borderRadius: BorderRadius.circular(
          AmberDuskTokens.spacing.moduleRadius,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Comparison',
            style: AppTypography.captionBold.copyWith(color: amberColors.text),
          ),
          const SizedBox(height: AppDimens.p12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Budget:',
                style: AppTypography.bodySmall.copyWith(
                  color: amberColors.muted,
                ),
              ),
              Text(
                PriceFormatter.formatPrice(budgetValue),
                style: AppTypography.bodyMedium.copyWith(
                  color: amberColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bid Price:',
                style: AppTypography.bodySmall.copyWith(
                  color: amberColors.muted,
                ),
              ),
              Text(
                PriceFormatter.formatPrice(bidPrice),
                style: AppTypography.bodyMedium.copyWith(
                  color: amberColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Divider(height: AppDimens.p16, color: amberColors.muted),
          Row(
            children: [
              Icon(budgetIcon, color: budgetColor, size: 18),
              const SizedBox(width: AppDimens.p6),
              Text(
                budgetMessage,
                style: AppTypography.bodySmall.copyWith(
                  color: budgetColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Explains the deadline that starts after the award is confirmed.
class _PaymentDeadlineSection extends StatelessWidget {
  const _PaymentDeadlineSection({
    required this.formattedDeadline,
    required this.amberColors,
  });

  final String formattedDeadline;
  final AmberDuskColorTokens amberColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: amberColors.warningMuted,
        borderRadius: BorderRadius.circular(
          AmberDuskTokens.spacing.moduleRadius,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: amberColors.warning, size: 20),
              const SizedBox(width: AppDimens.p8),
              Text(
                'Payment Required Within $_kPaymentDeadlineHours Hours',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: amberColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p10),
          Text(
            'After awarding, you have until $formattedDeadline to complete payment.',
            style: AppTypography.bodySmall.copyWith(color: amberColors.text),
          ),
          const SizedBox(height: AppDimens.p6),
          Text(
            'Work starts only after payment is confirmed.',
            style: AppTypography.caption.copyWith(
              color: amberColors.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Summarizes the post-award sequence so the client understands the next steps.
class _WhatHappensNextSection extends StatelessWidget {
  const _WhatHappensNextSection({required this.amberColors});

  final AmberDuskColorTokens amberColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: amberColors.surface,
        borderRadius: BorderRadius.circular(
          AmberDuskTokens.spacing.moduleRadius,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What happens next:',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: amberColors.text,
            ),
          ),
          const SizedBox(height: AppDimens.p12),
          const _StepRow(
            number: 1,
            title: 'Award the bid',
            description: 'Now',
            isActive: true,
          ),
          const _StepRow(
            number: 2,
            title: 'Complete payment',
            description: 'Within $_kPaymentDeadlineHours hours',
            isActive: false,
          ),
          const _StepRow(
            number: 3,
            title: 'Work begins',
            description: 'After payment confirmed',
            isActive: false,
          ),
        ],
      ),
    );
  }
}

/// Calls out the payment commitment before the award action is confirmed.
class _RiskAcknowledgmentSection extends StatelessWidget {
  const _RiskAcknowledgmentSection({required this.amberColors});

  final AmberDuskColorTokens amberColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p12),
      decoration: BoxDecoration(
        color: amberColors.infoMuted,
        borderRadius: BorderRadius.circular(AppDimens.r8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: amberColors.info),
          const SizedBox(width: AppDimens.p8),
          Expanded(
            child: Text(
              'By awarding, you commit to completing payment within $_kPaymentDeadlineHours hours. Failure to pay will cancel this award.',
              style: AppTypography.caption.copyWith(color: amberColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the price mismatch dialog with a refresh option.
Future<void> showPriceMismatchDialog({
  required BuildContext context,
  required PriceMismatchException exception,
}) async {
  final expectedIqd = PriceFormatter.formatPrice(exception.expectedCents / 100);
  final actualIqd = PriceFormatter.formatPrice(exception.actualCents / 100);

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      const amberColors = AmberDuskTokens.colors;
      return AlertDialog(
        backgroundColor: amberColors.background,
        icon: Icon(Icons.price_change, color: amberColors.warning, size: 48),
        title: Text(
          'Offer Updated',
          style: AppTypography.h5.copyWith(color: amberColors.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The freelancer changed their offer while you were reviewing it.',
              style: AppTypography.bodyMedium.copyWith(color: amberColors.text),
            ),
            const SizedBox(height: AppDimens.p16),
            Container(
              padding: const EdgeInsets.all(AppDimens.p12),
              decoration: BoxDecoration(
                color: amberColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.r8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Old Price:',
                        style: AppTypography.bodySmall.copyWith(
                          color: amberColors.muted,
                        ),
                      ),
                      Text(
                        expectedIqd,
                        style: AppTypography.bodyMedium.copyWith(
                          color: amberColors.muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.p4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'New Price:',
                        style: AppTypography.bodySmall.copyWith(
                          color: amberColors.muted,
                        ),
                      ),
                      Text(
                        actualIqd,
                        style: AppTypography.bodyMedium.copyWith(
                          color: amberColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.p16),
            Text(
              'Please review the new price before awarding.',
              style: AppTypography.bodySmall.copyWith(
                color: amberColors.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              final vm = context.read<TaskRequestsViewModel>();
              Navigator.pop(ctx);
              if (context.mounted) vm.loadInitial();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Review New Price'),
          ),
        ],
      );
    },
  );
}

/// Step row widget for the "What happens next" section.
class _StepRow extends StatelessWidget {
  final int number;
  final String title;
  final String description;
  final bool isActive;

  const _StepRow({
    required this.number,
    required this.title,
    required this.description,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    const amberColors = AmberDuskTokens.colors;
    final stepColor = isActive ? amberColors.forest : amberColors.surfaceRaised;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: stepColor, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$number',
                style: AppTypography.captionBold.copyWith(
                  color: isActive ? amberColors.textInverse : amberColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? amberColors.forest : amberColors.text,
                  ),
                ),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: amberColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
