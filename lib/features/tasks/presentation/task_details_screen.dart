import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../../../core/utils/format_price.dart';
import 'requests/requests_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows details of a task and provides entry points to offers (requests).
class TaskDetailsScreen extends StatelessWidget {
  final Task task;
  const TaskDetailsScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final bool isOwner = currentUserId != null && currentUserId == task.userId;

    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Category: ${task.category}', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                Text('Budget: ${PriceFormatter.formatPrice(task.budget.toDouble())}'),
                const SizedBox(height: 12),
                Text(task.description),
                const SizedBox(height: 12),
                if (task.isBooking)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This task uses scheduling instead of bidding. Check availability to book a session.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Builder(
            builder: (context) {
              if (task.isTender) {
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RequestsListScreen(
                                taskId: task.id,
                                autoOpenSubmitSheet: false,
                                isTender: task.isTender,
                                isOwner: isOwner,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.list_alt),
                        label: const Text('View Offers'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!isOwner)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RequestsListScreen(
                                  taskId: task.id,
                                  autoOpenSubmitSheet: true,
                                  isTender: task.isTender,
                                  isOwner: isOwner,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Submit Offer'),
                        ),
                      ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showComingSoon(context, 'Availability will be here in Sprint 2');
                        },
                        icon: const Icon(Icons.schedule),
                        label: const Text('Check Availability'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showComingSoon(context, 'Booking flow will be here in Sprint 2');
                        },
                        icon: const Icon(Icons.event_available),
                        label: const Text('Book Now'),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.construction),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}