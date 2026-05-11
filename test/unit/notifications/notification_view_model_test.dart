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

      await vm.markAllAsRead();

      verify(() => mockService.markAllAsRead()).called(1);
    });

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
  });
}
