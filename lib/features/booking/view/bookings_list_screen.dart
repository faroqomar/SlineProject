import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/booking/view/widgets/booking_card.dart';
import 'package:sline_app/features/booking/view/booking_details_screen.dart';
import '../viewmodels/booking_view_model.dart';
import '../models/booking_model.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  BookingStatus? _filter; // null = All

  @override
  void initState() {
    super.initState();
    // Load data after first frame to ensure the global Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<BookingViewModel>();
      vm.loadBookingsAsClient();
      vm.loadBookingsAsProvider();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                final vm = context.read<BookingViewModel>();
                vm.loadBookingsAsClient();
                vm.loadBookingsAsProvider();
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'As Client'),
              Tab(text: 'As Provider'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingsListView(
              items: vm.bookingsAsClient,
              loading: vm.bookingsLoading,
              error: vm.bookingsError,
              filter: _filter,
              onFilterChanged: (v) => setState(() => _filter = v),
              hasMore: vm.bookingsClientHasMore,
            ),
            _BookingsListView(
              items: vm.bookingsAsProvider,
              loading: vm.bookingsLoading,
              error: vm.bookingsError,
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

class _BookingsListView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: SkeletonTaskCard(),
        ),
      );
    }
    if (error != null && items.isEmpty) {
      return Center(child: Text('Failed to load: $error'));
    }

    final filtered = filter == null
        ? items
        : items.where((e) => e.status == filter).toList();

    if (filtered.isEmpty) {
      if (loading) return const Center(child: CircularProgressIndicator());
      return const Center(child: Text('No bookings'));
    }

    return Column(
      children: [
        _FilterBar(value: filter, onChanged: onFilterChanged),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              if (i == filtered.length) {
                // Load More Indicator
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: OutlinedButton(
                      onPressed: () {
                        final vm = context.read<BookingViewModel>();
                        if (asProvider) {
                          vm.loadMoreBookingsAsProvider();
                        } else {
                          vm.loadMoreBookingsAsClient();
                        }
                      },
                      child: const Text('Load More'),
                    ),
                  ),
                );
              }

              final b = filtered[i];
              return BookingCard(
                booking: b,
                asProvider: asProvider,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingDetailsScreen(booking: b),
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.value, required this.onChanged});

  final BookingStatus? value;
  final ValueChanged<BookingStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          const Text('Status:'),
          const SizedBox(width: 12),
          DropdownButton<BookingStatus?>(
            value: value,
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(
                value: BookingStatus.pending,
                child: Text('Pending'),
              ),
              DropdownMenuItem(
                value: BookingStatus.confirmed,
                child: Text('Confirmed'),
              ),
              DropdownMenuItem(
                value: BookingStatus.completed,
                child: Text('Completed'),
              ),
              DropdownMenuItem(
                value: BookingStatus.canceled,
                child: Text('Canceled'),
              ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
