import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/proposals/models/proposal_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';

Map<String, dynamic> _taskRequestMap({Map<String, dynamic>? overrides}) {
  final data = <String, dynamic>{
    'id': 'req-1',
    'task_id': 'task-1',
    'freelancer_id': 'freelancer-canonical',
    'bidder_id': 'bidder-legacy',
    'price': 250,
    'days': 3,
    'note': 'I can do this',
    'status': 'pending',
    'payment_status': 'unpaid',
    'created_at': '2026-02-24T10:00:00Z',
  };
  if (overrides != null) {
    data.addAll(overrides);
  }
  return data;
}

void main() {
  group('TaskRequest model T31-T33', () {
    test('T31 TaskRequest.fromMap chooses freelancer_id then bidder_id', () {
      final request = TaskRequest.fromMap(
        _taskRequestMap(
          overrides: {
            'freelancer_id': 'freelancer-wins',
            'bidder_id': 'bidder-loses',
          },
        ),
      );

      expect(request.bidderId, 'freelancer-wins');
      expect(request.taskId, 'task-1');
      expect(request.price, 250);
    });

    test('T32 TaskRequest.fromMap missing bidder fields falls back safely', () {
      final map = _taskRequestMap();
      map.remove('freelancer_id');
      map.remove('bidder_id');

      final request = TaskRequest.fromMap(map);

      expect(request.bidderId, '');
      expect(request.price, 250);
    });

    test(
      'T32b TaskRequest.fromMap uses message and duration fallback fields',
      () {
        final request = TaskRequest.fromMap(
          _taskRequestMap(
            overrides: {
              'days': null,
              'duration_days': 5,
              'note': null,
              'message': 'Fallback message',
            },
          ),
        );

        expect(request.days, 5);
        expect(request.note, 'Fallback message');
      },
    );

    test('T32c TaskRequest.fromMap maps unknown statuses to unknown', () {
      final request = TaskRequest.fromMap(
        _taskRequestMap(overrides: {'status': 'expired_by_system'}),
      );

      expect(request.status, OfferStatus.unknown);
      expect(request.isUnknown, isTrue);
      expect(request.isPending, isFalse);
    });

    test('T33 TaskRequest.toMap(forInsert: true) excludes system fields', () {
      final request = TaskRequest(
        id: 'req-system',
        taskId: 'task-99',
        bidderId: 'freelancer-42',
        price: 999,
        days: 7,
        note: 'Please hire me',
        status: OfferStatus.accepted,
        createdAt: DateTime.utc(2026, 2, 24, 11),
      );

      final payload = request.toMap(forInsert: true);

      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('status'), isFalse);
      expect(payload.containsKey('created_at'), isFalse);
      expect(payload['task_id'], 'task-99');
      expect(payload['freelancer_id'], 'freelancer-42');
      expect(payload['bidder_id'], 'freelancer-42');
      expect(payload['price'], 999);
      expect(payload['days'], 7);
      expect(payload['note'], 'Please hire me');
    });

    test('TaskRequest.fromProposal maps ProposalModel to TaskRequest', () {
      final createdAt = DateTime.utc(2026, 3, 4, 12, 0);
      final p = ProposalModel(
        id: 'req-p',
        taskId: 'task-p',
        bidderId: 'bidder-p',
        price: 100,
        days: 5,
        note: 'Cover',
        status: OfferStatus.accepted,
        paymentStatus: PaymentStatus.held,
        createdAt: createdAt,
        bidderName: 'Jane',
        taskTitle: 'My Task',
      );
      final request = TaskRequest.fromProposal(p);
      expect(request.id, 'req-p');
      expect(request.taskId, 'task-p');
      expect(request.bidderId, 'bidder-p');
      expect(request.price, 100);
      expect(request.days, 5);
      expect(request.note, 'Cover');
      expect(request.status, OfferStatus.accepted);
      expect(request.paymentStatus, PaymentStatus.held);
      expect(request.createdAt, createdAt);
      expect(request.bidderName, 'Jane');
      expect(request.taskTitle, 'My Task');
    });
  });
}
