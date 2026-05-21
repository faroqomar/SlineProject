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

Conversation _conversationFixture({
  String? taskId,
  String? taskTitle,
}) {
  return Conversation(
    id: 'convo-1',
    user1Id: 'user-1',
    user2Id: 'user-2',
    createdAt: DateTime.utc(2026, 2, 24, 10),
    otherUserName: 'Other User',
    taskId: taskId,
    taskTitle: taskTitle,
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
  Conversation? conversation,
}) async {
  when(() => vm.currentUserId).thenReturn('user-1');
  when(() => vm.currentMessages).thenReturn(messages);
  when(() => vm.isSending).thenReturn(false);
  when(() => vm.otherUserTyping).thenReturn(false);
  when(() => vm.isPresenceReceiptsEnabled).thenReturn(false);
  when(() => vm.isLoadingMessages).thenReturn(false);
  when(() => vm.setTyping(isTyping: any(named: 'isTyping'))).thenAnswer(
    (_) async {},
  );
  when(() => vm.sendMessage(any())).thenAnswer((_) async {});

  await pumpApp(
    tester,
    ChangeNotifierProvider<ChatViewModel>.value(
      value: vm,
      child: ChatScreen(
        conversation: conversation ?? _conversationFixture(),
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
      await tester.pumpAndSettle();

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

      await tester.pumpAndSettle();

      expect(find.byType(AttachmentMessageTile), findsOneWidget);
      expect(find.text('Reference image'), findsOneWidget);
      expect(
        resolvedPaths,
        equals(['chat-attachments/convos/convo-1/image.jpg']),
      );
    });

    testWidgets('reserves context banner space above date separator', (
      tester,
    ) async {
      final vm = _MockChatViewModel();
      final message = Message(
        id: 'msg-context-1',
        conversationId: 'convo-1',
        senderId: 'user-2',
        receiverId: 'user-1',
        content: 'Hi, I am testing the booking flow.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)).toUtc(),
        messageType: MessageType.text,
        payload: const {},
      );

      await _pumpChatScreen(
        tester,
        vm,
        messages: [message],
        conversation: _conversationFixture(
          taskId: 'task-1',
          taskTitle: 'i will market your campaign with a long title',
        ),
      );
      await tester.pumpAndSettle();

      final contextBottom = tester
          .getBottomLeft(
            find.text('i will market your campaign with a long title'),
          )
          .dy;
      final dateTop = tester.getTopLeft(find.text('Yesterday').first).dy;

      // The linked-task context must participate in layout, leaving rhythm
      // space before the list begins so date pills and messages cannot overlap.
      expect(contextBottom, lessThan(dateTop));
    });

    testWidgets(
      'report conversation dialog names target and validates reason',
      (
        tester,
      ) async {
        final vm = _MockChatViewModel();

        await _pumpChatScreen(
          tester,
          vm,
          messages: const [],
          conversation: _conversationFixture(taskTitle: 'Linked task'),
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Report conversation'));
        await tester.pumpAndSettle();

        expect(find.text('Report Conversation'), findsOneWidget);
        expect(find.text('Conversation with Other User'), findsOneWidget);
        expect(
          find.text('Tell us what happened in this thread.'),
          findsOneWidget,
        );

        final emptySubmit = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Submit'),
        );
        expect(emptySubmit.onPressed, isNull);

        await tester.enterText(
          find.byType(TextField).last,
          'Spam and harassment',
        );
        await tester.pump();

        final filledSubmit = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Submit'),
        );
        expect(filledSubmit.onPressed, isNotNull);
      },
    );

    testWidgets('report user dialog makes the reported account clear', (
      tester,
    ) async {
      final vm = _MockChatViewModel();

      await _pumpChatScreen(tester, vm, messages: const []);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Report user'), findsOneWidget);
      expect(find.text('Other User'), findsWidgets);

      await tester.tap(find.text('Report user'));
      await tester.pumpAndSettle();

      expect(find.text('Report User'), findsOneWidget);
      expect(find.text('Other User'), findsWidgets);
      expect(find.text('Tell us what this account did.'), findsOneWidget);

      final emptySubmit = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit'),
      );
      expect(emptySubmit.onPressed, isNull);
    });
  });
}
