import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import '../../models/dashboard_enums.dart';

// Helper class for Mock Data
// Helper class for Mock Data
class MockBookingDisplay {
  final String title;
  final String otherParams;
  final DateTime scheduledAt;
  final BookingStatus status;
  final UserRole userRole; // Role of the viewer

  MockBookingDisplay(
    this.title,
    this.otherParams,
    this.scheduledAt,
    this.status,
    this.userRole,
  );
}

// Since _MockBooking is private in tab, we redefine a simple holder or pass parameters.
// For Prototype speed, I will use a simple data holder class here or duplicate _MockBooking if needed.
// Actually, it's better to make the card versatile.

class BookingCard extends StatelessWidget {
  final dynamic
  booking; // Using dynamic for mock flexibility or define a simple interface used here

  const BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final scheduledAt = booking.scheduledAt as DateTime;
    final status = booking.status as BookingStatus;

    final dayFormatter = DateFormat('EEE, MMM d');
    final timeFormatter = DateFormat('h:mm a');

    Color statusColor;
    String statusText = status.name.toUpperCase();

    switch (status) {
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
        statusColor = AppColors.mediumGrey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: colorScheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Date & Status
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p16,
              vertical: AppDimens.p12,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimens.r16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      "${dayFormatter.format(scheduledAt)} • ${timeFormatter.format(scheduledAt)}",
                      style: AppTypography.captionBold.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  statusText,
                  style: AppTypography.captionBold.copyWith(color: statusColor),
                ),
              ],
            ),
          ),

          // Body: Info & Actions
          Padding(
            padding: const EdgeInsets.all(AppDimens.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.title,
                  style: AppTypography.h5.copyWith(color: colorScheme.text),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: colorScheme.textSecondary,
                      child: const Icon(
                        Icons.person,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "With ${booking.otherParams}",
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimens.p16),

                // Actions (Demo)
                if (status == BookingStatus.pending)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {},
                          child: const Text("Accept"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                          ),
                          child: const Text("Decline"),
                        ),
                      ),
                    ],
                  )
                else if (status == BookingStatus.confirmed)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text("Join Call"),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
