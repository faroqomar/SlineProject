import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/orders/viewmodels/orders_view_model.dart';
import 'package:sline_app/features/orders/view/widgets/order_card.dart';
import 'package:sline_app/features/orders/view/widgets/offer_list_sheet.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/view/create_task_screen.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/core/utils/loading_utils.dart';

/// Orders dashboard screen showing user's published tasks.
class OrdersDashboardScreen extends StatefulWidget {
  const OrdersDashboardScreen({super.key});

  @override
  State<OrdersDashboardScreen> createState() => _OrdersDashboardScreenState();
}

class _OrdersDashboardScreenState extends State<OrdersDashboardScreen> {
  final List<String> _tabs = ['Open', 'In Progress', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersViewModel>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;
    final vm = context.watch<OrdersViewModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // --- Header ---
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimens.p24,
              topPadding + AppDimens.p24,
              AppDimens.p24,
              AppDimens.p16,
            ),
            child: Column(
              children: [
                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Published Tasks',
                          style: AppTypography.h2.copyWith(
                            color: colorScheme.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage your job posts',
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: colorScheme.textSecondary,
                      ),
                      onPressed: () => vm.loadOrders(),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.p16),

                // Tab bar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.inputBackground,
                    borderRadius: BorderRadius.circular(AppDimens.r14),
                    border: Border.all(color: colorScheme.inputBorder),
                  ),
                  child: Row(
                    children: _tabs.map((tab) {
                      final bool isActive = vm.activeTab == tab;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => vm.setActiveTab(tab),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimens.p8,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.teal
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppDimens.r10,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.teal.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                tab,
                                style: AppTypography.micro.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? AppColors.offWhite
                                      : colorScheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // --- Content ---
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.filteredOrders.isEmpty
                ? _buildEmptyState(colorScheme, vm.activeTab)
                : RefreshIndicator(
                    onRefresh: vm.loadOrders,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.p24,
                        0,
                        AppDimens.p24,
                        AppDimens.p100,
                      ),
                      itemCount: vm.filteredOrders.length,
                      itemBuilder: (context, index) {
                        final task = vm.filteredOrders[index];
                        return OrderCard(
                          task: task,
                          actionLabel: _getActionLabel(task),
                          showChatButton:
                              task.status == TaskStatus.inProgress ||
                              task.status == TaskStatus.assigned,
                          onActionTap: () => _handleActionTap(context, task),
                          onChatTap: () => _handleChatTap(context, task),
                          onEdit: () => _handleEdit(context, task),
                          onDelete: () => _handleDelete(context, task),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColorScheme colorScheme, String activeTab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.work_outline,
              size: 32,
              color: colorScheme.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          Text(
            'No $activeTab Tasks',
            style: AppTypography.h5.copyWith(color: colorScheme.text),
          ),
          const SizedBox(height: 8),
          Text(
            "You don't have any tasks in this status.",
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getActionLabel(Task task) {
    if (task.status == TaskStatus.open) {
      if (task.isTender) {
        return 'View Offers (${task.offers})';
      } else {
        return 'View Bookings'; // Booking type not fully implemented in UI yet
      }
    } else if (task.status == TaskStatus.assigned ||
        task.status == TaskStatus.inProgress) {
      return 'View Status';
    } else if (task.status == TaskStatus.closed) {
      return 'View Details';
    }
    return 'View Details';
  }

  void _handleActionTap(BuildContext context, Task task) {
    if (task.status == TaskStatus.open && task.isTender) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.7,
          child: OfferListSheet(taskId: task.id),
        ),
      );
    } else {
      // Default to task details
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)));
    }
  }

  void _handleEdit(BuildContext context, Task task) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => CreateTaskScreen(task: task)))
        .then((_) {
          if (context.mounted) {
            context.read<OrdersViewModel>().loadOrders();
          }
        });
  }

  void _handleDelete(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<OrdersViewModel>().deleteTask(task.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Task deleted')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting task: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChatTap(BuildContext context, Task task) async {
    final chatVm = context.read<ChatViewModel>();
    LoadingUtils.show(context);
    try {
      final convo = await chatVm.getTaskConversation(task);
      if (!context.mounted) return;
      LoadingUtils.hide(context);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(conversation: convo)),
      );
    } catch (e) {
      if (!context.mounted) return;
      LoadingUtils.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }
}
