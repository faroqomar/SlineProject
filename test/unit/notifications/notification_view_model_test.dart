import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sline_app/features/notifications/services/notification_service.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';

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
      expect(() => vm.retry(), returnsNormally);
    });
  });
}
