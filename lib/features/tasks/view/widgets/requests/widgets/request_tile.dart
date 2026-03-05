import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/utils/format_price.dart';
import '../../../../../favorites/viewmodels/favorites_view_model.dart';
import '../../../../../favorites/models/favorites_mutation_result.dart';
import '../../../../models/task_request_model.dart';

/// One row/tile for a TaskRequest in the offers list.
/// Add-to-favorites uses FavoritesViewModel only (MVVM; no direct service).
class RequestTile extends StatelessWidget {
  final TaskRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isOwner;
  final bool isLoading;

  /// FavoritesViewModel from app-level provider. Required for add-to-favorites when !isOwner.
  final FavoritesViewModel? favoritesVM;

  /// When set, favorite button is hidden for the current user's own offer (self-favorite guard).
  final String? viewerUserId;

  const RequestTile({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
    required this.isOwner,
    this.favoritesVM,
    this.viewerUserId,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = PriceFormatter.formatPrice(request.price.toDouble());
    final subtitle = '${request.days} days • ${_getStatusLabel()}';
    final canAct =
        request.isPending && onAccept != null && onReject != null && !isLoading;

    return Card(
      key: Key('request_tile_${request.id}'),
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
            if (!isOwner && favoritesVM != null && request.bidderId != viewerUserId)
              Consumer<FavoritesViewModel>(
                builder: (context, vm, _) {
                  final pending = vm.isPending(request.bidderId);
                  return IconButton(
                    key: Key('request_tile_add_favorite_${request.bidderId}'),
                    tooltip: pending ? null : 'Add to favorites',
                    icon: pending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.favorite_border),
                    onPressed: pending ? null : () => _handleAddFavorite(context),
                  );
                },
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

  /// Add bidder to favorites via ViewModel (typed result).
  Future<void> _handleAddFavorite(BuildContext context) async {
    final vm = favoritesVM;
    if (vm == null) return;
    final result = await vm.add(request.bidderId);
    if (!context.mounted) return;
    switch (result) {
      case FavoritesMutationResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to favorites')),
        );
        break;
      case FavoritesMutationResult.duplicate:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already in favorites')),
        );
        break;
      case FavoritesMutationResult.skipped:
        // Already in progress; no snackbar (button is disabled via Consumer).
        break;
      case FavoritesMutationResult.unauthenticated:
      case FavoritesMutationResult.forbidden:
      case FavoritesMutationResult.failure:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.error ?? 'Could not add. Please try again.')),
        );
        break;
    }
  }
}
