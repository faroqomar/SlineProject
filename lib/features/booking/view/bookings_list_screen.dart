import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/view/booking_details_screen.dart';
import 'package:sline_app/features/booking/view/widgets/booking_card.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';

/// Booking management screen for client and provider booking lists.
class BookingsListScreen extends StatefulWidget {
  /// Creates the bookings list screen.
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  BookingStatus? _filter; // null = All

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<BookingViewModel>();
      unawaited(vm.loadBookingsAsClient());
      unawaited(vm.loadBookingsAsProvider());
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();
    const amber = AmberDuskTokens.colors;
    const typography = AmberDuskTokens.typography;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: amber.page,
        appBar: AppBar(
          title: Text(
            'Bookings',
            style: typography.sectionTitle.copyWith(color: amber.text),
          ),
          backgroundColor: amber.page,
          foregroundColor: amber.text,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                AppLogger.i('Bookings list refresh requested', tag: 'Booking');
                final vm = context.read<BookingViewModel>();
                unawaited(vm.loadBookingsAsClient());
                unawaited(vm.loadBookingsAsProvider());
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: TabBar(
            labelColor: amber.primary,
            unselectedLabelColor: amber.textSubtle,
            indicatorColor: amber.primary,
            tabs: const [
              Tab(text: 'As Client'),
              Tab(text: 'As Provider'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingsListView(
              items: vm.bookingsAsClient,
              loading: vm.clientBookingsLoading,
              error: vm.clientBookingsError,
              filter: _filter,
              onFilterChanged: (v) => setState(() => _filter = v),
              hasMore: vm.bookingsClientHasMore,
            ),
            _BookingsListView(
              items: vm.bookingsAsProvider,
              loading: vm.providerBookingsLoading,
              error: vm.providerBookingsError,
              filter: _filter,
              onFilterChanged: (v) => setState(() => _filter = v),
              asProvider: true,
              hasMore: vm.bookingsProviderHasMore,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsListView extends StatefulWidget {
  const _BookingsListView({
    required this.items,
    required this.loading,
    required this.error,
    required this.filter,
    required this.onFilterChanged,
    required this.hasMore,
    this.asProvider = false,
  });

  final List<BookingModel> items;
  final bool loading;
  final String? error;
  final BookingStatus? filter;
  final ValueChanged<BookingStatus?> onFilterChanged;
  final bool hasMore;
  final bool asProvider;

  @override
  State<_BookingsListView> createState() => _BookingsListViewState();
}

class _BookingsListViewState extends State<_BookingsListView> {
  List<BookingModel>? _cachedFiltered;
  List<BookingModel>? _cachedItems;
  BookingStatus? _cachedFilter;

  @override
  void didUpdateWidget(covariant _BookingsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items) ||
        oldWidget.filter != widget.filter) {
      _cachedFiltered = null;
      _cachedItems = null;
      _cachedFilter = null;
    }
  }

  List<BookingModel> _filteredItems() {
    if (_cachedFiltered != null &&
        identical(_cachedItems, widget.items) &&
        _cachedFilter == widget.filter) {
      return _cachedFiltered!;
    }

    final filtered = widget.filter == null
        ? widget.items
        : widget.items
              .where((booking) => booking.status == widget.filter)
              .toList(growable: false);
    _cachedItems = widget.items;
    _cachedFilter = widget.filter;
    _cachedFiltered = filtered;
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    if (widget.loading && widget.items.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(AppDimens.p24),
        itemCount: 5,
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.only(bottom: AppDimens.p12),
          child: SkeletonBookingCard(),
        ),
      );
    }

    final filtered = _filteredItems();

    return Column(
      children: [
        _FilterBar(value: widget.filter, onChanged: widget.onFilterChanged),
        if (widget.error != null && widget.items.isNotEmpty)
          _RefreshErrorBanner(message: widget.error!),
        Expanded(
          child: widget.error != null && widget.items.isEmpty
              ? _BookingStateCard(
                  icon: Icons.cloud_off_rounded,
                  title: 'Bookings unavailable',
                  message: widget.error!,
                )
              : filtered.isEmpty
              ? _BookingStateCard(
                  icon: widget.loading
                      ? Icons.hourglass_top_rounded
                      : Icons.event_busy_outlined,
                  title: widget.loading ? 'Loading bookings' : 'No bookings',
                  message: widget.loading
                      ? 'Checking your latest booking activity.'
                      : 'New booking requests and confirmed work will appear here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.p24,
                    AppDimens.p8,
                    AppDimens.p24,
                    AppDimens.p100,
                  ),
                  itemCount: filtered.length + (widget.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppDimens.p4),
                  itemBuilder: (context, i) {
                    if (i == filtered.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimens.p16,
                        ),
                        child: Center(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              AppLogger.i(
                                'Bookings list load-more requested',
                                tag: 'Booking',
                                json: <String, dynamic>{
                                  'surface': widget.asProvider
                                      ? 'provider'
                                      : 'client',
                                },
                              );
                              final vm = context.read<BookingViewModel>();
                              if (widget.asProvider) {
                                unawaited(vm.loadMoreBookingsAsProvider());
                              } else {
                                unawaited(vm.loadMoreBookingsAsClient());
                              }
                            },
                            icon: Icon(
                              Icons.expand_more_rounded,
                              color: amber.primary,
                            ),
                            label: const Text('Load more'),
                          ),
                        ),
                      );
                    }

                    final b = filtered[i];
                    return BookingCard(
                      booking: b,
                      asProvider: widget.asProvider,
                      onTap: () {
                        unawaited(
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailsScreen(booking: b),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RefreshErrorBanner extends StatelessWidget {
  const _RefreshErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p24,
        AppDimens.p12,
        AppDimens.p24,
        AppDimens.p4,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.p12),
        decoration: BoxDecoration(
          color: amber.warningMuted,
          borderRadius: BorderRadius.circular(AppDimens.r12),
          border: Border.all(color: amber.warning),
        ),
        child: Row(
          children: [
            Icon(Icons.sync_problem_rounded, color: amber.warning),
            const SizedBox(width: AppDimens.p8),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodySmall.copyWith(color: amber.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty/error state card for booking tabs.
class _BookingStateCard extends StatelessWidget {
  /// Creates a compact state card.
  const _BookingStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  /// Leading icon that describes the state.
  final IconData icon;

  /// State title.
  final String title;

  /// Supporting state message.
  final String message;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    return ListView(
      padding: const EdgeInsets.all(AppDimens.p24),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppDimens.p24),
          child: Column(
            children: [
              Icon(icon, color: amber.primary, size: AppDimens.iconSizeLarge),
              const SizedBox(height: AppDimens.p12),
              Text(
                title,
                style: AppTypography.h5.copyWith(color: amber.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.p8),
              Text(
                message,
                style: AppTypography.bodySmall.copyWith(
                  color: amber.textSubtle,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Amber Dusk status filter for booking tabs.
class _FilterBar extends StatelessWidget {
  /// Creates a horizontal booking status filter.
  const _FilterBar({required this.value, required this.onChanged});

  /// Active filter, or null for all statuses.
  final BookingStatus? value;

  /// Filter selection callback.
  final ValueChanged<BookingStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const spacing = AmberDuskTokens.spacing;
    final filters = <({BookingStatus? status, String label})>[
      (status: null, label: 'All'),
      (status: BookingStatus.pending, label: 'Pending'),
      (status: BookingStatus.confirmed, label: 'Confirmed'),
      (status: BookingStatus.completed, label: 'Completed'),
      (status: BookingStatus.canceled, label: 'Canceled'),
    ];

    return SizedBox(
      height: AppDimens.p60,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.p24,
          AppDimens.p12,
          AppDimens.p24,
          AppDimens.p8,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter.status == value;
          return ChoiceChip(
            selected: selected,
            label: Text(filter.label),
            onSelected: (_) => onChanged(filter.status),
            selectedColor: amber.primary,
            backgroundColor: amber.surfaceRaised,
            labelStyle: AmberDuskTokens.typography.chip.copyWith(
              color: selected ? amber.textInverse : amber.textSubtle,
            ),
            side: BorderSide(
              color: selected ? amber.primary : amber.transparent,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacing.pillRadius),
            ),
          );
        },
      ),
    );
  }
}
