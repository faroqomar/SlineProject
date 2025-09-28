import 'package:flutter/material.dart';
import '../../../../models/task_request_model.dart';
import '../../../../../../core/utils/format_price.dart';
import '../../../../../favorites/data/favorites_service.dart';

/// One row/tile for a TaskRequest in the offers list.
class RequestTile extends StatelessWidget {
  final TaskRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isOwner;

  const RequestTile({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = PriceFormatter.formatPrice(request.price.toDouble());
    final subtitle = '${request.days} days • ${request.status.dbValue}';
    final canAct = request.isPending && onAccept != null && onReject != null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(priceText, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isOwner)
              IconButton(
                tooltip: 'Add to favorites',
                icon: const Icon(Icons.favorite_border),
                onPressed: () async {
                  try {
                    await FavoritesService().addFavorite(request.bidderId);
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to favorites')),
                    );
                  } catch (e) {
                    final msg = e.toString().contains('23505')
                        ? 'Already in favorites'
                        : e.toString().toLowerCase().contains('rls')
                            ? 'Not allowed for your role'
                            : 'Failed to add favorite';
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                },
              ),
            if (isOwner && canAct) ...[
              IconButton(
                tooltip: 'Accept',
                icon: const Icon(Icons.check_circle),
                onPressed: onAccept,
              ),
              IconButton(
                tooltip: 'Reject',
                icon: const Icon(Icons.cancel),
                onPressed: onReject,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
