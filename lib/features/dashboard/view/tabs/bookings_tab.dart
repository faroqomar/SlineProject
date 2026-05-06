import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';
import 'package:sline_app/features/booking/view/widgets/dashboard_booking_card.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/work/view/work_item_details_screen.dart';

/// Bookings tab with skeleton loading, icon-badged section headers,
/// dimmed past bookings, and enhanced empty state.
///
/// Phase 7 REDESIGN: Section headers get colored icon badges + count pills,
/// past bookings wrapped in Opacity(0.6) for clear visual hierarchy,
/// empty state icon in circular container for designed feel.
class BookingsTab extends StatelessWidget {
  const BookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, child) {
        // Skeleton loading state
        if (vm.isLoading) {
          return _buildSkeletonList();
        }

        final bookings = vm.bookings;

        // Enhanced empty state
        if (bookings.isEmpty) {
          return _buildEmptyState(context, vm);
        }

        // Split into Upcoming and Past
        final now = DateTime.now().toUtc();
        final upcoming = bookings.where((b) {
          final bookingTimeline = b.dueAtUtc ?? b.scheduledAt;
          if (bookingTimeline != null) {
            return bookingTimeline.isAfter(now);
          }
          // Fallback: Pending items are "Upcoming" regardless of date
          return b.status == BookingStatus.pending ||
              b.status == BookingStatus.confirmed;
        }).toList();

        final upcomingIds = upcoming.map((b) => b.id).toSet();
        final past = bookings
            .where((b) => !upcomingIds.contains(b.id))
            .toList();

        final colorScheme = context.colorScheme;

        return RefreshIndicator(
          onRefresh: () => vm.refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppDimens.p16),
            children: [
              if (upcoming.isNotEmpty) ...[
                // Phase 7: icon-badged header with count pill
                _BookingSectionHeader(
                  title: 'Upcoming',
                  count: upcoming.length,
                  icon: Icons.calendar_month_rounded,
                  iconColor: colorScheme.primary,
                ),
                ...upcoming.map(
                  (b) => DashboardBookingCard(
                    booking: b,
                    isProvider: vm.currentRole == UserRole.freelancer,
                    onTapDetails: (booking) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkItemDetailsScreen(
                          id: booking.id,
                          type: WorkItemType.booking,
                        ),
                      ),
                    ),
                    onRefresh: vm.refresh,
                    onAccept: vm.acceptBooking,
                    onDecline: vm.declineBooking,
                    onCancel: vm.cancelBooking,
                    onUpdateStatus: vm.updateBookingStatus,
                  ),
                ),
                const SizedBox(height: AppLayout.spacingScreen),
              ],

              if (past.isNotEmpty) ...[
                // Phase 7: muted header for past section
                _BookingSectionHeader(
                  title: 'Past',
                  count: past.length,
                  icon: Icons.history_rounded,
                  iconColor: colorScheme.textTertiary,
                ),
                // Phase 7: dimmed past bookings — clearly secondary
                ...past.map(
                  (b) => Opacity(
                    opacity: 0.6,
                    child: DashboardBookingCard(
                      booking: b,
                      isProvider: vm.currentRole == UserRole.freelancer,
                      onTapDetails: (booking) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkItemDetailsScreen(
                            id: booking.id,
                            type: WorkItemType.booking,
                          ),
                        ),
                      ),
                      onRefresh: vm.refresh,
                      onAccept: vm.acceptBooking,
                      onDecline: vm.declineBooking,
                      onCancel: vm.cancelBooking,
                      onUpdateStatus: vm.updateBookingStatus,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Skeleton loading — 4 placeholder booking cards.
  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.p16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.p12),
      itemBuilder: (_, __) => const _SkeletonBookingCard(),
    );
  }

  /// Enhanced empty state with circular icon container.
  ///
  /// Phase 7 REDESIGN: Icon wrapped in primary-tinted circle (80px) for
  /// designed feel instead of a naked floating icon.
  Widget _buildEmptyState(BuildContext context, DashboardViewModel vm) {
    final colorScheme = context.colorScheme;

    return RefreshIndicator(
      onRefresh: () => vm.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Semantics(
          label: 'No bookings yet. Discover services to book.',
          excludeSemantics: true,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Phase 7: Circular icon container — feels designed, not stock
                  Container(
                    width: AppDimens.emptyStateIconContainer,
                    height: AppDimens.emptyStateIconContainer,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      size: AppDimens.emptyStateIconSize,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppLayout.spacingSection),
                  Text(
                    'No bookings yet',
                    style: AppTypography.h5.copyWith(
                      color: colorScheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppLayout.spacingStandard),
                  Text(
                    'Discover services to book',
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon-badged section header with count pill.
///
/// Phase 7 REDESIGN: Colored icon in rounded container + title + count badge.
/// Matches OverviewTab _SectionCard pattern for visual consistency.
class _BookingSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color iconColor;

  const _BookingSectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Semantics(
      header: true,
      label: '$title bookings: $count',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: AppDimens.p12,
          left: AppDimens.p4,
        ),
        child: Row(
          children: [
            // Icon badge
            Container(
              padding: const EdgeInsets.all(AppDimens.p6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.r8),
              ),
              child: Icon(
                icon,
                size: AppDimens.iconSizeSmall,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppDimens.p8),
            Text(
              title,
              style: AppTypography.h3.copyWith(color: colorScheme.text),
            ),
            const SizedBox(width: AppDimens.p8),
            // Count pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p8,
                vertical: AppDimens.p2,
              ),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.r12),
              ),
              child: Text(
                '$count',
                style: AppTypography.captionBold.copyWith(color: iconColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder for booking card loading state.
class _SkeletonBookingCard extends StatelessWidget {
  const _SkeletonBookingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimens.p4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: 200,
            height: AppDimens.p16,
            borderRadius: AppDimens.r4,
          ),
          SizedBox(height: AppDimens.p8),
          SkeletonLoader(height: AppDimens.p12, borderRadius: AppDimens.r4),
          SizedBox(height: AppDimens.p8),
          Row(
            children: [
              SkeletonLoader(
                width: 80,
                height: AppDimens.p12,
                borderRadius: AppDimens.r4,
              ),
              SizedBox(width: AppDimens.p12),
              SkeletonLoader(
                width: 60,
                height: AppDimens.p12,
                borderRadius: AppDimens.r4,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
