import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/utils/loading_utils.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/profile/view/widgets/profile_preview_modal.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:sline_app/features/proposals/routes/proposal_payment_route.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';
import 'package:sline_app/features/work/view/widgets/request_extension_modal.dart';
import 'package:sline_app/features/work/view/widgets/review_delivery_modal.dart';
import 'package:sline_app/features/work/view/widgets/submit_delivery_modal.dart';
import 'package:sline_app/features/work/view/widgets/work_item_booking_details.dart';
import 'package:sline_app/features/work/view/widgets/work_item_bottom_actions.dart';
import 'package:sline_app/features/work/view/widgets/work_item_guard_widgets.dart';
import 'package:sline_app/features/work/viewmodels/work_item_details_view_model.dart';

class WorkItemDetailsScreen extends StatelessWidget {
  final String id;
  final WorkItemType type;

  const WorkItemDetailsScreen({
    super.key,
    required this.id,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthSessionViewModel>().currentUserId ?? '';
    return ChangeNotifierProvider(
      create: (ctx) => WorkItemDetailsViewModel(
        uid: uid,
        chatViewModel: ctx.read<ChatViewModel>(),
        dashboardViewModel: ctx.read<DashboardViewModel>(),
      ),
      child: _WorkItemDetailsContent(id: id, type: type),
    );
  }
}

class _WorkItemDetailsContent extends StatefulWidget {
  final String id;
  final WorkItemType type;

  const _WorkItemDetailsContent({required this.id, required this.type});

