import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import 'package:sline_app/features/dashboard/view/widgets/work_item_card.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:sline_app/features/proposals/routes/proposal_payment_route.dart';
import 'package:sline_app/features/wallet/view/wallet_screen.dart';

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
    final colorScheme = context.colorScheme;

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
        // Header & Tab Bar
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.p16,
            AppDimens.p16,
            AppDimens.p16,
            0,
          ),
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Work',
                style: AppTypography.h3.copyWith(color: colorScheme.text),
              ),
              const SizedBox(height: AppDimens.p8),
              Text(
                'Track all your jobs and bookings.',
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimens.p16),

              // Nested Tab Bar
              Semantics(
                label: 'Work sub-tabs',
                child: Container(
                  height: AppLayout.statusIndicatorHeight,
                  decoration: BoxDecoration(
                    color: colorScheme.inputBackground,
                    borderRadius: BorderRadius.circular(AppDimens.r12),
                  ),
                  child: TabBar(
                    controller: _subTabController,
                    // Semantic primary replaces hardcoded AppColors.teal
                    indicator: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppDimens.r10),
                    ),
                    // onPrimary (Material ColorScheme) ensures contrast against the primary-colored active indicator
                    labelColor: Theme.of(context).colorScheme.onPrimary,
                    unselectedLabelColor: colorScheme.textSecondary,
                    labelStyle: AppTypography.captionBold,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'Active (${active.length})'),
                      Tab(text: 'Done (${completed.length})'),
                      const Tab(text: 'Cancelled'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.p16),
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
    if (active.isEmpty && delivered.isEmpty) {
      return RefreshIndicator(
        onRefresh: vm.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      color: context.colorScheme.textSecondary,
                    ),
                    const SizedBox(height: AppLayout.spacingSection),
                    Text(
                      'No active work',
                      style: AppTypography.h5.copyWith(
                        color: context.colorScheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppLayout.spacingStandard),
                    Text(
                      'Browse tasks to get started',
                      style: AppTypography.bodySmall.copyWith(
                        color: context.colorScheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final colorScheme = context.colorScheme;

    // Separate delivered (needs review) from the rest
    final reviewItems = delivered;
    final otherActive = active.where((i) => !i.actionableNeedsReview).toList();

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.p16,
          0,
          AppDimens.p16,
          AppDimens.p100,
        ),
        children: [
          // Pinned "Needs Review" section
          if (reviewItems.isNotEmpty) ...[
            Semantics(
              header: true,
              label: 'Needs your review, ${reviewItems.length} items',
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.p8),
                child: Row(
                  children: [
                    Icon(
                      Icons.rate_review,
                      size: AppDimens.iconSizeSmall,
                      color: colorScheme.danger,
                    ),
                    const SizedBox(width: AppLayout.spacingTight),
                    Text(
                      'Needs Your Review (${reviewItems.length})',
                      style: AppTypography.captionBold.copyWith(
                        color: colorScheme.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...reviewItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.p12),
                child: WorkItemCard(
                  item: item,
                  onPrimaryAction: () => _onPrimaryAction(context, vm, item),
                  onSecondaryAction:
                      item.permissions.canCancel &&
                          item.awardedRequestId != null
                      ? () => _onCancelAward(context, vm, item)
                      : null,
                ),
              ),
            ),
            if (otherActive.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppDimens.p8,
                  bottom: AppDimens.p8,
                ),
                child: Divider(
                  color: colorScheme.textSecondary.withValues(alpha: 0.2),
                ),
              ),
          ],

          // Remaining active work
          if (otherActive.isNotEmpty) ...[
            if (reviewItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.p8),
                child: Text(
                  'In Progress (${otherActive.length})',
                  style: AppTypography.captionBold.copyWith(
                    color: colorScheme.textSecondary,
                  ),
                ),
              ),
            ...otherActive.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.p12),
                child: WorkItemCard(
                  item: item,
                  onPrimaryAction: () => _onPrimaryAction(context, vm, item),
                  onSecondaryAction:
                      item.permissions.canCancel &&
                          item.awardedRequestId != null
                      ? () => _onCancelAward(context, vm, item)
                      : null,
                ),
              ),
            ),
          ],
        ],
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
            backgroundColor: context.colorScheme.success,
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMapper.map(e)),
            backgroundColor: context.colorScheme.danger,
          ),
        );
      }
    }
  }

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

  Widget _buildWorkList({
    required BuildContext context,
    required List<WorkItem> items,
    required String emptyMessage,
    bool isDimmed = false,
  }) {
    final vm = context.read<DashboardViewModel>();
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: vm.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      color: context.colorScheme.textSecondary,
                    ),
                    const SizedBox(height: AppLayout.spacingSection),
                    // Phase 7: h5 title + bodySmall subtitle for consistency
                    // with _buildActiveList and other tab empty states.
                    Text(
                      emptyMessage,
                      style: AppTypography.h5.copyWith(
                        color: context.colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.p16,
          0,
          AppDimens.p16,
          AppDimens.p100,
        ),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.p12),
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
}
