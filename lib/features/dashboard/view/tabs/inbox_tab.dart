import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:sline_app/features/proposals/routes/proposal_payment_route.dart';
import 'package:sline_app/features/tasks/view/widgets/dashboard_offer_card.dart';

enum _InboxMode { received, sent }

/// Dashboard inbox tab showing pending offers and proposals.
///
/// The tab keeps all offer actions on DashboardViewModel and only normalizes
/// inbox loading, empty, and list presentation.
class InboxTab extends StatefulWidget {
  const InboxTab({super.key});

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab> {
  bool _isAwarding = false;
  _InboxMode _mode = _InboxMode.received;

  Future<void> _handleAwardOffer(
    BuildContext context,
    DashboardViewModel vm,
    dynamic offer,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    const amber = AmberDuskTokens.colors;
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
            backgroundColor: amber.danger,
          ),
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isAwarding = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: amber.danger),
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
        final isClient = vm.currentRole == UserRole.client;
        final label = isClient ? 'Proposals' : 'Offers';
        final body = _bodyForMode(
          context,
          vm,
          isClient: isClient,
          label: label,
        );

        return Column(
          key: const Key('inbox_tab'),
          children: [
            _buildModeToggle(label),
            Expanded(child: body),
          ],
        );
      },
    );
  }

  Widget _bodyForMode(
    BuildContext context,
    DashboardViewModel vm, {
    required bool isClient,
    required String label,
  }) {
    if (_mode == _InboxMode.sent) {
      return RefreshIndicator(
        onRefresh: () => vm.refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: AmberDuskTokens.spacing.contentHorizontalPadding,
          ),
          children: [
            _EmptyInboxState(
              label: 'Sent $label Preview',
              message:
                  'Sent inbox data needs a separate dashboard contract before this mode can become active.',
            ),
          ],
        ),
      );
    }

    if (vm.isLoading && vm.inboxOffers.isEmpty) {
      return _buildSkeletonList();
    }

    if (vm.inboxOffers.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => vm.refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: AmberDuskTokens.spacing.contentHorizontalPadding,
          ),
          children: [_EmptyInboxState(label: label)],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.refresh(),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: AmberDuskTokens.spacing.contentHorizontalPadding,
        ),
        itemCount: vm.inboxOffers.length,
        itemBuilder: (context, index) {
          final offer = vm.inboxOffers[index];

          // Determine the correct handler based on offer state.
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
  }

  Widget _buildModeToggle(String label) {
    const amber = AmberDuskTokens.colors;
    final tabTheme = AmberDuskTokens.widgetTheme.tabs;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AmberDuskTokens.spacing.contentHorizontalPadding,
        0,
        AmberDuskTokens.spacing.contentHorizontalPadding,
        AppDimens.p12,
      ),
      child: Semantics(
        label: '$label inbox mode',
        child: Container(
          height: AppLayout.statusIndicatorHeight,
          padding: const EdgeInsets.all(AppDimens.p4),
          decoration: BoxDecoration(
            color: amber.surface,
            borderRadius: BorderRadius.circular(
              AmberDuskTokens.spacing.pillRadius,
            ),
          ),
          child: Row(
            children: [
              _buildModeButton(
                label: 'Received',
                mode: _InboxMode.received,
                textStyle: tabTheme.labelStyle,
              ),
              _buildModeButton(
                label: 'Sent',
                mode: _InboxMode.sent,
                textStyle: tabTheme.labelStyle,
                enabled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required _InboxMode mode,
    required TextStyle textStyle,
    bool enabled = true,
  }) {
    const amber = AmberDuskTokens.colors;
    final isSelected = _mode == mode;

    return Expanded(
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: isSelected,
        label: enabled ? '$label inbox mode' : '$label inbox mode unavailable',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!enabled) {
              AppLogger.d(
                'Inbox sent mode blocked by data contract gap',
                tag: 'dashboard.inbox',
              );
              return;
            }
            if (_mode == mode) return;
            AppLogger.d(
              'Inbox mode switched',
              tag: 'dashboard.inbox',
              json: {'mode': mode.name},
            );
            setState(() => _mode = mode);
          },
          child: AnimatedContainer(
            duration: AmberDuskTokens.motion.activeState,
            curve: AmberDuskTokens.motion.stateCurve,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? amber.primary : amber.transparent,
              borderRadius: BorderRadius.circular(
                AmberDuskTokens.spacing.pillRadius,
              ),
            ),
            child: Text(
              label,
              style: textStyle.copyWith(
                color: !enabled
                    ? amber.muted
                    : isSelected
                    ? amber.text
                    : amber.textSubtle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Skeleton loading — 3 placeholder cards matching DashboardOfferCard shape.
  ///
  Widget _buildSkeletonList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: AmberDuskTokens.spacing.contentHorizontalPadding,
      ),
      itemCount: 3,
      itemBuilder: (_, index) => const Padding(
        padding: EdgeInsets.only(bottom: AppDimens.p12),
        child: SkeletonLoader(height: 160, borderRadius: AppDimens.r16),
      ),
    );
  }
}

/// Polished empty state for inbox tab.
///
/// Empty inbox state for both client proposals and freelancer offers.
class _EmptyInboxState extends StatelessWidget {
  final String label;
  final String? message;
  const _EmptyInboxState({required this.label, this.message});

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;

    return Semantics(
      label:
          'No $label yet. ${message ?? '$label you receive or send will appear here.'}',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(top: AppDimens.p8),
        padding: const EdgeInsets.all(AppDimens.p18),
        decoration: BoxDecoration(
          color: amber.surface,
          borderRadius: BorderRadius.circular(
            AmberDuskTokens.spacing.moduleRadius,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: AppDimens.p48,
              height: AppDimens.p48,
              decoration: BoxDecoration(
                color: amber.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.r16),
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: AppDimens.iconSizeMedium,
                color: amber.primary,
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No $label Yet',
                    style: AmberDuskTokens.typography.sectionTitle.copyWith(
                      color: amber.text,
                    ),
                  ),
                  const SizedBox(height: AppDimens.p4),
                  Text(
                    message ?? '$label you receive or send will appear here.',
                    style: AmberDuskTokens.typography.bodySmall.copyWith(
                      color: amber.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
