import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import '../../../../core/app_enums.dart';

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

    // Determine counterparty name/avatar
    // final counterpartyName = booking.taskData?['profiles']?['full_name'] ?? 'User';
    // For now we don't have avatar URL easily accessible without extra fetch in service
    // or passing it down. Let's use generic for now or task title.
    final taskTitle = booking.taskData?['title'] ?? 'Task';

    // Status Color
    Color statusColor;
    switch (booking.status) {
      case BookingStatus.confirmed:
        statusColor = AppColors.teal;
        break;
      case BookingStatus.pending:
        statusColor = AppColors.gold;
        break;
      case BookingStatus.canceled:
      case BookingStatus.declined:
        statusColor = AppColors.lightRed;
        break;
      default:
        statusColor = colorScheme.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p16),
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: colorScheme.cardBorder),
      ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  booking.status.name.toUpperCase(),
                  style: AppTypography.captionBold.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          if (booking.note != null) ...[
            const SizedBox(height: AppDimens.p12),
            Container(
              padding: const EdgeInsets.all(AppDimens.p8),
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(AppDimens.r8),
              ),
              child: Text(
                '"${booking.note}"',
                style: AppTypography.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppDimens.p16),
          // Actions
          if (booking.status == BookingStatus.pending)
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
