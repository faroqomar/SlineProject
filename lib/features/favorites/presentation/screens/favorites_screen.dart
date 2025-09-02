import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controller/favorites_controller.dart';
import '../../data/favorites_service.dart';
import '../widgets/favorite_card.dart';
import '../../../chat/services/message_service.dart';

/// FavoritesScreen
/// Shows the current user's favorite freelancers with simple actions.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final c = FavoritesController(service: FavoritesService());
        // Load on first build
        c.load();
        return c;
      },
      child: const _FavoritesView(),
    );
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FavoritesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: Builder(
          builder: (context) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.error != null) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      controller.error!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              );
            }
            final items = controller.itemsWithProfile;
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No favorites yet.')),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final favorite = items[index];
                return FavoriteCard(
                  favorite: favorite,
                  onStartChat: () async {
                    // Starts a conversation with the freelancer from favorites.
                    // Checks authentication and navigates to Chat screen using conversationId.
                    try {
                      final clientId = Supabase.instance.client.auth.currentUser?.id;
                      if (clientId == null) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please sign in to start chat')),
                        );
                        return;
                      }
                      final conversationId = await MessageService(Supabase.instance.client)
                          .startConversationByClient(
                        taskId: null,
                        clientId: clientId,
                        freelancerId: favorite.freelancerId,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pushNamed(
                        '/chat',
                        arguments: {'conversationId': conversationId},
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to start chat: $e')),
                      );
                    }
                  },
                  onRemove: () async {
                    await controller.remove(favorite.freelancerId);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Removed from favorites')),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}