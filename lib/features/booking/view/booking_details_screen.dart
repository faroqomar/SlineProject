import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/loading_utils.dart';
import 'package:sline_app/core/utils/unified_cta_resolver.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/management/models/work_log_scope.dart';
import 'package:sline_app/features/management/view/widgets/order_management_section.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';
import 'package:sline_app/l10n/app_localizations.dart';

/// Booking detail screen for lifecycle, payment, chat, and safety actions.
class BookingDetailsScreen extends StatelessWidget {
  /// Booking shown by this detail route.
  final BookingModel booking;

  /// Creates a booking detail route for an existing booking model.
  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    const amber = AmberDuskTokens.colors;
    final isProvider =
        context.read<BookingViewModel>().currentUserId == booking.providerId;
    final taskTitleValue = booking.taskData?['title'];
    final taskTitle = taskTitleValue is String
        ? taskTitleValue
        : l10n.bookedService;

    return Scaffold(
      backgroundColor: amber.page,
      appBar: AppBar(
        title: Text(
          l10n.bookingDetails,
          style: AmberDuskTokens.typography.sectionTitle.copyWith(
            color: amber.text,
          ),
        ),
        backgroundColor: amber.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: amber.text,
            size: AppDimens.iconSizeSmall,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            _buildStatusBanner(context, booking.status),

            // CTA Resolver Banner
            Builder(
              builder: (_) {
                final ctaMeta = UnifiedCtaResolver.resolveActions(
                  status: booking.status.name,
                  paymentStatus: booking.paymentStatus.name,
                  actorRole: isProvider ? 'provider' : 'client',
                  entityType: 'booking',
                );
                if (ctaMeta.badgeText != null && ctaMeta.badgeColor != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppDimens.p12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimens.p12),
                      decoration: BoxDecoration(
                        color: ctaMeta.badgeColor!.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimens.r8),
                        border: Border.all(color: ctaMeta.badgeColor!),
                      ),
                      child: Text(
                        ctaMeta.badgeText!,
                        style: AppTypography.bodySmall.copyWith(
                          color: ctaMeta.badgeColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: AppDimens.p24),

            _BookingDisputeBanner(bookingId: booking.id),

            // Service Card (Task Info)
            _buildSectionHeader(context, l10n.bookingService),
            const SizedBox(height: AppDimens.p12),
            AppCardContainer(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Row(
                children: [
                  Container(
                    width: AppLayout.thumbnailSmall,
                    height: AppLayout.thumbnailSmall,
                    decoration: BoxDecoration(
                      color: colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimens.r12),
                    ),
                    child: Icon(Icons.work_outline, color: amber.primary),
                  ),
                  const SizedBox(width: AppDimens.p16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          taskTitle,
                          style: AppTypography.h6.copyWith(
                            color: colorScheme.text,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDimens.p4),
                        Text(
                          l10n.bookedOn(formatUtcToLocal(booking.createdAtUtc)),
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.p24),

            // Counterparty Info
            _buildSectionHeader(
              context,
              isProvider ? l10n.bookingClient : l10n.bookingProvider,
            ),
            const SizedBox(height: AppDimens.p12),
            AppCardContainer(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Row(
                children: [
                  const SignedAvatar(
                    // Ideally we fetch profiles, but for now we might only have IDs.
                    storagePathOrUrl: null,
                    radius: 24,
                  ),
                  const SizedBox(width: AppDimens.p16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isProvider
                              ? l10n.bookingClient
                              : l10n.bookingProvider,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.text,
                          ),
                        ),
                        Text(
                          isProvider
                              ? l10n.bookingRequester
                              : l10n.assignedServiceProvider,
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline, color: amber.primary),
                    onPressed: () => _handleMessage(context, booking),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.p24),

            // Timeline
            _buildSectionHeader(context, l10n.bookingTimeline),
            const SizedBox(height: AppDimens.p12),
            AppCardContainer(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _timelineRow(
                    context,
                    l10n.bookingTimelineBooked,
                    formatUtcToLocal(booking.createdAtUtc),
                  ),
                  const SizedBox(height: AppDimens.p8),
                  _timelineRow(
                    context,
                    l10n.bookingTimelineDue,
                    booking.dueAtUtc != null
                        ? formatUtcToLocal(booking.dueAtUtc!)
                        : l10n.noDeadline,
                  ),
                  if (booking.deliveryDays != null) ...[
                    const SizedBox(height: AppDimens.p8),
                    _timelineRow(
                      context,
                      l10n.bookingTimelineDelivery,
                      l10n.bookingDeliveryDays(booking.deliveryDays!),
                    ),
                  ],
                  if (booking.slotId != null) ...[
                    const SizedBox(height: AppDimens.p12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.p10,
                        vertical: AppDimens.p8,
                      ),
                      decoration: BoxDecoration(
                        color: amber.warningMuted,
                        borderRadius: BorderRadius.circular(AppDimens.r8),
                        border: Border.all(
                          color: amber.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        l10n.legacySlotBasedBooking,
                        style: AppTypography.bodySmall.copyWith(
                          color: amber.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppDimens.p24),

            // Order Management
            OrderManagementSection(
              scope: WorkLogScope(entityId: booking.id, entityType: 'booking'),
              currentUserId:
                  context.read<BookingViewModel>().currentUserId ?? '',
            ),

            const SizedBox(height: AppDimens.p24),

            // Actions
            if (isProvider &&
                booking.status == BookingStatus.pending &&
                booking.paymentStatus != PaymentStatus.held)
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: l10n.reject,
                      isPrimary: false,
                      onPressed: () => _updateStatus(
                        context,
                        booking,
                        BookingStatus.canceled,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.p16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.p12,
                        vertical: AppDimens.p14,
                      ),
                      decoration: BoxDecoration(
                        color: amber.warningMuted,
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                        border: Border.all(
                          color: amber.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        l10n.awaitingPayment,
                        style: AppTypography.bodySmall.copyWith(
                          color: amber.warning,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),

            if (!isProvider && booking.status == BookingStatus.pending)
              AppButton(
                text: l10n.cancelBooking,
                isPrimary: false,
                onPressed: () =>
                    _updateStatus(context, booking, BookingStatus.canceled),
              ),

            // --- Dynamic Actions based on CTA Resolver ---
            Builder(
              builder: (ctx) {
                final ctaMeta = UnifiedCtaResolver.resolveActions(
                  status: booking.status.name,
                  paymentStatus: booking.paymentStatus.name,
                  actorRole: isProvider ? 'provider' : 'client',
                  entityType: 'booking',
                );

                final dynamicActions = <Widget>[];

                if (ctaMeta.allowedActions.contains('escrow_hold')) {
                  dynamicActions.addAll([
                    AppButton(
                      text: l10n.escrowFunds,
                      onPressed: () => ctx
                          .read<BookingViewModel>()
                          .escrowHoldBooking(booking.id),
                    ),
                    const SizedBox(height: AppDimens.p12),
                  ]);
                }

                if (ctaMeta.allowedActions.contains('release_with_fee')) {
                  dynamicActions.addAll([
                    _ApproveWithDisputeGuard(
                      booking: booking,
                      onRelease: () => ctx
                          .read<BookingViewModel>()
                          .releaseBookingWithFee(booking.id),
                    ),
                    const SizedBox(height: AppDimens.p12),
                  ]);
                }

                if (ctaMeta.allowedActions.contains('refund')) {
                  dynamicActions.addAll([
                    AppButton(
                      text: l10n.issueRefund,
                      isPrimary: false,
                      onPressed: () {
                        // The refund logic can be wired here if the provider needs an explicit refund button
                        // Usually handled automatically on decline though.
                      },
                    ),
                    const SizedBox(height: AppDimens.p12),
                  ]);
                }

                return Column(children: dynamicActions);
              },
            ),

            // 1. Provider Actions (Legacy status-based checks that don't overlap with Payment matrix directly yet)
            if (isProvider) ...[
              // Accept Request (Funds held)
              if (booking.status == BookingStatus.paidRequestPending ||
                  (booking.status == BookingStatus.pending &&
                      booking.paymentStatus == PaymentStatus.held)) ...[
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: l10n.decline,
                        isPrimary: false,
                        onPressed: () => context
                            .read<BookingViewModel>()
                            .declineBooking(booking.id),
                      ),
                    ),
                    const SizedBox(width: AppDimens.p16),
                    Expanded(
                      child: AppButton(
                        text: l10n.acceptJob,
                        onPressed: () => context
                            .read<BookingViewModel>()
                            .acceptBooking(booking.id),
                      ),
                    ),
                  ],
                ),
              ],
              // Mark Delivered
              if (booking.status == BookingStatus.active) ...[
                AppButton(
                  text: l10n.markDelivered,
                  onPressed: () => context
                      .read<BookingViewModel>()
                      .markDelivered(booking.id),
                ),
              ],
            ],

            // 2. Client Actions
            if (!isProvider) ...[
              // Report Issue when active or delivered; hidden when open dispute exists
              if (booking.status == BookingStatus.active ||
                  booking.status == BookingStatus.delivered) ...[
                const SizedBox(height: AppDimens.p12),
                _ReportIssueGuardBooking(
                  bookingId: booking.id,
                  onReportIssue: () => _showDisputeDialog(context, booking),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _timelineRow(BuildContext context, String label, String value) {
    final colorScheme = context.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: AppTypography.h5.copyWith(color: context.colorScheme.text),
    );
  }

  Future<void> _showDisputeDialog(
    BuildContext context,
    BookingModel booking,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (booking.taskId == null || booking.taskId!.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bookingCannotDisputeMissingTask)),
      );
      return;
    }

    var draftReason = '';
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reportIssue),
        content: TextField(
          maxLines: 4,
          onChanged: (value) => draftReason = value,
          decoration: InputDecoration(
            hintText: l10n.describeBookingProblem,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, draftReason.trim()),
            child: Text(l10n.actionSubmit),
          ),
        ],
      ),
    );

    if (!context.mounted || reason == null || reason.isEmpty) return;

    final currentUserId = context.read<BookingViewModel>().currentUserId;
    final defendantId = currentUserId == booking.clientId
        ? booking.providerId
        : booking.clientId;

    final vm = context.read<SafetyViewModel>();
    final ok = await vm.submitDispute(
      taskId: booking.taskId,
      reason: reason,
      defendantId: defendantId,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? l10n.disputeSubmitted : (vm.error ?? l10n.disputeFailed),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, BookingStatus status) {
    const amber = AmberDuskTokens.colors;
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String text;

    switch (status) {
      case BookingStatus.pending:
        color = amber.warning;
        text = l10n.bookingStatusPendingConfirmation;
      case BookingStatus.confirmed:
        color = amber.primary;
        text = l10n.bookingStatusConfirmed;
      case BookingStatus.completed:
        color = amber.success;
        text = l10n.bookingStatusCompleted;
      case BookingStatus.canceled:
        color = amber.danger;
        text = l10n.bookingStatusCanceled;
      case BookingStatus.noShow:
        color = amber.danger;
        text = l10n.bookingStatusNoShow;
      case BookingStatus.inProgress:
        color = amber.primary;
        text = l10n.bookingStatusInProgress;
      case BookingStatus.declined:
        color = amber.danger;
        text = l10n.bookingStatusDeclined;
      case BookingStatus.active:
        color = amber.primary;
        text = l10n.bookingStatusActive;
      case BookingStatus.paidRequestPending:
        color = amber.warning;
        text = l10n.bookingStatusRequestPending;
      case BookingStatus.delivered:
        color = amber.success;
        text = l10n.bookingStatusDeliveredReview;
      case BookingStatus.refunded:
        color = amber.success;
        text = l10n.bookingStatusRefunded;
      case BookingStatus.expiredUnanswered:
        color = amber.muted;
        text = l10n.bookingStatusExpired;
      case BookingStatus.disputed:
        color = amber.warning;
        text = l10n.bookingStatusDisputedUnderReview;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: AppDimens.p12),
          Text(
            text,
            style: AppTypography.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMessage(
    BuildContext context,
    BookingModel booking,
  ) async {
    final vm = context.read<BookingViewModel>();
    final uid = vm.currentUserId;
    if (uid == null) return;

    final loader = LoadingUtils.show(context, debugLabel: 'booking_chat');
    try {
      final convo = await vm.contactProvider(booking, uid);
      if (!context.mounted) return;

      if (convo != null) {
        unawaited(
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(conversation: convo)),
          ),
        );
      }
    } finally {
      loader.close();
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    BookingModel booking,
    BookingStatus status,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.read<BookingViewModel>();
    final loader = LoadingUtils.show(
      context,
      debugLabel: 'booking_status_update',
    );
    try {
      final success = await vm.updateBookingStatus(
        bookingId: booking.id,
        newStatus: status,
      );
      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.statusUpdated)));
        Navigator.pop(context); // Refresh/Back
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.statusUpdateFailed)));
      }
    } finally {
      loader.close();
    }
  }
}

