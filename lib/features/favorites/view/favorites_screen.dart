import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/favorites/models/favorites_mutation_result.dart';
import 'package:sline_app/features/favorites/view/widgets/favorite_card.dart';
import 'package:sline_app/features/favorites/viewmodels/favorites_view_model.dart';

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
  void initState() {
    super.initState();
    AppLogger.d('favorites_screen_loaded', tag: 'FavoritesScreen');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel>();
    if (!_ensureLoadedScheduled) {
      _ensureLoadedScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(vm.ensureLoaded());
      });
    }
    return const _FavoritesView();
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  /// Top gap used by scrollable empty/error states so pull-to-refresh remains
  /// available while the state content still lands near the visual center.
  static const double _stateTopGap = AppDimens.p100 + AppDimens.p20;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel>();
    final colorScheme = context.colorScheme;
    final amber = _amberScheme(context);

    return Scaffold(
      key: const Key('favorites_screen'),
      backgroundColor: amber.page,
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: amber.page,
        foregroundColor: colorScheme.text,
        surfaceTintColor: AmberDuskColors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: Builder(
          builder: (context) {
            if (vm.isLoading) {
              // Skeleton shimmer list — 5 placeholder cards for perceived speed
              return ListView.builder(
                key: const Key('favorites_loading'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.p24,
                  vertical: AppDimens.p16,
                ),
                itemCount: 5,
                itemBuilder: (_, _) => const SkeletonFavoriteCard(),
              );
            }
            if (vm.error != null) {
              final amber = _amberScheme(context);
              return ListView(
                key: const Key('favorites_error'),
                children: [
                  const SizedBox(height: _stateTopGap),
                  // Error icon in a tinted circle
                  Center(
                    child: Semantics(
                      label: 'Error loading favorites',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: AppDimens.p80,
                            height: AppDimens.p80,
                            decoration: BoxDecoration(
                              color: amber.dangerMuted,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline,
                              size: AppDimens.p48,
                              color: amber.danger,
                            ),
                          ),
                          const SizedBox(height: AppDimens.p16),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.p24,
                            ),
                            child: Text(
                              vm.userFriendlyError,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: amber.danger,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimens.p16),
                          // Retry button to refresh favorites
                          OutlinedButton(
                            onPressed: () {
                              AppInteractionStates.hapticTap();
                              unawaited(vm.refresh());
                            },
                            style: _outlineButtonStyle(context),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            final items = vm.itemsWithProfile;
            if (items.isEmpty) {
              final colorScheme = context.colorScheme;
              final amber = _amberScheme(context);
              return ListView(
                key: const Key('favorites_empty'),
                children: [
                  const SizedBox(height: _stateTopGap),
                  // Empty state: icon + title + subtitle
                  Center(
                    child: Semantics(
                      label: 'No favorites yet',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon in a tinted circle
                          Container(
                            width: AppDimens.p80,
                            height: AppDimens.p80,
                            decoration: BoxDecoration(
                              color: amber.activeGlow,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_border,
                              size: AppDimens.p48,
                              color: amber.primary,
                            ),
                          ),
                          const SizedBox(height: AppDimens.p16),
                          Text(
                            'No favorites yet',
                            style: AppTypography.h5.copyWith(
                              color: colorScheme.text,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimens.p8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.p24,
                            ),
                            child: Text(
                              'Find and save your favorite freelancers',
                              style: AppTypography.bodySmall.copyWith(
                                color: colorScheme.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // CTA button to guide users toward discovery
                          const SizedBox(height: AppDimens.p24),
                          OutlinedButton.icon(
                            onPressed: () {
                              AppInteractionStates.hapticTap();
                              Navigator.pop(context);
                            },
                            style: _outlineButtonStyle(context),
                            icon: const Icon(
                              Icons.explore,
                              size: AppDimens.iconSmall,
                            ),
                            label: const Text('Explore Freelancers'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              key: const Key('favorites_list'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p24,
                vertical: AppDimens.p16,
              ),
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
                      unawaited(
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(conversation: convo),
                          ),
                        ),
                      );
                    } on Object catch (e) {
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
                        const SnackBar(content: Text('Removed from favorites')),
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

  /// Returns the brightness-aware Amber Dusk scheme for local state accents.
  AmberDuskColorScheme _amberScheme(BuildContext context) {
    return context.colorScheme.isDark
        ? AmberDuskTokens.colors.dark
        : AmberDuskTokens.colors.light;
  }

  /// Applies Amber Dusk action color to secondary buttons without replacing
  /// the existing Material button behavior or callbacks.
  ButtonStyle _outlineButtonStyle(BuildContext context) {
    final amber = _amberScheme(context);
    return OutlinedButton.styleFrom(
      foregroundColor: amber.primary,
      minimumSize: const Size(AppDimens.touchTarget, AppDimens.touchTarget),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
      side: BorderSide(color: amber.primary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.r12),
      ),
    );
  }
}
