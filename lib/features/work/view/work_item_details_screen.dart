import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/utils/loading_utils.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/circle_icon_button.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/profile/view/widgets/profile_preview_modal.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:sline_app/features/proposals/routes/proposal_payment_route.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';
import 'package:sline_app/features/work/models/unified_work_item_model.dart';
import 'package:sline_app/features/work/models/work_contract_model.dart';
import 'package:sline_app/features/work/services/work_management_service.dart';
import 'package:sline_app/features/work/view/widgets/request_extension_modal.dart';
import 'package:sline_app/features/work/view/widgets/review_delivery_modal.dart';
import 'package:sline_app/features/work/view/widgets/submit_delivery_modal.dart';
import 'package:sline_app/features/work/view/widgets/work_item_booking_details.dart';
import 'package:sline_app/features/work/view/widgets/work_item_bottom_actions.dart';
import 'package:sline_app/features/work/view/widgets/work_item_guard_widgets.dart';
import 'package:sline_app/features/work/viewmodels/work_item_details_view_model.dart';

/// Detail route for unified work items from tasks, bookings, and custom offers.
///
/// The route owns presentation and user actions while work loading and mutation
/// stay in [WorkItemDetailsViewModel] to preserve the feature MVVM boundary.
class WorkItemDetailsScreen extends StatelessWidget {
  /// Entity id from `vw_unified_work_items` or the originating deep link.
  final String id;

  /// Work item branch to load through [WorkItemDetailsViewModel].
  final WorkItemType type;

  /// Optional service override used by widget tests to exercise the production
  /// route without touching Supabase-backed defaults.
  final WorkManagementService? workService;

  /// Creates a work-item details route for a task, booking, or direct offer.
  const WorkItemDetailsScreen({
    super.key,
    required this.id,
    required this.type,
    this.workService,
  });

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthSessionViewModel>().currentUserId ?? '';
    return ChangeNotifierProvider(
      create: (ctx) => WorkItemDetailsViewModel(
        uid: uid,
        workService: workService,
        chatViewModel: ctx.read<ChatViewModel>(),
        dashboardViewModel: ctx.read<DashboardViewModel>(),
      ),
      child: _WorkItemDetailsContent(id: id, type: type),
    );
  }
}

/// Loading route that keeps deep-link transitions visually aligned with the
/// Amber Dusk work-management surface.
class _WorkItemLoadingScaffold extends StatelessWidget {
  const _WorkItemLoadingScaffold({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmberDuskColors.background,
      body: AmberDuskBackground(
        child: Stack(
          children: [
            const Center(
              child: CircularProgressIndicator(color: AmberDuskColors.primary),
            ),
            _WorkItemFloatingBackButton(onTap: onBack),
          ],
        ),
      ),
    );
  }
}

