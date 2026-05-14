import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/deep_link_service.dart'
    as sline_deep_link;
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import 'package:sline_app/features/dashboard/view/widgets/work_item_card.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:sline_app/features/proposals/routes/proposal_payment_route.dart';
import 'package:sline_app/features/wallet/view/wallet_screen.dart';

/// Insufficient funds dialog — shown when user tries to pay escrow without
/// enough wallet balance. Navigates to WalletScreen to add funds.
void _showInsufficientFundsDialog(BuildContext context) {
  unawaited(
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
              unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const WalletScreen()),
                ),
              );
            },
            child: const Text('Add funds'),
          ),
        ],
      ),
    ),
  );
}

/// Priority-driven next actions list with stagger entrance animation,
/// skeleton loading, and enhanced empty state.
///
/// View-layer only: the list preserves existing payment, cancel, and deep-link
/// callback routing while using Amber Dusk priority colors.
class NextActionsList extends StatefulWidget {
  const NextActionsList({super.key});

  @override
  State<NextActionsList> createState() => _NextActionsListState();
}

class _NextActionsListState extends State<NextActionsList>
    with SingleTickerProviderStateMixin {
  // ── Stagger entrance animation ─────────────────────────────
  late final AnimationController _staggerController;
  bool _hasAnimatedEntrance = false;
  static const int _maxStaggerCount = 3;

  // Cached per-item animations — built once to avoid allocating new
  // Animation objects on every rebuild.
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      // emphasis (500ms) — same as ActivityFeedPreview for visual consistency
      duration: AppMotion.emphasis,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  /// Builds and caches per-item slide+fade animations, then triggers the
  /// stagger entrance. Called once via postFrameCallback to avoid setState
  /// during build (RG-5 from Phase 5 learnings).
  void _triggerStaggerIfNeeded(int itemCount) {
    if (_hasAnimatedEntrance || itemCount == 0) return;
    _hasAnimatedEntrance = true;

    final count = itemCount.clamp(0, _maxStaggerCount);
    for (var i = 0; i < count; i++) {
      final staggerFraction = i / (_maxStaggerCount + 2);
      final begin = staggerFraction;
      final end = (staggerFraction + 0.3).clamp(0.0, 1.0);

      _slideAnimations.add(
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _staggerController,
            // curveDecel for natural entrance deceleration
            curve: Interval(begin, end, curve: AppMotion.curveDecel),
          ),
        ),
      );

      _fadeAnimations.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(begin, end, curve: AppMotion.curveDecel),
          ),
        ),
      );
    }

    AppLogger.d(
      'NextActionsList: stagger entrance ($itemCount items)',
      tag: 'Dashboard',
    );
    unawaited(_staggerController.forward());
  }

  /// Maps a work item's primary action type to a priority color.
  ///
  /// Higher urgency actions (payment) get danger color, review gets warning,
  /// standard actions get primary — creating visual urgency hierarchy on the
  /// left border of each card.
  Color _priorityColor(
    PrimaryActionType? actionType,
    AmberDuskColorTokens colors,
  ) {
    switch (actionType) {
      // Urgent — money action requires immediate attention
      case PrimaryActionType.payEscrow:
        return colors.danger;
      // Attention — delivery needs review
      case PrimaryActionType.reviewDelivery:
        return colors.warning;
      // Action needed — evidence submission
      case PrimaryActionType.submitEvidence:
        return colors.info;
      // Standard — general actions
      case PrimaryActionType.startWork:
      case PrimaryActionType.markCompleted:
      case PrimaryActionType.approveClose:
      case PrimaryActionType.viewDetails:
      case null:
        return colors.primary;
    }
  }

  /// Returns a human-readable priority label for accessibility.
  String _priorityLabel(PrimaryActionType? actionType) {
    switch (actionType) {
      case PrimaryActionType.payEscrow:
        return 'Urgent';
      case PrimaryActionType.reviewDelivery:
        return 'Needs attention';
      case PrimaryActionType.submitEvidence:
        return 'Action needed';
      case PrimaryActionType.startWork:
      case PrimaryActionType.markCompleted:
      case PrimaryActionType.approveClose:
      case PrimaryActionType.viewDetails:
      case null:
        return 'Standard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    const amber = AmberDuskTokens.colors;
    final items = vm.nextActions;

    // ── Skeleton loading state ──────────────────────────────────
    if (vm.isLoading && items.isEmpty) {
      return _buildSkeletonList();
    }

    // ── Enhanced empty state ────────────────────────────────────
    if (items.isEmpty) {
      return _buildEmptyState(amber);
    }

    // Show top 3 items for "Next Actions" section
    final displayItems = items.take(_maxStaggerCount).toList();

    // Schedule stagger trigger after the current frame to avoid mutating
    // controller state during build (RG-5 from Phase 5).
    if (!_hasAnimatedEntrance) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _triggerStaggerIfNeeded(displayItems.length),
      );
    }

    return Column(
      key: const Key('next_actions_list'),
      children: List.generate(displayItems.length, (index) {
        final item = displayItems[index];
        final priorityColor = _priorityColor(item.primaryActionType, amber);

        // Priority-colored left border wrapping each card — creates visual
        // urgency hierarchy without IntrinsicHeight (zero extra layout cost).
        Widget card = Semantics(
          label: 'Priority: ${_priorityLabel(item.primaryActionType)}',
          child: Container(
            margin: const EdgeInsets.only(bottom: AppDimens.p12),
            decoration: BoxDecoration(
              // Left bar indicates action urgency level
              border: Border(left: BorderSide(width: 4, color: priorityColor)),
              borderRadius: BorderRadius.circular(AppDimens.r16),
            ),
            child: WorkItemCard(
              item: item,
              onPrimaryAction: () => _handlePrimaryAction(context, item),
              onSecondaryAction:
                  item.permissions.canCancel && item.awardedRequestId != null
                  ? () => _handleSecondaryAction(context, item)
                  : null,
            ),
          ),
        );

        // Apply stagger entrance for items within the animation window
        if (_hasAnimatedEntrance && index < _maxStaggerCount) {
          card = SlideTransition(
            position: _slideAnimations[index],
            child: FadeTransition(opacity: _fadeAnimations[index], child: card),
          );
        }

        return card;
      }),
    );
  }

  /// Skeleton loading — 3 placeholder cards matching WorkItemCard shape.
  Widget _buildSkeletonList() {
    return Column(
      children: List.generate(
        3,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: AppDimens.p12),
          child: SkeletonLoader(height: 120, borderRadius: AppDimens.r16),
        ),
      ),
    );
  }

  /// Enhanced empty state — "All caught up!" with check icon.
  ///
  /// Replaces bare "No actions pending." text with an illustrated, accessible
  /// empty state matching the pattern used in WorkTab and BookingsTab.
  Widget _buildEmptyState(AmberDuskColorTokens colors) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Semantics(
        label: 'All caught up. No actions need your attention right now.',
        excludeSemantics: true,
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: AppLayout.iconFeature,
                color: colors.success,
              ),
              const SizedBox(height: AppLayout.spacingStandard),
              Text(
                'All caught up!',
                style: AppTypography.h5.copyWith(color: colors.textSubtle),
              ),
              const SizedBox(height: AppLayout.spacingTight),
              Text(
                'No actions need your attention right now.',
                style: AppTypography.bodySmall.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles primary action (pay, navigate, review) for a next action item.
  ///
  /// Business logic routing is unchanged from pre-Phase 7 — only the widget
  /// structure around it changed (StatefulWidget + stagger).
  Future<void> _handlePrimaryAction(BuildContext context, WorkItem item) async {
    final action = item.primaryActionType;
    final vm = context.read<DashboardViewModel>();

    // Direct offer Pay Now: perform payment from dashboard
    if (item.type == WorkItemType.directOffer &&
        action == PrimaryActionType.payEscrow) {
      try {
        await vm.performPrimaryAction(item);
        if (context.mounted) unawaited(vm.refresh());
      } on FormatException catch (e) {
        if (!context.mounted) return;
        if (e.message.contains('Insufficient')) {
          _showInsufficientFundsDialog(context);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e))));
        }
      } on Exception catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e))));
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
      await openProposalPayment(
        context,
        summary: summary,
        launcherSource: 'next_actions_list',
      );
      if (context.mounted) unawaited(vm.refresh());
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
        unawaited(vm.refresh());
      }
    } else {
      try {
        await vm.performPrimaryAction(item);
        if (context.mounted) unawaited(vm.refresh());
      } on FormatException catch (e) {
        if (!context.mounted) return;
        if (e.message.contains('Insufficient')) {
          _showInsufficientFundsDialog(context);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e))));
        }
      } on Exception catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e))));
      }
    }
  }

  /// Handles secondary action (cancel awarded offer) for a next action item.
  ///
  /// Phase 7: SnackBar colors migrated from Colors.green/red to semantic
  /// colorScheme.success/danger for light+dark mode consistency.
  Future<void> _handleSecondaryAction(
    BuildContext context,
    WorkItem item,
  ) async {
    final materialColors = Theme.of(context).colorScheme;

    AppInteractionStates.hapticTap();
    try {
      await context.read<DashboardViewModel>().cancelAwardedOffer(
        item.awardedRequestId!,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Award cancelled. Task is open again.',
              style: TextStyle(color: materialColors.onPrimary),
            ),
            backgroundColor: materialColors.primary,
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorMapper.map(e),
              style: TextStyle(color: materialColors.onError),
            ),
            backgroundColor: materialColors.error,
          ),
        );
      }
    }
  }
}
