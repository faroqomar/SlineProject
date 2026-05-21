/// Tests notification badge contrast and count capping in light and dark mode.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';
import 'package:sline_app/features/notifications/services/notification_service.dart';
import 'package:sline_app/features/notifications/view/widgets/notification_badge_button.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/mock_supabase.dart';

class _MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('NotificationBadgeButton', () {
    late _MockNotificationService mockService;
    late StreamController<AuthState> authController;
    late StreamController<List<NotificationItem>> notificationController;

    setUp(() {
      mockService = _MockNotificationService();
      authController = StreamController<AuthState>.broadcast(sync: true);
      notificationController =
          StreamController<List<NotificationItem>>.broadcast(sync: true);
    });

    tearDown(() async {
      await notificationController.close();
      await authController.close();
    });

    testWidgets('uses readable light-mode badge foreground for 9+', (
      tester,
    ) async {
      const colors = AmberDuskTokens.colors;
      final notifications = _unreadNotifications(12);
      final vm = _buildViewModel(
        mockService,
        authController,
        notificationController,
        notifications,
      );
      addTearDown(vm.dispose);

      await _pumpBadge(tester, vm, theme: AppTheme.light());
      authController.add(_signedInAuthState());
      await tester.pump();
      await tester.pump();

      _expectBadgeColors(
        label: '9+',
        expectedBackground: colors.light.dangerMuted,
        expectedForeground: colors.light.text,
        tester: tester,
      );
    });

    testWidgets('uses readable dark-mode badge foreground for single count', (
      tester,
    ) async {
      const colors = AmberDuskTokens.colors;
      final notifications = _unreadNotifications(1);
      final vm = _buildViewModel(
        mockService,
        authController,
        notificationController,
        notifications,
      );
      addTearDown(vm.dispose);

      await _pumpBadge(tester, vm, theme: AppTheme.dark());
      authController.add(_signedInAuthState());
      await tester.pump();
      await tester.pump();

      _expectBadgeColors(
        label: '1',
        expectedBackground: colors.dark.dangerMuted,
        expectedForeground: colors.dark.text,
        tester: tester,
      );
    });
  });
}

NotificationViewModel _buildViewModel(
  _MockNotificationService service,
  StreamController<AuthState> authController,
  StreamController<List<NotificationItem>> notificationController,
  List<NotificationItem> notifications,
) {
  when(
    () => service.getUnreadNotifications(limit: any(named: 'limit')),
  ).thenAnswer((_) async => notifications);
  when(
    () => service.streamNotifications(),
  ).thenAnswer((_) => notificationController.stream);
  return NotificationViewModel(
    service: service,
    authStateChanges: authController.stream,
    client: createMockSupabaseClient(),
  );
}

Future<void> _pumpBadge(
  WidgetTester tester,
  NotificationViewModel viewModel, {
  required ThemeData theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: ChangeNotifierProvider<NotificationViewModel>.value(
            value: viewModel,
            child: const NotificationBadgeButton(),
          ),
        ),
      ),
    ),
  );
}

List<NotificationItem> _unreadNotifications(int count) {
  return List<NotificationItem>.generate(
    count,
    (index) => NotificationItem(
      id: 'n-$index',
      userId: 'user-1',
      title: 'Notification $index',
      message: 'Message $index',
      type: NotificationType.system,
      isRead: false,
      createdAt: DateTime.utc(2026, 5, 13),
    ),
  );
}

void _expectBadgeColors({
  required String label,
  required Color expectedBackground,
  required Color expectedForeground,
  required WidgetTester tester,
}) {
  final text = tester.widget<Text>(find.text(label));
  final badgeContainer = tester.widget<Container>(
    find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
  );
  final decoration = badgeContainer.decoration! as BoxDecoration;

  expect(decoration.color, expectedBackground);
  expect(text.style?.color, expectedForeground);
  expect(
    _contrastRatio(expectedBackground, expectedForeground),
    greaterThanOrEqualTo(4.5),
  );
}

double _contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

AuthState _signedInAuthState() {
  final user = MockUser();
  when(() => user.id).thenReturn('user-1');
  final session = MockSession();
  when(() => session.user).thenReturn(user);
  return AuthState(AuthChangeEvent.signedIn, session);
}
