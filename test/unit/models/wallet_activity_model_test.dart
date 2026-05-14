// Schema ref: vw_wallet_activity_user view / wallet_journal_entries table in SUPABASE_SETUP.md
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/wallet/models/wallet_activity_model.dart';

/// Full valid JSON fixture matching Supabase `vw_wallet_activity_user` view columns.
Map<String, dynamic> _fullJson() {
  return <String, dynamic>{
    'journal_entry_id': 'entry-uuid-001',
    'created_at': '2026-03-15T10:30:00Z',
    'event_type': 'booking_payment',
    'amount_gross': 50000,
    'amount_net': 47500,
    'fee_amount': 2500,
    'currency': 'IQD',
    'related_entity_type': 'booking',
    'related_entity_id': 'booking-uuid-001',
    'counterparty_user_id': 'user-uuid-002',
  };
}

/// Minimal JSON -- only the required fields.
Map<String, dynamic> _minimalJson() {
  return <String, dynamic>{
    'journal_entry_id': 'entry-uuid-002',
    'created_at': '2026-04-01T00:00:00Z',
    'event_type': 'withdrawal',
  };
}

void main() {
  group('WalletActivityModel.fromJson', () {
    test('parses all fields from valid JSON', () {
      final activity = WalletActivityModel.fromJson(_fullJson());

      expect(activity.journalEntryId, 'entry-uuid-001');
      expect(activity.createdAtUtc, DateTime.utc(2026, 3, 15, 10, 30));
      expect(activity.eventType, 'booking_payment');
      expect(activity.amountGross, 50000);
      expect(activity.amountNet, 47500);
      expect(activity.feeAmount, 2500);
      expect(activity.currency, 'IQD');
      expect(activity.relatedEntityType, 'booking');
      expect(activity.relatedEntityId, 'booking-uuid-001');
      expect(activity.counterpartyUserId, 'user-uuid-002');
    });

    test('numeric fields default to 0 when null', () {
      final activity = WalletActivityModel.fromJson(<String, dynamic>{
        'journal_entry_id': 'entry-uuid-003',
        'created_at': '2026-04-01T00:00:00Z',
        'event_type': 'refund',
        'amount_gross': null,
        'amount_net': null,
        'fee_amount': null,
      });

      expect(activity.amountGross, 0);
      expect(activity.amountNet, 0);
      expect(activity.feeAmount, 0);
    });

    test('numeric fields default to 0 when missing', () {
      final activity = WalletActivityModel.fromJson(_minimalJson());

      expect(activity.amountGross, 0);
      expect(activity.amountNet, 0);
      expect(activity.feeAmount, 0);
    });

    test('currency defaults to IQD when null', () {
      final activity = WalletActivityModel.fromJson(<String, dynamic>{
        'journal_entry_id': 'entry-uuid-004',
        'created_at': '2026-04-01T00:00:00Z',
        'event_type': 'deposit',
        'currency': null,
      });

      expect(activity.currency, 'IQD');
    });

    test('currency defaults to IQD when missing', () {
      final activity = WalletActivityModel.fromJson(_minimalJson());

      expect(activity.currency, 'IQD');
    });

    test('nullable fields handle null gracefully', () {
      final activity = WalletActivityModel.fromJson(<String, dynamic>{
        'journal_entry_id': 'entry-uuid-005',
        'created_at': '2026-04-01T00:00:00Z',
        'event_type': 'payout',
        'related_entity_type': null,
        'related_entity_id': null,
        'counterparty_user_id': null,
      });

      expect(activity.relatedEntityType, isNull);
      expect(activity.relatedEntityId, isNull);
      expect(activity.counterpartyUserId, isNull);
    });

    test('missing nullable fields default to null without crash', () {
      final activity = WalletActivityModel.fromJson(_minimalJson());

      expect(activity.relatedEntityType, isNull);
      expect(activity.relatedEntityId, isNull);
      expect(activity.counterpartyUserId, isNull);
    });

    test('createdAtUtc is parsed as UTC', () {
      final activity = WalletActivityModel.fromJson(_fullJson());

      expect(activity.createdAtUtc.isUtc, isTrue);
    });

    test('createdAtUtc from offset timestamp is converted to UTC', () {
      final activity = WalletActivityModel.fromJson(<String, dynamic>{
        ..._fullJson(),
        'created_at': '2026-03-15T13:30:00+03:00',
      });

      expect(activity.createdAtUtc.isUtc, isTrue);
      expect(activity.createdAtUtc, DateTime.utc(2026, 3, 15, 10, 30));
    });

    test('handles decimal numeric values', () {
      final activity = WalletActivityModel.fromJson(<String, dynamic>{
        ..._fullJson(),
        'amount_gross': 500.75,
        'amount_net': 475.25,
        'fee_amount': 25.50,
      });

      expect(activity.amountGross, 500.75);
      expect(activity.amountNet, 475.25);
      expect(activity.feeAmount, 25.50);
    });

    test('handles zero numeric values', () {
      final activity = WalletActivityModel.fromJson(<String, dynamic>{
        ..._fullJson(),
        'amount_gross': 0,
        'amount_net': 0,
        'fee_amount': 0,
      });

      expect(activity.amountGross, 0);
      expect(activity.amountNet, 0);
      expect(activity.feeAmount, 0);
    });

    test('parses various event_type values', () {
      for (final eventType in [
        'booking_payment',
        'withdrawal',
        'refund',
        'deposit',
        'payout',
        'fee_charge',
      ]) {
        final activity = WalletActivityModel.fromJson(<String, dynamic>{
          ..._minimalJson(),
          'event_type': eventType,
        });
        expect(activity.eventType, eventType);
      }
    });
  });
}
