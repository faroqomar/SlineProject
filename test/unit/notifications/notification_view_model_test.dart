import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';
import 'package:sline_app/features/notifications/services/notification_service.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/mock_supabase.dart';

class _MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('NotificationViewModel', () {
    late _MockNotificationService mockService;
    late StreamController<AuthState> authController;

    setUp(() {
      mockService = _MockNotificationService();
      authController = StreamController<AuthState>.broadcast(sync: true);
    });

    tearDown(() async {
      await authController.close();
    });

    test('initial state when no session', () {
      when(
        () => mockService.streamNotifications(),
      ).thenAnswer((_) => Stream.value([]));
      final vm = NotificationViewModel(
        service: mockService,
        authStateChanges: authController.stream,
      );
      addTearDown(vm.dispose);
      expect(vm.notifications, isEmpty);
      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
      expect(vm.unreadCount, 0);
    });

    test('markAsRead calls service and notifies', () async {
      when(
        () => mockService.streamNotifications(),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockService.markAsRead(any())).thenAnswer((_) async {});
      final vm = NotificationViewModel(
        service: mockService,
        authStateChanges: authController.stream,
      );
      addTearDown(vm.dispose);

      await vm.markAsRead('n-1');

      verify(() => mockService.markAsRead('n-1')).called(1);
    });

    test('markAllAsRead calls service', () async {
      when(
        () => mockService.streamNotifications(),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockService.markAllAsRead()).thenAnswer((_) async {});
      final vm = NotificationViewModel(
        service: mockService,
        authStateChanges: authController.stream,
      );
      addTearDown(vm.dispose);

      final didMarkAllRead = await vm.markAllAsRead();

      expect(didMarkAllRead, isTrue);
      verify(() => mockService.markAllAsRead()).called(1);
    });

    test(
      'markAllAsRead returns false and sets safe error on failure',
      () async {
        when(
          () => mockService.streamNotifications(),
        ).thenAnswer((_) => Stream.value([]));
        when(
          () => mockService.markAllAsRead(),
        ).thenThrow(Exception('write failed'));
        final vm = NotificationViewModel(
          service: mockService,
          authStateChanges: authController.stream,
        );
        addTearDown(vm.dispose);

        final didMarkAllRead = await vm.markAllAsRead();

        expect(didMarkAllRead, isFalse);
        expect(vm.error, 'Failed to mark all as read');
        verify(() => mockService.markAllAsRead()).called(1);
      },
    );

    test('retry does not throw when Supabase not initialized', () {
      when(
        () => mockService.streamNotifications(),
      ).thenAnswer((_) => Stream.value([]));
      final vm = NotificationViewModel(
        service: mockService,
        authStateChanges: authController.stream,
      );
      addTearDown(vm.dispose);
      expect(vm.retry, returnsNormally);
    });

    test(
      'userDeleted auth event disconnects and clears notifications',
      () async {
        final notificationStream =
            StreamController<List<NotificationItem>>.broadcast();
        addTearDown(notificationStream.close);
        when(
          () => mockService.getUnreadNotifications(limit: any(named: 'limit')),
        ).thenAnswer((_) async => []);
        when(
          () => mockService.streamNotifications(),
        ).thenAnswer((_) => notificationStream.stream);

        final vm = NotificationViewModel(
          service: mockService,
          authStateChanges: authController.stream,
        );
        addTearDown(vm.dispose);

        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('user-1');
        final mockSession = MockSession();
        when(() => mockSession.user).thenReturn(mockUser);

        authController.add(AuthState(AuthChangeEvent.signedIn, mockSession));
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        notificationStream.add([
          NotificationItem(
            id: 'n-1',
            userId: 'user-1',
            title: 'Notification',
            message: 'Message',
            type: NotificationType.system,
            isRead: false,
            createdAt: DateTime.utc(2026),
          ),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(vm.notifications, hasLength(1));

        authController.add(
          AuthState(AuthChangeEvent.values.byName('userDeleted'), null),
        );
        await Future<void>.delayed(Duration.zero);

        expect(vm.notifications, isEmpty);
        expect(vm.isLoading, isFalse);

        notificationStream.add([
          NotificationItem(
            id: 'n-2',
            userId: 'user-1',
            title: 'Late notification',
            message: 'Should not be received',
            type: NotificationType.system,
            isRead: false,
            createdAt: DateTime.utc(2026),
          ),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(vm.notifications, isEmpty);
      },
    );

    test(
      'transient realtime close keeps notifications and reconnects',
      () async {
        final firstStream =
            StreamController<List<NotificationItem>>.broadcast();
        final secondStream =
            StreamController<List<NotificationItem>>.broadcast();
        addTearDown(firstStream.close);
        addTearDown(secondStream.close);

        var streamCallCount = 0;
        when(
          () => mockService.getUnreadNotifications(limit: any(named: 'limit')),
        ).thenAnswer((_) async => []);
        when(() => mockService.streamNotifications()).thenAnswer((_) {
          streamCallCount++;
          return streamCallCount == 1
              ? firstStream.stream
              : secondStream.stream;
        });

        final vm = NotificationViewModel(
          service: mockService,
          authStateChanges: authController.stream,
          realtimeReconnectBaseDelay: Duration.zero,
        );
        addTearDown(vm.dispose);

        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('user-1');
        final mockSession = MockSession();
        when(() => mockSession.user).thenReturn(mockUser);

        authController.add(AuthState(AuthChangeEvent.signedIn, mockSession));
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        firstStream.add([
          NotificationItem(
            id: 'n-1',
            userId: 'user-1',
            title: 'Notification',
            message: 'Message',
            type: NotificationType.system,
            isRead: false,
            createdAt: DateTime.utc(2026),
          ),
        ]);
        await Future<void>.delayed(Duration.zero);

        firstStream.addError(
          RealtimeSubscribeException(
            RealtimeSubscribeStatus.channelError,
            const RealtimeCloseEvent(code: 1006, reason: ''),
          ),
          StackTrace.current,
        );
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(vm.error, isNull);
        expect(vm.notifications, hasLength(1));
        expect(streamCallCount, 2);
      },
    );

    test('non-realtime stream error sets user-facing error', () async {
      final notificationStream =
          StreamController<List<NotificationItem>>.broadcast();
      addTearDown(notificationStream.close);
      when(
        () => mockService.getUnreadNotifications(limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);
      when(
        () => mockService.streamNotifications(),
      ).thenAnswer((_) => notificationStream.stream);

      final vm = NotificationViewModel(
        service: mockService,
        authStateChanges: authController.stream,
      );
      addTearDown(vm.dispose);

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');
      final mockSession = MockSession();
      when(() => mockSession.user).thenReturn(mockUser);

      authController.add(AuthState(AuthChangeEvent.signedIn, mockSession));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      notificationStream.addError(Exception('fatal'), StackTrace.current);
      await Future<void>.delayed(Duration.zero);

      expect(vm.error, 'Failed to load notifications');
    });
  });
}
