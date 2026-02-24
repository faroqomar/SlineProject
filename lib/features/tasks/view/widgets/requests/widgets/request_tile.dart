import 'package:flutter/material.dart';

import '../../../../../../core/utils/format_price.dart';
import '../../../../../favorites/data/favorites_service.dart';
import '../../../../../favorites/viewmodels/favorites_view_model.dart';
import '../../../../models/task_request_model.dart';

/// One row/tile for a TaskRequest in the offers list.
///
/// Note: This widget needs a FavoritesViewModel available in the widget tree
/// to handle the "Add to favorites" action properly via MVVM pattern.
class RequestTile extends StatelessWidget {
  final TaskRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isOwner;
  final bool isLoading;

  /// Optional FavoritesViewModel. If null, favorites will be added via direct
  /// service call (legacy behavior). Prefer providing a ViewModel for testability.
  final FavoritesViewModel? favoritesVM;

  const RequestTile({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
    required this.isOwner,
    this.favoritesVM,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = PriceFormatter.formatPrice(request.price.toDouble());
    final subtitle = '${request.days} days • ${_getStatusLabel()}';
    final canAct = request.isPending && onAccept != null && onReject != null && !isLoading;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          priceText,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isOwner)
              IconButton(
                tooltip: 'Add to favorites',
                icon: const Icon(Icons.favorite_border),
                onPressed: () => _handleAddFavorite(context),
              ),
            if (isOwner && isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (isOwner && canAct) ...[
              IconButton(
                tooltip: 'Award',
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: onAccept,
              ),
              IconButton(
                tooltip: 'Reject',
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: onReject,
              ),
            ],
            if (isOwner && !canAct && !isLoading && request.isAccepted)
              const Chip(
                label: Text('Awarded', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel() {
    if (isLoading) return 'Processing...';
    return request.status.name;
  }

  /// Handle adding the bidder to favorites.
  ///
  /// If a FavoritesViewModel is provided, use it (preferred MVVM approach).
  /// Otherwise, fall back to direct service call (legacy compatibility).
  Future<void> _handleAddFavorite(BuildContext context) async {
    try {
      if (favoritesVM != null) {
        // Preferred: Use ViewModel for proper state management
        await favoritesVM!.add(request.bidderId);
        if (!context.mounted) return;
        final error = favoritesVM!.error;
        if (error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
        }
      } else {
        // Legacy fallback: Direct service call
        await FavoritesService().addFavorite(request.bidderId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
      }
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().contains('23505')
          ? 'Already in favorites'
          : e.toString().toLowerCase().contains('rls')
          ? 'Not allowed for your role'
          : 'Failed to add favorite';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
