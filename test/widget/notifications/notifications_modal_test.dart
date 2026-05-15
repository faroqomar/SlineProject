/// Tests notification modal states with mocked notification authority.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';
import 'package:sline_app/features/notifications/services/notification_service.dart';
import 'package:sline_app/features/notifications/view/notifications_modal.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/mock_supabase.dart';

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
        client: createMockSupabaseClient(),
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
      expect(find.text('No new notifications'), findsOneWidget);
    });

    testWidgets('modal has stable key', (tester) async {
      final vm = NotificationViewModel(
        service: mockService,
        authStateChanges: authController.stream,
        client: createMockSupabaseClient(),
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

    testWidgets('notification list reserves bottom safe-area padding', (
      tester,
    ) async {
      final notificationStream =
          StreamController<List<NotificationItem>>.broadcast();
      addTearDown(notificationStream.close);
      final notifications = List<NotificationItem>.generate(
        8,
        (index) => _notification(id: 'safe-$index', isRead: index.isEven),
      );
      when(
        () => mockService.getUnreadNotifications(limit: any(named: 'limit')),
      ).thenAnswer((_) async => notifications);
      when(
        () => mockService.streamNotifications(),
      ).thenAnswer((_) => notificationStream.stream);

      final vm = NotificationViewModel(
        service: mockService,
        authStateChanges: authController.stream,
        client: createMockSupabaseClient(),
      );
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: 34),
            viewPadding: EdgeInsets.only(bottom: 34),
          ),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: ChangeNotifierProvider<NotificationViewModel>.value(
                value: vm,
                child: const NotificationsModal(),
              ),
            ),
          ),
        ),
      );

      authController.add(_signedInAuthState());
      await tester.pump();
      await tester.pump();

      expect(find.byKey(NotificationsModalKeys.list), findsOneWidget);
      final listView = tester.widget<ListView>(
        find.byKey(NotificationsModalKeys.list),
      );
      final padding = listView.padding! as EdgeInsets;
      expect(padding.bottom, greaterThan(34));
      expect(find.text('Unread'), findsWidgets);
    });

    testWidgets('shows Amber Dusk skeleton loading state after auth connects', (
      tester,
    ) async {
      final unreadCompleter = Completer<List<NotificationItem>>();
      final notificationStream =
          StreamController<List<NotificationItem>>.broadcast();
      addTearDown(notificationStream.close);
      when(
        () => mockService.getUnreadNotifications(limit: any(named: 'limit')),
      ).thenAnswer((_) => unreadCompleter.future);
      when(
        () => mockService.streamNotifications(),
      ).thenAnswer((_) => notificationStream.stream);

      final vm = NotificationViewModel(
        service: mockService,
        authStateChanges: authController.stream,
        client: createMockSupabaseClient(),
      );
      addTearDown(vm.dispose);

      await _pumpModal(tester, vm);

      // The injected auth stream is the only way this widget test starts the
      // production foreground-sync path without initializing Supabase.
      authController.add(_signedInAuthState());
      await tester.pump();
      await tester.pump();

      expect(find.byKey(NotificationsModalKeys.loading), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      unreadCompleter.complete([]);
      await tester.pump();
    });

    testWidgets('shows error state and keeps retry action label', (
      tester,
    ) async {
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
        client: createMockSupabaseClient(),
      );
      addTearDown(vm.dispose);

      await _pumpModal(tester, vm);
      authController.add(_signedInAuthState());
      await tester.pump();
      await tester.pump();

      notificationStream.addError(Exception('fatal'), StackTrace.current);
      await tester.pump();

      expect(find.byKey(NotificationsModalKeys.error), findsOneWidget);
      expect(find.text('Failed to load notifications'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(find.byKey(NotificationsModalKeys.error), findsNothing);
    });

    testWidgets(
      'mark all action preserves label and calls view model service',
      (tester) async {
        final vm = NotificationViewModel(
          service: mockService,
          authStateChanges: authController.stream,
          client: createMockSupabaseClient(),
        );
        addTearDown(vm.dispose);

        await _pumpModal(tester, vm);
        await tester.tap(find.text('Mark all as read'));
        await tester.pump();

        verify(() => mockService.markAllAsRead()).called(1);
        expect(find.text('All marked as read'), findsOneWidget);
      },
    );

    testWidgets('mark all failure keeps user-safe snackbar', (tester) async {
      when(
        () => mockService.markAllAsRead(),
      ).thenThrow(Exception('write failed'));
      final vm = NotificationViewModel(
        service: mockService,
        authStateChanges: authController.stream,
        client: createMockSupabaseClient(),
      );
      addTearDown(vm.dispose);

      await _pumpModal(tester, vm);
      await tester.tap(find.text('Mark all as read'));
      await tester.pump();

      verify(() => mockService.markAllAsRead()).called(1);
      expect(find.text('All marked as read'), findsNothing);
      expect(
        find.text('Could not mark notifications as read. Please try again.'),
        findsOneWidget,
      );
    });
  });
}

NotificationItem _notification({required String id, required bool isRead}) {
  return NotificationItem(
    id: id,
    userId: 'user-1',
    title: 'Booking Updated',
    message: 'Booking status changed.',
    type: NotificationType.booking,
    isRead: isRead,
    createdAt: DateTime.utc(2026, 5, 15, 12),
  );
}

Future<void> _pumpModal(
  WidgetTester tester,
  NotificationViewModel viewModel,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: ChangeNotifierProvider<NotificationViewModel>.value(
          value: viewModel,
          child: const NotificationsModal(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AuthState _signedInAuthState() {
  final user = MockUser();
  when(() => user.id).thenReturn('user-1');
  final session = MockSession();
  when(() => session.user).thenReturn(user);
  return AuthState(AuthChangeEvent.signedIn, session);
}
