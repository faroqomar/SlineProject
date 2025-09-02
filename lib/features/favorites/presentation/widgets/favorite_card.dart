import 'package:flutter/material.dart';
import 'package:sline_app/features/favorites/models/favorite_model.dart';

/// Simple favorite card showing a freelancer and actions.
/// NOTE: In MVP we only have freelancerId; later we can enrich with profile data.
class FavoriteCard extends StatelessWidget {
  final FavoriteWithProfile favorite;
  final VoidCallback onStartChat;
  final VoidCallback onRemove;

  const FavoriteCard({
    super.key,
    required this.favorite,
    required this.onStartChat,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: favorite.freelancerAvatar != null
                  ? NetworkImage(favorite.freelancerAvatar!)
                  : null,
              child: favorite.freelancerAvatar == null
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorite.freelancerName ?? 'Freelancer',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Added: ${favorite.createdAt}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onStartChat,
              child: const Text('Start Chat'),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}