  @override
  State<_WorkItemDetailsContent> createState() =>
      _WorkItemDetailsContentState();
}

class _WorkItemDetailsContentState extends State<_WorkItemDetailsContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkItemDetailsViewModel>().loadData(
        widget.id,
        widget.type.name,
      );
    });
  }

  bool _shouldRefresh = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkItemDetailsViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text(vm.error!)),
          );
        }

        if (vm.workItem == null) {
          return const Scaffold(body: Center(child: Text('No details found')));
        }

        final isBooking = widget.type == WorkItemType.booking;
        final title = vm.title.isNotEmpty
            ? vm.title
            : (isBooking ? 'Booking' : 'Task');

        return DefaultTabController(
          length: 3,
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              Navigator.pop(context, _shouldRefresh);
            },
            child: Scaffold(
              backgroundColor: context.colorScheme.phoneBackground,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context, _shouldRefresh),
                ),
                title: Text(isBooking ? 'Booking' : 'Task'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                // Phase 7 REDESIGN: Pill-style tabs matching dashboard pattern
                bottom: TabBar(
                  indicator: BoxDecoration(
                    color: context.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppDimens.r20),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Theme.of(context).colorScheme.onPrimary,
                  labelStyle: AppTypography.captionBold,
                  unselectedLabelColor: context.colorScheme.textSecondary,
                  unselectedLabelStyle: AppTypography.caption,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Extensions'),
                    Tab(text: 'Contract'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _buildOverviewTab(vm, title),
                  _buildExtensionsTab(vm),
                  _buildContractTab(vm),
                ],
              ),
              bottomNavigationBar: _buildBottomActions(vm, context),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Tabs
  // ---------------------------------------------------------------------------

  Widget _buildOverviewTab(WorkItemDetailsViewModel vm, String title) {
    if (vm.booking != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.h3.copyWith(color: context.colorScheme.text),
            ),
            const SizedBox(height: AppDimens.p24),
            _buildDisputedBanner(vm),
            _buildBookingSpecifics(vm),
            const SizedBox(height: AppDimens.p24),
            _buildUnifiedStatus(vm),
            const SizedBox(height: AppDimens.p24),
            _buildContractInfo(vm),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h3.copyWith(color: context.colorScheme.text),
          ),
          const SizedBox(height: AppDimens.p24),
          _buildDisputedBanner(vm),
          _buildUnifiedStatus(vm),
          const SizedBox(height: AppDimens.p24),
          _buildPendingPaymentActions(context, vm),
          const SizedBox(height: AppDimens.p24),
          _buildContractInfo(vm),
        ],
      ),
    );
  }

  Widget _buildExtensionsTab(WorkItemDetailsViewModel vm) {
    if (vm.extensionRequests.isEmpty && vm.changeRequests.isEmpty) {
      return const Center(child: Text('No requests history'));
    }

    final allRequests = <Widget>[
      ...vm.extensionRequests.map(ExtensionRequestItem.new),
      ...vm.changeRequests.map(ChangeRequestItem.new),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.p16),
      itemCount: allRequests.length,
      itemBuilder: (context, index) => allRequests[index],
    );
  }

  /// Contract tab — clean sections with hairline dividers.
  Widget _buildContractTab(WorkItemDetailsViewModel vm) {
    final contract = vm.activeContract;
    final colorScheme = context.colorScheme;
    if (contract == null) {
      return Center(
        child: Text(
          'No active contract',
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.textTertiary,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contract Info',
            style: AppTypography.h4.copyWith(color: colorScheme.text),
          ),
          const SizedBox(height: AppDimens.p16),
          Container(height: 0.5, color: colorScheme.divider),
          const SizedBox(height: AppDimens.p16),
          _infoRow('Version', contract.version.toString()),
          _infoRow(
            'Effective Date',
            contract.createdAt.toString().split(' ')[0],
          ),
          const SizedBox(height: AppDimens.p16),
          Container(height: 0.5, color: colorScheme.divider),
          const SizedBox(height: AppDimens.p16),
          Text(
            'SNAPSHOT',
            style: AppTypography.overline.copyWith(
              color: colorScheme.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppDimens.p12),
          ...contract.snapshot.entries.map(
            (e) => _infoRow(e.key, e.value.toString()),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Small helper widgets kept in parent
  // ---------------------------------------------------------------------------

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildDisputedBanner(WorkItemDetailsViewModel vm) {
    if (vm.status != UnifiedWorkStatus.disputed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p24),
      child: DisputeBannerContent(
        sourceType: vm.workItem!.sourceType,
        entityId: vm.workItem!.id,
        safetyViewModel: context.read<SafetyViewModel>(),
      ),
    );
  }

  /// Premium status strip — inline, no card wrapper. Colored dot + overline
  /// label + status name. Minimal, Stripe-like.
  Widget _buildUnifiedStatus(WorkItemDetailsViewModel vm) {
    final colorScheme = context.colorScheme;
    final statusColor = _mapStatusColor(vm.status, colorScheme);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p16,
        vertical: AppDimens.p14,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimens.r12),
      ),
      child: Row(
        children: [
          // Small colored dot indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimens.p12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STATUS',
                style: AppTypography.micro.copyWith(
                  color: colorScheme.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                vm.status.name.toUpperCase().replaceAll('_', ' '),
                style: AppTypography.h6.copyWith(color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Map UnifiedWorkStatus to semantic color.
  Color _mapStatusColor(UnifiedWorkStatus status, AppColorScheme cs) {
    switch (status) {
      case UnifiedWorkStatus.pending:
      case UnifiedWorkStatus.pendingPayment:
      case UnifiedWorkStatus.requestPending:
        return cs.warning;
      case UnifiedWorkStatus.active:
        return cs.primary;
      case UnifiedWorkStatus.delivered:
        return cs.info;
      case UnifiedWorkStatus.completed:
        return cs.success;
      case UnifiedWorkStatus.canceled:
      case UnifiedWorkStatus.disputed:
        return cs.danger;
      case UnifiedWorkStatus.unknown:
        return cs.textSecondary;
    }
  }

  /// Premium contract info — hero price on surface, hairline divider,
  /// deadline with icon. No card wrapper, lives directly in the overview.
  Widget _buildContractInfo(WorkItemDetailsViewModel vm) {
    if (vm.activeContract == null) return const SizedBox.shrink();
    final colorScheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero price — overline label + h1 amount
        Text(
          'PRICE',
          style: AppTypography.overline.copyWith(
            color: colorScheme.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppDimens.p4),
        Text(
          PriceFormatter.formatPrice(vm.workItem?.price ?? 0),
          style: AppTypography.h1.copyWith(
            color: colorScheme.text,
            letterSpacing: -0.5,
          ),
        ),
        if (vm.workItem?.deadline != null) ...[
          const SizedBox(height: AppDimens.p8),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: colorScheme.textTertiary),
              const SizedBox(width: AppDimens.p6),
              Text(
                'Due ${vm.workItem!.deadline}',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.textTertiary,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppDimens.p24),
        // Hairline divider between price and rest
        Container(height: 0.5, color: colorScheme.divider),
        const SizedBox(height: AppDimens.p16),
        // Contract label
        Text(
          'Contract Info',
          style: AppTypography.captionBold.copyWith(
            color: colorScheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Booking specifics -- delegates to extracted widget
  // ---------------------------------------------------------------------------

  Widget _buildBookingSpecifics(WorkItemDetailsViewModel vm) {
    final booking = vm.booking!;
    final profile = vm.otherPartyProfile;
    final otherName = profile?['full_name'] ?? 'Unknown User';
    final otherAvatar = profile?['avatar_url'] as String?;

    return WorkItemBookingDetails(
      booking: booking,
      isFreelancer: vm.isFreelancer,
      otherPartyName: otherName,
      otherPartyAvatar: otherAvatar,
      onTapProfile: () {
        final targetId = vm.isFreelancer
            ? vm.workItem?.clientId
            : vm.workItem?.freelancerId;
        if (targetId != null && context.mounted) {
          showProfilePreview(context, targetId);
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Pending payment actions (task-only, client-only)
  // ---------------------------------------------------------------------------

  Widget _buildPendingPaymentActions(
    BuildContext context,
    WorkItemDetailsViewModel vm,
  ) {
    final isTaskPendingPayment =
        widget.type == WorkItemType.task &&
        vm.status == UnifiedWorkStatus.pendingPayment &&
        vm.isClient &&
        vm.workItem?.awardedRequestId != null;

    if (!isTaskPendingPayment) return const SizedBox.shrink();

    final requestId = vm.workItem!.awardedRequestId!;
    final taskId = widget.id;
    final taskTitle = vm.title;
    final amount = vm.workItem!.price;
    final deadline =
        vm.workItem?.paymentDeadline ??
        DateTime.now().add(const Duration(hours: 24));
    final otherName = vm.otherPartyProfile?['full_name'] ?? 'Freelancer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('work_item_details_pay_cta'),
            onPressed: () async {
              final summary = ProposalPaymentSummary(
                requestId: requestId,
                taskId: taskId,
                taskTitle: taskTitle,
                freelancerName: otherName,
                amount: amount,
                paymentDeadline: deadline,
              );
              await openProposalPayment(
                context,
                summary: summary,
                launcherSource: 'work_item_details',
              );
              if (context.mounted) {
                context.read<WorkItemDetailsViewModel>().refreshDashboard();
                unawaited(
                  context.read<WorkItemDetailsViewModel>().loadData(
                    taskId,
                    'task',
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            child: const Text('Pay & Confirm'),
          ),
        ),
        const SizedBox(height: AppDimens.p8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () async {
              try {
                await context.read<WorkItemDetailsViewModel>().cancelAward(
                  requestId,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Award cancelled. Task is open again.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ErrorMapper.map(e)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Cancel payment'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom actions -- delegates to extracted widget
  // ---------------------------------------------------------------------------

  Widget? _buildBottomActions(
    WorkItemDetailsViewModel vm,
    BuildContext context,
  ) {
    if (vm.workItem == null) return null;

    return WorkItemBottomActions(
      status: vm.status,
      isFreelancer: vm.isFreelancer,
      isClient: vm.isClient,
      isBooking: vm.workItem?.isBooking ?? false,
      canReview: vm.canReview,
      sourceType: vm.workItem!.sourceType,
      entityId: vm.workItem!.id,
      canShowReportIssue: _canShowReportIssue(vm),
      safetyViewModel: context.read<SafetyViewModel>(),
      onSubmitWork: () => _showDeliveryModal(context, vm),
      onReview: () => _showReviewModal(context, vm),
      onRequestExtension: () => _showExtensionModal(context, vm),
      onMessage: () => _handleMessage(context, vm),
      onReportIssue: () => _showDisputeDialog(context, vm),
      onAcceptBooking: () => vm.acceptBooking(),
      onDeclineBooking: () => vm.declineBooking(),
      onCancelBooking: () => vm.cancelBooking(),
    );
  }

  // ---------------------------------------------------------------------------
  // Modal / dialog launchers
  // ---------------------------------------------------------------------------

  void _showDeliveryModal(BuildContext context, WorkItemDetailsViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SubmitDeliveryModal(
          isLoading: vm.isLoading,
          onSubmit: (note) async {
            await vm.submitDelivery(note);
            if (ctx.mounted) Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  void _showExtensionModal(BuildContext context, WorkItemDetailsViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: RequestExtensionModal(
          isLoading: vm.isLoading,
          onSubmit: (note, days) async {
            await vm.requestExtension(note, days);
            if (ctx.mounted) Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  Future<void> _showReviewModal(
    BuildContext context,
    WorkItemDetailsViewModel vm,
  ) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.cardBackground,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ReviewDeliveryModal(
          onApprove: vm.approveDelivery,
          onReject: (reason) async {
            await vm.requestRevision(reason);
          },
          canRequestRevision:
              vm.workItem != null &&
              (vm.workItem!.revisionsUsed < vm.workItem!.revisionsTotal),
          getRevisionError: () => vm.error,
        ),
      ),
    );

    if (result == true && context.mounted) {
      _shouldRefresh = true;
      if (vm.workItem != null) {
        unawaited(vm.loadData(vm.workItem!.id, vm.workItem!.sourceType));
      }
    }
  }

  bool _canShowReportIssue(WorkItemDetailsViewModel vm) {
    if (vm.workItem == null) return false;
    final type = vm.workItem!.sourceType;
    final allowedStatus =
        vm.status == UnifiedWorkStatus.active ||
        vm.status == UnifiedWorkStatus.delivered;
    if (!allowedStatus) return false;
    if (type == 'booking') {
      return vm.booking?.taskId != null && vm.booking!.taskId!.isNotEmpty;
    }
    return type == 'task' || type == 'direct_offer';
  }

  Future<void> _showDisputeDialog(
    BuildContext context,
    WorkItemDetailsViewModel vm,
  ) async {
    if (vm.workItem == null) return;
    final sourceType = vm.workItem!.sourceType;
    final uid = context.read<AuthSessionViewModel>().currentUserId ?? '';
    final entityId = vm.workItem!.id;
    final defendantId = uid == vm.workItem!.clientId
        ? vm.workItem!.freelancerId
        : vm.workItem!.clientId;

    if (sourceType == 'booking') {
      final taskId = vm.booking?.taskId;
      if (taskId == null || taskId.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This booking cannot be disputed because task data is missing.',
            ),
          ),
        );
        return;
      }
    }

    var draftReason = '';
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Issue'),
        content: TextField(
          maxLines: 4,
          onChanged: (value) => draftReason = value,
          decoration: const InputDecoration(
            hintText: 'Describe the problem with this work',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, draftReason.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (!context.mounted || reason == null || reason.isEmpty) return;
    final safetyVm = context.read<SafetyViewModel>();
    final bool ok;
    if (sourceType == 'task') {
      ok = await safetyVm.submitDispute(
        taskId: entityId,
        reason: reason,
        defendantId: defendantId,
      );
    } else if (sourceType == 'direct_offer') {
      ok = await safetyVm.submitDispute(
        directOfferId: entityId,
        reason: reason,
        defendantId: defendantId,
      );
    } else {
      assert(sourceType == 'booking', 'Expected sourceType to be booking');
      ok = await safetyVm.submitDispute(
        taskId: vm.booking!.taskId,
        reason: reason,
        defendantId: defendantId,
      );
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Dispute submitted.' : (safetyVm.error ?? 'Dispute failed.'),
        ),
      ),
    );
    if (ok && vm.workItem != null) {
      unawaited(vm.loadData(vm.workItem!.id, vm.workItem!.sourceType));
    }
  }

  Future<void> _handleMessage(
    BuildContext context,
    WorkItemDetailsViewModel vm,
  ) async {
    if (vm.workItem == null) return;

    final loader = LoadingUtils.show(context, debugLabel: 'work_item_chat');

    try {
      final convo = await vm.openConversation();
      if (!context.mounted) return;
      if (convo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open conversation')),
        );
        return;
      }
      unawaited(
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(conversation: convo)),
        ),
      );
    } on Exception catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open chat. Please try again.')),
      );
    } finally {
      loader.close();
    }
  }
}
