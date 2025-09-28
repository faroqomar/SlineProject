import 'package:flutter/material.dart';

/// Simple tile for a saved task (MVP: shows taskId only).
/// Later we can join with `tasks` to show title/budget/etc.
class SavedTaskTile extends StatelessWidget {
  final String taskId;
  final VoidCallback onRemove;

  const SavedTaskTile({
    super.key,
    required this.taskId,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.bookmark),
      title: Text('Task: $taskId', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        tooltip: 'Remove',
        onPressed: onRemove,
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }
}
