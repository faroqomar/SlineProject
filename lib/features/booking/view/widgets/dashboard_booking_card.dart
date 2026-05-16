import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/utils/status_presenter.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/core/widgets/status_badge.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';

/// Dashboard-style booking card with structured zones; uses callbacks so
/// the widget stays in the booking feature without depending on DashboardVM.
///
/// The card presents booking state with Amber Dusk dashboard surfaces while
/// leaving accept, decline, cancel, and status-update behavior to callers.
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
    const amber = AmberDuskTokens.colors;
    const spacing = AmberDuskTokens.spacing;
    const typography = AmberDuskTokens.typography;
    final taskTitle = booking.taskData?['title']?.toString() ?? 'Task';
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

    final statusColor = _bookingStatusColor(booking.status);
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
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.lg,
                vertical: spacing.md,
              ),
              decoration: BoxDecoration(
                gradient: AmberDuskMaterial.activeWashGradient,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(spacing.taskCardRadius),
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
                        style: typography.chip.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
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
              _DeadlineUrgencyBar(dueDate: bookingDue!, colors: amber),

            Padding(
              padding: EdgeInsets.all(spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          taskTitle,
                          style: typography.sectionTitle.copyWith(
                            color: amber.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppDimens.p12),
                      Text(
                        PriceFormatter.formatPrice(
                          (booking.price ?? 0).toDouble(),
                        ),
                        style: typography.sectionTitle.copyWith(
                          color: amber.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.p4),
                  Text(
                    bookingDue != null
                        ? 'Due ${formatUtcToLocal(bookingDue)}'
                        : 'No deadline',
                    style: typography.bodySmall.copyWith(
                      color: amber.muted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (displayNote != null) ...[
                    const SizedBox(height: AppDimens.p12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimens.p8),
                      decoration: BoxDecoration(
                        color: amber.surfaceRaised,
                        borderRadius: BorderRadius.circular(AppDimens.r8),
                      ),
                      child: Text(
                        '"$displayNote"',
                        style: typography.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: amber.textSubtle,
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
                          color: amber.muted,
                        ),
                        const SizedBox(width: AppDimens.p4),
                        Text(
                          '${booking.deliveryDays} days delivery',
                          style: typography.bodySmall.copyWith(
                            color: amber.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            if (hasActions) ...[
              Divider(height: 1, thickness: 1, color: amber.rowSeparator),
              Padding(
                padding: EdgeInsets.all(spacing.md),
                child: _buildActions(
                  amber,
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
    AmberDuskColorTokens colors,
    bool canProviderAccept,
    bool awaitingClientPayment,
  ) {
    if (booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.paidRequestPending) {
      final providerSecondaryAction = canProviderAccept
          ? () {
              AppLogger.i('DashboardBookingCard decline pressed', tag: 'Cards');
              onDecline(booking.id);
            }
          : awaitingClientPayment
          ? () {
              AppLogger.i(
                'DashboardBookingCard cancel unpaid request pressed',
                tag: 'Cards',
              );
              onCancel(booking.id);
            }
          : null;
      final providerSecondaryLabel = canProviderAccept
          ? 'Decline'
          : awaitingClientPayment
          ? 'Cancel'
          : 'Decline';

      return Row(
        children: [
          if (isProvider) ...[
            Expanded(
              child: FilledButton(
                onPressed: providerSecondaryAction,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.surfaceRaised,
                  foregroundColor: colors.text,
                ),
                child: Text(providerSecondaryLabel),
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: FilledButton(
                onPressed: canProviderAccept
                    ? () {
                        AppLogger.i(
                          'DashboardBookingCard accept pressed',
                          tag: 'Cards',
                        );
                        onAccept(booking.id);
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.text,
                ),
                child: Text(canProviderAccept ? 'Accept' : 'Awaiting Payment'),
              ),
            ),
          ] else ...[
            Expanded(
              child: FilledButton(
                onPressed: () {
                  AppLogger.i(
                    'DashboardBookingCard cancel request pressed',
                    tag: 'Cards',
                  );
                  onCancel(booking.id);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.surfaceRaised,
                  foregroundColor: colors.danger,
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
                      ? colors.primary
                      : colors.muted.withValues(alpha: 0.3),
                ),
              ),
              child: const Text('Message'),
            ),
          ),
          const SizedBox(width: AppDimens.p12),
          if (!isProvider)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  AppLogger.i(
                    'DashboardBookingCard cancel confirmed booking pressed',
                    tag: 'Cards',
                  );
                  onUpdateStatus(booking.id, BookingStatus.canceled);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.danger,
                  side: BorderSide(color: colors.danger),
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
  final AmberDuskColorTokens colors;

  const _DeadlineUrgencyBar({required this.dueDate, required this.colors});

  @override
  Widget build(BuildContext context) {
    final hoursLeft = dueDate.difference(DateTime.now()).inHours;
    // Deadline urgency mirrors the status system: danger inside 24h, warning inside 48h.
    final urgencyColor = hoursLeft < 24 ? colors.danger : colors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p16,
        vertical: AppDimens.p8,
      ),
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: colors.rowSeparator),
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
            style: AmberDuskTokens.typography.chip.copyWith(
              color: urgencyColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Amber Dusk status color mapping for dashboard booking cards.
Color _bookingStatusColor(BookingStatus status) {
  const colors = AmberDuskTokens.colors;
  switch (status) {
    case BookingStatus.confirmed:
    case BookingStatus.active:
    case BookingStatus.inProgress:
      return colors.primary;
    case BookingStatus.pending:
    case BookingStatus.paidRequestPending:
    case BookingStatus.disputed:
      return colors.warning;
    case BookingStatus.completed:
    case BookingStatus.delivered:
    case BookingStatus.refunded:
      return colors.success;
    case BookingStatus.canceled:
    case BookingStatus.declined:
    case BookingStatus.noShow:
    case BookingStatus.expiredUnanswered:
      return colors.danger;
  }
}
