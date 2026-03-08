// ignore_for_file: deprecated_member_use_from_same_package

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

  group('Expiration Getters (24h window)', () {
    test('isExpired returns false for non-pending status', () {
      final acceptedRequest = TaskRequest(
        id: 'req-1',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(hours: 48)),
      );
      expect(acceptedRequest.isExpired, isFalse);

      final rejectedRequest = TaskRequest(
        id: 'req-2',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.rejected,
        createdAt: DateTime.now().subtract(const Duration(hours: 48)),
      );
      expect(rejectedRequest.isExpired, isFalse);

      final withdrawnRequest = TaskRequest(
        id: 'req-3',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.withdrawn,
        createdAt: DateTime.now().subtract(const Duration(hours: 48)),
      );
      expect(withdrawnRequest.isExpired, isFalse);
    });

    test('isExpired returns false for recent pending bids', () {
      final recentBid = TaskRequest(
        id: 'req-1',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      );
      expect(recentBid.isExpired, isFalse);
    });

    test('isExpired returns true for pending bids older than 24h', () {
      final oldBid = TaskRequest(
        id: 'req-1',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 25)),
      );
      expect(oldBid.isExpired, isTrue);
    });

    test('expirationTime returns createdAt + 24 hours', () {
      final createdAt = DateTime.utc(2026, 3, 1, 12, 0);
      final request = TaskRequest(
        id: 'req-1',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.pending,
        createdAt: createdAt,
      );
      expect(request.expirationTime, createdAt.add(const Duration(hours: 24)));
    });

    test('timeUntilExpiration returns positive duration for pending bids', () {
      final recentBid = TaskRequest(
        id: 'req-1',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      );
      final timeLeft = recentBid.timeUntilExpiration();
      expect(timeLeft.inHours, greaterThan(0));
      expect(timeLeft.inHours, lessThan(24));
    });

    test('timeUntilExpiration returns negative duration for expired bids', () {
      final expiredBid = TaskRequest(
        id: 'req-1',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 30)),
      );
      final timeLeft = expiredBid.timeUntilExpiration();
      expect(timeLeft.inHours, lessThan(0));
    });
  });

  group('Payment State Getters', () {
    test('isPendingPayment true only when accepted and unpaid', () {
      final pendingPayment = TaskRequest(
        id: 'req-1',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.accepted,
        paymentStatus: PaymentStatus.unpaid,
        createdAt: DateTime.now(),
      );
      expect(pendingPayment.isPendingPayment, isTrue);
      expect(pendingPayment.isActive, isFalse);
    });

    test('isPendingPayment false for held payment', () {
      final heldPayment = TaskRequest(
        id: 'req-1',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.accepted,
        paymentStatus: PaymentStatus.held,
        createdAt: DateTime.now(),
      );
      expect(heldPayment.isPendingPayment, isFalse);
      expect(heldPayment.isActive, isTrue);
    });

    test(
      'isActive true only when accepted and held (T3: Work Without Escrow)',
      () {
        final activeWork = TaskRequest(
          id: 'req-1',
          taskId: 'task-1',
          bidderId: 'bidder-1',
          price: 100,
          days: 5,
          status: OfferStatus.accepted,
          paymentStatus: PaymentStatus.held,
          createdAt: DateTime.now(),
        );
        expect(activeWork.isActive, isTrue);
        expect(activeWork.isPendingPayment, isFalse);
      },
    );

    test('isActive false for pending status regardless of payment', () {
      final pendingWithUnpaid = TaskRequest(
        id: 'req-1',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.pending,
        paymentStatus: PaymentStatus.unpaid,
        createdAt: DateTime.now(),
      );
      expect(pendingWithUnpaid.isActive, isFalse);

      // Edge case: pending with held payment (shouldn't occur in practice)
      final pendingWithHeld = TaskRequest(
        id: 'req-2',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.pending,
        paymentStatus: PaymentStatus.held,
        createdAt: DateTime.now(),
      );
      expect(pendingWithHeld.isActive, isFalse);
    });

    test('isActive false for released/refunded payments', () {
      final released = TaskRequest(
        id: 'req-1',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.accepted,
        paymentStatus: PaymentStatus.released,
        createdAt: DateTime.now(),
      );
      expect(released.isActive, isFalse);

      final refunded = TaskRequest(
        id: 'req-2',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.accepted,
        paymentStatus: PaymentStatus.refunded,
        createdAt: DateTime.now(),
      );
      expect(refunded.isActive, isFalse);
    });
  });
}
