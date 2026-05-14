import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';

enum _MessageMode { received, sent }

const String _kFallbackUserName = 'Unknown user';
const int _presenceOnlineThresholdSeconds = 60;

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

  /// Visual inbox mode matching the Open Design segmented control.
  _MessageMode _mode = _MessageMode.received;

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
      unawaited(_chatCtrl.fetchConversations());
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
    _chatCtrl
      ..unsubscribeFromUserConversations()
      ..unsubscribeFromConversation();
    super.dispose();
  }

  /// Debounced search handler — waits 300ms after last keystroke before
  /// filtering to avoid excessive rebuilds during rapid typing.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppMotion.standard, () {
      if (!mounted) return; // FIX-8: Guard against unmounted setState
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  /// Filters conversations by name or last message content.
  ///
  /// Received/Sent is visual copy until the model exposes a stable direction
  /// field; filtering by latest sender would hide active conversations.
  List<Conversation> _filteredConversations(List<Conversation> conversations) {
    if (_searchQuery.isEmpty) return conversations;
    return conversations.where((convo) {
      final name = (convo.otherUserName ?? '').toLowerCase();
      final msg = (convo.lastMessage ?? '').toLowerCase();
      return name.contains(_searchQuery) || msg.contains(_searchQuery);
    }).toList();
  }

  bool _isOnlineConversation(Conversation conversation) {
    final presence = conversation.presenceUpdatedAt;
    if (presence == null) return false;
    return DateTime.now().difference(presence).inSeconds <=
        _presenceOnlineThresholdSeconds;
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
    unawaited(_staggerController.forward());
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    const amber = AmberDuskTokens.colors;
    const typography = AmberDuskTokens.typography;
    const spacing = AmberDuskTokens.spacing;

    return Scaffold(
      backgroundColor: AmberDuskColors.transparent,
      body: Consumer<ChatViewModel>(
        builder: (context, controller, child) {
          final unreadCount = controller.conversations.where(_isUnread).length;
          final filtered = _filteredConversations(controller.conversations);

          // Trigger stagger on first content arrival
          if (!controller.isLoadingConversations &&
              controller.conversations.isNotEmpty) {
            _triggerStaggerIfNeeded(controller.conversations.length);
          }

          return RefreshIndicator(
            color: amber.primary,
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
                          Text(
                            'INBOX',
                            style: typography.chip.copyWith(
                              color: amber.muted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppDimens.p4),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      'Messages',
                                      style: typography.screenTitle.copyWith(
                                        color: amber.text,
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
                                          color: amber.primary,
                                          borderRadius: BorderRadius.circular(
                                            AppDimens.r10,
                                          ),
                                        ),
                                        child: Text(
                                          unreadCount.toString(),
                                          style: AppTypography.micro.copyWith(
                                            color: amber.text,
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
                                  behavior: HitTestBehavior.opaque,
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
                                          ? amber.primary.withValues(alpha: 0.1)
                                          : AmberDuskColors.transparent,
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.r10,
                                      ),
                                    ),
                                    child: Icon(
                                      _showSearch
                                          ? Icons.close_rounded
                                          : Icons.search_rounded,
                                      color: _showSearch
                                          ? amber.primary
                                          : amber.textSubtle,
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
                              child: _buildSearchBar(),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        spacing.contentHorizontalPadding,
                        AppDimens.p4,
                        spacing.contentHorizontalPadding,
                        AppDimens.p12,
                      ),
                      child: _buildModeToggle(),
                    ),
                  ),

                  if (!controller.isLoadingConversations &&
                      controller.conversations.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildOnlineRow(
                        filtered.where(_isOnlineConversation).toList(),
                      ),
                    ),

                  // ── Content: Loading / Empty / List / No Results ─
                  if (controller.isLoadingConversations)
                    _buildSkeletonList()
                  else if (controller.conversations.isEmpty)
                    _buildEmptyState()
                  else ...[
                    // Apply search filter to conversations
                    if (filtered.isEmpty)
                      _buildNoSearchResults()
                    else
                      _buildConversationList(controller, filtered),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Segmented inbox control from the Amber Dusk Open Design evidence.
  Widget _buildModeToggle() {
    const amber = AmberDuskTokens.colors;
    final tabTheme = AmberDuskTokens.widgetTheme.tabs;

    return Container(
      height: AppLayout.statusIndicatorHeight,
      padding: const EdgeInsets.all(AppDimens.p4),
      decoration: BoxDecoration(
        color: amber.surface,
        borderRadius: BorderRadius.circular(AmberDuskTokens.spacing.pillRadius),
      ),
      child: Row(
        children: [
          _buildModeButton(
            label: 'Received',
            mode: _MessageMode.received,
            textStyle: tabTheme.labelStyle,
          ),
          _buildModeButton(
            label: 'Sent',
            mode: _MessageMode.sent,
            textStyle: tabTheme.labelStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required _MessageMode mode,
    required TextStyle textStyle,
  }) {
    const amber = AmberDuskTokens.colors;
    final isSelected = _mode == mode;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '$label conversations',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_mode == mode) return;
            AppInteractionStates.hapticSelection();
            AppLogger.d(
              'MessagesScreen: mode switched',
              tag: 'Chat',
              json: {'mode': mode.name},
            );
            setState(() => _mode = mode);
          },
          child: AnimatedContainer(
            duration: AmberDuskTokens.motion.activeState,
            curve: AmberDuskTokens.motion.stateCurve,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? amber.primary : AmberDuskColors.transparent,
              borderRadius: BorderRadius.circular(
                AmberDuskTokens.spacing.pillRadius,
              ),
            ),
            child: Text(
              label,
              style: textStyle.copyWith(
                color: isSelected ? amber.text : amber.textSubtle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Horizontal participant strip matching the Open Design "online now" row.
  Widget _buildOnlineRow(List<Conversation> conversations) {
    const amber = AmberDuskTokens.colors;
    final visible = conversations.take(4).toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label: 'Online now, ${visible.length} users',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AmberDuskSpacing.contentHorizontalPadding,
          0,
          AmberDuskSpacing.contentHorizontalPadding,
          AppDimens.p12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ONLINE NOW',
              style: AmberDuskTokens.typography.chip.copyWith(
                color: amber.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppDimens.p8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: visible
                    .map(
                      (conversation) => Padding(
                        padding: const EdgeInsets.only(right: AppDimens.p8),
                        child: _OnlinePill(conversation: conversation),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton loading state — 6 placeholder tiles while conversations load.
  Widget _buildSkeletonList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.spacingSection),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, _) => const SkeletonConversationTile(),
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
  Widget _buildEmptyState() {
    const amber = AmberDuskTokens.colors;
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
                    color: amber.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 32,
                    color: amber.primary,
                  ),
                ),
                const SizedBox(height: AppLayout.spacingScreen),
                Text(
                  'No messages yet',
                  style: AmberDuskTokens.typography.sectionTitle.copyWith(
                    color: amber.text,
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
                    style: AmberDuskTokens.typography.bodySmall.copyWith(
                      color: amber.muted,
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
  Widget _buildSearchBar() {
    const amber = AmberDuskTokens.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p12, top: AppDimens.p4),
      child: TextField(
        controller: _searchController,
        style: AmberDuskTokens.typography.bodySmall.copyWith(color: amber.text),
        decoration: InputDecoration(
          hintText: 'Search current mode by name or message...',
          hintStyle: AmberDuskTokens.typography.bodySmall.copyWith(
            color: amber.muted,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: AppDimens.p12),
            child: Icon(Icons.search_rounded, color: amber.muted, size: 18),
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
                    color: amber.muted,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: amber.surface,
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
            borderSide: BorderSide(color: amber.primary.withValues(alpha: 0.3)),
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
  Widget _buildNoSearchResults() {
    const amber = AmberDuskTokens.colors;
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
                  color: amber.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 24,
                  color: amber.muted,
                ),
              ),
              const SizedBox(height: AppLayout.spacingSection),
              Text(
                'No results found',
                style: AmberDuskTokens.typography.body.copyWith(
                  color: amber.textSubtle,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppLayout.spacingTight),
              Text(
                'Search checks the current Received or Sent view',
                style: AmberDuskTokens.typography.bodySmall.copyWith(
                  color: amber.muted,
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
    List<Conversation> conversations,
  ) {
    const amber = AmberDuskTokens.colors;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AmberDuskSpacing.contentHorizontalPadding,
        0,
        AmberDuskSpacing.contentHorizontalPadding,
        AppDimens.p100,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final convo = conversations[index];
          final tile = Dismissible(
            key: ValueKey(convo.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: AppDimens.p10),
              decoration: BoxDecoration(
                color: amber.danger,
                borderRadius: BorderRadius.circular(AppDimens.r16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppLayout.spacingScreen),
              child: Icon(Icons.delete_outline, color: amber.text, size: 24),
            ),
            confirmDismiss: (direction) async {
              // Haptic for destructive action warning
              AppInteractionStates.hapticHeavy();

              // Show confirmation dialog first; only proceed to delete if confirmed.
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: amber.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.r18),
                  ),
                  title: Text(
                    'Delete Conversation?',
                    style: AmberDuskTokens.typography.sectionTitle.copyWith(
                      color: amber.text,
                    ),
                  ),
                  content: Text(
                    'This will hide the conversation until a new message is sent.',
                    style: AmberDuskTokens.typography.body.copyWith(
                      color: amber.textSubtle,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: amber.textSubtle),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: amber.danger,
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
              } on Exception catch (e, st) {
                AppLogger.w(
                  'MessagesScreen: deleteConversation failed; refreshing conversations',
                  tag: 'Chat',
                  error: e,
                  json: {'stack_trace': st.toString()},
                );
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
            child: _AmberConversationCard(
              conversation: convo,
              isUnread: _isUnread(convo),
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
    AppLogger.i('MessagesScreen: opening conversation', tag: 'Chat');
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
      'MessagesScreen: returned from chat, refreshing conversations',
      tag: 'Chat',
    );
  }
}

/// Compact participant pill for the Amber Dusk online row.
class _OnlinePill extends StatelessWidget {
  const _OnlinePill({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    final name = conversation.otherUserName ?? _kFallbackUserName;

    return Semantics(
      label: '$name, online',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p10,
            vertical: AppDimens.p6,
          ),
          decoration: BoxDecoration(
            color: amber.surface,
            borderRadius: BorderRadius.circular(AmberDuskSpacing.pillRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _InitialsAvatar(name: name, size: AppDimens.p28),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: AppDimens.p8,
                      height: AppDimens.p8,
                      decoration: BoxDecoration(
                        color: AmberDuskTokens.widgetTheme.media.onlineDot,
                        shape: BoxShape.circle,
                        border: Border.all(color: amber.surface, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppDimens.p6),
              Text(
                name,
                style: AmberDuskTokens.typography.chip.copyWith(
                  color: amber.textSubtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Amber Dusk conversation card used by [MessagesScreen].
///
/// The card keeps the same conversation navigation and archive behavior while
/// replacing the legacy list tile with the Open Design message-card rhythm.
class _AmberConversationCard extends StatelessWidget {
  const _AmberConversationCard({
    required this.conversation,
    required this.isUnread,
    required this.onTap,
  });

  final Conversation conversation;
  final bool isUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    final name = conversation.otherUserName ?? _kFallbackUserName;
    final message = conversation.otherUserTyping
        ? 'Typing...'
        : (conversation.lastMessage?.trim().isNotEmpty ?? false)
        ? conversation.lastMessage!.trim()
        : 'No messages yet';
    final taskTitle = conversation.taskTitle?.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.p10),
        padding: const EdgeInsets.all(AppDimens.p14),
        decoration: BoxDecoration(
          color: amber.surface,
          borderRadius: BorderRadius.circular(AmberDuskSpacing.moduleRadius),
          border: Border.all(
            color: isUnread
                ? amber.primary.withValues(alpha: 0.28)
                : AmberDuskColors.transparent,
          ),
        ),
        child: Row(
          children: [
            _InitialsAvatar(name: name, size: AppDimens.p48),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AmberDuskTokens.typography.body.copyWith(
                            color: amber.text,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: AppDimens.p8,
                          height: AppDimens.p8,
                          decoration: BoxDecoration(
                            color: amber.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.p4),
                  Text(
                    message,
                    style: AmberDuskTokens.typography.bodySmall.copyWith(
                      color: conversation.otherUserTyping
                          ? amber.primary
                          : amber.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (taskTitle != null && taskTitle.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.p8),
                    Container(
                      padding:
                          AmberDuskTokens.widgetTheme.statusPills.smallPadding,
                      decoration: BoxDecoration(
                        color: amber.surfaceHighest,
                        borderRadius: BorderRadius.circular(
                          AmberDuskTokens.widgetTheme.statusPills.radius,
                        ),
                      ),
                      child: Text(
                        taskTitle,
                        style: AmberDuskTokens
                            .widgetTheme
                            .statusPills
                            .smallTextStyle
                            .copyWith(color: amber.textSubtle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDimens.p8),
            Text(
              _relativeTime(conversation.lastMessageTime),
              style: AmberDuskTokens.typography.chip.copyWith(
                color: amber.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

/// Initials avatar that avoids remote image work in the dense inbox list.
class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final media = AmberDuskTokens.widgetTheme.media;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: media.avatarFallback,
        shape: BoxShape.circle,
      ),
      child: Text(_initials(name), style: media.initialsTextStyle(size)),
    );
  }

  String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
        .toUpperCase();
  }
}
