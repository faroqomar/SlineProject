import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/core/widgets/signed_image.dart';
import 'package:sline_app/core/widgets/status_badge.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';

/// Compact booking list card rendered with Amber Dusk booking material.
///
/// The card keeps the existing booking navigation callback and model parsing
/// while aligning the visible booking summary with Phase 3 hero card tokens.
class BookingCard extends StatelessWidget {
  /// Creates a booking summary card.
  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.asProvider = false,
  });

  /// Booking row supplied by the bookings ViewModel.
  final BookingModel booking;

  /// Opens the existing booking detail flow.
  final VoidCallback onTap;

  /// Whether the current user is viewing the booking as provider.
  final bool asProvider;

  @override
  Widget build(BuildContext context) {
    const amberColors = AmberDuskTokens.colors;
    const spacing = AmberDuskTokens.spacing;
    const typography = AmberDuskTokens.typography;
    final heroSurface = AmberDuskTokens.surfaces.hero;
    final taskData = booking.taskData;
    final taskTitle =
        taskData?['title'] as String? ??
        (asProvider ? 'Client booking' : 'Provider booking');
    final taskImages =
        (taskData?['image_paths'] as List<dynamic>?)?.cast<String>() ?? [];
    final imagePath = taskImages.isNotEmpty ? taskImages.first : null;
    final rawBudget = taskData?['budget'];
    final budget = rawBudget is num
        ? rawBudget.toDouble()
        : booking.price?.toDouble() ?? 0.0;
    final timeline = booking.dueAtUtc ?? booking.scheduledAt;
    final statusColor = _bookingStatusColor(booking.status, amberColors);
    final statusLabel = _bookingStatusLabel(booking.status);
    final roleLabel = asProvider ? 'CLIENT' : 'PROVIDER';

    return Semantics(
      button: true,
      label: '$taskTitle booking, status ${statusLabel.toLowerCase()}',
      child: ScaleButton(
        onPressed: () {
          AppLogger.d('BookingCard tapped', tag: 'Cards');
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: AppDimens.p12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: heroSurface.gradientStops,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(heroSurface.radius),
            border: Border.all(color: amberColors.heroRim),
            boxShadow: AppDecorations.elevation(
              heroSurface.elevationLevel,
              isDark: context.colorScheme.isDark,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BookingImage(imagePath: imagePath),
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            taskTitle,
                            style: typography.bookingName.copyWith(
                              color: amberColors.heroText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: spacing.xs),
                          Text(
                            roleLabel,
                            style: typography.chip.copyWith(
                              color: amberColors.heroMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      text: statusLabel,
                      color: statusColor,
                      isSmall: true,
                    ),
                  ],
                ),
                SizedBox(height: spacing.md),
                Wrap(
                  spacing: spacing.sm,
                  runSpacing: spacing.sm,
                  children: [
                    _BookingChip(
                      icon: Icons.event_available_outlined,
                      label: 'Booked',
                      value: formatUtcToLocal(booking.createdAtUtc),
                    ),
                    _BookingChip(
                      icon: Icons.schedule_outlined,
                      label: 'Due',
                      value: timeline != null
                          ? formatUtcToLocal(timeline)
                          : 'No deadline',
                    ),
                    if (booking.deliveryDays != null)
                      _BookingChip(
                        icon: Icons.local_shipping_outlined,
                        label: 'Delivery',
                        value: '${booking.deliveryDays} days',
                      ),
                  ],
                ),
                SizedBox(height: spacing.md),
                Container(
                  height: AppDimens.hairlineDivider,
                  color: amberColors.heroDivider,
                ),
                SizedBox(height: spacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (budget > 0)
                            Text(
                              PriceFormatter.formatPrice(budget),
                              style: typography.moneyMedium.copyWith(
                                color: amberColors.heroText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            booking.paymentStatus.name.toUpperCase(),
                            style: typography.chip.copyWith(
                              color: amberColors.heroMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: AmberDuskTokens.widgetTheme.buttons.minHeight,
                      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                      decoration: BoxDecoration(
                        color: amberColors.heroText,
                        borderRadius: BorderRadius.circular(
                          AmberDuskTokens.widgetTheme.buttons.radius,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View details',
                            style: AmberDuskTokens.widgetTheme.buttons.textStyle
                                .copyWith(color: amberColors.textInverse),
                          ),
                          SizedBox(width: spacing.xs),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: amberColors.textInverse,
                            size: AppDimens.iconSizeSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Booking media thumbnail that resolves task images through the task bucket.
///
/// Booking rows can carry `taskData.image_paths`; those paths belong to the
/// private `task-images` bucket, so this adapter intentionally uses
/// [SignedImage] instead of avatar storage.
class _BookingImage extends StatelessWidget {
  /// Creates a booking media thumbnail for the task image path.
  const _BookingImage({required this.imagePath});

  /// Optional private task image path.
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    const amberColors = AmberDuskTokens.colors;

    if (imagePath == null || imagePath!.isEmpty) {
      return Container(
        width: AppDimens.p54,
        height: AppDimens.p54,
        decoration: BoxDecoration(
          color: amberColors.heroChip,
          borderRadius: BorderRadius.circular(AppDimens.r18),
        ),
        child: Icon(
          Icons.work_outline_rounded,
          color: amberColors.heroMuted,
          size: AppDimens.iconSizeMedium,
        ),
      );
    }

    return SignedImage(
      storagePathOrUrl: imagePath,
      width: AppDimens.p54,
      height: AppDimens.p54,
      borderRadius: AppDimens.r18,
    );
  }
}

/// Compact metadata chip used inside the hero booking card.
class _BookingChip extends StatelessWidget {
  /// Creates a chip for one booking detail.
  const _BookingChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  /// Icon that identifies the metadata type.
  final IconData icon;

  /// Short label for screen readers and narrow layouts.
  final String label;

  /// Visible metadata value.
  final String value;

  @override
  Widget build(BuildContext context) {
    const amberColors = AmberDuskTokens.colors;
    const spacing = AmberDuskTokens.spacing;
    const typography = AmberDuskTokens.typography;

    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        decoration: BoxDecoration(
          color: amberColors.heroChip,
          borderRadius: BorderRadius.circular(spacing.pillRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppDimens.iconSizeSmall, color: amberColors.star),
            SizedBox(width: spacing.xs),
            Flexible(
              child: Text(
                value,
                style: typography.chip.copyWith(color: amberColors.heroText),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Amber Dusk booking status color mapping for compact cards.
Color _bookingStatusColor(BookingStatus status, AmberDuskColorTokens colors) {
  switch (status) {
    case BookingStatus.confirmed:
    case BookingStatus.active:
    case BookingStatus.inProgress:
      return colors.primary;
    case BookingStatus.pending:
    case BookingStatus.paidRequestPending:
    case BookingStatus.disputed:
    case BookingStatus.completed:
      return colors.warning;
    case BookingStatus.refunded:
      return colors.success;
    case BookingStatus.canceled:
    case BookingStatus.declined:
    case BookingStatus.delivered:
    case BookingStatus.noShow:
    case BookingStatus.expiredUnanswered:
      return colors.danger;
  }
}

/// User-facing status label that avoids leaking raw enum casing.
String _bookingStatusLabel(BookingStatus status) {
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
