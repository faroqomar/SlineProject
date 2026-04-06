import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:sline_app/features/proposals/routes/proposal_payment_route.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';

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
    json: {
      'requestId': request.id,
      'bidderName': request.bidderName,
      'price': request.price,
      'taskBudget': budget,
    },
  );

  final paymentDeadline = DateTime.now().add(const Duration(hours: 24));
  final formattedDeadline = DateFormat('MMM d, h:mm a').format(paymentDeadline);

  final budgetValue = double.tryParse(budget ?? '0') ?? 0;
  final bidPrice = request.price.toDouble();
  final budgetDiff = bidPrice - budgetValue;
  final isUnderBudget = budgetDiff < 0;
  final isAtBudget = budgetDiff.abs() < 0.01;

  Color budgetColor;
  IconData budgetIcon;
  String budgetMessage;

  if (isUnderBudget) {
    budgetColor = Colors.green.shade700;
    budgetIcon = Icons.trending_down;
    budgetMessage =
        'Under budget by ${PriceFormatter.formatPrice(budgetDiff.abs())}';
  } else if (isAtBudget) {
    budgetColor = Colors.orange.shade700;
    budgetIcon = Icons.check_circle;
    budgetMessage = 'At budget limit';
  } else {
    budgetColor = Colors.red.shade700;
    budgetIcon = Icons.trending_up;
    budgetMessage = 'Over budget by ${PriceFormatter.formatPrice(budgetDiff)}';
  }

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Award ${request.bidderName ?? "Freelancer"}?',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price Comparison
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price Comparison',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Budget:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        PriceFormatter.formatPrice(budgetValue),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bid Price:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        PriceFormatter.formatPrice(bidPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      Icon(budgetIcon, color: budgetColor, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        budgetMessage,
                        style: TextStyle(
                          color: budgetColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Delivery: ${request.days} days',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Payment Deadline
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Payment Required Within 24 Hours',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'After awarding, you have until $formattedDeadline to complete payment.',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Work starts only after payment is confirmed.',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // What Happens Next
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What happens next:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _StepRow(
                    number: 1,
                    title: 'Award the bid',
                    description: 'Now',
                    isActive: true,
                  ),
                  const _StepRow(
                    number: 2,
                    title: 'Complete payment',
                    description: 'Within 24 hours',
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
            ),
            const SizedBox(height: 12),
            // Risk Acknowledgment
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'By awarding, you commit to completing payment within 24 hours. Failure to pay will cancel this award.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            AppLogger.i(
              'Award dialog cancelled by user',
              tag: 'TaskRequests',
              json: {'requestId': request.id},
            );
            Navigator.pop(ctx, false);
          },
          icon: const Icon(Icons.close),
          label: const Text('Cancel'),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
        ),
        ElevatedButton.icon(
          onPressed: () {
            AppLogger.i(
              'Award dialog confirmed by user',
              tag: 'TaskRequests',
              json: {
                'requestId': request.id,
                'bidPrice': bidPrice,
                'budget': budgetValue,
              },
            );
            Navigator.pop(ctx, true);
          },
          icon: const Icon(Icons.check),
          label: const Text(
            'Award Freelancer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(ctx).primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
  );

  if ((confirmed ?? false) && context.mounted) {
    AppLogger.i(
      'Award attempt started',
      tag: 'TaskRequests',
      json: {'requestId': request.id, 'expectedPriceCents': expectedPriceCents},
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
          content: Text(result?['error'] ?? 'Failed to award offer'),
          backgroundColor: Colors.red,
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
      const SnackBar(
        content: Text('This offer has already been awarded.'),
        backgroundColor: Colors.orange,
      ),
    );
  } on Exception catch (e) {
    if (!context.mounted) return;
    onAwardingChanged(false);
    AppLogger.e('Award failed', error: e, tag: 'TaskRequests');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Award failed: $e'), backgroundColor: Colors.red),
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
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.price_change, color: Colors.orange, size: 48),
      title: const Text('Offer Updated'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The freelancer changed their offer while you were reviewing it.',
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Old Price:'),
                    Text(
                      expectedIqd,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Price:'),
                    Text(
                      actualIqd,
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Please review the new price before awarding.',
            style: TextStyle(fontStyle: FontStyle.italic),
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
    ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? Colors.green.shade800
                        : Colors.grey.shade800,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
