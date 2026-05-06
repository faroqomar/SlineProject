import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/status_presenter.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/core/widgets/status_badge.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';

/// Dashboard-style booking card with structured zones; uses callbacks so
/// the widget stays in the booking feature without depending on DashboardVM.
///
/// Phase 7 REDESIGN: Status-colored header zone with calendar icon + "BOOKING"
/// label, optional urgency bar for approaching deadlines, body zone with
/// title/date/note, and divider-separated action zone.
class DashboardBookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isProvider;
  final Future<bool?> Function(BookingModel) onTapDetails;
  final VoidCallback? onRefresh;
  final void Function(String bookingId) onAccept;
  final void Function(String bookingId) onDecline;
  final void Function(String bookingId) onCancel;
  final void Function(String bookingId, BookingStatus status) onUpdateStatus;
  final VoidCallback? onMessagePressed;

  const DashboardBookingCard({
    super.key,
    required this.booking,
    required this.isProvider,
    required this.onTapDetails,
    this.onRefresh,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
    required this.onUpdateStatus,
    this.onMessagePressed,
  });

  /// Whether the deadline is within 48 hours (triggers urgency bar).
  static bool _isApproachingDeadline(DateTime? due) {
    if (due == null) return false;
    return due.difference(DateTime.now()).inHours < 48 &&
        due.isAfter(DateTime.now());
  }

  /// Human-friendly remaining time label (e.g., "3 hours", "1 day").
  static String _friendlyTimeRemaining(DateTime due) {
    final diff = due.difference(DateTime.now());
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} hours';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final taskTitle = booking.taskData?['title'] ?? 'Task';
    final bookingDue = booking.dueAtUtc ?? booking.scheduledAt;

    var displayNote = booking.note;
    if (displayNote != null && displayNote.contains('---')) {
      final parts = displayNote.split('---');
      if (parts.length > 1) {
        displayNote = parts.last.trim();
      } else {
        if (displayNote.trim().startsWith('Package:')) {
          displayNote = '';
        }
      }
    }
    if (displayNote != null && displayNote.isEmpty) {
      displayNote = null;
    }

    final statusColor = StatusPresenter.bookingStatusColor(booking.status);
    final statusLabel = StatusPresenter.bookingStatusLabel(booking.status);
    final canProviderAccept =
        isProvider &&
        (booking.status == BookingStatus.paidRequestPending ||
            (booking.status == BookingStatus.pending &&
                booking.paymentStatus == PaymentStatus.held));
    final awaitingClientPayment =
        isProvider &&
        booking.status == BookingStatus.pending &&
        booking.paymentStatus != PaymentStatus.held;

    final hasActions =
        booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.paidRequestPending ||
        booking.status == BookingStatus.confirmed;

    return Semantics(
      container: true,
      label: '$taskTitle booking, status ${statusLabel.toLowerCase()}',
      child: AppCard(
        // Phase 7: zones handle their own padding
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(bottom: AppDimens.p16),
        onTap: () async {
          AppLogger.d('DashboardBookingCard tapped', tag: 'Cards');
          final result = await onTapDetails(booking);
          if ((result ?? false) && context.mounted && onRefresh != null) {
            onRefresh!();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ZONE: Status-colored band ──────────────────
            // Matches WorkItemCard header pattern for visual consistency.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p16,
                vertical: AppDimens.p12,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimens.r20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: AppDimens.iconSizeSmall,
                        color: statusColor,
                      ),
                      const SizedBox(width: AppDimens.p8),
                      Text(
                        'BOOKING',
                        style: AppTypography.captionBold.copyWith(
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(
                    text: statusLabel,
                    color: statusColor,
                    isSmall: true,
                  ),
                ],
              ),
            ),

            // ── URGENCY BAR (conditional < 48h deadline) ──────────
            if (_isApproachingDeadline(bookingDue))
              _DeadlineUrgencyBar(
                dueDate: bookingDue!,
                colorScheme: colorScheme,
              ),

            // ── BODY ZONE: Title, date, note, delivery ────────────
            Padding(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taskTitle,
                    style: AppTypography.h5.copyWith(color: colorScheme.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimens.p4),
                  Text(
                    bookingDue != null
                        ? 'Due ${formatUtcToLocal(bookingDue)}'
                        : 'No deadline',
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (displayNote != null) ...[
                    const SizedBox(height: AppDimens.p12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimens.p8),
                      decoration: BoxDecoration(
                        color: colorScheme.background.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppDimens.r8),
                      ),
                      child: Text(
                        '"$displayNote"',
                        style: AppTypography.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  if (booking.deliveryDays != null) ...[
                    const SizedBox(height: AppDimens.p8),
                    // Phase 7: delivery info gets an icon for visual clarity
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: AppDimens.iconSizeSmall,
                          color: colorScheme.textSecondary,
                        ),
                        const SizedBox(width: AppDimens.p4),
                        Text(
                          '${booking.deliveryDays} days delivery',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── ACTION ZONE: Separated by divider ─────────────────
            if (hasActions) ...[
              Divider(height: 1, thickness: 1, color: colorScheme.divider),
              Padding(
                padding: const EdgeInsets.all(AppDimens.p12),
                child: _buildActions(
                  colorScheme,
                  canProviderAccept,
                  awaitingClientPayment,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the action buttons for pending/confirmed booking states.
  Widget _buildActions(
    AppColorScheme colorScheme,
    bool canProviderAccept,
    bool awaitingClientPayment,
  ) {
    if (booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.paidRequestPending) {
      return Row(
        children: [
          if (isProvider) ...[
            Expanded(
              child: FilledButton(
                onPressed: canProviderAccept
                    ? () => onAccept(booking.id)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                ),
                child: Text(canProviderAccept ? 'Accept' : 'Awaiting Payment'),
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  if (canProviderAccept) {
                    onDecline(booking.id);
                    return;
                  }
                  if (awaitingClientPayment) {
                    onCancel(booking.id);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.danger,
                  side: BorderSide(color: colorScheme.danger),
                ),
                child: const Text('Decline'),
              ),
            ),
          ] else ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => onCancel(booking.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.danger,
                  side: BorderSide(color: colorScheme.danger),
                ),
                child: const Text('Cancel Request'),
              ),
            ),
          ],
        ],
      );
    }

    if (booking.status == BookingStatus.confirmed) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onMessagePressed != null
                  ? () {
                      AppLogger.d(
                        'DashboardBookingCard message pressed',
                        tag: 'Cards',
                      );
                      onMessagePressed!();
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: onMessagePressed != null
                      ? colorScheme.primary
                      : colorScheme.textSecondary.withValues(alpha: 0.3),
                ),
              ),
              child: const Text('Message'),
            ),
          ),
          const SizedBox(width: AppDimens.p12),
          if (!isProvider)
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    onUpdateStatus(booking.id, BookingStatus.canceled),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.danger,
                  side: BorderSide(color: colorScheme.danger),
                ),
                child: const Text('Cancel'),
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

/// Urgency bar shown when a booking deadline is within 48 hours.
///
/// Uses danger color for < 24h, warning for < 48h. Appears between the
/// header zone and body zone to draw immediate attention.
class _DeadlineUrgencyBar extends StatelessWidget {
  final DateTime dueDate;
  final AppColorScheme colorScheme;

  const _DeadlineUrgencyBar({required this.dueDate, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final hoursLeft = dueDate.difference(DateTime.now()).inHours;
    // < 24h = danger (red), < 48h = warning (orange)
    final urgencyColor = hoursLeft < 24
        ? colorScheme.danger
        : colorScheme.warning;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p16,
        vertical: AppDimens.p8,
      ),
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: urgencyColor.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: AppDimens.iconSizeSmall,
            color: urgencyColor,
          ),
          const SizedBox(width: AppDimens.p8),
          Text(
            'Due in ${DashboardBookingCard._friendlyTimeRemaining(dueDate)}',
            style: AppTypography.captionBold.copyWith(color: urgencyColor),
          ),
        ],
      ),
    );
  }
}
