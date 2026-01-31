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
    // Use calculated priority actions (Phase 1.3 Logic)
    final items = vm.nextActions;

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
                // TODO: Wire up action properly based on type
                // For now, WorkItemCard handles deep link on tap
                // Primary action could be distinct
              },
            ),
          )
          .toList(),
    );
  }
}
