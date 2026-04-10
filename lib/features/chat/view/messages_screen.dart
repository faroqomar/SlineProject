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
/// Phase 5 redesign: motion polish (stagger entrance on first load),
/// enhanced empty state with CTA, accessibility labels, and full
/// design-token normalization. View-layer only — no ViewModel changes.
///
/// Phase 6 redesign: Modernized header with greeting-style title, inline
/// unread count badge, cleaner search bar styling, and conversation tiles
/// that use transparent backgrounds with subtle unread highlights.
/// Added conversation search bar with debounced client-side filtering
/// by name or last message content. Search bar toggles via header icon with
/// slide animation. Timer disposal + mounted guard prevent setState on
/// unmounted widget.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with TickerProviderStateMixin {
  late final ChatViewModel _chatCtrl;

  // ── Search bar state ──────────────────────────────────────
  /// Controls the search text field input.
  final TextEditingController _searchController = TextEditingController();

  /// Current search query, lowercased and trimmed for case-insensitive matching.
  String _searchQuery = '';

  /// Debounce timer — prevents excessive rebuilds during rapid typing.
  /// Cancelled in dispose() to prevent setState on unmounted widget (FIX-8).
  Timer? _searchDebounce;

  /// Whether the search bar is visible. Toggled by the search icon button.
  bool _showSearch = false;

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
    // FIX-8: Cancel debounce timer to prevent setState on unmounted widget
    _searchDebounce?.cancel();
    _searchController.dispose();
    _staggerController.dispose();
    _chatCtrl.unsubscribeFromUserConversations();
    _chatCtrl.unsubscribeFromConversation();
    super.dispose();
  }

  /// Debounced search handler — waits 300ms after last keystroke before
  /// filtering to avoid excessive rebuilds during rapid typing.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return; // FIX-8: Guard against unmounted setState
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  /// Filters conversations by name or last message content.
  /// Returns all conversations when query is empty or whitespace-only.
  List<Conversation> _filteredConversations(List<Conversation> conversations) {
    if (_searchQuery.isEmpty) return conversations;
    return conversations.where((convo) {
      final name = (convo.otherUserName ?? '').toLowerCase();
      final msg = (convo.lastMessage ?? '').toLowerCase();
      return name.contains(_searchQuery) || msg.contains(_searchQuery);
    }).toList();
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
                        AppDimens.p8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title row: "Messages" + action icons
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      'Messages',
                                      style: AppTypography.h2.copyWith(
                                        color: colorScheme.text,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    // Inline unread count badge — compact pill next to title
                                    if (unreadCount > 0) ...[
                                      const SizedBox(width: AppDimens.p10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppDimens.p8,
                                          vertical: AppDimens.p2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            AppDimens.r10,
                                          ),
                                        ),
                                        child: Text(
                                          unreadCount.toString(),
                                          style: AppTypography.micro.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Search toggle — icon button with container
                              Semantics(
                                button: true,
                                label: _showSearch
                                    ? 'Close search'
                                    : 'Search conversations',
                                child: GestureDetector(
                                  onTap: () {
                                    AppInteractionStates.hapticTap();
                                    setState(() {
                                      _showSearch = !_showSearch;
                                      if (!_showSearch) {
                                        _searchController.clear();
                                        _searchQuery = '';
                                        _searchDebounce?.cancel();
                                      }
                                    });
                                    AppLogger.d(
                                      'MessagesScreen: search ${_showSearch ? "opened" : "closed"}',
                                      tag: 'Chat',
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: AppMotion.fast,
                                    padding: const EdgeInsets.all(AppDimens.p8),
                                    decoration: BoxDecoration(
                                      color: _showSearch
                                          ? colorScheme.primary.withValues(
                                              alpha: 0.1,
                                            )
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.r10,
                                      ),
                                    ),
                                    child: Icon(
                                      _showSearch
                                          ? Icons.close_rounded
                                          : Icons.search_rounded,
                                      color: _showSearch
                                          ? colorScheme.primary
                                          : colorScheme.textSecondary,
                                      size: AppLayout.iconStandard,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Search bar — slides in/out with animation ──
                  SliverToBoxAdapter(
                    child: AnimatedSize(
                      // AppMotion.standard (300ms) + curveDecel for smooth slide
                      duration: AppMotion.standard,
                      curve: AppMotion.curveDecel,
                      alignment: Alignment.topCenter,
                      child: _showSearch
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppLayout.screenHorizontalMargin,
                              ),
                              child: _buildSearchBar(colorScheme),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  // ── Content: Loading / Empty / List / No Results ─
                  if (controller.isLoadingConversations)
                    _buildSkeletonList()
                  else if (controller.conversations.isEmpty)
                    _buildEmptyState(colorScheme)
                  else ...[
                    // Apply search filter to conversations
                    if (_filteredConversations(
                      controller.conversations,
                    ).isEmpty)
                      _buildNoSearchResults(colorScheme)
                    else
                      _buildConversationList(controller, colorScheme),
                  ],
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
  ///
  /// Uses a large icon and two-line description to communicate
  /// the empty state clearly. Offset slightly above center for
  /// better visual balance with the header above.
  Widget _buildEmptyState(AppColorScheme colorScheme) {
    return SliverFillRemaining(
      key: const ValueKey('message_list_empty_state'),
      hasScrollBody: false,
      child: Semantics(
        label: 'No messages. Start a conversation by contacting a freelancer.',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppLayout.spacingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decorative icon in a soft circle background
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 32,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: AppLayout.spacingScreen),
                Text(
                  'No messages yet',
                  style: AppTypography.h4.copyWith(
                    color: colorScheme.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppLayout.spacingStandard),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppLayout.spacingLarge * 2,
                  ),
                  child: Text(
                    'Start a conversation by contacting a freelancer or posting a task',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.textTertiary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Search bar text field with styled input, prefix icon, and clear button.
  ///
  /// Uses a rounded pill shape with subtle fill for a modern, minimal look.
  /// Autofocus is intentionally false so the keyboard doesn't open on
  /// screen entry — the user taps the search icon first.
  Widget _buildSearchBar(AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p12, top: AppDimens.p4),
      child: TextField(
        controller: _searchController,
        style: AppTypography.bodySmall.copyWith(color: colorScheme.text),
        decoration: InputDecoration(
          hintText: 'Search by name or message...',
          hintStyle: AppTypography.bodySmall.copyWith(
            color: colorScheme.textTertiary,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: AppDimens.p12),
            child: Icon(
              Icons.search_rounded,
              color: colorScheme.textTertiary,
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _onSearchChanged('');
                    FocusScope.of(context).unfocus();
                  },
                  child: Icon(
                    Icons.clear_rounded,
                    color: colorScheme.textTertiary,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: colorScheme.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.r12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.r12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.r12),
            borderSide: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p12,
            vertical: AppDimens.p10,
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  /// "No results" empty state when search filter returns nothing
  /// but conversations do exist. Shows a subtle icon and guidance text.
  Widget _buildNoSearchResults(AppColorScheme colorScheme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppLayout.spacingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.textTertiary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 24,
                  color: colorScheme.textTertiary,
                ),
              ),
              const SizedBox(height: AppLayout.spacingSection),
              Text(
                'No results found',
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppLayout.spacingTight),
              Text(
                'Try a different name or keyword',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Main conversation list with stagger entrance and swipe-to-delete.
  ///
  /// Uses filtered conversations when a search query is active. Tiles render
  /// with transparent backgrounds and subtle dividers between them for a
  /// clean, modern inbox look.
  Widget _buildConversationList(
    ChatViewModel controller,
    AppColorScheme colorScheme,
  ) {
    final conversations = _filteredConversations(controller.conversations);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p10,
        0,
        AppDimens.p10,
        AppDimens.p100,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final convo = conversations[index];
          final tile = Dismissible(
            key: ValueKey(convo.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: AppDimens.p4),
              decoration: BoxDecoration(
                color: colorScheme.danger,
                borderRadius: BorderRadius.circular(AppDimens.r16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppLayout.spacingScreen),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 24,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.r18),
                  ),
                  title: Text(
                    'Delete Conversation?',
                    style: AppTypography.h3.copyWith(color: colorScheme.text),
                  ),
                  content: Text(
                    'This will hide the conversation until a new message is sent.',
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
        }, childCount: conversations.length),
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
  ///
  /// Awaits the navigation push so we can mark the conversation as read
  /// locally when the user returns. This instantly clears the unread badge
  /// without waiting for a full `fetchConversations()` round-trip. A
  /// background refetch is also triggered to sync `lastMessageSeenAt` from
  /// the backend for full consistency.
  Future<void> _openChat(
    BuildContext context,
    Conversation convo,
    ChatViewModel controller,
  ) async {
    AppLogger.i(
      '[MessagesScreen] opening conversation: ${convo.id}',
      tag: 'Chat',
    );
    AppInteractionStates.hapticTap();
    controller.activeConversation = convo;
    // Navigate immediately — ChatScreen.initState() fetches messages itself.
    // Previously fetchMessages() blocked here, causing a visible ~500ms+ lag
    // between tap and screen transition.
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: convo)),
    );

    // User returned from chat — optimistically mark as read locally so the
    // unread badge clears instantly, then refetch in the background for
    // full backend consistency (updated lastMessageSeenAt).
    if (!context.mounted) return;
    controller.markConversationReadLocally(convo.id);
    unawaited(controller.fetchConversations());
    AppLogger.d(
      '[MessagesScreen] returned from chat, refreshing conversations',
      tag: 'Chat',
    );
  }
}
