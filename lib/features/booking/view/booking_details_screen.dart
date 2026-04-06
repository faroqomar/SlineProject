import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/loading_utils.dart';
import 'package:sline_app/core/utils/unified_cta_resolver.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/management/models/work_log_scope.dart';
import 'package:sline_app/features/management/view/widgets/order_management_section.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';

class BookingDetailsScreen extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isProvider =
        context.read<BookingViewModel>().currentUserId == booking.providerId;

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.text, size: 20),
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
            _buildSectionHeader(context, 'Service'),
            const SizedBox(height: AppDimens.p12),
            GlassContainer(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimens.r12),
                    ),
                    child: Icon(Icons.work_outline, color: AppColors.teal),
                  ),
                  const SizedBox(width: AppDimens.p16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task #${booking.taskId?.substring(0, 8) ?? "N/A"}',
                          style: AppTypography.h6.copyWith(
                            color: colorScheme.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Booked on ${formatUtcToLocal(booking.createdAtUtc)}',
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
            _buildSectionHeader(context, isProvider ? 'Client' : 'Provider'),
            const SizedBox(height: AppDimens.p12),
            GlassContainer(
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
                          isProvider ? 'Client' : 'Provider',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.text,
                          ),
                        ),
                        Text(
                          isProvider
                              ? 'ID: ${booking.clientId.substring(0, 8)}'
                              : 'ID: ${booking.providerId.substring(0, 8)}',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.teal,
                    ),
                    onPressed: () => _handleMessage(context, booking),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.p24),

            // Timeline
            _buildSectionHeader(context, 'Timeline'),
            const SizedBox(height: AppDimens.p12),
            GlassContainer(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _timelineRow(
                    context,
                    'Booked',
                    formatUtcToLocal(booking.createdAtUtc),
                  ),
                  const SizedBox(height: AppDimens.p8),
                  _timelineRow(
                    context,
                    'Due',
                    booking.dueAtUtc != null
                        ? formatUtcToLocal(booking.dueAtUtc!)
                        : 'No deadline',
                  ),
                  if (booking.deliveryDays != null) ...[
                    const SizedBox(height: AppDimens.p8),
                    _timelineRow(
                      context,
                      'Delivery',
                      '${booking.deliveryDays} days',
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
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppDimens.r8),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Legacy slot-based booking',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gold,
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
                      text: 'Reject',
                      isPrimary: false,
                      onPressed: () => _updateStatus(
                        context,
                        booking,
                        BookingStatus.canceled,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.p16),
                  const Expanded(
                    child: AppButton(text: 'Awaiting Payment', onPressed: null),
                  ),
                ],
              ),

            if (!isProvider && booking.status == BookingStatus.pending)
              AppButton(
                text: 'Cancel Booking',
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
                  dynamicActions.add(
                    AppButton(
                      text: 'Escrow Funds',
                      onPressed: () => ctx
                          .read<BookingViewModel>()
                          .escrowHoldBooking(booking.id),
                    ),
                  );
                  dynamicActions.add(const SizedBox(height: AppDimens.p12));
                }

                if (ctaMeta.allowedActions.contains('release_with_fee')) {
                  dynamicActions.add(
                    _ApproveWithDisputeGuard(
                      booking: booking,
                      onRelease: () => ctx
                          .read<BookingViewModel>()
                          .releaseBookingWithFee(booking.id),
                    ),
                  );
                  dynamicActions.add(const SizedBox(height: AppDimens.p12));
                }

                if (ctaMeta.allowedActions.contains('refund')) {
                  dynamicActions.add(
                    AppButton(
                      text: 'Issue Refund',
                      isPrimary: false,
                      onPressed: () {
                        // The refund logic can be wired here if the provider needs an explicit refund button
                        // Usually handled automatically on decline though.
                      },
                    ),
                  );
                  dynamicActions.add(const SizedBox(height: AppDimens.p12));
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
                        text: 'Decline',
                        isPrimary: false,
                        onPressed: () => context
                            .read<BookingViewModel>()
                            .declineBooking(booking.id),
                      ),
                    ),
                    const SizedBox(width: AppDimens.p16),
                    Expanded(
                      child: AppButton(
                        text: 'Accept Job',
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
                  text: 'Mark Delivered',
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
    if (booking.taskId == null || booking.taskId!.isEmpty) {
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

    var draftReason = '';
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Issue'),
        content: TextField(
          maxLines: 4,
          onChanged: (value) => draftReason = value,
          decoration: const InputDecoration(
            hintText: 'Describe the problem with this booking',
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
          ok ? 'Dispute submitted.' : (vm.error ?? 'Dispute failed.'),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, BookingStatus status) {
    Color color;
    String text;

    switch (status) {
      case BookingStatus.pending:
        color = AppColors.gold;
        text = 'Pending Confirmation';
      case BookingStatus.confirmed:
        color = AppColors.teal;
        text = 'Confirmed';
      case BookingStatus.completed:
        color = AppColors.mediumGrey;
        text = 'Completed';
      case BookingStatus.canceled:
        color = AppColors.lightRed;
        text = 'Canceled';
      case BookingStatus.noShow:
        color = AppColors.lightRed;
        text = 'No Show';
      case BookingStatus.inProgress:
        color = AppColors.teal;
        text = 'In Progress';
      case BookingStatus.declined:
        color = AppColors.lightRed;
        text = 'Declined';
      case BookingStatus.active:
        color = AppColors.teal;
        text = 'Active';
      case BookingStatus.paidRequestPending:
        color = AppColors.gold;
        text = 'Request Pending';
      case BookingStatus.delivered:
        color = AppColors.teal;
        text = 'Delivered (Review)';
      case BookingStatus.refunded:
        color = AppColors.mediumGrey;
        text = 'Refunded';
      case BookingStatus.expiredUnanswered:
        color = AppColors.mediumGrey;
        text = 'Expired';
      case BookingStatus.disputed:
        color = AppColors.gold;
        text = 'Disputed (Under Review)';
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
        ).showSnackBar(const SnackBar(content: Text('Status updated')));
        Navigator.pop(context); // Refresh/Back
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
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
        return Center(
          child: TextButton(
            onPressed: onReportIssue,
            child: Text(
              'Report Issue',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.lightRed,
              ),
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
                ? 'Work frozen — in dispute.'
                : 'Dispute under review. Approve and release disabled.';
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.p24),
              child: GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.p12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: context.colorScheme.primary,
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
    return FutureBuilder<bool>(
      future: context.read<SafetyViewModel>().hasOpenDisputeForBooking(
        booking.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppButton(text: 'Checking…', onPressed: null);
        }
        final hasOpenDispute = snapshot.data ?? true;
        if (hasOpenDispute) {
          return const AppButton(
            text: 'Approve & Release Funds',
            onPressed: null,
          );
        }
        return AppButton(text: 'Approve & Release Funds', onPressed: onRelease);
      },
    );
  }
}
