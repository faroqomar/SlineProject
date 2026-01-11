import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/booking/view/add_slot_sheet.dart';
import 'package:sline_app/features/booking/view/booking_sheet.dart';
import '../../../core/utils/format_date.dart';
import '../viewmodels/booking_view_model.dart';
import '../models/slot_model.dart';

/// Shows provider availability slots, supports pagination, error handling,
/// and role-based guard for adding new slots (provider-only).
class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({
    super.key,
    required this.providerId,
    required this.taskId,
    this.packageTier,
    this.packagePrice,
    this.packageData,
  });

  /// Provider (freelancer) id whose availability we display.
  final String providerId;

  /// Task id that the booking will be tied to.
  final String taskId;

  /// Optional: Selected package tier (e.g., 'Basic', 'Standard')
  final String? packageTier;

  /// Optional: Price associated with the package
  final String? packagePrice;

  /// Optional: Full package data
  final Map<String, dynamic>? packageData;

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  /// Scroll controller to trigger "load more" near the end.
  final ScrollController _scroll = ScrollController();
  bool _asGrid = false;

  @override
  void initState() {
    super.initState();
    // First load once the widget has a valid context under the global Provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingViewModel>().loadSlots(providerId: widget.providerId);
    });
    // Infinite scroll: fetch more when approaching the bottom.
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 120) {
        final vm = context.read<BookingViewModel>();
        vm.loadMoreSlots(providerId: widget.providerId);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Pull-to-refresh handler (reload from first page).
  Future<void> _reload() async {
    await context.read<BookingViewModel>().loadSlots(
      providerId: widget.providerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();

    // Only the provider (owner of providerId) can add availability.
    final currentUserId = vm.currentUserId;
    final bool isProviderOwner =
        currentUserId != null && currentUserId == widget.providerId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability'),
        actions: [
          // Provider-only: Add Slot
          IconButton(
            tooltip: isProviderOwner ? 'Add Slot' : 'Only provider can add',
            onPressed: isProviderOwner
                ? () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddSlotSheet(
                        onCreated: (created) {
                          // Refresh after creating a slot
                          if (created) {
                            vm.loadSlots(providerId: widget.providerId);
                          }
                        },
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.add),
          ),
          // Toggle grid/list
          IconButton(
            tooltip: _asGrid ? 'List view' : 'Grid view',
            onPressed: () => setState(() => _asGrid = !_asGrid),
            icon: Icon(_asGrid ? Icons.view_list : Icons.grid_view),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: _buildBody(context, vm, isProviderOwner),
      ),
    );
  }

  /// Builds the body with error/empty states, list/grid, and "load more".
  Widget _buildBody(
    BuildContext context,
    BookingViewModel vm,
    bool isProviderOwner,
  ) {
    // Loading first page
    if (vm.slotsLoading && vm.slots.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state with retry
    if (vm.slotsError != null && vm.slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load: ${vm.slotsError}'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => vm.loadSlots(providerId: widget.providerId),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final List<SlotModel> slots = vm.slots;

    // Empty state
    if (slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No slots yet'),
            if (isProviderOwner) ...[
              const SizedBox(height: 8),
              const Text('Tip: Add your first slot from the + button above.'),
            ],
          ],
        ),
      );
    }

    // Main content with "load more" footer and bottom progress indicator
    return Column(
      children: [
        Expanded(
          child: _asGrid
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    controller: _scroll,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.6,
                        ),
                    itemCount: slots.length,
                    itemBuilder: (context, i) => _SlotCard(
                      slot: slots[i],
                      fmt: formatRangeUtcToLocal,
                      onTap: (slot) => _onTapSlot(context, slot),
                    ),
                  ),
                )
              : ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: slots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final slot = slots[i];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      title: Text(
                        formatRangeUtcToLocal(slot.startsAtUtc, slot.endsAtUtc),
                      ),
                      subtitle: Text(slot.isBlocked ? 'Blocked' : 'Open'),
                      leading: Icon(
                        slot.isBlocked ? Icons.block : Icons.event_available,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: slot.isBlocked
                          ? null
                          : () => _onTapSlot(context, slot),
                    );
                  },
                ),
        ),

        // Bottom inline progress while loading next page
        if (vm.slotsLoading && slots.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),

        // Manual "Load more" button (hidden when there is no more data or currently loading)
        if (vm.slotsHasMore && !vm.slotsLoading)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () =>
                    vm.loadMoreSlots(providerId: widget.providerId),
                icon: const Icon(Icons.more_horiz),
                label: const Text('Load more'),
              ),
            ),
          ),
      ],
    );
  }

  void _onTapSlot(BuildContext context, SlotModel slot) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => BookingSheet(
        slotId: slot.id,
        providerId: widget.providerId,
        taskId: widget.taskId,
        packageTier: widget.packageTier,
        packagePrice: widget.packagePrice,
        packageData: widget.packageData,
        startUtc: slot.startsAtUtc,
        endUtc: slot.endsAtUtc,
        isBlocked: slot.isBlocked,
        onSubmitted: () {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Booking requested')));
        },
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot, required this.fmt, required this.onTap});

  final SlotModel slot;

  /// Formatter for "YYYY-MM-DD  HH:mm → HH:mm" given UTC range.
  final String Function(DateTime, DateTime) fmt;
  final void Function(SlotModel) onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: slot.isBlocked ? null : () => onTap(slot),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(slot.isBlocked ? Icons.block : Icons.event_available),
                  const SizedBox(width: 8),
                  Text(slot.isBlocked ? 'Blocked' : 'Open'),
                ],
              ),
              Text(
                fmt(slot.startsAtUtc, slot.endsAtUtc),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
