import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/chat/view/widgets/conversation_list_tile.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';

/// Messages inbox screen — displays all conversations with stagger entrance
/// animation, skeleton loading, rich empty state, and pull-to-refresh.
///
/// Phase 5 redesign adds motion polish (stagger entrance on first load),
/// enhanced empty state with CTA, accessibility labels, and full
/// design-token normalization. View-layer only — no ViewModel changes.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with TickerProviderStateMixin {
  late final ChatViewModel _chatCtrl;

  // ── Stagger entrance animation ─────────────────────────────
  // Pattern: single controller + Interval-based per-element animations.
  // Reference: login_screen.dart:47-159 (canonical stagger pattern).
  late final AnimationController _staggerController;

  /// Guard prevents stagger replay on back-navigation or pull-to-refresh.
  /// Only the initial data load triggers the entrance animation.
  bool _hasAnimatedEntrance = false;

  /// Number of tiles to animate in the stagger. Capped to avoid long delays.
  static const int _maxStaggerCount = 8;

  /// Cached per-tile slide animations, populated once in _triggerStaggerIfNeeded.
  /// Avoids rebuilding Animation objects on every list rebuild.
  final List<Animation<Offset>> _slideAnimations = [];

  /// Cached per-tile fade animations, populated once in _triggerStaggerIfNeeded.
  final List<Animation<double>> _fadeAnimations = [];

  @override
  void initState() {
    super.initState();
    _chatCtrl = context.read<ChatViewModel>();

    // 500ms total stagger window — first tile at 0%, last at ~70%
    _staggerController = AnimationController(
      duration: AppMotion.emphasis,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _chatCtrl.fetchConversations();
      _chatCtrl.subscribeToUserConversations();
      AppLogger.d('MessagesScreen: initial load started', tag: 'Chat');
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _chatCtrl.unsubscribeFromUserConversations();
    _chatCtrl.unsubscribeFromConversation();
    super.dispose();
  }

  /// Build slide animation for stagger interval [begin..end].
  Animation<Offset> _buildSlide(double begin, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(begin, end, curve: AppMotion.curveDecel),
      ),
    );
  }

  /// Build fade animation for stagger interval [begin..end].
  Animation<double> _buildFade(double begin, double end) {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(begin, end, curve: AppMotion.curveDecel),
      ),
    );
  }

  /// Trigger stagger entrance once when data first arrives.
  /// Also pre-builds and caches slide/fade animations so the list builder
  /// does not allocate new Animation objects on every frame.
  void _triggerStaggerIfNeeded(int itemCount) {
    if (_hasAnimatedEntrance || itemCount == 0) return;
    _hasAnimatedEntrance = true;

    // Build and cache animations for up to _maxStaggerCount tiles.
    final count = itemCount.clamp(0, _maxStaggerCount);
    for (var i = 0; i < count; i++) {
      final staggerFraction = i / (_maxStaggerCount + 2);
      final begin = staggerFraction;
      final end = (staggerFraction + 0.3).clamp(0.0, 1.0);
      _slideAnimations.add(_buildSlide(begin, end));
      _fadeAnimations.add(_buildFade(begin, end));
    }

    AppLogger.d(
      'MessagesScreen: stagger entrance triggered ($itemCount items)',
      tag: 'Chat',
    );
    _staggerController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<ChatViewModel>(
        builder: (context, controller, child) {
          final unreadCount = controller.conversations.where(_isUnread).length;

          // Trigger stagger on first content arrival
          if (!controller.isLoadingConversations &&
              controller.conversations.isNotEmpty) {
            _triggerStaggerIfNeeded(controller.conversations.length);
          }

          return RefreshIndicator(
            color: colorScheme.primary,
            onRefresh: () async {
              // Haptic on pull-to-refresh for tactile feedback
              AppInteractionStates.hapticSelection();
              await controller.fetchConversations();
            },
            child: Semantics(
              label: 'Conversations list',
              child: CustomScrollView(
                slivers: [
                  // ── Header ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppLayout.screenHorizontalMargin,
                        topPadding + AppLayout.spacingScreen,
                        AppLayout.screenHorizontalMargin,
                        AppLayout.spacingSection,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Messages',
                                style: AppTypography.h2.copyWith(
                                  color: colorScheme.text,
                                ),
                              ),
                              const SizedBox(height: AppLayout.spacingTight),
                              Text(
                                '$unreadCount unread conversations',
                                style: AppTypography.bodySmall.copyWith(
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Content: Loading / Empty / List ────────────
                  if (controller.isLoadingConversations)
                    _buildSkeletonList()
                  else if (controller.conversations.isEmpty)
                    _buildEmptyState(colorScheme)
                  else
                    _buildConversationList(controller, colorScheme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Skeleton loading state — 6 placeholder tiles while conversations load.
  Widget _buildSkeletonList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.spacingSection),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const SkeletonConversationTile(),
          childCount: 6,
        ),
      ),
    );
  }

  /// Rich empty state with icon, descriptive text, and guidance.
  /// Replaces the previous minimal icon+text empty state.
  Widget _buildEmptyState(AppColorScheme colorScheme) {
    return SliverFillRemaining(
      key: const ValueKey('message_list_empty_state'),
      hasScrollBody: false,
      child: Semantics(
        label: 'No messages. Start a conversation by contacting a freelancer.',
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: AppLayout.iconFeature,
                color: colorScheme.textSecondary,
              ),
              const SizedBox(height: AppLayout.spacingSection),
              Text(
                'No messages yet',
                style: AppTypography.h5.copyWith(
                  color: colorScheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppLayout.spacingStandard),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.spacingLarge,
                ),
                child: Text(
                  'Start a conversation by contacting a freelancer',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Main conversation list with stagger entrance and swipe-to-delete.
  Widget _buildConversationList(
    ChatViewModel controller,
    AppColorScheme colorScheme,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.spacingSection,
        0,
        AppLayout.spacingSection,
        AppDimens.p100,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final convo = controller.conversations[index];
          final tile = Dismissible(
            key: ValueKey(convo.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: AppDimens.p12),
              decoration: BoxDecoration(
                color: colorScheme.danger,
                borderRadius: BorderRadius.circular(AppDimens.r18),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppLayout.spacingScreen),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            confirmDismiss: (direction) async {
              // Haptic for destructive action warning
              AppInteractionStates.hapticHeavy();

              // Show confirmation dialog first; only proceed to delete if confirmed.
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: colorScheme.cardBackground,
                  title: Text(
                    'Delete Conversation?',
                    // Explicit color ensures readable contrast in both light and dark themes.
                    style: AppTypography.h3.copyWith(color: colorScheme.text),
                  ),
                  content: Text(
                    'This will hide the conversation until a new message is sent.',
                    // textSecondary keeps the content slightly de-emphasised while
                    // still meeting contrast requirements in dark mode.
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.textSecondary,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: colorScheme.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: colorScheme.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return false;

              // Attempt the delete here so we can prevent the swipe dismissal
              // on failure — Dismissible only removes the tile when we return true.
              try {
                await controller.deleteConversation(convo.id);
                return true;
              } on Exception catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not archive this conversation. Please try again.',
                      ),
                    ),
                  );
                  await controller.fetchConversations();
                }
                // Return false so the tile snaps back instead of disappearing.
                return false;
              }
            },
            child: ConversationListTile(
              conversation: convo,
              onTap: () => _openChat(context, convo, controller),
            ),
          );

          // Stagger entrance: animate each tile with offset delay.
          // Only first _maxStaggerCount tiles get individual stagger timing;
          // remaining tiles appear immediately at the end of the stagger.
          // Use the cached lists to avoid allocating new Animation objects
          // on every list rebuild.
          if (_hasAnimatedEntrance && index < _slideAnimations.length) {
            return SlideTransition(
              position: _slideAnimations[index],
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: tile,
              ),
            );
          }

          return tile;
        }, childCount: controller.conversations.length),
      ),
    );
  }

  /// Check if a conversation has unread messages (boolean only —
  /// ConversationModel has no numeric unreadCount field).
  bool _isUnread(Conversation convo) {
    final myId = context.read<ChatViewModel>().currentUserId;
    if (myId == null) return false;
    final isFromOther =
        convo.lastMessageSenderId != null && convo.lastMessageSenderId != myId;
    if (!isFromOther) return false;
    return convo.lastMessageSeenAt == null;
  }

  /// Navigate to the chat screen for a specific conversation.
  Future<void> _openChat(
    BuildContext context,
    Conversation convo,
    ChatViewModel controller,
  ) async {
    AppLogger.i(
      '[MessagesScreen] opening conversation: ${convo.id}',
      tag: 'Chat',
    );
    // Haptic on conversation tap
    AppInteractionStates.hapticTap();
    controller.activeConversation = convo;
    await controller.fetchMessages(convo.id);
    if (context.mounted) {
      unawaited(
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(conversation: convo)),
        ),
      );
    }
  }
}
