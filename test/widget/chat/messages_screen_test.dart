import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/view/messages_screen.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';

import '../../test_support/pump_app.dart';

class _MockChatViewModel extends Mock
    with ChangeNotifier
    implements ChatViewModel {}

Conversation _conversation({
  required String id,
  required String name,
  required String lastMessage,
  String? lastMessageSenderId,
  String? taskTitle,
  String? taskType,
}) {
  return Conversation(
    id: id,
    user1Id: 'user-1',
    user2Id: 'user-2',
    createdAt: DateTime.utc(2026, 5),
    otherUserName: name,
    lastMessage: lastMessage,
    lastMessageSenderId: lastMessageSenderId,
    lastMessageTime: DateTime.utc(2026, 5, 1, 12),
    taskTitle: taskTitle,
    taskType: taskType,
  );
}

Future<void> _pumpMessagesScreen(
  WidgetTester tester,
  _MockChatViewModel vm, {
  required List<Conversation> conversations,
  bool isLoadingConversations = false,
}) async {
  when(() => vm.conversations).thenReturn(conversations);
  when(() => vm.isLoadingConversations).thenReturn(isLoadingConversations);
  when(() => vm.currentUserId).thenReturn('user-1');
  when(vm.fetchConversations).thenAnswer((_) async {});
  when(vm.subscribeToUserConversations).thenReturn(null);
  when(vm.unsubscribeFromUserConversations).thenReturn(null);
  when(vm.unsubscribeFromConversation).thenReturn(null);

  await pumpApp(
    tester,
    ChangeNotifierProvider<ChatViewModel>.value(
      value: vm,
      child: const MessagesScreen(),
    ),
  );
}

void main() {
  group('MessagesScreen', () {
    testWidgets('shows empty state when no conversations', (tester) async {
      final vm = _MockChatViewModel();
      await _pumpMessagesScreen(tester, vm, conversations: const []);

      expect(
        find.byKey(const ValueKey('message_list_empty_state')),
        findsOneWidget,
      );
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('shows loading skeletons when loading', (tester) async {
      final vm = _MockChatViewModel();
      await _pumpMessagesScreen(
        tester,
        vm,
        conversations: const [],
        isLoadingConversations: true,
      );

      expect(find.text('Messages'), findsOneWidget);
    });

    testWidgets(
      'mode toggle keeps all conversations visible without a direction contract',
      (tester) async {
        final vm = _MockChatViewModel();
        await _pumpMessagesScreen(
          tester,
          vm,
          conversations: [
            _conversation(
              id: 'from-me',
              name: 'Sent Thread',
              lastMessage: 'I replied',
              lastMessageSenderId: 'user-1',
            ),
            _conversation(
              id: 'from-them',
              name: 'Response Thread',
              lastMessage: 'They replied',
              lastMessageSenderId: 'user-2',
            ),
          ],
        );

        expect(find.text('Sent Thread'), findsOneWidget);
        expect(find.text('Response Thread'), findsOneWidget);

        await tester.tap(find.text('Sent'));
        await tester.pumpAndSettle();

        expect(find.text('Sent Thread'), findsOneWidget);
        expect(find.text('Response Thread'), findsOneWidget);
      },
    );

    testWidgets('uses corrected Received and Sent mode copy', (tester) async {
      final vm = _MockChatViewModel();
      await _pumpMessagesScreen(
        tester,
        vm,
        conversations: [
          _conversation(
            id: 'thread',
            name: 'Yara',
            lastMessage: 'Ready to start',
          ),
        ],
      );

      expect(find.text('Received'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);
      expect(find.text('Responses'), findsNothing);
      expect(find.text('Requests'), findsNothing);
    });

    testWidgets('search filters conversations by participant and message', (
      tester,
    ) async {
      final vm = _MockChatViewModel();
      await _pumpMessagesScreen(
        tester,
        vm,
        conversations: [
          _conversation(
            id: 'design',
            name: 'Yara Designer',
            lastMessage: 'Prototype is ready',
          ),
          _conversation(
            id: 'finance',
            name: 'Omar Finance',
            lastMessage: 'Invoice sent',
          ),
        ],
      );

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'prototype');
      // Wait past the MessagesScreen search debounce after typing in the
      // search TextField so the filtered conversation list has rebuilt.
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Yara Designer'), findsOneWidget);
      expect(find.text('Omar Finance'), findsNothing);
    });

    testWidgets('conversation list clears floating bottom navigation', (
      tester,
    ) async {
      final vm = _MockChatViewModel();
      await _pumpMessagesScreen(
        tester,
        vm,
        conversations: [
          _conversation(
            id: 'last-visible',
            name: 'Zahraa Firas',
            lastMessage: 'Ready',
          ),
        ],
      );

      final paddingWidgets = tester.widgetList<SliverPadding>(
        find.byType(SliverPadding),
      );
      final conversationListPadding = paddingWidgets
          .map((widget) => widget.padding)
          .whereType<EdgeInsets>()
          .firstWhere(
            (padding) =>
                padding.left ==
                AmberDuskTokens.spacing.contentHorizontalPadding,
          );

      // The inbox lives behind the app shell Stack, so its scrollable content
      // must reserve the floating nav band even when the test safe area is 0.
      expect(
        conversationListPadding.bottom,
        equals(
          AmberDuskTokens.phoneLayout.bottomNavBottom +
              AmberDuskTokens.phoneLayout.bottomNavHeight +
              AppLayout.spacingScreen,
        ),
      );
    });

    testWidgets('empty linked task rows explain the context', (tester) async {
      final vm = _MockChatViewModel();
      await _pumpMessagesScreen(
        tester,
        vm,
        conversations: [
          _conversation(
            id: 'task-empty',
            name: 'Test One',
            lastMessage: '',
            taskTitle: 'i will market your campaign',
          ),
        ],
      );

      expect(find.text('Linked task - no messages yet'), findsOneWidget);
      expect(find.text('No messages yet'), findsNothing);
    });

    testWidgets('read conversation rows use quiet blended surfaces', (
      tester,
    ) async {
      final vm = _MockChatViewModel();
      await _pumpMessagesScreen(
        tester,
        vm,
        conversations: [
          _conversation(
            id: 'read-thread',
            name: 'Eros Gray',
            lastMessage: 'hi',
            taskTitle: 'Outdoor Personal Photo Session',
          ),
        ],
      );

      final quietSurface = AmberDuskTokens.colors.surface.withValues(
        alpha: 0.46,
      );
      final quietConversationCards = tester
          .widgetList<Container>(find.byType(Container))
          .where((container) {
            final decoration = container.decoration;
            return decoration is BoxDecoration &&
                decoration.color == quietSurface;
          });

      // Read rows should blend with the inbox canvas instead of using the full
      // card surface, which made the message list look like stacked blocks.
      expect(quietConversationCards, isNotEmpty);
    });
  });
}
