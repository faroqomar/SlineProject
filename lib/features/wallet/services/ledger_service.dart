import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sline_app/core/services/logger_service.dart';

class LedgerService {
  LedgerService(this._client);
  final SupabaseClient _client;
  final Uuid _uuid = const Uuid();

  /// Constant namespace for Ledger idempotency generation
  static const String _ledgerNamespace = '4c1db351-a20d-4034-add5-b74bc48b3b78';

  /// Generates a deterministic idempotency key based on UUIDv5
  String generateIdempotencyKey(String entityId, String eventType) {
    return _uuid.v5(
      Namespace.url.value,
      'sline:ledger:$_ledgerNamespace:${entityId}_$eventType',
    );
  }

  /// Submits a payment event to the ledger RPC
  Future<Map<String, dynamic>> submitPaymentEvent({
    required String eventType,
    required String relatedEntityType,
    required String relatedEntityId,
    required num amountGross,
    required Map<String, dynamic> meta,
  }) async {
    final idempotencyKey = generateIdempotencyKey(relatedEntityId, eventType);

    AppLogger.i(
      'Submitting Ledger Event: $eventType for $relatedEntityType:$relatedEntityId',
    );

    try {
      final response = await _client.rpc(
        'process_payment_event_ledger',
        params: {
          'p_event_type': eventType,
          'p_related_entity_type': relatedEntityType,
          'p_related_entity_id': relatedEntityId,
          'p_idempotency_key': idempotencyKey,
          'p_amount_gross': amountGross,
          'p_meta': meta,
        },
      );

      return response as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      AppLogger.e('Ledger RPC Failed: ${e.message}', error: e);
      throw FormatException(_mapLedgerError(e));
    } catch (e) {
      AppLogger.e('Unexpected Ledger Error', error: e);
      throw const FormatException('An unexpected payment error occurred.');
    }
  }

  String _mapLedgerError(PostgrestException e) {
    // If the RPC threw an error JSON inside PostgrestException, attempt to format it
    if (e.message.contains('ERR_INSUFFICIENT_FUNDS')) {
      return 'Insufficient available balance.';
    }
    if (e.message.contains('ERR_GATE_NOT_ALLOWED')) {
      return 'Event not allowed for current status.';
    }
    if (e.message.contains('ERR_AMOUNT_MISMATCH')) {
      return 'Amount mismatch detected.';
    }
    if (e.message.contains('ERR_ENTITY_NOT_FOUND')) {
      return 'Related entity not found.';
    }
    return 'Payment failed to process. Please try again.';
  }
}
