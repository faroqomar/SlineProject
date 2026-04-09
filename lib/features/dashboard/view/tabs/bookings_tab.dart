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

/// Bookings tab with skeleton loading, rich empty state, section Semantics,
/// and token normalization.
///
/// Phase 5 redesign: replaced CircularProgressIndicator with skeleton list,
/// enhanced empty state with icon + descriptive text, added Semantics to
/// section headers, replaced hardcoded icon size with token. View-layer only.
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

        return RefreshIndicator(
          onRefresh: () => vm.refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppDimens.p16),
            children: [
              if (upcoming.isNotEmpty) ...[
                const _SectionHeader(title: 'Upcoming'),
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
                const SizedBox(height: AppDimens.p24),
              ],

              if (past.isNotEmpty) ...[
                const _SectionHeader(title: 'Past'),
                ...past.map(
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

  /// Enhanced empty state with icon and descriptive text.
  Widget _buildEmptyState(BuildContext context, DashboardViewModel vm) {
    final colorScheme = context.colorScheme;

    return RefreshIndicator(
      onRefresh: () => vm.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Semantics(
          label: 'No bookings yet. Discover services to book.',
          // excludeSemantics prevents child widgets from duplicating the label
          excludeSemantics: true,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: AppLayout.iconFeature,
                    color: colorScheme.textSecondary,
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

/// Section header with Semantics for accessibility.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: '$title bookings',
      // excludeSemantics prevents the child Text from announcing a duplicate label
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: AppDimens.p12,
          left: AppDimens.p4,
        ),
        child: Text(
          title,
          style: AppTypography.h3.copyWith(color: context.colorScheme.text),
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
