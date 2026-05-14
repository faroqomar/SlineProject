// These tests lock legacy ProposalModel behavior while the app still reads
// historical proposal rows.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/proposals/models/proposal_model.dart';

void main() {
  group('ProposalModel', () {
    test('constructs with required fields', () {
      final createdAt = DateTime.utc(2026, 3, 4, 12, 0);
      final p = ProposalModel(
        id: 'req-1',
        taskId: 'task-1',
        bidderId: 'bidder-1',
        price: 100,
        days: 5,
        status: OfferStatus.pending,
        createdAt: createdAt,
      );
      expect(p.id, 'req-1');
      expect(p.taskId, 'task-1');
      expect(p.bidderId, 'bidder-1');
      expect(p.price, 100);
      expect(p.days, 5);
      expect(p.status, OfferStatus.pending);
      expect(p.createdAt, createdAt);
      expect(p.note, isNull);
      expect(p.paymentStatus, PaymentStatus.unpaid);
      expect(p.bidderName, isNull);
      expect(p.taskTitle, isNull);
      expect(p.paymentDeadline, isNull);
    });

    test('isPending is true when status is pending', () {
      final p = ProposalModel(
        id: 'r',
        taskId: 't',
        bidderId: 'b',
        price: 0,
        days: 0,
        status: OfferStatus.pending,
        createdAt: DateTime.now(),
      );
      expect(p.isPending, isTrue);
      expect(p.isAccepted, isFalse);
      expect(p.isRejected, isFalse);
    });

    test('isAccepted is true when status is accepted', () {
      final p = ProposalModel(
        id: 'r',
        taskId: 't',
        bidderId: 'b',
        price: 0,
        days: 0,
        status: OfferStatus.accepted,
        createdAt: DateTime.now(),
      );
      expect(p.isPending, isFalse);
      expect(p.isAccepted, isTrue);
      expect(p.isRejected, isFalse);
    });

    test('isRejected is true when status is rejected', () {
      final p = ProposalModel(
        id: 'r',
        taskId: 't',
        bidderId: 'b',
        price: 0,
        days: 0,
        status: OfferStatus.rejected,
        createdAt: DateTime.now(),
      );
      expect(p.isPending, isFalse);
      expect(p.isAccepted, isFalse);
      expect(p.isRejected, isTrue);
    });

    test('optional fields are stored', () {
      final deadline = DateTime.utc(2026, 3, 10, 0, 0);
      final p = ProposalModel(
        id: 'r',
        taskId: 't',
        bidderId: 'b',
        price: 50,
        days: 3,
        note: 'Cover letter',
        status: OfferStatus.pending,
        paymentStatus: PaymentStatus.held,
        createdAt: DateTime.now(),
        bidderName: 'Jane',
        bidderAvatar: 'https://example.com/av.png',
        taskTitle: 'My Task',
        paymentDeadline: deadline,
      );
      expect(p.note, 'Cover letter');
      expect(p.paymentStatus, PaymentStatus.held);
      expect(p.bidderName, 'Jane');
      expect(p.bidderAvatar, 'https://example.com/av.png');
      expect(p.taskTitle, 'My Task');
      expect(p.paymentDeadline, deadline);
    });
  });
}
