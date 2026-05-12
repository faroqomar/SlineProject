import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';
import 'package:sline_app/features/booking/view/widgets/dashboard_booking_card.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/work/view/work_item_details_screen.dart';

/// Bookings tab with skeleton loading, icon-badged section headers,
/// dimmed past bookings, and enhanced empty state.
///
/// The tab keeps booking callbacks in [DashboardViewModel] while normalizing
/// the dashboard list rhythm to Amber Dusk section and surface tokens.
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

        const spacing = AmberDuskTokens.spacing;

        return RefreshIndicator(
          onRefresh: () => vm.refresh(),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.contentHorizontalPadding,
            ),
            children: [
              if (upcoming.isNotEmpty) ...[
                _BookingSectionHeader(
                  title: 'Upcoming',
                  count: upcoming.length,
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
                SizedBox(height: spacing.xl),
              ],

              if (past.isNotEmpty) ...[
                _BookingSectionHeader(title: 'Past', count: past.length),
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
    const spacing = AmberDuskTokens.spacing;

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.contentHorizontalPadding,
        vertical: AppDimens.p16,
      ),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.p12),
      itemBuilder: (_, __) => const _SkeletonBookingCard(),
    );
  }

  /// Enhanced empty state with circular icon container.
  ///
  Widget _buildEmptyState(BuildContext context, DashboardViewModel vm) {
    const amber = AmberDuskTokens.colors;

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
                      color: amber.activeGlow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      size: AppDimens.emptyStateIconSize,
                      color: amber.textSubtle,
                    ),
                  ),
                  const SizedBox(height: AppLayout.spacingSection),
                  Text(
                    'No bookings yet',
                    style: AppTypography.h5.copyWith(color: amber.textSubtle),
                  ),
                  const SizedBox(height: AppLayout.spacingStandard),
                  Text(
                    'Discover services to book',
                    style: AppTypography.bodySmall.copyWith(color: amber.muted),
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

/// Compact booking section header with count suffix.
///
/// Open Design uses uppercase dashboard section labels rather than large card
/// headers, so the count stays in-line to avoid adding another surface.
class _BookingSectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _BookingSectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const typography = AmberDuskTokens.typography;

    return Semantics(
      header: true,
      label: '$title bookings: $count',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.p12),
        child: Row(
          children: [
            Text(
              _uppercaseForLocale(context, title),
              style: typography.chip.copyWith(
                color: amber.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: AppDimens.p8),
            Text('$count', style: typography.chip.copyWith(color: amber.muted)),
          ],
        ),
      ),
    );
  }

  String _uppercaseForLocale(BuildContext context, String value) {
    final locale = Localizations.localeOf(context).languageCode.toLowerCase();
    if (locale == 'tr' || locale == 'az') {
      return value.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
    }
    return value.toUpperCase();
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
