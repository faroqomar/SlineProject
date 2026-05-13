import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
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
}) {
  return Conversation(
    id: id,
    user1Id: 'user-1',
    user2Id: 'user-2',
    createdAt: DateTime.utc(2026, 5, 1),
    otherUserName: name,
    lastMessage: lastMessage,
    lastMessageSenderId: lastMessageSenderId,
    lastMessageTime: DateTime.utc(2026, 5, 1, 12),
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
  });
}
