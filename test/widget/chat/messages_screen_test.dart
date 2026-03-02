import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/chat/view/messages_screen.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';

import '../../test_support/pump_app.dart';

class _MockChatViewModel extends Mock
    with ChangeNotifier
    implements ChatViewModel {}

void main() {
  group('MessagesScreen', () {
    testWidgets('shows empty state when no conversations', (tester) async {
      final vm = _MockChatViewModel();
      when(() => vm.conversations).thenReturn([]);
      when(() => vm.isLoadingConversations).thenReturn(false);
      when(() => vm.currentUserId).thenReturn('user-1');
      when(() => vm.fetchConversations()).thenAnswer((_) async {});
      when(() => vm.subscribeToUserConversations()).thenReturn(null);
      when(() => vm.unsubscribeFromUserConversations()).thenReturn(null);
      when(() => vm.unsubscribeFromConversation()).thenReturn(null);

      await pumpApp(
        tester,
        ChangeNotifierProvider<ChatViewModel>.value(
          value: vm,
          child: const MessagesScreen(),
        ),
      );

      expect(
        find.byKey(const ValueKey('message_list_empty_state')),
        findsOneWidget,
      );
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('shows loading skeletons when loading', (tester) async {
      final vm = _MockChatViewModel();
      when(() => vm.conversations).thenReturn([]);
      when(() => vm.isLoadingConversations).thenReturn(true);
      when(() => vm.currentUserId).thenReturn('user-1');
      when(() => vm.fetchConversations()).thenAnswer((_) async {});
      when(() => vm.subscribeToUserConversations()).thenReturn(null);
      when(() => vm.unsubscribeFromUserConversations()).thenReturn(null);
      when(() => vm.unsubscribeFromConversation()).thenReturn(null);

      await pumpApp(
        tester,
        ChangeNotifierProvider<ChatViewModel>.value(
          value: vm,
          child: const MessagesScreen(),
        ),
      );

      expect(find.text('Messages'), findsOneWidget);
    });
  });
}
