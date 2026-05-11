import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/features/notifications/services/notification_service.dart';
import 'package:sline_app/features/notifications/view/notifications_modal.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('NotificationsModal', () {
    late _MockNotificationService mockService;
    late StreamController<AuthState> authController;

    setUp(() {
      mockService = _MockNotificationService();
      when(
        () => mockService.streamNotifications(),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockService.markAsRead(any())).thenAnswer((_) async {});
      when(() => mockService.markAllAsRead()).thenAnswer((_) async {});
      authController = StreamController<AuthState>.broadcast(sync: true);
    });

    tearDown(() async {
      await authController.close();
    });

    testWidgets('shows empty state when no notifications', (tester) async {
      final vm = NotificationViewModel(
        service: mockService,
        authStateChanges: authController.stream,
      );
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: ChangeNotifierProvider<NotificationViewModel>.value(
            value: vm,
            child: const NotificationsModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(NotificationsModalKeys.empty), findsOneWidget);
      expect(find.text("You're all caught up!"), findsOneWidget);
    });

    testWidgets('modal has stable key', (tester) async {
      final vm = NotificationViewModel(
        service: mockService,
        authStateChanges: authController.stream,
      );
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: ChangeNotifierProvider<NotificationViewModel>.value(
            value: vm,
            child: const NotificationsModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(NotificationsModalKeys.modal), findsOneWidget);
    });
  });
}
