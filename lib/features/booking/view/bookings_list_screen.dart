import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/booking_view_model.dart';
import '../models/booking_model.dart';
import '../../../core/utils/format_date.dart';

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

  String _fmtDate(DateTime createdAtUtc) => formatUtcToLocal(createdAtUtc);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text('Failed to load: $error'));
    }

    final filtered = filter == null
        ? items
        : items.where((e) => e.status == filter).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No bookings'));
    }

    return Column(
      children: [
        _FilterBar(
          value: filter,
          onChanged: onFilterChanged,
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final b = filtered[i];
              final roleLabel = asProvider ? 'AS PROVIDER' : 'AS CLIENT';

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.2),
                  ),
                ),
                title: Text(
                  '${b.status.name.toUpperCase()} · $roleLabel',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text(
                  'Created: ${_fmtDate(b.createdAtUtc)}\n'
                  'Slot: ${b.slotId}',
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: asProvider
                      ? [
                          Tooltip(
                            message: 'Confirm (coming soon) — provider only',
                            child: FilledButton(
                              onPressed: null,
                              child: const Text('Confirm'),
                            ),
                          ),
                          Tooltip(
                            message: 'Complete (coming soon) — provider only',
                            child: OutlinedButton(
                              onPressed: null,
                              child: const Text('Complete'),
                            ),
                          ),
                        ]
                      : [
                          Tooltip(
                            message: 'Cancel (coming soon) — client only',
                            child: OutlinedButton(
                              onPressed: null,
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                ),
              );
            },
          ),
        ),
        if (loading && items.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (hasMore && !loading)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () {
                  final vm = context.read<BookingViewModel>();
                  if (asProvider) {
                    vm.loadMoreBookingsAsProvider();
                  } else {
                    vm.loadMoreBookingsAsClient();
                  }
                },
                icon: const Icon(Icons.more_horiz),
                label: const Text('Load more'),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.value,
    required this.onChanged,
  });

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
                  value: BookingStatus.pending, child: Text('Pending')),
              DropdownMenuItem(
                  value: BookingStatus.confirmed, child: Text('Confirmed')),
              DropdownMenuItem(
                  value: BookingStatus.completed, child: Text('Completed')),
              DropdownMenuItem(
                  value: BookingStatus.canceled, child: Text('Canceled')),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}