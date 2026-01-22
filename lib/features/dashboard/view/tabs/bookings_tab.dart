import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import '../../models/dashboard_enums.dart';
import '../widgets/booking_card.dart';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  // Mock filter state
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Pending',
    'Confirmed',
    'In Progress',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    // Mock Data
    final bookings = [
      MockBookingDisplay(
        "Logo Design Session",
        "Alice Client",
        DateTime.now().add(const Duration(hours: 2)),
        BookingStatus.confirmed,
        UserRole.freelancer,
      ),
      MockBookingDisplay(
        "Website Consultation",
        "Bob Startup",
        DateTime.now().add(const Duration(days: 1)),
        BookingStatus.pending,
        UserRole.freelancer,
      ),
    ];

    return Column(
      children: [
        // Filter Chips
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = filter == _selectedFilter;
              return ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                backgroundColor: colorScheme.cardBackground,
                labelStyle: AppTypography.captionBold.copyWith(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.textSecondary,
                ),
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.cardBorder,
                ),
              );
            },
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimens.p16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return BookingCard(booking: bookings[index]);
            },
          ),
        ),
      ],
    );
  }
}
