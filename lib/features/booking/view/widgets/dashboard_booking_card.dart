import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/status_presenter.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/core/widgets/status_badge.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';

/// Dashboard-style booking card with actions; uses callbacks so the widget
/// stays in the booking feature without depending on DashboardViewModel.
class DashboardBookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isProvider;
  final Future<bool?> Function(BookingModel) onTapDetails;
  final VoidCallback? onRefresh;
  final void Function(String bookingId) onAccept;
  final void Function(String bookingId) onDecline;
  final void Function(String bookingId) onCancel;
  final void Function(String bookingId, BookingStatus status) onUpdateStatus;

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
  });

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

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.p16),
      margin: const EdgeInsets.only(bottom: AppDimens.p16),
      onTap: () async {
        final result = await onTapDetails(booking);
        if ((result ?? false) && context.mounted && onRefresh != null) {
          onRefresh!();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskTitle,
                      style: AppTypography.h5.copyWith(color: colorScheme.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bookingDue != null
                          ? 'Due ${formatUtcToLocal(bookingDue)}'
                          : 'No deadline',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(text: statusLabel, color: statusColor, isSmall: true),
            ],
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
            const SizedBox(height: AppDimens.p12),
            Text(
              'Delivery: ${booking.deliveryDays} days',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppDimens.p16),
          if (booking.status == BookingStatus.pending ||
              booking.status == BookingStatus.paidRequestPending)
            Row(
              children: [
                if (isProvider) ...[
                  Expanded(
                    child: FilledButton(
                      onPressed: canProviderAccept
                          ? () => onAccept(booking.id)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                      ),
                      child: Text(
                        canProviderAccept ? 'Accept' : 'Awaiting Payment',
                      ),
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
                        foregroundColor: AppColors.lightRed,
                        side: BorderSide(color: AppColors.lightRed),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onCancel(booking.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.lightRed,
                        side: BorderSide(color: AppColors.lightRed),
                      ),
                      child: const Text('Cancel Request'),
                    ),
                  ),
                ],
              ],
            ),
          if (booking.status == BookingStatus.confirmed)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Todo: Open Chat logic
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.primary),
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
                        foregroundColor: AppColors.lightRed,
                        side: BorderSide(color: AppColors.lightRed),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
