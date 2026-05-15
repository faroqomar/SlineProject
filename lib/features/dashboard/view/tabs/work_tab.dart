import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/navigation/main_nav_destinations.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import 'package:sline_app/features/dashboard/view/widgets/work_item_card.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:sline_app/features/proposals/routes/proposal_payment_route.dart';
import 'package:sline_app/features/wallet/view/wallet_screen.dart';

/// Dashboard work bucket tab for active, completed, and cancelled work.
///
/// It owns only bucket presentation; all lifecycle actions continue to route
/// through [DashboardViewModel] and the existing payment route helpers.
class WorkTab extends StatefulWidget {
  const WorkTab({super.key});

  @override
  State<WorkTab> createState() => _WorkTabState();
}

class _WorkTabState extends State<WorkTab> with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final active = vm.activeWork;
    final delivered = vm.deliveredWork;
    final completed = vm.completedWork;
    final cancelled = vm.cancelledWork;
    final visibleActiveCount =
        delivered.length +
        active.where((item) => !item.actionableNeedsReview).length;
    const amber = AmberDuskTokens.colors;
    const spacing = AmberDuskTokens.spacing;
    final tabTheme = AmberDuskTokens.widgetTheme.tabs;
    // AmberDuskTokens own visual color/spacing recipes here; AppLayout and
    // AppDimens still provide structural shell sizes shared across dashboard tabs.

    // Consume pending sub-tab navigation intent from ViewModel
    final pendingSubTab = vm.consumeWorkSubTabIndex();
    if (pendingSubTab != null &&
        pendingSubTab >= 0 &&
        pendingSubTab < 3 &&
        _subTabController.index != pendingSubTab) {
      // Use addPostFrameCallback to avoid animating during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _subTabController.animateTo(pendingSubTab);
        }
      });
    }

    return Column(
      key: const Key('work_tab'),
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(
            spacing.contentHorizontalPadding,
            0,
            spacing.contentHorizontalPadding,
            spacing.lg,
          ),
          color: AmberDuskColors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'Work sub-tabs',
                child: Container(
                  height: AppLayout.statusIndicatorHeight,
                  decoration: BoxDecoration(
                    color: amber.surface,
                    borderRadius: BorderRadius.circular(spacing.pillRadius),
                  ),
                  child: TabBar(
                    controller: _subTabController,
                    indicator: BoxDecoration(
                      color: amber.primary,
                      borderRadius: BorderRadius.circular(spacing.pillRadius),
                    ),
                    labelColor: amber.text,
                    unselectedLabelColor: amber.textSubtle,
                    labelStyle: tabTheme.labelStyle,
                    unselectedLabelStyle: tabTheme.inactiveLabelStyle,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: AmberDuskColors.transparent,
                    tabs: [
                      Tab(text: 'Active $visibleActiveCount'),
                      Tab(text: 'Done ${completed.length}'),
                      Tab(text: 'Cancelled ${cancelled.length}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              // 1. Active Tab — with delivered pinned to top
              _buildActiveList(
                context: context,
                active: active,
                delivered: delivered,
              ),

              // 2. Completed Tab
              _buildWorkList(
                context: context,
                items: completed,
                emptyMessage: 'No completed work yet.',
                isDimmed: true,
              ),

              // 3. Cancelled Tab
              _buildWorkList(
                context: context,
                items: cancelled,
                emptyMessage: 'No cancelled work.',
                isDimmed: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveList({
    required BuildContext context,
    required List<WorkItem> active,
    required List<WorkItem> delivered,
  }) {
    final vm = context.read<DashboardViewModel>();
    const amber = AmberDuskTokens.colors;
    if (active.isEmpty && delivered.isEmpty) {
      return _dashboardRefreshIndicator(
        onRefresh: vm.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: _workListPadding(context),
          child: Semantics(
            label: 'No active work. Browse tasks to get started.',
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.work_off_outlined,
                      size: AppLayout.iconFeature,
                      color: amber.textSubtle,
                    ),
                    const SizedBox(height: AppLayout.spacingSection),
                    Text(
                      'No active work',
                      style: AppTypography.h5.copyWith(color: amber.textSubtle),
                    ),
                    const SizedBox(height: AppLayout.spacingStandard),
                    Text(
                      'Browse tasks to get started',
                      style: AppTypography.bodySmall.copyWith(
                        color: amber.muted,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p20),
                    FilledButton.icon(
                      onPressed: () => _openHomeTenders(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: amber.primary,
                        foregroundColor: amber.textInverse,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.r12),
                        ),
                      ),
                      icon: const Icon(Icons.assignment_outlined),
                      label: const Text('Find tender posts'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Open Design evidence shows one Active work list; urgency stays inside the
    // cards instead of splitting the tab into secondary status sections.
    final visibleActive = [
      ...delivered,
      ...active.where((item) => !item.actionableNeedsReview),
    ];

    return _dashboardRefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView.separated(
        padding: _workListPadding(context),
        itemCount: visibleActive.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppDimens.p12),
        itemBuilder: (_, index) {
          final item = visibleActive[index];
          return WorkItemCard(
            item: item,
            onPrimaryAction: () => _onPrimaryAction(context, vm, item),
            onSecondaryAction:
                item.permissions.canCancel && item.awardedRequestId != null
                ? () => _onCancelAward(context, vm, item)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _onPrimaryAction(
    BuildContext context,
    DashboardViewModel vm,
    WorkItem item,
  ) async {
    // Task awarded pending payment: open payment via shared route
    if (item.type == WorkItemType.task &&
        item.primaryActionType == PrimaryActionType.payEscrow &&
        item.awardedRequestId != null) {
      AppLogger.i(
        'Work: opening tender payment for request=${item.awardedRequestId} task=${item.id}',
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
        launcherSource: 'work_tab',
      );
      if (context.mounted) unawaited(vm.refresh());
      return;
    }

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

  Future<void> _onCancelAward(
    BuildContext context,
    DashboardViewModel vm,
    WorkItem item,
  ) async {
    if (item.awardedRequestId == null) return;
    AppLogger.i(
      'Work: cancel award request=${item.awardedRequestId}',
      tag: 'dashboard.work',
    );
    try {
      await vm.cancelAwardedOffer(item.awardedRequestId!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Award cancelled. Task is open again.'),
            backgroundColor: AmberDuskTokens.colors.success,
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMapper.map(e)),
            backgroundColor: AmberDuskTokens.colors.danger,
          ),
        );
      }
    }
  }

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
              style: TextButton.styleFrom(
                foregroundColor: AmberDuskTokens.colors.muted,
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const WalletScreen(),
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AmberDuskTokens.colors.primary,
                foregroundColor: AmberDuskTokens.colors.textInverse,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                ),
              ),
              child: const Text('Add funds'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkList({
    required BuildContext context,
    required List<WorkItem> items,
    required String emptyMessage,
    bool isDimmed = false,
  }) {
    final vm = context.read<DashboardViewModel>();
    const amber = AmberDuskTokens.colors;
    if (items.isEmpty) {
      return _dashboardRefreshIndicator(
        onRefresh: vm.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: _workListPadding(context),
          child: Semantics(
            label: emptyMessage,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.work_off_outlined,
                      size: AppLayout.iconFeature,
                      color: amber.textSubtle,
                    ),
                    const SizedBox(height: AppLayout.spacingSection),
                    // Phase 7: h5 title + bodySmall subtitle for consistency
                    // with _buildActiveList and other tab empty states.
                    Text(
                      emptyMessage,
                      style: AppTypography.h5.copyWith(color: amber.textSubtle),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return _dashboardRefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView.separated(
        padding: _workListPadding(context),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppDimens.p12),
        itemBuilder: (context, index) {
          final item = items[index];
          // 0.85 opacity for Done/Cancelled tabs — visually distinguishes completed/
          // inactive items from active work; 0.85 is less aggressive than 0.7 for
          // better readability while preserving the visual hierarchy intent.
          return Semantics(
            // Hint screen readers that this item is completed/inactive
            label: isDimmed ? 'Completed work item' : null,
            child: Opacity(
              opacity: isDimmed ? 0.85 : 1.0,
              child: WorkItemCard(
                item: item,
                onPrimaryAction: () => _onPrimaryAction(context, vm, item),
                onSecondaryAction:
                    item.permissions.canCancel && item.awardedRequestId != null
                    ? () => _onCancelAward(context, vm, item)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  void _openHomeTenders(BuildContext context) {
    AppLogger.i('Dashboard work empty CTA opened Home', tag: 'dashboard.work');
    context.read<NavigationProvider?>()?.setCurrentIndex(
      MainNavDestinations.home,
    );
  }

  EdgeInsets _workListPadding(BuildContext context) {
    const phoneLayout = AmberDuskTokens.phoneLayout;
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;
    return EdgeInsets.fromLTRB(
      AppDimens.p16,
      0,
      AppDimens.p16,
      bottomSafePadding +
          phoneLayout.bottomNavBottom +
          phoneLayout.bottomNavHeight +
          AppDimens.p24,
    );
  }

  RefreshIndicator _dashboardRefreshIndicator({
    required RefreshCallback onRefresh,
    required Widget child,
  }) {
    const amber = AmberDuskTokens.colors;
    return RefreshIndicator(
      color: amber.primary,
      backgroundColor: amber.surface,
      strokeWidth: 2.6,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