/// Shared error and empty-state shell with retry so transient work-detail
/// failures are recoverable without leaving the route.
class _WorkItemStateScaffold extends StatelessWidget {
  const _WorkItemStateScaffold({
    required this.title,
    required this.message,
    required this.icon,
    required this.onRetry,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmberDuskColors.background,
      body: AmberDuskBackground(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.p24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.cardMaxWidth,
                  ),
                  child: AppCardContainer(
                    padding: const EdgeInsets.all(AppDimens.p20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          color: AmberDuskColors.rust,
                          size: AppDimens.p40,
                        ),
                        const SizedBox(height: AppDimens.p12),
                        Text(
                          title,
                          style: AmberDuskTokens.typography.sectionTitle
                              .copyWith(color: AmberDuskColors.text),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimens.p8),
                        Text(
                          message,
                          style: AmberDuskTokens.typography.body.copyWith(
                            color: AmberDuskColors.textSubtle,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimens.p16),
                        AppButton(
                          onPressed: onRetry,
                          text: 'Retry',
                          icon: Icons.refresh,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _WorkItemFloatingBackButton(onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

/// Floating route escape used instead of a standard app bar so the work hero
/// remains the screen's primary title surface.
class _WorkItemFloatingBackButton extends StatelessWidget {
  const _WorkItemFloatingBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + AppDimens.p8,
      left: AppDimens.p16,
      child: CircleIconButton(
        icon: Icons.arrow_back,
        tooltip: 'Back',
        size: AppDimens.p40,
        onTap: onTap,
      ),
    );
  }
}

/// Floating back control plus compact tab strip that replaces the old app bar
/// without losing fast access to the three detail sections.
class _WorkItemFloatingChrome extends StatelessWidget {
  const _WorkItemFloatingChrome({
    required this.onBack,
    required this.semanticLabel,
  });

  final VoidCallback onBack;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + AppDimens.p8,
      left: AppDimens.p16,
      right: AppDimens.p16,
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.arrow_back,
            tooltip: 'Back',
            size: AppDimens.p40,
            onTap: onBack,
          ),
          const SizedBox(width: AppDimens.p8),
          Expanded(
            child: Semantics(
              label: semanticLabel,
              child: const SizedBox(
                height: AppDimens.p60,
                child: _WorkItemTabBar(horizontalPadding: AppDimens.p0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact floating tab strip with dashboard-style Amber Dusk pills.
class _WorkItemTabBar extends StatelessWidget implements PreferredSizeWidget {
  const _WorkItemTabBar({
    this.horizontalPadding = AmberDuskSpacing.contentHorizontalPadding,
  });

  final double horizontalPadding;

  @override
  Size get preferredSize => const Size.fromHeight(AppDimens.p60);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppDimens.p8,
        horizontalPadding,
        AppDimens.p10,
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: AmberDuskColors.primary,
          borderRadius: BorderRadius.circular(AmberDuskSpacing.pillRadius),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AmberDuskColors.textDark,
        labelStyle: AmberDuskTokens.typography.chip,
        unselectedLabelColor: AmberDuskColors.muted,
        unselectedLabelStyle: AmberDuskTokens.typography.chip,
        dividerColor: AmberDuskColors.transparent,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Extensions'),
          Tab(text: 'Contract'),
        ],
      ),
    );
  }
}

/// Hero summary for the work item, prioritizing title, status, price, and due
/// date so users can understand the contract at a glance.
class _WorkItemHeroCard extends StatelessWidget {
  const _WorkItemHeroCard({
    required this.title,
    required this.item,
    required this.statusColor,
    required this.otherPartyName,
    required this.isFreelancer,
  });

  final String title;
  final UnifiedWorkItemModel item;
  final Color statusColor;
  final String otherPartyName;
  final bool isFreelancer;

  @override
  Widget build(BuildContext context) {
    final isBooking = item.isBooking;
    final textColor = isBooking
        ? AmberDuskColors.heroText
        : AmberDuskColors.text;
    final mutedColor = isBooking
        ? AmberDuskColors.heroMuted
        : AmberDuskColors.textSubtle;
    final decoration = isBooking
        ? AmberDuskMaterial.bookingCardDecoration()
        : AmberDuskMaterial.taskCardDecoration();

    return Semantics(
      label:
          '${_sourceLabel(item)}, $title, ${_workStatusLabel(item.unifiedStatus)}',
      child: DecoratedBox(
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          _sourceIcon(item),
                          size: AppLayout.iconStandard,
                          color: statusColor,
                        ),
                        const SizedBox(width: AppDimens.p8),
                        Text(
                          _sourceLabel(item).toUpperCase(),
                          style: AmberDuskTokens.typography.chip.copyWith(
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _WorkStatusPill(
                    label: _workStatusLabel(item.unifiedStatus),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.p18),
              Text(
                title,
                style: AmberDuskTokens.typography.bookingName.copyWith(
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimens.p8),
              Text(
                '${isFreelancer ? 'Client' : 'Freelancer'} · $otherPartyName',
                style: AmberDuskTokens.typography.bodySmall.copyWith(
                  color: mutedColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimens.p20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VALUE',
                          style: AmberDuskTokens.typography.chip.copyWith(
                            color: mutedColor,
                          ),
                        ),
                        const SizedBox(height: AppDimens.p4),
                        Text(
                          PriceFormatter.formatPrice(item.price),
                          style: AmberDuskTokens.typography.moneyMedium
                              .copyWith(
                                color: textColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.p12),
                  _WorkMetricPill(
                    icon: Icons.schedule_outlined,
                    label: 'DUE',
                    value: _shortDate(item.deadline),
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lifecycle card with status guidance and operational metadata.
class _WorkItemLifecycleCard extends StatelessWidget {
  const _WorkItemLifecycleCard({
    required this.item,
    required this.statusColor,
    required this.isClient,
    required this.isFreelancer,
  });

  final UnifiedWorkItemModel item;
  final Color statusColor;
  final bool isClient;
  final bool isFreelancer;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppDimens.p40,
                height: AppDimens.p40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _workStatusIcon(item.unifiedStatus),
                  color: statusColor,
                  size: AppLayout.iconStandard,
                ),
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current stage',
                      style: AmberDuskTokens.typography.chip.copyWith(
                        color: AmberDuskColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p4),
                    Text(
                      _workStageTitle(item.unifiedStatus),
                      style: AmberDuskTokens.typography.sectionTitle.copyWith(
                        color: AmberDuskColors.text,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p6),
                    Text(
                      _workNextStep(item),
                      style: AmberDuskTokens.typography.bodySmall.copyWith(
                        color: AmberDuskColors.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(
            height: AppDimens.p32,
            thickness: AppDimens.hairlineDivider,
            color: AmberDuskMaterial.rowSeparator,
          ),
          _WorkDetailRow(
            label: 'Your role',
            value: _roleLabel(isClient: isClient, isFreelancer: isFreelancer),
            icon: Icons.person_outline,
          ),
          _WorkDetailRow(
            label: 'Source',
            value: _sourceLabel(item),
            icon: _sourceIcon(item),
          ),
          _WorkDetailRow(
            label: 'Revisions',
            value: '${item.revisionsUsed}/${item.revisionsTotal}',
            icon: Icons.replay_outlined,
          ),
          _WorkDetailRow(
            label: 'Deadline',
            value: _formatOptionalDate(item.deadline),
            icon: Icons.event_available_outlined,
          ),
          if (item.deliveredAt != null)
            _WorkDetailRow(
              label: 'Delivered',
              value: formatUtcToLocal(item.deliveredAt!),
              icon: Icons.outbox_outlined,
            ),
          if (item.reviewExpiresAt != null)
            _WorkDetailRow(
              label: 'Review by',
              value: formatUtcToLocal(item.reviewExpiresAt!),
              icon: Icons.rate_review_outlined,
            ),
          if (item.lastActivityAt != null)
            _WorkDetailRow(
              label: 'Last activity',
              value: formatUtcToLocal(item.lastActivityAt!),
              icon: Icons.update,
            ),
        ],
      ),
    );
  }
}

/// Compact contract preview for the overview tab, with the full snapshot still
/// available in the Contract tab.
class _WorkContractPreviewCard extends StatelessWidget {
  const _WorkContractPreviewCard({required this.contract});

  final WorkContractModel contract;

  @override
  Widget build(BuildContext context) {
    final previewEntries = contract.snapshot.entries.take(3).toList();

    return AppCardContainer(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WorkSectionHeader(
            icon: Icons.assignment_outlined,
            title: 'Contract snapshot',
            subtitle: 'Pinned terms used for this work item.',
          ),
          const SizedBox(height: AppDimens.p12),
          _WorkDetailRow(
            label: 'Version',
            value: contract.version.toString(),
            icon: Icons.layers_outlined,
          ),
          _WorkDetailRow(
            label: 'Effective',
            value: formatUtcToLocal(contract.createdAt),
            icon: Icons.calendar_today_outlined,
          ),
          for (final entry in previewEntries)
            _WorkDetailRow(
              label: _humanizeKey(entry.key),
              value: entry.value.toString(),
              icon: Icons.circle_outlined,
            ),
        ],
      ),
    );
  }
}

/// Section title used inside work-detail cards.
class _WorkSectionHeader extends StatelessWidget {
  const _WorkSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AmberDuskColors.primary,
          size: AppLayout.iconStandard,
        ),
        const SizedBox(width: AppDimens.p10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AmberDuskTokens.typography.sectionTitle.copyWith(
                  color: AmberDuskColors.text,
                ),
              ),
              const SizedBox(height: AppDimens.p4),
              Text(
                subtitle,
                style: AmberDuskTokens.typography.bodySmall.copyWith(
                  color: AmberDuskColors.textSubtle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Empty-state panel for secondary tabs.
class _WorkItemEmptyState extends StatelessWidget {
  const _WorkItemEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: AppCardContainer(
          padding: const EdgeInsets.all(AppDimens.p20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AmberDuskColors.primary, size: AppDimens.p40),
              const SizedBox(height: AppDimens.p12),
              Text(
                title,
                style: AmberDuskTokens.typography.sectionTitle.copyWith(
                  color: AmberDuskColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.p8),
              Text(
                message,
                style: AmberDuskTokens.typography.body.copyWith(
                  color: AmberDuskColors.textSubtle,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small metric chip used inside the hero card.
class _WorkMetricPill extends StatelessWidget {
  const _WorkMetricPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
    required this.mutedColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p10,
      ),
      decoration: BoxDecoration(
        color: AmberDuskColors.heroChip,
        borderRadius: BorderRadius.circular(AmberDuskSpacing.moduleRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: mutedColor, size: AppLayout.iconTiny),
          const SizedBox(width: AppDimens.p6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AmberDuskTokens.typography.chip.copyWith(
                  color: textColor,
                ),
              ),
              Text(
                label,
                style: AmberDuskTokens.typography.chip.copyWith(
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact status pill shared by work-detail summaries.
class _WorkStatusPill extends StatelessWidget {
  const _WorkStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p10,
        vertical: AppDimens.p6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AmberDuskSpacing.pillRadius),
      ),
      child: Text(
        label,
        style: AmberDuskTokens.typography.chip.copyWith(color: color),
      ),
    );
  }
}

/// Single metadata row with a stable icon slot for scanability.
class _WorkDetailRow extends StatelessWidget {
  const _WorkDetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AmberDuskColors.muted,
            size: AppLayout.iconStandard,
          ),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Text(
              label,
              style: AmberDuskTokens.typography.bodySmall.copyWith(
                color: AmberDuskColors.muted,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.p12),
          Flexible(
            child: Text(
              value,
              style: AmberDuskTokens.typography.bodySmall.copyWith(
                color: AmberDuskColors.text,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Converts a work source into the screen title language users expect.
String _workTypeLabel(String sourceType, bool isBookingFallback) {
  if (isBookingFallback || sourceType == 'booking') return 'Booking';
  if (sourceType == 'direct_offer') return 'Custom offer';
  return 'Task';
}

/// Human label for the source branch from `vw_unified_work_items`.
String _sourceLabel(UnifiedWorkItemModel item) {
  if (item.isBooking) return 'Booking';
  if (item.isDirectOffer) return 'Custom offer';
  return 'Task';
}

/// Icon that helps distinguish task, booking, and direct-offer branches.
IconData _sourceIcon(UnifiedWorkItemModel item) {
  if (item.isBooking) return Icons.event_available_outlined;
  if (item.isDirectOffer) return Icons.handshake_outlined;
  return Icons.work_outline;
}

/// Uppercase status label for badges and screen-reader summaries.
String _workStatusLabel(UnifiedWorkStatus status) {
  switch (status) {
    case UnifiedWorkStatus.pendingPayment:
      return 'PENDING PAYMENT';
    case UnifiedWorkStatus.requestPending:
      return 'REQUEST PENDING';
    case UnifiedWorkStatus.unknown:
      return 'STATUS UNKNOWN';
    case UnifiedWorkStatus.pending:
    case UnifiedWorkStatus.active:
    case UnifiedWorkStatus.delivered:
    case UnifiedWorkStatus.completed:
    case UnifiedWorkStatus.canceled:
    case UnifiedWorkStatus.disputed:
      return status.name.toUpperCase();
  }
}

/// Title-case lifecycle label for sections that already have a status badge.
String _workStageTitle(UnifiedWorkStatus status) {
  return _titleCaseWords(_workStatusLabel(status));
}

/// User-facing explanation of the next expected action.
String _workNextStep(UnifiedWorkItemModel item) {
  switch (item.unifiedStatus) {
    case UnifiedWorkStatus.pending:
    case UnifiedWorkStatus.requestPending:
      return 'The request is waiting for a response before work starts.';
    case UnifiedWorkStatus.pendingPayment:
      return 'Payment is required before the contract can move into active work.';
    case UnifiedWorkStatus.active:
      return 'Work is active. Delivery, extension, message, and safety actions are available.';
    case UnifiedWorkStatus.delivered:
      return item.needsReview
          ? 'Delivery is ready for client review.'
          : 'Delivery was submitted and is waiting for the next review step.';
    case UnifiedWorkStatus.completed:
      return 'This work item is complete and no further action is required.';
    case UnifiedWorkStatus.canceled:
      return 'This work item is closed.';
    case UnifiedWorkStatus.disputed:
      return 'Work is frozen while the dispute is under review.';
    case UnifiedWorkStatus.unknown:
      return 'The current lifecycle state could not be resolved.';
  }
}

/// Status icon used in the lifecycle card.
IconData _workStatusIcon(UnifiedWorkStatus status) {
  switch (status) {
    case UnifiedWorkStatus.pending:
    case UnifiedWorkStatus.requestPending:
      return Icons.hourglass_top_outlined;
    case UnifiedWorkStatus.pendingPayment:
      return Icons.payments_outlined;
    case UnifiedWorkStatus.active:
      return Icons.work_outline;
    case UnifiedWorkStatus.delivered:
      return Icons.rate_review_outlined;
    case UnifiedWorkStatus.completed:
      return Icons.verified_outlined;
    case UnifiedWorkStatus.canceled:
      return Icons.block_outlined;
    case UnifiedWorkStatus.disputed:
      return Icons.warning_amber_rounded;
    case UnifiedWorkStatus.unknown:
      return Icons.help_outline;
  }
}

/// Role label avoids exposing raw participant IDs.
String _roleLabel({required bool isClient, required bool isFreelancer}) {
  if (isClient) return 'Client';
  if (isFreelancer) return 'Freelancer';
  return 'Viewer';
}

/// Extracts the loaded profile name with a safe fallback.
String _otherPartyName(WorkItemDetailsViewModel vm) {
  return vm.otherPartyProfile?['full_name']?.toString() ?? 'Unknown user';
}

/// Localized date string or a clear empty-value label.
String _formatOptionalDate(DateTime? value) {
  return value == null ? 'No deadline' : formatUtcToLocal(value);
}

/// Short date for hero chips where the full timestamp would crowd the price.
String _shortDate(DateTime? value) {
  if (value == null) return 'None';
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

/// Presents snake_case contract snapshot keys as readable labels.
String _humanizeKey(String key) {
  return _titleCaseWords(key.replaceAll('_', ' '));
}

/// Small formatting helper for enum-like labels.
String _titleCaseWords(String value) {
  return value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
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
      unawaited(
        context.read<WorkItemDetailsViewModel>().loadData(
          widget.id,
          widget.type.name,
        ),
      );
    });
  }

  bool _shouldRefresh = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkItemDetailsViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) {
          return _WorkItemLoadingScaffold(
            onBack: () => Navigator.pop(context, _shouldRefresh),
          );
        }

        if (vm.error != null) {
          return _WorkItemStateScaffold(
            title: 'Work details',
            message: vm.error!,
            icon: Icons.error_outline,
            onRetry: () => unawaited(
              vm.loadData(widget.id, widget.type.name),
            ),
          );
        }

        if (vm.workItem == null) {
          return _WorkItemStateScaffold(
            title: 'Work details',
            message: 'No details found',
            icon: Icons.search_off_outlined,
            onRetry: () => unawaited(
              vm.loadData(widget.id, widget.type.name),
            ),
          );
        }

        final isBooking = widget.type == WorkItemType.booking;
        final title = vm.title.isNotEmpty
            ? vm.title
            : (isBooking ? 'Booking' : 'Task');
        final typeLabel = _workTypeLabel(vm.workItem!.sourceType, isBooking);
        final topInset = MediaQuery.paddingOf(context).top;

        return DefaultTabController(
          length: 3,
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              Navigator.pop(context, _shouldRefresh);
            },
            child: Scaffold(
              backgroundColor: AmberDuskColors.background,
              body: AmberDuskBackground(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: topInset + AppDimens.p80,
                        ),
                        child: TabBarView(
                          children: [
                            _buildOverviewTab(vm, title),
                            _buildExtensionsTab(vm),
                            _buildContractTab(vm),
                          ],
                        ),
                      ),
                    ),
                    _WorkItemFloatingChrome(
                      semanticLabel: '$typeLabel details sections',
                      onBack: () => Navigator.pop(context, _shouldRefresh),
                    ),
                  ],
                ),
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

  /// Builds the overview tab as a scannable work summary before role-specific
  /// booking and payment actions.
  Widget _buildOverviewTab(WorkItemDetailsViewModel vm, String title) {
    final item = vm.workItem;
    if (item == null) return const SizedBox.shrink();
    final statusColor = _mapStatusColor(vm.status, context.amberColors);
    final pendingPaymentActions = _buildPendingPaymentActions(context, vm);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AmberDuskSpacing.contentHorizontalPadding,
        AppDimens.p16,
        AmberDuskSpacing.contentHorizontalPadding,
        AppDimens.p32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkItemHeroCard(
            title: title,
            item: item,
            statusColor: statusColor,
            otherPartyName: _otherPartyName(vm),
            isFreelancer: vm.isFreelancer,
          ),
          const SizedBox(height: AppDimens.p16),
          _buildDisputedBanner(vm),
          _WorkItemLifecycleCard(
            item: item,
            statusColor: statusColor,
            isClient: vm.isClient,
            isFreelancer: vm.isFreelancer,
          ),
          if (vm.booking != null) ...[
            const SizedBox(height: AppDimens.p16),
            _buildBookingSpecifics(vm),
          ],
          if (pendingPaymentActions is! SizedBox) ...[
            const SizedBox(height: AppDimens.p16),
            pendingPaymentActions,
          ],
          if (vm.activeContract != null) ...[
            const SizedBox(height: AppDimens.p16),
            _WorkContractPreviewCard(contract: vm.activeContract!),
          ],
        ],
      ),
    );
  }

  /// Shows request history with the same Amber Dusk empty-state treatment used
  /// by other transactional screens.
  Widget _buildExtensionsTab(WorkItemDetailsViewModel vm) {
    if (vm.extensionRequests.isEmpty && vm.changeRequests.isEmpty) {
      return const _WorkItemEmptyState(
        icon: Icons.history_toggle_off_outlined,
        title: 'No requests history',
        message: 'Extension and change requests will appear here.',
      );
    }

    final allRequests = <Widget>[
      ...vm.extensionRequests.map(ExtensionRequestItem.new),
      ...vm.changeRequests.map(ChangeRequestItem.new),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AmberDuskSpacing.contentHorizontalPadding,
        AppDimens.p16,
        AmberDuskSpacing.contentHorizontalPadding,
        AppDimens.p32,
      ),
      itemCount: allRequests.length,
      itemBuilder: (context, index) => allRequests[index],
    );
  }

  /// Contract tab — clean sections with hairline dividers.
  Widget _buildContractTab(WorkItemDetailsViewModel vm) {
    final contract = vm.activeContract;
    if (contract == null) {
      return const _WorkItemEmptyState(
        icon: Icons.description_outlined,
        title: 'No active contract',
        message:
            'A signed work snapshot will appear after the contract starts.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AmberDuskSpacing.contentHorizontalPadding,
        AppDimens.p16,
        AmberDuskSpacing.contentHorizontalPadding,
        AppDimens.p32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCardContainer(
            padding: const EdgeInsets.all(AppDimens.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WorkSectionHeader(
                  icon: Icons.assignment_outlined,
                  title: 'Contract Info',
                  subtitle: 'Versioned snapshot used for delivery review.',
                ),
                const Divider(
                  height: AppDimens.p32,
                  thickness: AppDimens.hairlineDivider,
                  color: AmberDuskMaterial.rowSeparator,
                ),
                _WorkDetailRow(
                  label: 'Version',
                  value: contract.version.toString(),
                  icon: Icons.layers_outlined,
                ),
                _WorkDetailRow(
                  label: 'Effective',
                  value: formatUtcToLocal(contract.createdAt),
                  icon: Icons.calendar_today_outlined,
                ),
                _WorkDetailRow(
                  label: 'Hash',
                  value: contract.contractHash,
                  icon: Icons.tag_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          AppCardContainer(
            padding: const EdgeInsets.all(AppDimens.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WorkSectionHeader(
                  icon: Icons.fact_check_outlined,
                  title: 'Snapshot',
                  subtitle: 'Terms captured when this work item was created.',
                ),
                const SizedBox(height: AppDimens.p12),
                ...contract.snapshot.entries.map(
                  (entry) => _WorkDetailRow(
                    label: _humanizeKey(entry.key),
                    value: entry.value.toString(),
                    icon: Icons.circle_outlined,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Small helper widgets kept in parent
  // ---------------------------------------------------------------------------

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

  /// Map UnifiedWorkStatus to semantic color.
  Color _mapStatusColor(UnifiedWorkStatus status, AmberDuskColorScheme colors) {
    switch (status) {
      case UnifiedWorkStatus.pending:
      case UnifiedWorkStatus.pendingPayment:
      case UnifiedWorkStatus.requestPending:
        return colors.warning;
      case UnifiedWorkStatus.active:
        return colors.primary;
      case UnifiedWorkStatus.delivered:
        return colors.info;
      case UnifiedWorkStatus.completed:
        return colors.success;
      case UnifiedWorkStatus.canceled:
      case UnifiedWorkStatus.disputed:
        return colors.danger;
      case UnifiedWorkStatus.unknown:
        return colors.muted;
    }
  }

  // ---------------------------------------------------------------------------
  // Booking specifics -- delegates to extracted widget
  // ---------------------------------------------------------------------------

  Widget _buildBookingSpecifics(WorkItemDetailsViewModel vm) {
    final booking = vm.booking!;
    final profile = vm.otherPartyProfile;
    final otherName = profile?['full_name']?.toString() ?? 'Unknown User';
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
        // Awarded tasks can predate payment-deadline storage; keep the older
        // 24-hour checkout fallback so the proposal payment route still opens.
        DateTime.now().add(const Duration(hours: 24));
    final otherName =
        vm.otherPartyProfile?['full_name']?.toString() ?? 'Freelancer';

    return AppCardContainer(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _WorkSectionHeader(
            icon: Icons.payment_outlined,
            title: 'Payment required',
            subtitle: 'Confirm the awarded proposal before work can begin.',
          ),
          const SizedBox(height: AppDimens.p16),
          AppButton(
            tapTargetKey: const Key('work_item_details_pay_cta'),
            icon: Icons.lock_outline,
            text: 'Pay & Confirm',
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
          ),
          const SizedBox(height: AppDimens.p8),
          TextButton(
            onPressed: () async {
              try {
                await context.read<WorkItemDetailsViewModel>().cancelAward(
                  requestId,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Award cancelled. Task is open again.',
                      ),
                      backgroundColor: context.colorScheme.success,
                    ),
                  );
                  Navigator.of(context).pop();
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
            },
            child: const Text('Cancel payment'),
          ),
        ],
      ),
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
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AmberDuskColors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SubmitDeliveryModal(
            isLoading: vm.isLoading,
            onSubmit: (note) async {
              await vm.submitDelivery(note);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ),
      ),
    );
  }

  void _showExtensionModal(BuildContext context, WorkItemDetailsViewModel vm) {
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AmberDuskColors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: RequestExtensionModal(
            isLoading: vm.isLoading,
            onSubmit: (note, days) async {
              await vm.requestExtension(note, days);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showReviewModal(
    BuildContext context,
    WorkItemDetailsViewModel vm,
  ) async {
    final result = await showModalBottomSheet<bool>(
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
