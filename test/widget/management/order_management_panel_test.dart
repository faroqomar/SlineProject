import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/management/models/work_log_model.dart';
import 'package:sline_app/features/management/models/work_log_scope.dart';
import 'package:sline_app/features/management/services/work_log_service.dart';
import 'package:sline_app/features/management/view/order_management_panel.dart';
import 'package:sline_app/features/management/viewmodels/order_management_view_model.dart';

import '../../test_support/pump_app.dart';

class _MockWorkLogService extends Mock implements WorkLogService {}

const _scope = WorkLogScope(entityId: 'entity-1', entityType: 'task');

WorkLog _workLog({
  String id = 'log-1',
  String content = 'Existing note',
  bool isPrivate = false,
}) {
  return WorkLog(
    id: id,
    authorId: 'user-1',
    relatedEntityId: _scope.entityId,
    relatedEntityType: _scope.entityType,
    content: content,
    isPrivate: isPrivate,
    createdAt: DateTime.utc(2026, 3, 1, 12),
    authorName: 'User One',
  );
}

Future<void> _pumpPanel(
  WidgetTester tester,
  OrderManagementViewModel viewModel,
) async {
  await pumpApp(
    tester,
    ChangeNotifierProvider<OrderManagementViewModel>.value(
      value: viewModel,
      child: const Scaffold(
        body: OrderManagementPanel(scope: _scope, currentUserId: 'user-1'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() {
    registerFallbackValue(_scope);
  });

  group('OrderManagementPanel', () {
    late _MockWorkLogService service;
    late OrderManagementViewModel viewModel;

    setUp(() {
      service = _MockWorkLogService();
      viewModel = OrderManagementViewModel(service);
    });

    tearDown(() {
      viewModel.dispose();
    });

    testWidgets('shows explicit load error state and retry action', (
      tester,
    ) async {
      when(() => service.getLogs(_scope)).thenThrow(
        Exception('You do not have permission to view this order timeline.'),
      );

      await _pumpPanel(tester, viewModel);

      expect(find.byKey(OrderManagementPanel.timelineErrorKey), findsOneWidget);
      expect(find.byKey(OrderManagementPanel.timelineEmptyKey), findsNothing);

      await tester.tap(find.byKey(OrderManagementPanel.retryButtonKey));
      await tester.pump();

      verify(() => service.getLogs(_scope)).called(2);
    });

    testWidgets('shows empty state only when load succeeds with no logs', (
      tester,
    ) async {
      when(() => service.getLogs(_scope)).thenAnswer((_) async => []);

      await _pumpPanel(tester, viewModel);

      expect(find.byKey(OrderManagementPanel.timelineEmptyKey), findsOneWidget);
      expect(find.byKey(OrderManagementPanel.timelineErrorKey), findsNothing);
    });

    testWidgets('failed send keeps draft text and shows action error', (
      tester,
    ) async {
      when(() => service.getLogs(_scope)).thenAnswer((_) async => []);
      when(
        () => service.addLog(
          scope: _scope,
          content: 'Draft note',
        ),
      ).thenThrow(Exception('You cannot post notes to this order.'));

      await _pumpPanel(tester, viewModel);
      await tester.enterText(
        find.byKey(OrderManagementPanel.noteFieldKey),
        'Draft note',
      );
      await tester.tap(find.byKey(OrderManagementPanel.sendButtonKey));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(
        find.byKey(OrderManagementPanel.noteFieldKey),
      );
      expect(textField.controller?.text, 'Draft note');
      expect(find.byKey(OrderManagementPanel.actionErrorKey), findsOneWidget);
      expect(find.text('You cannot post notes to this order.'), findsOneWidget);
    });

    testWidgets('successful send clears the draft after refresh', (
      tester,
    ) async {
      var loadCount = 0;
      when(() => service.getLogs(_scope)).thenAnswer((_) async {
        loadCount += 1;
        if (loadCount == 1) {
          return [];
        }
        return [_workLog(content: 'Sent note')];
      });
      when(
        () => service.addLog(
          scope: _scope,
          content: 'Sent note',
        ),
      ).thenAnswer((_) async {});

      await _pumpPanel(tester, viewModel);
      await tester.enterText(
        find.byKey(OrderManagementPanel.noteFieldKey),
        'Sent note',
      );
      await tester.tap(find.byKey(OrderManagementPanel.sendButtonKey));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(
        find.byKey(OrderManagementPanel.noteFieldKey),
      );
      expect(textField.controller?.text, isEmpty);
      expect(find.text('Sent note'), findsOneWidget);
    });

    testWidgets('send button is disabled while a note is in flight', (
      tester,
    ) async {
      final completer = Completer<void>();
      when(() => service.getLogs(_scope)).thenAnswer((_) async => []);
      when(
        () => service.addLog(
          scope: _scope,
          content: 'Pending note',
        ),
      ).thenAnswer((_) => completer.future);

      await _pumpPanel(tester, viewModel);
      await tester.enterText(
        find.byKey(OrderManagementPanel.noteFieldKey),
        'Pending note',
      );
      await tester.tap(find.byKey(OrderManagementPanel.sendButtonKey));
      await tester.pump();

      final sendButton = tester.widget<IconButton>(
        find.byKey(OrderManagementPanel.sendButtonKey),
      );
      expect(sendButton.onPressed, isNull);

      completer.complete();
      await tester.pumpAndSettle();
    });
  });
}
