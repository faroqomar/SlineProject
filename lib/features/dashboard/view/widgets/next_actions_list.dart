import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_view_model.dart';
import 'work_item_card.dart';

class NextActionsList extends StatelessWidget {
  const NextActionsList({super.key});

  @override
  Widget build(BuildContext context) {
    // In Phase 2, we consume the VM directly
    final vm = context.watch<DashboardViewModel>();
    final items = vm.workItems; // Use activeItems later for filtering

    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return const Center(child: Text("No actions pending."));
    }

    // Show top 3 items for "Next Actions" section
    final displayItems = items.take(3).toList();

    return Column(
      children: displayItems
          .map(
            (item) => WorkItemCard(
              item: item,
              onPrimaryAction: () {
                // Todo: Handle action
              },
            ),
          )
          .toList(),
    );
  }
}
