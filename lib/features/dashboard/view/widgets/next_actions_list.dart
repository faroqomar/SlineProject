import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_view_model.dart';
import 'work_item_card.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/deep_link_service.dart'
    as sline_deep_link;
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:sline_app/features/proposals/routes/proposal_payment_route.dart';
import 'package:sline_app/features/wallet/view/wallet_screen.dart';
import 'package:sline_app/core/services/logger_service.dart';

void _showInsufficientFundsDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Insufficient balance'),
      content: const Text(
        'Add funds to your wallet and try again from the Dashboard.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const WalletScreen()),
            );
          },
          child: const Text('Add funds'),
        ),
      ],
    ),
  );
}

class NextActionsList extends StatelessWidget {
  const NextActionsList({super.key});

  @override
  Widget build(BuildContext context) {
    // In Phase 2, we consume the VM directly
    final vm = context.watch<DashboardViewModel>();
    // Use calculated priority actions (Phase 1.3 Logic)
    final items = vm.nextActions;

    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return const Center(child: Text("No actions pending."));
    }

    // Show top 3 items for "Next Actions" section
    final displayItems = items.take(3).toList();

    return Column(
      key: const Key('next_actions_list'),
      children: displayItems
          .map(
            (item) => WorkItemCard(
              item: item,
              onPrimaryAction: () async {
                final action = item.primaryActionType;
                final vm = context.read<DashboardViewModel>();
                // Direct offer Pay Now: perform payment from dashboard
                if (item.type == WorkItemType.directOffer &&
                    action == PrimaryActionType.payEscrow) {
                  try {
                    await vm.performPrimaryAction(item);
                    if (context.mounted) vm.refresh();
                  } on FormatException catch (e) {
                    if (!context.mounted) return;
                    if (e.message.contains('Insufficient')) {
                      _showInsufficientFundsDialog(context);
                    } else {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e is Exception
                              ? e.toString()
                              : 'Something went wrong',
                        ),
                      ),
                    );
                  }
                  return;
                }
                // Task awarded pending payment: open via shared route
                if (item.type == WorkItemType.task &&
                    action == PrimaryActionType.payEscrow &&
                    item.awardedRequestId != null) {
                  AppLogger.i(
                    'NextActions: opening tender payment request=${item.awardedRequestId}',
                    tag: 'dashboard.work',
                  );
                  final summary = ProposalPaymentSummary(
                    requestId: item.awardedRequestId!,
                    taskId: item.id,
                    taskTitle: item.title,
                    freelancerName: item.counterpartyName,
                    amount: item.price ?? 0,
                    paymentDeadline: item.paymentDeadline,
                  );
                  await openProposalPayment(context, summary: summary, launcherSource: 'next_actions_list');
                  if (context.mounted) vm.refresh();
                  return;
                }
                // Navigate for review/pay/view (booking/task pay goes to details)
                if (action == PrimaryActionType.reviewDelivery ||
                    action == PrimaryActionType.submitEvidence ||
                    action == PrimaryActionType.payEscrow ||
                    action == PrimaryActionType.viewDetails) {
                  final result = await context
                      .read<sline_deep_link.DeepLinkService>()
                      .handleWorkItem(
                        context,
                        item.type.name,
                        item.id,
                        conversationId: item.conversationId,
                      );
                  if (result == true && context.mounted) {
                    vm.refresh();
                  }
                } else {
                  try {
                    await vm.performPrimaryAction(item);
                    if (context.mounted) vm.refresh();
                  } on FormatException catch (e) {
                    if (!context.mounted) return;
                    if (e.message.contains('Insufficient')) {
                      _showInsufficientFundsDialog(context);
                    } else {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e is Exception
                              ? e.toString()
                              : 'Something went wrong',
                        ),
                      ),
                    );
                  }
                }
              },
              onSecondaryAction: item.permissions.canCancel &&
                      item.awardedRequestId != null
                  ? () async {
                      try {
                        await context
                            .read<DashboardViewModel>()
                            .cancelAwardedOffer(item.awardedRequestId!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Award cancelled. Task is open again.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e is Exception
                                    ? e.toString()
                                    : 'Failed to cancel',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  : null,
            ),
          )
          .toList(),
    );
  }
}
