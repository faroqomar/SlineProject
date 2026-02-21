import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_view_model.dart';
import 'work_item_card.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/deep_link_service.dart'
    as sline_deep_link;

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
              onPrimaryAction: () async {
                final action = item.primaryActionType;
                if (action == PrimaryActionType.reviewDelivery ||
                    action == PrimaryActionType.submitEvidence ||
                    action == PrimaryActionType.payEscrow ||
                    action == PrimaryActionType.viewDetails) {
                  // Navigate using deep link service
                  final result = await context
                      .read<sline_deep_link.DeepLinkService>()
                      .handleWorkItem(context, item.type.name, item.id);
                  if (result == true && context.mounted) {
                    context.read<DashboardViewModel>().refresh();
                  }
                } else {
                  await context.read<DashboardViewModel>().performPrimaryAction(
                    item,
                  );
                }
              },
            ),
          )
          .toList(),
    );
  }
}