/// Shows Report Issue button only when there is no open dispute for the booking.
class _ReportIssueGuardBooking extends StatelessWidget {
  const _ReportIssueGuardBooking({
    required this.bookingId,
    required this.onReportIssue,
  });

  final String bookingId;
  final VoidCallback onReportIssue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<bool>(
      future: context.read<SafetyViewModel>().hasOpenDisputeForBooking(
        bookingId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final hasOpenDispute = snapshot.data ?? true;
        if (hasOpenDispute) return const SizedBox.shrink();
        const amber = AmberDuskTokens.colors;
        return Center(
          child: TextButton(
            onPressed: onReportIssue,
            child: Text(
              l10n.reportIssue,
              style: AppTypography.bodySmall.copyWith(color: amber.danger),
            ),
          ),
        );
      },
    );
  }
}

/// Shows "Dispute under review" or "Work frozen — in dispute" when booking has an open/active dispute.
class _BookingDisputeBanner extends StatelessWidget {
  const _BookingDisputeBanner({required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<bool>(
      future: context.read<SafetyViewModel>().hasOpenDisputeForBooking(
        bookingId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.data != true) {
          return const SizedBox.shrink();
        }
        return FutureBuilder<String?>(
          future: context.read<SafetyViewModel>().getDisputeStatusForBooking(
            bookingId,
          ),
          builder: (context, statusSnapshot) {
            final status = statusSnapshot.data;
            final text = status == 'active'
                ? l10n.workFrozenInDispute
                : l10n.disputeUnderReviewReleaseDisabled;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.p24),
              child: AppCardContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.p12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AmberDuskTokens.colors.primary,
                      ),
                      const SizedBox(width: AppDimens.p8),
                      Expanded(
                        child: Text(
                          text,
                          style: AppTypography.bodySmall.copyWith(
                            color: context.colorScheme.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Shows Approve & Release button only when there is no open dispute for the booking's task.
class _ApproveWithDisputeGuard extends StatelessWidget {
  const _ApproveWithDisputeGuard({
    required this.booking,
    required this.onRelease,
  });

  final BookingModel booking;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<bool>(
      future: context.read<SafetyViewModel>().hasOpenDisputeForBooking(
        booking.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppButton(text: l10n.checking, onPressed: null);
        }
        final hasOpenDispute = snapshot.data ?? true;
        if (hasOpenDispute) {
          return AppButton(text: l10n.approveReleaseFunds, onPressed: null);
        }
        return AppButton(text: l10n.approveReleaseFunds, onPressed: onRelease);
      },
    );
  }
}
