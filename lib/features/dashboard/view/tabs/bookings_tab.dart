import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import '../widgets/booking_card.dart';

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
          return Center(
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
                  "No bookings yet",
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Split into Upcoming and Past
        final now = DateTime.now().toUtc();
        final upcoming = bookings.where((b) {
          // If scheduledAt is null, check createdAt or treat as upcoming/pending
          if (b.scheduledAt != null) {
            return b.scheduledAt!.isAfter(now);
          }
          // Fallback: Pending items are "Upcoming" regardless of date mostly?
          return b.status == BookingStatus.pending ||
              b.status == BookingStatus.confirmed;
        }).toList();

        final upcomingIds = upcoming.map((b) => b.id).toSet();
        final past = bookings
            .where((b) => !upcomingIds.contains(b.id))
            .toList();

        return ListView(
          padding: const EdgeInsets.all(AppDimens.p16),
          children: [
            if (upcoming.isNotEmpty) ...[
              _SectionHeader(title: "Upcoming"),
              ...upcoming.map(
                (b) => BookingCard(
                  booking: b,
                  isProvider: vm.currentRole == UserRole.freelancer,
                ),
              ),
              const SizedBox(height: AppDimens.p24),
            ],

            if (past.isNotEmpty) ...[
              _SectionHeader(title: "Past"),
              ...past.map(
                (b) => BookingCard(
                  booking: b,
                  isProvider: vm.currentRole == UserRole.freelancer,
                ),
              ),
            ],
          ],
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
