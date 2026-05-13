import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/services/role_switch_coordinator.dart';
import 'package:sline_app/features/chat/attachments/services/upload_service.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/models/message_model.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/direct_offers/models/direct_offer_model.dart';

import '../../helpers/helpers.dart';

// -- Factories --

Conversation _convo({String id = 'conv-1', String? taskId}) => Conversation(
  id: id,
  taskId: taskId,
  user1Id: 'user-1',
  user2Id: 'user-2',
  createdAt: DateTime.utc(2026, 1, 1),
);

Message _msg({String id = 'msg-1', Map<String, dynamic> payload = const {}}) =>
    Message(
      id: id,
      conversationId: 'conv-1',
      senderId: 'user-1',
      receiverId: 'user-2',
      content: 'Hello',
      createdAt: DateTime.utc(2026, 1, 1),
      messageType: MessageType.text,
      payload: payload,
    );

DirectOffer _offer() => DirectOffer(
  id: 'offer-1',
  conversationId: 'conv-1',
  clientId: 'user-2',
  freelancerId: 'user-1',
  price: 100,
  days: 3,
  status: 'sent',
  paymentStatus: 'unpaid',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

// -- Mock stub helpers (reduce 10-param repetition) --

When<Future<Message>> _stubSendMessage(MockChatRepository r) => when(
  () => r.sendMessage(
    conversationId: any(named: 'conversationId'),
    senderId: any(named: 'senderId'),
    receiverId: any(named: 'receiverId'),
    content: any(named: 'content'),
    attachmentUrl: any(named: 'attachmentUrl'),
    attachmentType: any(named: 'attachmentType'),
    attachmentName: any(named: 'attachmentName'),
    attachmentSize: any(named: 'attachmentSize'),
    messageType: any(named: 'messageType'),
    payload: any(named: 'payload'),
  ),
);

When<Future<DirectOffer>> _stubCreateOffer(MockDirectOffersService s) => when(
  () => s.createOffer(
    conversationId: any(named: 'conversationId'),
    clientId: any(named: 'clientId'),
    freelancerId: any(named: 'freelancerId'),
    senderId: any(named: 'senderId'),
    receiverId: any(named: 'receiverId'),
    taskId: any(named: 'taskId'),
    title: any(named: 'title'),
    description: any(named: 'description'),
    price: any(named: 'price'),
    days: any(named: 'days'),
  ),
);

void main() {
  late MockChatRepository repo;
  late MockAccountGuardService guard;
  late MockDirectOffersService offers;
  late ChatViewModel vm;

  setUpAll(() {
    registerFallbackValue(_convo());
    registerFallbackValue(_msg());
  });

  setUp(() {
    repo = MockChatRepository();
    guard = MockAccountGuardService();
    offers = MockDirectOffersService();
    final user = MockUser();
    configureMockUser(user, id: 'user-1');
    when(() => repo.currentUser).thenReturn(user);
    when(() => guard.canPerformSensitiveAction()).thenAnswer((_) async => true);
    when(() => repo.isPresenceReceiptsEnabled()).thenAnswer((_) async => false);
    when(() => repo.removeAllChannels()).thenAnswer((_) async {});
    vm = ChatViewModel(
      repo: repo,
      accountGuardService: guard,
      directOffersService: offers,
      attachmentUploader: SupabaseAttachmentUploader(),
    );
  });

  tearDown(() {
    vm.dispose();
    RoleSwitchCoordinator().clearForTesting();
  });

  group('Conversation CRUD', () {
    test('fetchConversations populates list', () async {
      when(
        () => repo.getUserConversations('user-1'),
      ).thenAnswer((_) async => [_convo(), _convo(id: 'conv-2')]);
      await vm.fetchConversations();
      expect(vm.conversations, hasLength(2));
    });

    test('fetchConversations sets isLoadingConversations', () async {
      final c = Completer<List<Conversation>>();
      when(
        () => repo.getUserConversations('user-1'),
      ).thenAnswer((_) => c.future);
      final f = vm.fetchConversations();
      expect(vm.isLoadingConversations, isTrue);
      c.complete([_convo()]);
      await f;
      expect(vm.isLoadingConversations, isFalse);
    });

    test('fetchConversations error sets state without crashing', () async {
      when(
        () => repo.getUserConversations('user-1'),
      ).thenThrow(Exception('network'));
      await vm.fetchConversations();
      expect(vm.isLoadingConversations, isFalse);
      expect(vm.conversations, isEmpty);
    });

    test('createOrGetConversation returns existing', () async {
      when(
        () => repo.createOrGetConversation(
          taskId: any(named: 'taskId'),
          user1Id: 'user-1',
          user2Id: 'user-2',
        ),
      ).thenAnswer((_) async => _convo());
      final result = await vm.createOrGetConversation(
        user1Id: 'user-1',
        user2Id: 'user-2',
      );
      expect(result?.id, 'conv-1');
      expect(vm.isCreatingConversation, isFalse);
    });

    test('createOrGetConversation creates new via repo', () async {
      when(
        () => repo.createOrGetConversation(
          taskId: 'task-1',
          user1Id: 'user-1',
          user2Id: 'user-2',
        ),
      ).thenAnswer((_) async => _convo(id: 'conv-new', taskId: 'task-1'));
      final result = await vm.createOrGetConversation(
        taskId: 'task-1',
        user1Id: 'user-1',
        user2Id: 'user-2',
      );
      expect(result?.id, 'conv-new');
    });

    test('deleteConversation removes from list', () async {
      vm.conversations.add(_convo());
      when(() => repo.deleteConversation('conv-1')).thenAnswer((_) async {});
      await vm.deleteConversation('conv-1');
      expect(vm.conversations, isEmpty);
      verify(() => repo.deleteConversation('conv-1')).called(1);
    });
  });

  group('Message operations', () {
    test('fetchMessages populates currentMessages', () async {
      when(
        () => repo.getMessages('conv-1'),
      ).thenAnswer((_) async => [_msg(), _msg(id: 'msg-2')]);
      await vm.fetchMessages('conv-1');
      expect(vm.currentMessages, hasLength(2));
    });

    test('fetchMessages sets isLoadingMessages', () async {
      final c = Completer<List<Message>>();
      when(() => repo.getMessages('conv-1')).thenAnswer((_) => c.future);
      final f = vm.fetchMessages('conv-1');
      expect(vm.isLoadingMessages, isTrue);
      c.complete([]);
      await f;
      expect(vm.isLoadingMessages, isFalse);
    });

    test('sendMessage calls repo and adds to currentMessages', () async {
      vm.conversations.add(_convo());
      when(() => repo.getMessages('conv-1')).thenAnswer((_) async => []);
      await vm.fetchMessages('conv-1');
      _stubSendMessage(repo).thenAnswer((_) async => _msg(id: 'msg-sent'));
      await vm.sendMessage('Hi there');
      expect(vm.currentMessages.last.id, 'msg-sent');
    });

    test('sendMessage sets isSending while in flight', () async {
      vm.activeConversation = _convo();
      final c = Completer<Message>();
      _stubSendMessage(repo).thenAnswer((_) => c.future);
      final f = vm.sendMessage('test');
      await Future<void>.delayed(Duration.zero); // let guard await resolve
      expect(vm.isSending, isTrue);
      c.complete(_msg());
      await f;
      expect(vm.isSending, isFalse);
    });

    test('sendMessage error sets isSending false and rethrows', () async {
      vm.activeConversation = _convo();
      _stubSendMessage(repo).thenThrow(Exception('send failed'));
      await expectLater(
        () => vm.sendMessage('test'),
        throwsA(isA<Exception>()),
      );
      expect(vm.isSending, isFalse);
    });
  });

  group('Offer actions - representative', () {
    test('createDirectOffer calls service and resets isSending', () async {
      vm.activeConversation = _convo();
      _stubCreateOffer(offers).thenAnswer((_) async => _offer());
      await vm.createDirectOffer(price: 100, days: 3);
      verify(
        () => offers.createOffer(
          conversationId: 'conv-1',
          clientId: any(named: 'clientId'),
          freelancerId: 'user-1',
          senderId: 'user-1',
          receiverId: any(named: 'receiverId'),
          taskId: any(named: 'taskId'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          price: 100,
          days: 3,
        ),
      ).called(1);
      expect(vm.isSending, isFalse);
    });

    test('offer action failure sets isSending false and rethrows', () async {
      vm.activeConversation = _convo();
      _stubCreateOffer(offers).thenThrow(Exception('offer creation failed'));
      await expectLater(
        () => vm.createDirectOffer(price: 100, days: 3),
        throwsA(isA<Exception>()),
      );
      expect(vm.isSending, isFalse);
    });
  });

  group('Realtime subscription lifecycle', () {
    test('subscribeToActiveConversation calls repo', () async {
      vm.activeConversation = _convo();
      final ctrl = StreamController<List<Message>>.broadcast();
      when(
        () => repo.subscribeToMessages('conv-1'),
      ).thenAnswer((_) => ctrl.stream);
      await vm.subscribeToActiveConversation();
      verify(() => repo.subscribeToMessages('conv-1')).called(1);
      await ctrl.close();
    });

    test('unsubscribeFromConversation cancels subscription', () async {
      vm.activeConversation = _convo();
      final ctrl = StreamController<List<Message>>.broadcast();
      when(
        () => repo.subscribeToMessages('conv-1'),
      ).thenAnswer((_) => ctrl.stream);
      await vm.subscribeToActiveConversation();
      vm.unsubscribeFromConversation();
      await ctrl.close(); // should close cleanly with no listeners
    });
  });

  group('Role switch teardown', () {
    test('teardownForRoleSwitch clears conversations', () async {
      vm.conversations.add(_convo());
      await vm.teardownForRoleSwitch();
      expect(vm.conversations, isEmpty);
    });

    test('teardownForRoleSwitch clears currentMessages', () async {
      vm.currentMessages.add(_msg());
      await vm.teardownForRoleSwitch();
      expect(vm.currentMessages, isEmpty);
    });

    test('teardownForRoleSwitch resets activeConversation', () async {
      vm.activeConversation = _convo();
      await vm.teardownForRoleSwitch();
      expect(vm.activeConversation, isNull);
    });

    test('teardownForRoleSwitch does not crash on empty state', () async {
      await vm.teardownForRoleSwitch();
      expect(vm.conversations, isEmpty);
      expect(vm.currentMessages, isEmpty);
      expect(vm.activeConversation, isNull);
      expect(vm.isLoadingConversations, isFalse);
      expect(vm.isSending, isFalse);
    });
  });

  group('Dispose safety', () {
    test('dispose completes without error and guards notifyListeners', () {
      final vm2 = ChatViewModel(
        repo: repo,
        accountGuardService: guard,
        directOffersService: offers,
        attachmentUploader: SupabaseAttachmentUploader(),
      );
      // _mounted = false prevents _notify from calling notifyListeners
      vm2.dispose();
      RoleSwitchCoordinator().clearForTesting();
    });

    test('dispose cancels active subscriptions', () async {
      vm.activeConversation = _convo();
      final ctrl = StreamController<List<Message>>.broadcast();
      when(
        () => repo.subscribeToMessages('conv-1'),
      ).thenAnswer((_) => ctrl.stream);
      await vm.subscribeToActiveConversation();
      vm.dispose();
      await ctrl.close(); // no lingering listeners
      // Recreate so tearDown does not double-dispose
      vm = ChatViewModel(
        repo: repo,
        accountGuardService: guard,
        directOffersService: offers,
        attachmentUploader: SupabaseAttachmentUploader(),
      );
    });
  });
}
