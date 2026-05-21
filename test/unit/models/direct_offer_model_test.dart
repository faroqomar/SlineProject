// Schema ref: direct_offers table — see Sline_everything/SUPABASE_SETUP.md
// Tests DirectOffer.fromJson, type coercion, defaults, nullable DateTimes, and computed getters.

import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/direct_offers/models/direct_offer_model.dart';

/// Builds a complete direct_offer JSON map with all 22 fields populated.
Map<String, dynamic> _directOfferJson({Map<String, dynamic>? overrides}) {
  final base = <String, dynamic>{
    'id': 'do-1',
    'conversation_id': 'conv-1',
    'client_id': 'client-aaa',
    'freelancer_id': 'freelancer-bbb',
    'task_id': 'task-1',
    'title': 'Build a website',
    'description': 'Modern landing page with animations',
    'price': 150000,
    'days': 14,
    'status': 'sent',
    'payment_status': 'unpaid',
    'created_at': '2026-03-20T10:00:00Z',
    'updated_at': '2026-03-20T10:00:00Z',
    'currency': 'IQD',
    'fee_rate_applied_bps': 500,
    'payment_request_id': 'pr-123',
    'payment_gateway_id': 'pg-456',
    'payment_correlation_id': 'pc-789',
    'payment_expires_at': '2026-03-21T10:00:00Z',
    'payment_recovered_at': '2026-03-22T12:00:00Z',
    'delivered_at': '2026-04-01T08:00:00Z',
    'review_expires_at': '2026-04-04T08:00:00Z',
  };
  if (overrides != null) {
    base.addAll(overrides);
  }
  return base;
}

