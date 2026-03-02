import 'package:flutter/material.dart';
import '../../../../core/services/logger_service.dart';
import '../sheets/portfolio_details_sheet.dart';
import '../../viewmodels/portfolio_view_model.dart';
import '../../models/portfolio_item.dart';
import 'image_placeholder.dart';

/// Grid tile for a single portfolio item.
/// Uses effectiveImageRef for rendering (handles both canonical imagePath and legacy imageUrl).
class PortfolioTile extends StatelessWidget {
  const PortfolioTile({
    super.key,
    required this.item,
    required this.controller,
    required this.onLongPress,
  });

  final PortfolioItem item;
  final PortfolioViewModel controller;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    // Get effective image URL (canonical path or legacy URL)
    final imageUrl = controller.getImageUrl(item);

    AppLogger.d(
      'Building portfolio tile',
      tag: 'PortfolioTile',
      json: {
        'itemId': item.id,
        'hasImage': imageUrl != null,
        'imagePath': item.imagePath,
        'imageUrl': item.imageUrl != null ? '(legacy)' : null,
      },
    );

    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: border,
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          AppLogger.d(
            'Opening portfolio details',
            tag: 'PortfolioTile',
            json: {'itemId': item.id},
          );
          PortfolioDetailsSheet.open(context, item, controller);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, __) {
                          AppLogger.w(
                            'Failed to load portfolio image',
                            tag: 'PortfolioTile',
                            error: error,
                          );
                          return ImagePlaceholder(title: item.title);
                        },
                      )
                    : ImagePlaceholder(title: item.title),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
