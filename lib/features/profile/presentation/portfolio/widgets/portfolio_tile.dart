import 'package:flutter/material.dart';
import 'package:sline_app/features/profile/presentation/portfolio/%20sheets/portfolio_details_sheet.dart';

import '../../../controllers/portfolio_controller.dart';
import '../../../models/portfolio_item.dart';
import 'image_placeholder.dart';

/// Grid tile for a single portfolio item.
class PortfolioTile extends StatelessWidget {
  const PortfolioTile({
    super.key,
    required this.item,
    required this.controller,
    required this.onLongPress,
  });

  final PortfolioItem item;
  final PortfolioController controller;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final border = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: border,
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        onTap: () => PortfolioDetailsSheet.open(context, item, controller),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ImagePlaceholder(title: item.title),
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