void main() {
  // ---------------------------------------------------------------------------
  // fromJson — all 22 fields
  // ---------------------------------------------------------------------------
  group('DirectOffer.fromJson all fields', () {
    test('parses all 22 fields from valid JSON', () {
      final o = DirectOffer.fromJson(_directOfferJson());

      expect(o.id, 'do-1');
      expect(o.conversationId, 'conv-1');
      expect(o.clientId, 'client-aaa');
      expect(o.freelancerId, 'freelancer-bbb');
      expect(o.taskId, 'task-1');
      expect(o.title, 'Build a website');
      expect(o.description, 'Modern landing page with animations');
      expect(o.price, 150000);
      expect(o.days, 14);
      expect(o.status, 'sent');
      expect(o.paymentStatus, 'unpaid');
      expect(o.createdAt, DateTime.utc(2026, 3, 20, 10));
      expect(o.updatedAt, DateTime.utc(2026, 3, 20, 10));
      expect(o.currency, 'IQD');
      expect(o.feeRateAppliedBps, 500);
      expect(o.paymentRequestId, 'pr-123');
      expect(o.paymentGatewayId, 'pg-456');
      expect(o.paymentCorrelationId, 'pc-789');
      expect(o.paymentExpiresAt, DateTime.utc(2026, 3, 21, 10));
      expect(o.paymentRecoveredAt, DateTime.utc(2026, 3, 22, 12));
      expect(o.deliveredAt, DateTime.utc(2026, 4, 1, 8));
      expect(o.reviewExpiresAt, DateTime.utc(2026, 4, 4, 8));
    });

    test('createdAt and updatedAt are parsed as UTC', () {
      final o = DirectOffer.fromJson(_directOfferJson());
      expect(o.createdAt.isUtc, isTrue);
      expect(o.updatedAt.isUtc, isTrue);
    });

    test('nullable DateTime fields are parsed as UTC when present', () {
      final o = DirectOffer.fromJson(_directOfferJson());
      expect(o.paymentExpiresAt!.isUtc, isTrue);
      expect(o.paymentRecoveredAt!.isUtc, isTrue);
      expect(o.deliveredAt!.isUtc, isTrue);
      expect(o.reviewExpiresAt!.isUtc, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson — defaults
  // ---------------------------------------------------------------------------
  group('DirectOffer.fromJson defaults', () {
    test('status defaults to sent when missing', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'status': null}),
      );
      expect(o.status, 'sent');
    });

    test('paymentStatus defaults to unpaid when missing', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'payment_status': null}),
      );
      expect(o.paymentStatus, 'unpaid');
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson — nullable fields
  // ---------------------------------------------------------------------------
  group('DirectOffer.fromJson nullable fields', () {
    test('all 8 nullable DateTime fields handle null gracefully', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(
          overrides: {
            'payment_expires_at': null,
            'payment_recovered_at': null,
            'delivered_at': null,
            'review_expires_at': null,
          },
        ),
      );

      expect(o.paymentExpiresAt, isNull);
      expect(o.paymentRecoveredAt, isNull);
      expect(o.deliveredAt, isNull);
      expect(o.reviewExpiresAt, isNull);
    });

    test('nullable String fields handle null', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(
          overrides: {
            'task_id': null,
            'title': null,
            'description': null,
            'currency': null,
            'payment_request_id': null,
            'payment_gateway_id': null,
            'payment_correlation_id': null,
          },
        ),
      );

      expect(o.taskId, isNull);
      expect(o.title, isNull);
      expect(o.description, isNull);
      expect(o.currency, isNull);
      expect(o.paymentRequestId, isNull);
      expect(o.paymentGatewayId, isNull);
      expect(o.paymentCorrelationId, isNull);
    });

    test('feeRateAppliedBps is null when missing', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'fee_rate_applied_bps': null}),
      );
      expect(o.feeRateAppliedBps, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson — price type coercion
  // ---------------------------------------------------------------------------
  group('DirectOffer.fromJson price coercion', () {
    test('price as int', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'price': 75000}),
      );
      expect(o.price, 75000);
    });

    test('price as double (num)', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'price': 99999.5}),
      );
      expect(o.price, 99999.5);
    });

    test('price as String (numeric)', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'price': '250000'}),
      );
      expect(o.price, 250000);
    });

    test('price as non-numeric String defaults to 0', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'price': 'invalid'}),
      );
      expect(o.price, 0);
    });

    test('price as null defaults to 0', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'price': null}),
      );
      expect(o.price, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson — days type coercion
  // ---------------------------------------------------------------------------
  group('DirectOffer.fromJson days coercion', () {
    test('days as int', () {
      final o = DirectOffer.fromJson(_directOfferJson(overrides: {'days': 30}));
      expect(o.days, 30);
    });

    test('days as String (numeric)', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'days': '45'}),
      );
      expect(o.days, 45);
    });

    test('days as non-numeric String defaults to 0', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'days': 'nope'}),
      );
      expect(o.days, 0);
    });

    test('days as null defaults to 0', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'days': null}),
      );
      expect(o.days, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson — feeRateAppliedBps type coercion
  // ---------------------------------------------------------------------------
  group('DirectOffer.fromJson feeRateAppliedBps coercion', () {
    test('feeRateAppliedBps as int', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'fee_rate_applied_bps': 1000}),
      );
      expect(o.feeRateAppliedBps, 1000);
    });

    test('feeRateAppliedBps as String (numeric)', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'fee_rate_applied_bps': '750'}),
      );
      expect(o.feeRateAppliedBps, 750);
    });

    test('feeRateAppliedBps as non-numeric String returns null', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'fee_rate_applied_bps': 'bad'}),
      );
      expect(o.feeRateAppliedBps, isNull);
    });

    test('feeRateAppliedBps as null returns null', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'fee_rate_applied_bps': null}),
      );
      expect(o.feeRateAppliedBps, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Computed getters
  // ---------------------------------------------------------------------------
  group('DirectOffer computed getters', () {
    test('isSent is true when status == sent', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'status': 'sent'}),
      );
      expect(o.isSent, isTrue);
      expect(o.isActive, isFalse);
      expect(o.isDelivered, isFalse);
      expect(o.isCompleted, isFalse);
      expect(o.isRejectedOrCanceled, isFalse);
    });

    test('isAcceptedPendingPayment is true when accepted + unpaid', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(
          overrides: {'status': 'accepted', 'payment_status': 'unpaid'},
        ),
      );
      expect(o.isAcceptedPendingPayment, isTrue);
      expect(o.isSent, isFalse);
    });

    test('isAcceptedPendingPayment is false when accepted + paid', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(
          overrides: {'status': 'accepted', 'payment_status': 'paid'},
        ),
      );
      expect(o.isAcceptedPendingPayment, isFalse);
    });

    test('isActive is true when status == active', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'status': 'active'}),
      );
      expect(o.isActive, isTrue);
    });

    test('isDelivered is true when status == delivered', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'status': 'delivered'}),
      );
      expect(o.isDelivered, isTrue);
    });

    test('isCompleted is true when status == completed', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'status': 'completed'}),
      );
      expect(o.isCompleted, isTrue);
    });

    test('isRejectedOrCanceled is true for rejected', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'status': 'rejected'}),
      );
      expect(o.isRejectedOrCanceled, isTrue);
    });

    test('isRejectedOrCanceled is true for canceled', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'status': 'canceled'}),
      );
      expect(o.isRejectedOrCanceled, isTrue);
    });

    test('isRejectedOrCanceled is true for refunded', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'status': 'refunded'}),
      );
      expect(o.isRejectedOrCanceled, isTrue);
    });

    test('isRejectedOrCanceled is false for active status', () {
      final o = DirectOffer.fromJson(
        _directOfferJson(overrides: {'status': 'active'}),
      );
      expect(o.isRejectedOrCanceled, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Minimal JSON — only required fields
  // ---------------------------------------------------------------------------
  group('DirectOffer.fromJson minimal', () {
    test('works with only required fields present', () {
      final json = <String, dynamic>{
        'id': 'do-min',
        'conversation_id': 'conv-min',
        'client_id': 'c1',
        'freelancer_id': 'f1',
        'price': 1000,
        'days': 3,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final o = DirectOffer.fromJson(json);

      expect(o.id, 'do-min');
      expect(o.status, 'sent');
      expect(o.paymentStatus, 'unpaid');
      expect(o.taskId, isNull);
      expect(o.title, isNull);
      expect(o.description, isNull);
      expect(o.currency, isNull);
      expect(o.feeRateAppliedBps, isNull);
      expect(o.paymentRequestId, isNull);
      expect(o.paymentGatewayId, isNull);
      expect(o.paymentCorrelationId, isNull);
      expect(o.paymentExpiresAt, isNull);
      expect(o.paymentRecoveredAt, isNull);
      expect(o.deliveredAt, isNull);
      expect(o.reviewExpiresAt, isNull);
    });
  });
}
