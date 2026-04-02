import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/booking/view/widgets/dashboard_booking_card.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/work/view/work_item_details_screen.dart';

class BookingsTab extends StatelessWidget {
  const BookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = vm.bookings;

        if (bookings.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => vm.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 48,
                        color: context.colorScheme.textSecondary,
                      ),
                      const SizedBox(height: AppDimens.p16),
                      Text(
                        'No bookings yet',
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.colorScheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Split into Upcoming and Past
        final now = DateTime.now().toUtc();
        final upcoming = bookings.where((b) {
          final bookingTimeline = b.dueAtUtc ?? b.scheduledAt;
          if (bookingTimeline != null) {
            return bookingTimeline.isAfter(now);
          }
          // Fallback: Pending items are "Upcoming" regardless of date mostly?
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p12, left: AppDimens.p4),
      child: Text(title, style: AppTypography.h3),
    );
  }
}
