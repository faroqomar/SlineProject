import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/management/models/work_log_model.dart';
import 'package:sline_app/features/management/models/work_log_scope.dart';
import 'package:sline_app/features/management/services/work_log_service.dart';
import 'package:sline_app/features/management/viewmodels/order_management_view_model.dart';

class _MockWorkLogService extends Mock implements WorkLogService {}

const _scope = WorkLogScope(entityId: 'entity-1', entityType: 'task');

WorkLog _workLog({String id = 'log-1', String content = 'A saved note'}) {
  return WorkLog(
    id: id,
    authorId: 'user-1',
    relatedEntityId: _scope.entityId,
    relatedEntityType: _scope.entityType,
    content: content,
    createdAt: DateTime.utc(2026, 3, 1, 12),
    authorName: 'User One',
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_scope);
  });

  group('OrderManagementViewModel', () {
    late _MockWorkLogService service;
    late OrderManagementViewModel viewModel;

    setUp(() {
      service = _MockWorkLogService();
      viewModel = OrderManagementViewModel(service);
    });

    tearDown(() {
      viewModel.dispose();
    });

    test(
      'postNote returns true, trims content, and refreshes logs on success',
      () async {
        when(
          () => service.addLog(
            scope: _scope,
            content: 'Trimmed note',
          ),
        ).thenAnswer((_) async {});
        when(
          () => service.getLogs(_scope),
        ).thenAnswer((_) async => [_workLog(content: 'Trimmed note')]);

        final result = await viewModel.postNote(
          scope: _scope,
          content: '  Trimmed note  ',
        );

        expect(result, isTrue);
        expect(viewModel.actionError, isNull);
        expect(viewModel.logs, hasLength(1));
        expect(viewModel.logs.single.content, 'Trimmed note');
        verify(
          () => service.addLog(
            scope: _scope,
            content: 'Trimmed note',
          ),
        ).called(1);
        verify(() => service.getLogs(_scope)).called(1);
      },
    );

    test(
      'postNote returns false and keeps mutation error on failure',
      () async {
        when(
          () => service.addLog(
            scope: any(named: 'scope'),
            content: any(named: 'content'),
            isPrivate: any(named: 'isPrivate'),
          ),
        ).thenThrow(Exception('You cannot post notes to this order.'));

        final result = await viewModel.postNote(
          scope: _scope,
          content: 'Draft note',
        );

        expect(result, isFalse);
        expect(viewModel.isSending, isFalse);
        expect(viewModel.actionError, 'You cannot post notes to this order.');
        verifyNever(() => service.getLogs(any()));
      },
    );

    test('loadLogs preserves existing logs when a refresh fails', () async {
      when(() => service.getLogs(_scope)).thenAnswer((_) async => [_workLog()]);
      await viewModel.loadLogs(_scope);

      when(() => service.getLogs(_scope)).thenThrow(
        Exception('You do not have permission to view this order timeline.'),
      );
      await viewModel.loadLogs(_scope);

      expect(viewModel.logs, hasLength(1));
      expect(
        viewModel.loadError,
        'You do not have permission to view this order timeline.',
      );
    });
  });
}
