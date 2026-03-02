import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/dashboard/view/widgets/work_item_card.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
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
                "My Work",
                style: AppTypography.h3.copyWith(color: colorScheme.text),
              ),
              const SizedBox(height: AppDimens.p8),
              Text(
                "Track all your jobs and bookings.",
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimens.p16),

              // Nested Tab Bar
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.inputBackground,
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                ),
                child: TabBar(
                  controller: _subTabController,
                  indicator: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(AppDimens.r10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: colorScheme.textSecondary,
                  labelStyle: AppTypography.captionBold,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: "Active (${active.length})"),
                    Tab(text: "Done (${completed.length})"),
                    Tab(text: "Cancelled"),
                  ],
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
                emptyMessage: "No completed work yet.",
                isDimmed: true,
              ),

              // 3. Cancelled Tab
              _buildWorkList(
                context: context,
                items: cancelled,
                emptyMessage: "No cancelled work.",
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
    if (active.isEmpty && delivered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off_outlined,
              size: 48,
              color: context.colorScheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimens.p16),
            Text(
              "No active work.",
              style: AppTypography.bodyMedium.copyWith(
                color: context.colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final vm = context.read<DashboardViewModel>();
    final colorScheme = context.colorScheme;

    // Separate delivered (needs review) from the rest
    final reviewItems = delivered;
    final otherActive = active.where((i) => !i.actionableNeedsReview).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p16,
        0,
        AppDimens.p16,
        AppDimens.p100,
      ),
      children: [
        // Pinned "Needs Review" section
        if (reviewItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.p8),
            child: Row(
              children: [
                Icon(Icons.rate_review, size: 16, color: AppColors.lightRed),
                const SizedBox(width: 6),
                Text(
                  'Needs Your Review (${reviewItems.length})',
                  style: AppTypography.captionBold.copyWith(
                    color: AppColors.lightRed,
                  ),
                ),
              ],
            ),
          ),
          ...reviewItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.p12),
              child: WorkItemCard(
                item: item,
                onPrimaryAction: () => _onPrimaryAction(context, vm, item),
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
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _onPrimaryAction(
    BuildContext context,
    DashboardViewModel vm,
    WorkItem item,
  ) async {
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
          content: Text(e is Exception ? e.toString() : 'Something went wrong'),
        ),
      );
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
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off_outlined,
              size: 48,
              color: context.colorScheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimens.p16),
            Text(
              emptyMessage,
              style: AppTypography.bodyMedium.copyWith(
                color: context.colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final vm = context.read<DashboardViewModel>();

    return ListView.separated(
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
        return Opacity(
          opacity: isDimmed ? 0.7 : 1.0,
          child: WorkItemCard(
            item: item,
            onPrimaryAction: () => _onPrimaryAction(context, vm, item),
          ),
        );
      },
    );
  }
}
