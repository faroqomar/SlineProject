import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:sline_app/features/proposals/routes/proposal_payment_route.dart';
import 'package:sline_app/features/tasks/view/widgets/dashboard_offer_card.dart';

class InboxTab extends StatefulWidget {
  const InboxTab({super.key});

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab> {
  bool _isAwarding = false;

  Future<void> _handleAwardOffer(
    BuildContext context,
    DashboardViewModel vm,
    dynamic offer,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isAwarding = true);

    try {
      final result = await vm.awardOffer(offer);
      if (!mounted) return;
      setState(() => _isAwarding = false);

      if (result != null && result['success'] == true) {
        // Task moves to Work tab as "Waiting payment"; user can Pay or Cancel from there
        await vm.refresh();
        if (!mounted) return;
        vm.setTab(DashboardTab.activeWork.index, workSubTab: 0);
        AppLogger.i(
          'Inbox: award success, switching to Work tab',
          tag: 'dashboard.inbox',
        );
      } else {
        // Show error
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(result?['error'] ?? 'Failed to award offer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isAwarding = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Handle "Pay Now" for awarded but unpaid offers (Pay Later flow)
  Future<void> _handlePayAwardedOffer(
    BuildContext context,
    dynamic offer,
  ) async {
    final vm = context.read<DashboardViewModel>();
    final summary = ProposalPaymentSummary(
      requestId: offer.id,
      taskId: offer.taskId ?? '',
      taskTitle: offer.taskTitle ?? 'Task',
      freelancerName: offer.bidderName ?? 'Freelancer',
      amount: offer.price.toDouble(),
      paymentDeadline: offer.paymentDeadline as DateTime?,
    );
    await openProposalPayment(
      context,
      summary: summary,
      launcherSource: 'inbox_tab',
    );
    if (!mounted) return;
    await vm.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading && vm.inboxOffers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final isClient = vm.currentRole == UserRole.client;
        final label = isClient ? 'Proposals' : 'Offers';

        if (vm.inboxOffers.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => vm.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _EmptyInboxState(label: label),
              ),
            ),
          );
        }

        return RefreshIndicator(
          key: const Key('inbox_tab'),
          onRefresh: () => vm.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimens.p16),
            itemCount: vm.inboxOffers.length,
            itemBuilder: (context, index) {
              final offer = vm.inboxOffers[index];

              // Determine the correct handler based on offer state
              VoidCallback acceptHandler;
              if (isClient && !_isAwarding) {
                if (offer.status == OfferStatus.pending) {
                  // Pending offer: Show Award dialog then navigate to payment
                  acceptHandler = () => _handleAwardOffer(context, vm, offer);
                } else if (offer.status == OfferStatus.accepted &&
                    offer.paymentStatus == PaymentStatus.unpaid) {
                  // Awarded but unpaid: Navigate directly to payment screen (Pay Later flow)
                  acceptHandler = () => _handlePayAwardedOffer(context, offer);
                } else {
                  // No-op for other states to prevent null callback crashes
                  acceptHandler = () {};
                }
              } else {
                // Provider view or during awarding: no-op to prevent null callback crashes
                acceptHandler = () {};
              }

              return DashboardOfferCard(
                offer: offer,
                isClientView: isClient,
                onAccept: acceptHandler,
                onReject: () => vm.rejectOffer(offer),
                onWithdraw: () => vm.withdrawOffer(offer.id),
                onRelease: () => vm.releaseOfferWithFee(offer.id),
                onRefund: () => vm.refundOffer(offer.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyInboxState extends StatelessWidget {
  final String label;
  const _EmptyInboxState({required this.label});

  @override
  Widget build(BuildContext context) {
    final secondaryColor = context.colorScheme.textSecondary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: secondaryColor),
          const SizedBox(height: AppDimens.p16),
          Text(
            'No $label Yet',
            style: AppTypography.h3.copyWith(color: secondaryColor),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            '$label you receive or send will appear here.',
            style: AppTypography.bodyMedium.copyWith(color: secondaryColor),
          ),
        ],
      ),
    );
  }
}
