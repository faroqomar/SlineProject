import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
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
///
/// Phase 8 polish: implements the Open Design-inspired conversations layout:
/// editorial header, persistent search, counted segmented controls, and richer
/// row metadata inside one continuous inbox panel.
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

  /// Lets the header search action move focus to the persistent search field.
  final FocusNode _searchFocusNode = FocusNode();

  /// Current search query, lowercased and trimmed for case-insensitive matching.
  String _searchQuery = '';

  /// Debounce timer — prevents excessive rebuilds during rapid typing.
  /// Cancelled in dispose() to prevent setState on unmounted widget (FIX-8).
  Timer? _searchDebounce;

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
    _searchFocusNode.dispose();
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

  /// Counts threads where the latest visible message was sent by the current
  /// user. The screen still keeps all threads visible because the model has no
  /// stable received/sent tab contract yet.
  int _sentConversationCount(List<Conversation> conversations) {
    final myId = context.read<ChatViewModel>().currentUserId;
    if (myId == null) return 0;
    return conversations
        .where((conversation) => conversation.lastMessageSenderId == myId)
        .length;
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
    const spacing = AmberDuskTokens.spacing;

    return Scaffold(
      backgroundColor: amber.background,
      body: AmberDuskBackground(
        // Match HomeScreen's page-level atmospheric background so the inbox
        // sits on the same Amber Dusk shell as the discovery feed.
        child: Consumer<ChatViewModel>(
          builder: (context, controller, child) {
            final unreadCount = controller.conversations
                .where(_isUnread)
                .length;
            final sentCount = _sentConversationCount(controller.conversations);
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppLayout.screenHorizontalMargin,
                          topPadding + AppDimens.p12,
                          AppLayout.screenHorizontalMargin,
                          AppDimens.p16,
                        ),
                        child: _MessagesHeader(
                          totalCount: controller.conversations.length,
                          unreadCount: unreadCount,
                          onSearchTap: () {
                            AppInteractionStates.hapticTap();
                            _searchFocusNode.requestFocus();
                            AppLogger.d(
                              'MessagesScreen: search focused from header',
                              tag: 'Chat',
                            );
                          },
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppLayout.screenHorizontalMargin,
                        ),
                        child: _buildSearchBar(),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          spacing.contentHorizontalPadding,
                          AppDimens.p20,
                          spacing.contentHorizontalPadding,
                          AppDimens.p20,
                        ),
                        child: _buildModeToggle(
                          receivedCount: controller.conversations.length,
                          sentCount: sentCount,
                        ),
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
      ),
    );
  }

  /// Segmented inbox control from the Amber Dusk Open Design evidence.
  Widget _buildModeToggle({
    required int receivedCount,
    required int sentCount,
  }) {
    final tabTheme = AmberDuskTokens.widgetTheme.tabs;

    return Container(
      height: AppDimens.p52,
      padding: const EdgeInsets.all(AppDimens.p6),
      decoration: BoxDecoration(
        color: AmberDuskMaterial.raisedSurface,
        borderRadius: BorderRadius.circular(AmberDuskTokens.spacing.pillRadius),
        boxShadow: AmberDuskMaterial.surfaceDepthShadows,
      ),
      child: Row(
        children: [
          _buildModeButton(
            label: 'Received',
            count: receivedCount,
            mode: _MessageMode.received,
            textStyle: tabTheme.labelStyle,
          ),
          _buildModeButton(
            label: 'Sent',
            count: sentCount,
            mode: _MessageMode.sent,
            textStyle: tabTheme.labelStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required int count,
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
              gradient: isSelected
                  ? AmberDuskMaterial.activeWashGradient
                  : null,
              color: isSelected ? null : AmberDuskColors.transparent,
              borderRadius: BorderRadius.circular(
                AmberDuskTokens.spacing.pillRadius,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: textStyle.copyWith(
                    color: isSelected ? amber.text : amber.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: AppDimens.p8),
                Text(
                  count.toString(),
                  style: textStyle.copyWith(
                    color: isSelected ? amber.primary : amber.muted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
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
                    size: AppDimens.iconSizeLarge,
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
    return SizedBox(
      height: AppDimens.p60,
      child: TextField(
        key: const ValueKey('messages_search_field'),
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: AmberDuskTokens.typography.body.copyWith(color: amber.text),
        decoration: InputDecoration(
          hintText: 'Search messages',
          hintStyle: AmberDuskTokens.typography.body.copyWith(
            color: amber.muted,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: AppDimens.p16),
            child: Icon(
              Icons.search_rounded,
              color: amber.muted,
              size: AppDimens.iconSizeMedium,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: AppDimens.p52,
            minHeight: AppDimens.p52,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _onSearchChanged('');
                    FocusScope.of(context).unfocus();
                  },
                  child: Icon(
                    Icons.clear_rounded,
                    color: amber.muted,
                    size: AppDimens.iconSizeMedium,
                  ),
                )
              : null,
          filled: true,
          fillColor: AmberDuskMaterial.raisedSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AmberDuskSpacing.moduleRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AmberDuskSpacing.moduleRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AmberDuskSpacing.moduleRadius),
            borderSide: BorderSide(
              color: amber.rowSeparator,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p16,
            vertical: AppDimens.p18,
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
                  size: AppDimens.iconSizeMedium,
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
  /// Uses a single continuous surface behind the rows so the inbox has a
  /// deliberate shape without making every conversation a separate card.
  Widget _buildConversationList(
    ChatViewModel controller,
    List<Conversation> conversations,
  ) {
    const amber = AmberDuskTokens.colors;
    const phoneLayout = AmberDuskTokens.phoneLayout;
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;
    // Reserve the same vertical band occupied by the floating nav so the last
    // conversation can scroll fully above the overlaid app shell.
    final bottomNavClearance =
        bottomSafePadding +
        phoneLayout.bottomNavBottom +
        phoneLayout.bottomNavHeight +
        AppLayout.spacingScreen;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AmberDuskSpacing.contentHorizontalPadding,
        0,
        AmberDuskSpacing.contentHorizontalPadding,
        bottomNavClearance,
      ),
      sliver: SliverToBoxAdapter(
        child: Container(
          key: const ValueKey('message_conversation_panel'),
          decoration: AmberDuskMaterial.surfaceDecoration(
            radius: AmberDuskSpacing.taskCardRadius,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              AmberDuskSpacing.taskCardRadius,
            ),
            child: Column(
              children: List.generate(conversations.length, (index) {
                final convo = conversations[index];
                final tile = Dismissible(
                  key: ValueKey(convo.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: amber.danger,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(
                      right: AppLayout.spacingScreen,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: amber.text,
                      size: AppDimens.iconSizeMedium,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    // Haptic for destructive action warning
                    AppInteractionStates.hapticHeavy();
                    // Capture the messenger before dialog/delete awaits so the
                    // failure path does not read BuildContext after an async gap.
                    final messenger = ScaffoldMessenger.of(context);

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
                          style: AmberDuskTokens.typography.sectionTitle
                              .copyWith(color: amber.text),
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
                      if (mounted) {
                        messenger.showSnackBar(
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
                    isLast: index == conversations.length - 1,
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
              }),
            ),
          ),
        ),
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

/// Header matching the Open Design conversations composition.
///
/// It keeps search as a visible primary workflow and uses the action button
/// only to focus the field, avoiding a hidden search state on a dense inbox.
class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader({
    required this.totalCount,
    required this.unreadCount,
    required this.onSearchTap,
  });

  final int totalCount;
  final int unreadCount;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;

    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INBOX',
                  style: AmberDuskTokens.typography.chip.copyWith(
                    color: amber.muted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppDimens.p4),
                Text(
                  'Conversations',
                  style: AmberDuskTokens.typography.screenTitle.copyWith(
                    color: amber.text,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimens.p10),
                Text(
                  '$totalCount conversations, $unreadCount unread',
                  style: AmberDuskTokens.typography.bodySmall.copyWith(
                    color: amber.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.p12),
          Semantics(
            button: true,
            label: 'Focus message search',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSearchTap,
              child: Container(
                width: AppDimens.p48,
                height: AppDimens.p48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AmberDuskMaterial.raisedSurface,
                  borderRadius: BorderRadius.circular(AppDimens.r18),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: amber.textSubtle,
                  size: AppLayout.iconStandard,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Amber Dusk conversation row used by [MessagesScreen].
///
/// The row follows the supplied Open Design target: prominent avatar, strong
/// participant name, truncated preview, task context line, and a compact
/// right-side action state.
class _AmberConversationCard extends StatelessWidget {
  const _AmberConversationCard({
    required this.conversation,
    required this.isUnread,
    required this.isLast,
    required this.onTap,
  });

  final Conversation conversation;
  final bool isUnread;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    final name = conversation.otherUserName ?? _kFallbackUserName;
    final taskTitle = conversation.taskTitle?.trim();
    final hasContext = taskTitle != null && taskTitle.isNotEmpty;
    final isLinkedEmpty =
        (conversation.lastMessage?.trim().isEmpty ?? true) && hasContext;
    final showOnline = _isOnline(conversation.presenceUpdatedAt);
    final dividerColor = amber.rowSeparator;
    final timeText = _relativeTime(conversation.lastMessageTime);
    final statusLabel = isUnread
        ? 'Reply'
        : (isLinkedEmpty ? 'Linked' : 'Open');
    // Conversation currently exposes read state for only the latest message,
    // so the row can truthfully show a one-message unread preview at most.
    final unreadPreviewCount = isUnread ? 1 : 0;
    final message = conversation.otherUserTyping
        ? 'Typing...'
        : (conversation.lastMessage?.trim().isNotEmpty ?? false)
        ? conversation.lastMessage!.trim()
        // Empty task-linked rows need context because repeated names can
        // otherwise look like duplicate conversations with no content.
        : _emptyConversationPreview(taskTitle);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        key: ValueKey<String>('message_conversation_row_${conversation.id}'),
        duration: AppMotion.fast,
        curve: AppMotion.curveDecel,
        decoration: BoxDecoration(
          // The unread row uses a warm wash like the supplied design while all
          // other rows inherit the parent panel for one continuous inbox stack.
          gradient: isUnread ? AmberDuskMaterial.activeWashGradient : null,
          color: isUnread ? null : AmberDuskColors.transparent,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.p16,
                AppDimens.p20,
                AppDimens.p16,
                AppDimens.p20,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InitialsAvatar(
                    name: name,
                    size: AppDimens.p54,
                    showOnline: showOnline,
                  ),
                  const SizedBox(width: AppDimens.p14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AmberDuskTokens.typography.sectionTitle
                              .copyWith(color: amber.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDimens.p4),
                        Text(
                          message,
                          style: AmberDuskTokens.typography.body.copyWith(
                            color: conversation.otherUserTyping
                                ? amber.primary
                                : amber.textSubtle.withValues(alpha: 0.70),
                            height: 1.25,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasContext) ...[
                          const SizedBox(height: AppDimens.p8),
                          _ContextLine(title: taskTitle),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.p10),
                  _ConversationActionState(
                    timeText: timeText,
                    statusLabel: statusLabel,
                    unreadCount: unreadPreviewCount,
                  ),
                ],
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppDimens.p54 + AppDimens.p16 + AppDimens.p14,
                  right: AppDimens.p28,
                ),
                child: Container(
                  key: ValueKey<String>(
                    'message_conversation_divider_${conversation.id}',
                  ),
                  height: AppDimens.hairlineDivider,
                  decoration: BoxDecoration(
                    color: dividerColor,
                    borderRadius: BorderRadius.circular(
                      AppDimens.hairlineDivider,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static bool _isOnline(DateTime? presenceUpdatedAt) {
    if (presenceUpdatedAt == null) return false;
    return DateTime.now().difference(presenceUpdatedAt).inSeconds <=
        _presenceOnlineThresholdSeconds;
  }

  String _relativeTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  /// Preview copy for conversations that were created from work context before
  /// either participant sent the first message.
  String _emptyConversationPreview(String? taskTitle) {
    if (taskTitle == null || taskTitle.isEmpty) return 'No messages yet';
    return conversation.taskType == 'booking'
        ? 'Linked booking - no messages yet'
        : 'Linked task - no messages yet';
  }
}

/// Task context line with a small primary dot, matching the supplied mockup.
class _ContextLine extends StatelessWidget {
  const _ContextLine({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;

    return Row(
      children: [
        Container(
          width: AppDimens.p6,
          height: AppDimens.p6,
          decoration: BoxDecoration(
            color: amber.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppDimens.p8),
        Expanded(
          child: Text(
            title,
            style: AmberDuskTokens.typography.bodySmall.copyWith(
              color: amber.textSubtle.withValues(alpha: 0.78),
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Right-side time and action state for a conversation row.
class _ConversationActionState extends StatelessWidget {
  const _ConversationActionState({
    required this.timeText,
    required this.statusLabel,
    required this.unreadCount,
  });

  final String timeText;
  final String statusLabel;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    final showBadge = unreadCount > 0;

    return SizedBox(
      width: AppDimens.p64,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (timeText.isNotEmpty)
            Text(
              timeText,
              style: AmberDuskTokens.typography.chip.copyWith(
                color: amber.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: AppDimens.p12),
          if (showBadge) ...[
            Container(
              width: AppDimens.p32,
              height: AppDimens.p32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: amber.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: AmberDuskTokens.typography.control.copyWith(
                  color: amber.page,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.p10),
          ],
          Text(
            statusLabel,
            style: AmberDuskTokens.typography.chip.copyWith(
              color: showBadge ? amber.primary : amber.muted,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Initials avatar that avoids remote image work in the dense inbox list.
class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.name,
    required this.size,
    required this.showOnline,
  });

  final String name;
  final double size;
  final bool showOnline;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    final fill = _fillForName(name);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials(name),
              style: AmberDuskTokens.typography.sectionTitle.copyWith(
                color: amber.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (showOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: AppDimens.p14,
                height: AppDimens.p14,
                decoration: BoxDecoration(
                  color: AmberDuskTokens.widgetTheme.media.onlineDot,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AmberDuskMaterial.raisedSurface,
                    width: AppDimens.p2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _fillForName(String value) {
    const amber = AmberDuskTokens.colors;
    final seed = value.codeUnits.fold<int>(0, (total, unit) => total + unit);
    final palette = <Color>[
      amber.primaryDeep.withValues(alpha: 0.44),
      amber.forest.withValues(alpha: 0.36),
      amber.surface.withValues(alpha: 0.52),
      amber.surface.withValues(alpha: 0.78),
    ];
    return palette[seed % palette.length];
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
