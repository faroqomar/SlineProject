import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/chat/attachments/widgets/attachment_message_tile.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/models/message_model.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/chat/view/widgets/offer_message_bubble.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';

import '../../test_support/pump_app.dart';

class _MockChatViewModel extends Mock
    with ChangeNotifier
    implements ChatViewModel {}

Conversation _conversationFixture() {
  return Conversation(
    id: 'convo-1',
    taskId: null,
    user1Id: 'user-1',
    user2Id: 'user-2',
    createdAt: DateTime.utc(2026, 2, 24, 10),
    otherUserName: 'Other User',
  );
}

Message _offerMessageFixture() {
  return Message(
    id: 'msg-offer-1',
    conversationId: 'convo-1',
    senderId: 'user-2',
    receiverId: 'user-1',
    content: 'Offer: Logo package',
    createdAt: DateTime.utc(2026, 2, 24, 10, 5),
    messageType: MessageType.offer,
    payload: const {
      'title': 'Logo package',
      'description': 'Three logo concepts',
      'price': 120,
      'delivery': 3,
      'status': 'pending',
    },
  );
}

Message _imageMessageFixture() {
  return Message(
    id: 'msg-image-1',
    conversationId: 'convo-1',
    senderId: 'user-2',
    receiverId: 'user-1',
    content: 'Reference image',
    createdAt: DateTime.utc(2026, 2, 24, 10, 10),
    attachmentUrl: 'chat-attachments/convos/convo-1/image.jpg',
    attachmentType: 'image',
    messageType: MessageType.text,
    payload: const {},
  );
}

Future<void> _pumpChatScreen(
  WidgetTester tester,
  _MockChatViewModel vm, {
  required List<Message> messages,
  AttachmentSignedUrlResolver? resolver,
}) async {
  when(() => vm.currentUserId).thenReturn('user-1');
  when(() => vm.currentMessages).thenReturn(messages);
  when(() => vm.sendMessage(any())).thenAnswer((_) async {});

  await pumpApp(
    tester,
    ChangeNotifierProvider<ChatViewModel>.value(
      value: vm,
      child: ChatScreen(
        conversation: _conversationFixture(),
        enableLifecycleEffects: false,
        attachmentSignedUrlResolver: resolver,
      ),
    ),
  );
}

void main() {
  group('ChatScreen T59-T61', () {
    testWidgets('T61 sending text triggers sendMessage call', (tester) async {
      final vm = _MockChatViewModel();

      await _pumpChatScreen(tester, vm, messages: const []);

      await tester.enterText(
        find.byKey(ChatScreen.messageInputKey),
        '  hello  ',
      );
      await tester.tap(find.byKey(ChatScreen.sendButtonKey));
      await tester.pump();

      verify(() => vm.sendMessage('hello')).called(1);
      final textField = tester.widget<TextField>(
        find.byKey(ChatScreen.messageInputKey),
      );
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('T59 renders offer bubble when messageType equals offer', (
      tester,
    ) async {
      final vm = _MockChatViewModel();

      await _pumpChatScreen(tester, vm, messages: [_offerMessageFixture()]);

      expect(find.byType(OfferMessageBubble), findsOneWidget);
      expect(find.text('Logo package'), findsOneWidget);
    });

    testWidgets('T60 renders attachment tile for image messages', (
      tester,
    ) async {
      final vm = _MockChatViewModel();
      final resolvedPaths = <String>[];

      await _pumpChatScreen(
        tester,
        vm,
        messages: [_imageMessageFixture()],
        resolver: (path) async {
          resolvedPaths.add(path);
          return '';
        },
      );

      await tester.pump();

      expect(find.byType(AttachmentMessageTile), findsOneWidget);
      expect(find.text('Reference image'), findsOneWidget);
      expect(
        resolvedPaths,
        equals(['chat-attachments/convos/convo-1/image.jpg']),
      );
    });
  });
}
