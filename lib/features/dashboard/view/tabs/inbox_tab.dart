import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:sline_app/features/proposals/routes/proposal_payment_route.dart';
import 'package:sline_app/features/tasks/view/widgets/dashboard_offer_card.dart';

/// Dashboard inbox tab showing pending offers and proposals.
///
/// Phase 7 redesign: replaced CircularProgressIndicator with skeleton loading,
/// polished empty state to match other tab patterns, and migrated SnackBar
/// colors from Colors.red to colorScheme.danger.
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
    final colorScheme = context.colorScheme;
    setState(() => _isAwarding = true);

    try {
      final result = await vm.awardOffer(offer);
      if (!mounted) return;
      setState(() => _isAwarding = false);

      if (result != null && result['success'] == true) {
        // Task moves to Work tab as "Waiting payment"
        await vm.refresh();
        if (!mounted) return;
        vm.setTab(DashboardTab.activeWork.index, workSubTab: 0);
        AppLogger.i(
          'Inbox: award success, switching to Work tab',
          tag: 'dashboard.inbox',
        );
      } else {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(result?['error'] ?? 'Failed to award offer'),
            // Phase 7: semantic danger replaces hardcoded Colors.red
            backgroundColor: colorScheme.danger,
          ),
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isAwarding = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          // Phase 7: semantic danger replaces hardcoded Colors.red
          backgroundColor: colorScheme.danger,
        ),
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
        // ── Skeleton loading state ──────────────────────────────
        // Phase 7: replaced CircularProgressIndicator with skeleton shimmer
        // matching the approximate shape of DashboardOfferCard.
        if (vm.isLoading && vm.inboxOffers.isEmpty) {
          return _buildSkeletonList();
        }

        final isClient = vm.currentRole == UserRole.client;
        final label = isClient ? 'Proposals' : 'Offers';

        // ── Empty state ─────────────────────────────────────────
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
                  acceptHandler = () => _handleAwardOffer(context, vm, offer);
                } else if (offer.status == OfferStatus.accepted &&
                    offer.paymentStatus == PaymentStatus.unpaid) {
                  acceptHandler = () => _handlePayAwardedOffer(context, offer);
                } else {
                  acceptHandler = () {};
                }
              } else {
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

  /// Skeleton loading — 3 placeholder cards matching DashboardOfferCard shape.
  ///
  /// Phase 7: replaces CircularProgressIndicator for visual consistency with
  /// other tabs (BookingsTab, WorkTab) that already use skeleton loading.
  Widget _buildSkeletonList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimens.p16),
      itemCount: 3,
      itemBuilder: (_, index) => const Padding(
        padding: EdgeInsets.only(bottom: AppDimens.p12),
        child: SkeletonLoader(
          height: 160,
          borderRadius: AppDimens.r16,
        ),
      ),
    );
  }
}

/// Polished empty state for inbox tab.
///
/// Phase 7 redesign: icon size downsized from hardcoded 64 to AppLayout.iconFeature
/// (48) for consistency with other tab empty states. Typography downsized from
/// h3 to h5 to match WorkTab and BookingsTab patterns.
class _EmptyInboxState extends StatelessWidget {
  final String label;
  const _EmptyInboxState({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Semantics(
      label: 'No $label yet. $label you receive or send will appear here.',
      excludeSemantics: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              // Phase 7: AppLayout.iconFeature (48) replaces hardcoded 64
              // for consistency with other empty states
              size: AppLayout.iconFeature,
              color: colorScheme.textSecondary,
            ),
            const SizedBox(height: AppLayout.spacingSection),
            Text(
              'No $label Yet',
              // Phase 7: h5 replaces h3 for consistency with WorkTab/BookingsTab
              style:
                  AppTypography.h5.copyWith(color: colorScheme.textSecondary),
            ),
            const SizedBox(height: AppLayout.spacingStandard),
            Text(
              '$label you receive or send will appear here.',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
