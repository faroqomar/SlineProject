import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/favorites_view_model.dart';
import '../data/favorites_service.dart';
import 'widgets/favorite_card.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';

/// FavoritesScreen (MVVM)
/// Shows the current user's favorite freelancers with simple actions.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final FavoritesViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = FavoritesViewModel(service: FavoritesService());
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FavoritesViewModel>.value(
      value: _vm,
      child: const _FavoritesView(),
    );
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: Builder(
          builder: (context) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.error != null) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      vm.error!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              );
            }
            final items = vm.itemsWithProfile;
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
                    // MVVM: use ChatViewModel to create/get conversation and open ChatScreen
                    try {
                      final chatVM = context.read<ChatViewModel>();
                      final clientId = chatVM.currentUserId;
                      if (clientId == null) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please sign in to start chat')),
                        );
                        return;
                      }
                      final convo = await chatVM.createOrGetConversation(
                        taskId: null,
                        user1Id: clientId,
                        user2Id: favorite.freelancerId,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(conversation: convo),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to start chat: $e')),
                      );
                    }
                  },
                  onRemove: () async {
                    await vm.remove(favorite.freelancerId);
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
