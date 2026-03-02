import 'package:flutter/material.dart';

import '../../../../core/services/logger_service.dart';
import '../../viewmodels/portfolio_view_model.dart';
import '../../models/portfolio_item.dart';
import '../widgets/image_placeholder.dart';
import 'edit_portfolio_sheet.dart';

/// Bottom sheet that shows portfolio item details and actions.
/// Uses effectiveImageRef for rendering portfolio images.
class PortfolioDetailsSheet extends StatelessWidget {
  const PortfolioDetailsSheet({
    super.key,
    required this.item,
    required this.controller,
  });
  final PortfolioItem item;
  final PortfolioViewModel controller;

  static Future<void> open(
    BuildContext context,
    PortfolioItem item,
    PortfolioViewModel controller,
  ) {
    AppLogger.d(
      'Opening portfolio details sheet',
      tag: 'PortfolioDetailsSheet',
      json: {'itemId': item.id},
    );
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) =>
          PortfolioDetailsSheet(item: item, controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final createdLocal = item.createdAt.toLocal();
    final imageUrl = controller.getImageUrl(item);

    AppLogger.d(
      'Building portfolio details',
      tag: 'PortfolioDetailsSheet',
      json: {'itemId': item.id, 'hasImage': imageUrl != null},
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Portfolio Item',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, __) {
                    AppLogger.w(
                      'Failed to load portfolio image in details',
                      tag: 'PortfolioDetailsSheet',
                      error: error,
                    );
                    return ImagePlaceholder(title: item.title, height: 200);
                  },
                ),
              )
            else
              ImagePlaceholder(title: item.title, height: 200),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            if ((item.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Created: ${createdLocal.year}-${createdLocal.month.toString().padLeft(2, '0')}-${createdLocal.day.toString().padLeft(2, '0')} '
              '${createdLocal.hour.toString().padLeft(2, '0')}:${createdLocal.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      AppLogger.d(
                        'Edit button pressed',
                        tag: 'PortfolioDetailsSheet',
                      );
                      final updated = await EditPortfolioSheet.open(
                        context,
                        item,
                        controller,
                      );
                      if (updated == true && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () async {
                      AppLogger.d(
                        'Delete button pressed',
                        tag: 'PortfolioDetailsSheet',
                      );
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete item?'),
                          content: const Text(
                            'This will permanently remove the portfolio entry.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (!context.mounted) return;
                      if (ok == true) {
                        AppLogger.i(
                          'User confirmed delete',
                          tag: 'PortfolioDetailsSheet',
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await controller.deleteItem(item.id);
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Deleted successfully'
                                  : 'Delete failed. Please try again.',
                            ),
                          ),
                        );
                        if (success) Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
