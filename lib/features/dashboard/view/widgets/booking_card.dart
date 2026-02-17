import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/widgets/glass_card.dart';
import 'package:sline_app/core/widgets/status_badge.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import '../../../../core/app_enums.dart';

import 'package:sline_app/features/work/view/work_item_details_screen.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isProvider;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isProvider,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final vm = context.read<DashboardViewModel>();

    // Determine task title
    final taskTitle = booking.taskData?['title'] ?? 'Task';

    // Parse note to hide metadata if present
    String? displayNote = booking.note;
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

    // Status Color Helper
    Color getStatusColor(BookingStatus status) {
      switch (status) {
        case BookingStatus.confirmed:
        case BookingStatus.active:
          return AppColors.teal;
        case BookingStatus.pending:
        case BookingStatus.paidRequestPending:
          return AppColors.gold;
        case BookingStatus.canceled:
        case BookingStatus.declined:
          return AppColors.lightRed;
        case BookingStatus.delivered:
          return AppColors.lightRed;
        case BookingStatus.completed:
          return AppColors.gold; // Awaiting client review
        default:
          return colorScheme.textSecondary;
      }
    }

    // Human-readable status label
    String getStatusLabel(BookingStatus status) {
      switch (status) {
        case BookingStatus.paidRequestPending:
          return 'REQUEST PENDING';
        case BookingStatus.inProgress:
          return 'IN PROGRESS';
        case BookingStatus.noShow:
          return 'NO SHOW';
        case BookingStatus.expiredUnanswered:
          return 'EXPIRED';
        default:
          return status.name.toUpperCase();
      }
    }

    final statusColor = getStatusColor(booking.status);

    return GlassCard(
      padding: const EdgeInsets.all(AppDimens.p16),
      margin: const EdgeInsets.only(bottom: AppDimens.p16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkItemDetailsScreen(
              id: booking.id,
              type: WorkItemType.booking,
            ),
          ),
        );
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
                      booking.scheduledAt != null
                          ? formatUtcToLocal(booking.scheduledAt!)
                          : "Date Pending",
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                text: getStatusLabel(booking.status),
                color: statusColor,
                isSmall: true,
              ),
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

          const SizedBox(height: AppDimens.p16),

          // Actions
          if (booking.status == BookingStatus.pending ||
              booking.status ==
                  BookingStatus.paidRequestPending) // Added OR condition
            Row(
              children: [
                if (isProvider) ...[
                  Expanded(
                    child: FilledButton(
                      onPressed: () => vm.updateBookingStatus(
                        booking.id,
                        BookingStatus.confirmed,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                      ),
                      child: const Text("Confirm"),
                    ),
                  ),
                  const SizedBox(width: AppDimens.p12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => vm.updateBookingStatus(
                        booking.id,
                        BookingStatus.canceled,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.lightRed,
                        side: BorderSide(color: AppColors.lightRed),
                      ),
                      child: const Text("Decline"),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => vm.updateBookingStatus(
                        booking.id,
                        BookingStatus.canceled,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.lightRed,
                        side: BorderSide(color: AppColors.lightRed),
                      ),
                      child: const Text("Cancel Request"),
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
                    child: const Text("Message"),
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                if (!isProvider)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => vm.updateBookingStatus(
                        booking.id,
                        BookingStatus.canceled,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.lightRed,
                        side: BorderSide(color: AppColors.lightRed),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
