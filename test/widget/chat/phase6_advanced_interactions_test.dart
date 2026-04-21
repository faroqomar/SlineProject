/// Phase 6 widget tests — advanced chat interaction features.
///
/// Tests cover: emoji-only rendering, link detection, reply quote display,
/// relative time formatting, search bar filtering, offer bubble elevation,
/// and fullscreen image viewer widget structure.
/// All tests are view-layer only — no backend or ViewModel logic tested.
library;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/widgets/fullscreen_image_viewer.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/view/messages_screen.dart';
import 'package:sline_app/features/chat/view/widgets/conversation_list_tile.dart';
import 'package:sline_app/features/chat/view/widgets/message_bubble.dart';
import 'package:sline_app/features/chat/view/widgets/offer_message_bubble.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';

import '../../test_support/pump_app.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class _MockChatViewModel extends Mock
    with ChangeNotifier
    implements ChatViewModel {}

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Wraps a single widget in MaterialApp with light theme for isolated testing.
Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Group 1 — MessageBubble: Emoji-Only Rendering
  // ═══════════════════════════════════════════════════════════════════════════
  group('MessageBubble emoji-only', () {
    testWidgets('renders single emoji without bubble container', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const MessageBubble(text: '😀', time: '12:00', isMine: true)),
      );

      // Emoji-only messages render at 32px without the standard bubble
      // Container — verify the emoji text exists and the Semantics label
      // says "sent emoji" rather than "said".
      final semantics = find.bySemanticsLabel(RegExp('sent emoji'));
      expect(semantics, findsOneWidget);
      expect(find.text('😀'), findsOneWidget);
    });

    testWidgets('renders three emoji without bubble container', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MessageBubble(text: '🎉🔥💯', time: '12:00', isMine: false),
        ),
      );

      final semantics = find.bySemanticsLabel(RegExp('sent emoji'));
      expect(semantics, findsOneWidget);
    });

    testWidgets('renders text with emoji in normal bubble (not emoji-only)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const MessageBubble(text: 'Hello 😀', time: '12:00', isMine: true),
        ),
      );

      // Mixed text+emoji should use the regular "said" semantics, not "sent emoji"
      final emojiSemantics = find.bySemanticsLabel(RegExp('sent emoji'));
      expect(emojiSemantics, findsNothing);
      final normalSemantics = find.bySemanticsLabel(RegExp('You said'));
      expect(normalSemantics, findsOneWidget);
    });

    testWidgets('digits are not treated as emoji-only', (tester) async {
      // DECISION-1: \p{Extended_Pictographic} should NOT match digits.
      // Verifies that "123" renders as a normal text bubble.
      await tester.pumpWidget(
        _wrap(const MessageBubble(text: '123', time: '12:00', isMine: true)),
      );

      final emojiSemantics = find.bySemanticsLabel(RegExp('sent emoji'));
      expect(emojiSemantics, findsNothing);
      final normalSemantics = find.bySemanticsLabel(RegExp('You said'));
      expect(normalSemantics, findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 2 — MessageBubble: Link Detection
  // ═══════════════════════════════════════════════════════════════════════════
  group('MessageBubble link detection', () {
    testWidgets('renders URL as tappable RichText', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MessageBubble(
            text: 'Check https://example.com for details',
            time: '12:00',
            isMine: true,
          ),
        ),
      );

      // Link messages should use RichText instead of plain Text
      expect(find.byType(RichText), findsWidgets);
      // The full message text should be present in some form
      final semantics = find.bySemanticsLabel(
        RegExp('You said.*https://example.com'),
      );
      expect(semantics, findsOneWidget);
    });

    testWidgets('URL message is never treated as emoji-only', (tester) async {
      // Even if a message contains only an emoji + URL, link detection
      // takes priority over emoji-only rendering.
      await tester.pumpWidget(
        _wrap(
          const MessageBubble(
            text: 'https://example.com',
            time: '12:00',
            isMine: true,
          ),
        ),
      );

      // Should use "said" semantics (regular bubble), not "sent emoji"
      final emojiSemantics = find.bySemanticsLabel(RegExp('sent emoji'));
      expect(emojiSemantics, findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 3 — MessageBubble: Reply Quote
  // ═══════════════════════════════════════════════════════════════════════════
  group('MessageBubble reply quote', () {
    testWidgets('shows reply quote when replyToText is set', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MessageBubble(
            text: 'Sure!',
            time: '12:00',
            isMine: true,
            replyToSender: 'Alice',
            replyToText: 'Can you help?',
          ),
        ),
      );

      // Reply quote shows sender name and quoted text
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Can you help?'), findsOneWidget);
    });

    testWidgets('hides reply quote when replyToText is null', (tester) async {
      await tester.pumpWidget(
        _wrap(const MessageBubble(text: 'Hello', time: '12:00', isMine: true)),
      );

      // No reply quote elements should be present
      expect(find.text('Alice'), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 4 — ConversationListTile: Relative Time Formatting
  // ═══════════════════════════════════════════════════════════════════════════
  group('ConversationListTile relative time', () {
    /// Creates a mock ChatViewModel with standard stubs for ConversationListTile.
    /// Note: otherUserTyping/activeConversation stubs removed — typing indicator
    /// was disabled (see conversation_list_tile.dart TODO).
    _MockChatViewModel _buildVm() {
      final vm = _MockChatViewModel();
      when(() => vm.currentUserId).thenReturn('user-1');
      when(() => vm.isPresenceReceiptsEnabled).thenReturn(false);
      return vm;
    }

    testWidgets('shows "Just now" for messages less than 60s old', (
      tester,
    ) async {
      final vm = _buildVm();
      final convo = Conversation(
        id: 'c1',
        user1Id: 'user-1',
        user2Id: 'u2',
        createdAt: DateTime.now(),
        otherUserName: 'Bob',
        lastMessage: 'Hello',
        lastMessageTime: DateTime.now().subtract(const Duration(seconds: 30)),
        lastMessageSenderId: 'u2',
      );

      await pumpApp(
        tester,
        ChangeNotifierProvider<ChatViewModel>.value(
          value: vm,
          child: ConversationListTile(conversation: convo, onTap: () {}),
        ),
      );

      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('shows minute format for messages < 60 minutes old', (
      tester,
    ) async {
      final vm = _buildVm();
      final convo = Conversation(
        id: 'c1',
        user1Id: 'user-1',
        user2Id: 'u2',
        createdAt: DateTime.now(),
        otherUserName: 'Bob',
        lastMessage: 'Hello',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
        lastMessageSenderId: 'u2',
      );

      await pumpApp(
        tester,
        ChangeNotifierProvider<ChatViewModel>.value(
          value: vm,
          child: ConversationListTile(conversation: convo, onTap: () {}),
        ),
      );

      expect(find.text('5m'), findsOneWidget);
    });

    testWidgets('shows hour format for messages < 24 hours old', (
      tester,
    ) async {
      final vm = _buildVm();
      final convo = Conversation(
        id: 'c1',
        user1Id: 'user-1',
        user2Id: 'u2',
        createdAt: DateTime.now(),
        otherUserName: 'Bob',
        lastMessage: 'Hello',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
        lastMessageSenderId: 'u2',
      );

      await pumpApp(
        tester,
        ChangeNotifierProvider<ChatViewModel>.value(
          value: vm,
          child: ConversationListTile(conversation: convo, onTap: () {}),
        ),
      );

      expect(find.text('3h'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 5 — MessagesScreen: Search Bar
  // ═══════════════════════════════════════════════════════════════════════════
  group('MessagesScreen search', () {
    _MockChatViewModel _buildVm({List<Conversation>? conversations}) {
      final vm = _MockChatViewModel();
      when(() => vm.conversations).thenReturn(conversations ?? []);
      when(() => vm.isLoadingConversations).thenReturn(false);
      when(() => vm.currentUserId).thenReturn('user-1');
      when(vm.fetchConversations).thenAnswer((_) async {});
      when(vm.subscribeToUserConversations).thenReturn(null);
      when(vm.unsubscribeFromUserConversations).thenReturn(null);
      when(vm.unsubscribeFromConversation).thenReturn(null);
      return vm;
    }

    testWidgets('shows search icon in header', (tester) async {
      final vm = _buildVm();

      await pumpApp(
        tester,
        ChangeNotifierProvider<ChatViewModel>.value(
          value: vm,
          child: const MessagesScreen(),
        ),
      );

      // Search icon should be visible in the header
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('toggles search bar on icon tap', (tester) async {
      final vm = _buildVm();

      await pumpApp(
        tester,
        ChangeNotifierProvider<ChatViewModel>.value(
          value: vm,
          child: const MessagesScreen(),
        ),
      );

      // Tap search icon to open search bar
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      // Search field should now be visible
      expect(find.byType(TextField), findsOneWidget);

      // Close icon should replace search icon
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('filters conversations by name', (tester) async {
      final conversations = <Conversation>[
        Conversation(
          id: 'c1',
          user1Id: 'user-1',
          user2Id: 'u1',
          createdAt: DateTime.now(),
          otherUserName: 'Alice',
          lastMessage: 'Hello',
          lastMessageTime: DateTime.now(),
          lastMessageSenderId: 'u1',
        ),
        Conversation(
          id: 'c2',
          user1Id: 'user-1',
          user2Id: 'u2',
          createdAt: DateTime.now(),
          otherUserName: 'Bob',
          lastMessage: 'Hi there',
          lastMessageTime: DateTime.now(),
          lastMessageSenderId: 'u2',
        ),
      ];
      final vm = _buildVm(conversations: conversations);
      when(() => vm.isPresenceReceiptsEnabled).thenReturn(false);

      await pumpApp(
        tester,
        ChangeNotifierProvider<ChatViewModel>.value(
          value: vm,
          child: const MessagesScreen(),
        ),
      );

      // Open search
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      // Type filter text
      await tester.enterText(find.byType(TextField), 'Alice');
      // Wait for debounce (300ms)
      await tester.pump(const Duration(milliseconds: 350));

      // Alice should be visible (text widget + semantics may produce multiple),
      // Bob should be completely filtered out of the list.
      expect(find.text('Alice'), findsWidgets);
      expect(find.text('Bob'), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 6 — OfferMessageBubble: Elevation + Status Border
  // ═══════════════════════════════════════════════════════════════════════════
  group('OfferMessageBubble Phase 6 elevation', () {
    testWidgets('renders as StatefulWidget with AnimatedContainer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const OfferMessageBubble(
            title: 'Logo Design',
            description: 'A custom logo',
            price: '50',
            deliveryDays: '3',
            isMine: true,
            time: '12:00',
            status: OfferStatus.pending,
          ),
        ),
      );

      // AnimatedContainer is used for smooth status border transitions
      expect(find.byType(AnimatedContainer), findsOneWidget);
      // The CUSTOM OFFER badge should still render
      expect(find.text('CUSTOM OFFER'), findsOneWidget);
    });

    testWidgets('shows accepted status chip', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const OfferMessageBubble(
            title: 'Logo Design',
            description: 'A custom logo',
            price: '50',
            deliveryDays: '3',
            isMine: true,
            time: '12:00',
            status: OfferStatus.accepted,
          ),
        ),
      );

      expect(find.text('Accepted'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 7 — FullscreenImageViewer: Widget Structure
  // ═══════════════════════════════════════════════════════════════════════════
  group('FullscreenImageViewer', () {
    testWidgets('renders close button and InteractiveViewer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const FullscreenImageViewer(
            imageUrl: 'https://example.com/test.jpg',
          ),
        ),
      );

      // Close button should be present
      expect(find.byIcon(Icons.close), findsOneWidget);
      // InteractiveViewer for pinch-to-zoom
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('shows caption bar when caption is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const FullscreenImageViewer(
            imageUrl: 'https://example.com/test.jpg',
            caption: 'Test caption',
          ),
        ),
      );

      expect(find.text('Test caption'), findsOneWidget);
    });

    testWidgets('has correct Semantics label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const FullscreenImageViewer(
            imageUrl: 'https://example.com/test.jpg',
            caption: 'Delivery proof',
          ),
        ),
      );

      final semantics = find.bySemanticsLabel(
        RegExp('Fullscreen image: Delivery proof'),
      );
      expect(semantics, findsOneWidget);
    });
  });
}
