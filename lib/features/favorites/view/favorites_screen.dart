import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/logger_service.dart';
import '../viewmodels/favorites_view_model.dart';
import '../models/favorites_mutation_result.dart';
import 'widgets/favorite_card.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';

/// FavoritesScreen (MVVM)
/// Uses app-level FavoritesViewModel only; no local service/VM.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _ensureLoadedScheduled = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel>();
    if (!_ensureLoadedScheduled) {
      _ensureLoadedScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vm.ensureLoaded();
      });
    }
    return const _FavoritesView();
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel>();

    return Scaffold(
      key: const Key('favorites_screen'),
      appBar: AppBar(title: const Text('Favorites')),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: Builder(
          builder: (context) {
            if (vm.isLoading) {
              return const Center(
                key: Key('favorites_loading'),
                child: CircularProgressIndicator(),
              );
            }
            if (vm.error != null) {
              return ListView(
                key: const Key('favorites_error'),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      vm.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              );
            }
            final items = vm.itemsWithProfile;
            if (items.isEmpty) {
              return ListView(
                key: const Key('favorites_empty'),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No favorites yet.')),
                ],
              );
            }
            return ListView.builder(
              key: const Key('favorites_list'),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final favorite = items[index];
                return FavoriteCard(
                  key: Key('favorite_card_${favorite.freelancerId}'),
                  favorite: favorite,
                  onStartChat: () async {
                    // MVVM: use ChatViewModel to create/get conversation and open ChatScreen
                    try {
                      final chatVM = context.read<ChatViewModel>();
                      final clientId = chatVM.currentUserId;
                      if (clientId == null) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please sign in to start chat'),
                          ),
                        );
                        return;
                      }
                      final convo = await chatVM.createOrGetConversation(
                        taskId: null,
                        user1Id: clientId,
                        user2Id: favorite.freelancerId,
                      );
                      // Handle double-tap or error (conversation is null)
                      if (convo == null) return;
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(conversation: convo),
                        ),
                      );
                    } catch (e) {
                      AppLogger.e(
                        'Chat start failed',
                        tag: 'Favorites',
                        error: e,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not start chat. Please try again.',
                          ),
                        ),
                      );
                    }
                  },
                  onRemove: () async {
                    final result = await vm.remove(favorite.freelancerId);
                    if (!context.mounted) return;
                    if (result == FavoritesMutationResult.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Removed from favorites'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            vm.error ?? 'Could not remove. Please try again.',
                          ),
                        ),
                      );
                    }
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
