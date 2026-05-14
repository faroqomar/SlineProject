import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';

/// Displays booking-specific details: other party info, due date, payment
/// status, and optional note.
class WorkItemBookingDetails extends StatelessWidget {
  const WorkItemBookingDetails({
    super.key,
    required this.booking,
    required this.isFreelancer,
    required this.otherPartyName,
    this.otherPartyAvatar,
    this.onTapProfile,
  });

  final BookingModel booking;
  final bool isFreelancer;
  final String otherPartyName;
  final String? otherPartyAvatar;
  final VoidCallback? onTapProfile;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: AppTypography.h4.copyWith(color: context.colorScheme.text),
            ),
            const SizedBox(height: AppDimens.p16),
            // Who
            GestureDetector(
              onTap: onTapProfile,
              child: Row(
                children: [
                  SignedAvatar(
                    storagePathOrUrl: otherPartyAvatar,
                    placeholder: CircleAvatar(
                      radius: 20,
                      backgroundColor: context.colorScheme.primary,
                      child: Text(
                        otherPartyName.isNotEmpty
                            ? otherPartyName[0].toUpperCase()
                            : '?',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.p12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFreelancer ? 'Booked by' : 'Provider',
                        style: AppTypography.bodySmall,
                      ),
                      Text(
                        otherPartyName,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.p16),
            // When
            _infoRow(
              'Due',
              booking.dueAtUtc != null
                  ? formatUtcToLocal(booking.dueAtUtc!)
                  : (booking.scheduledAt != null
                        ? formatUtcToLocal(booking.scheduledAt!)
                        : 'No deadline'),
            ),
            if (booking.deliveryDays != null)
              _infoRow('Delivery', '${booking.deliveryDays} days'),
            // Payment
            _infoRow('Payment', booking.paymentStatus.name.toUpperCase()),
            // Note
            if (booking.note != null && booking.note!.isNotEmpty) ...[
              const SizedBox(height: AppDimens.p16),
              Text('Note', style: AppTypography.bodySmall),
              const SizedBox(height: AppDimens.p4),
              Text(
                booking.note!,
                style: AppTypography.bodyMedium.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
}
