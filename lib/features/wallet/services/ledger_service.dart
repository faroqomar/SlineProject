import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/utils/ledger_forensics.dart';

class LedgerService {
  LedgerService(this._client, [LedgerForensics? forensics])
    : _forensics = forensics ?? LedgerForensics();
  final SupabaseClient _client;
  final LedgerForensics _forensics;
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

  /// Submits a payment event to the ledger RPC.
  /// Injects forensics (session_id, request_id) into [meta] per CONTRACT_ledger_event_flow.
  Future<Map<String, dynamic>> submitPaymentEvent({
    required String eventType,
    required String relatedEntityType,
    required String relatedEntityId,
    required num amountGross,
    required Map<String, dynamic> meta,
  }) async {
    final idempotencyKey = generateIdempotencyKey(relatedEntityId, eventType);
    final metaWithForensics = _mergeForensics(meta);
    final requestId = metaWithForensics['request_id'] as String?;

    AppLogger.i(
      'Submitting Ledger Event: $eventType for $relatedEntityType:$relatedEntityId${requestId != null ? ' request_id:$requestId' : ''}',
      tag: 'LedgerService',
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
          'p_currency': 'IQD', // Always IQD for MVP
          'p_meta': metaWithForensics,
        },
      );

      final result = response as Map<String, dynamic>;
      if (result['ok'] == false) {
        final err = result['error'];
        final message = err is Map
            ? (err['message'] as String? ??
                  err['code'] as String? ??
                  'Payment failed.')
            : 'Payment failed.';
        AppLogger.e(
          'Ledger RPC returned ok: false${requestId != null ? ' request_id:$requestId' : ''}',
          tag: 'LedgerService',
          error: err is Map ? err.toString() : err,
        );
        final userMessage =
            _mapLedgerCode(err is Map ? err['code'] as String? : null) ??
            message;
        throw Exception(userMessage);
      }
      AppLogger.i(
        'Ledger event succeeded: $eventType $relatedEntityType:$relatedEntityId${requestId != null ? ' request_id:$requestId' : ''}',
        tag: 'LedgerService',
      );
      return result;
    } on PostgrestException catch (e) {
      AppLogger.e(
        'Ledger RPC Failed: ${e.message}${requestId != null ? ' request_id:$requestId' : ''}',
        error: e,
        tag: 'LedgerService',
      );
      throw FormatException(_mapLedgerError(e));
    } catch (e) {
      AppLogger.e(
        'Unexpected Ledger Error${requestId != null ? ' request_id:$requestId' : ''}',
        error: e,
        tag: 'LedgerService',
      );
      throw const FormatException('An unexpected payment error occurred.');
    }
  }

  /// Merges forensics (session_id, request_id) into meta per CONTRACT_ledger_event_flow.
  /// Caller meta takes precedence; forensics fill in missing keys only.
  Map<String, dynamic> _mergeForensics(Map<String, dynamic> meta) {
    final sessionId = _client.auth.currentUser?.id;
    final forensics = _forensics.build(
      sessionId: sessionId,
      includeRequestId: true,
    );
    final merged = <String, dynamic>{...meta};
    for (final e in forensics.entries) {
      merged[e.key] ??= e.value;
    }
    return merged;
  }

  /// Map RPC error code from jsonb response to user-facing message.
  String? _mapLedgerCode(String? code) {
    if (code == null) return null;
    switch (code) {
      case 'ERR_GATE_NOT_ALLOWED':
        return 'Event not allowed for current status.';
      case 'ERR_ENTITY_NOT_FOUND':
        return 'Related entity not found.';
      case 'ERR_MISSING_IDEMPOTENCY_KEY':
        return 'Missing idempotency key. Please try again.';
      case 'ERR_IDEMPOTENCY_REPLAY':
        return 'This transaction was already processed.';
      case 'ERR_AMOUNT_MISMATCH':
        return 'Amount mismatch detected.';
      case 'ERR_CURRENCY_MISMATCH':
        return 'Currency mismatch. Only IQD is supported.';
      case 'ERR_INSUFFICIENT_FUNDS':
        return 'Insufficient available balance.';
      default:
        return null;
    }
  }

  String _mapLedgerError(PostgrestException e) {
    final message = e.message;

    // Idempotency errors
    if (message.contains('ERR_MISSING_IDEMPOTENCY_KEY')) {
      return 'Missing idempotency key. Please try again.';
    }
    if (message.contains('ERR_IDEMPOTENCY_REPLAY')) {
      return 'This transaction was already processed.';
    }

    // Gate validation errors
    if (message.contains('ERR_GATE_NOT_ALLOWED')) {
      return 'Event not allowed for current status.';
    }

    // Entity errors
    if (message.contains('ERR_ENTITY_NOT_FOUND')) {
      return 'Related entity not found.';
    }

    // Amount errors
    if (message.contains('ERR_AMOUNT_MISMATCH')) {
      return 'Amount mismatch detected.';
    }
    if (message.contains('ERR_CURRENCY_MISMATCH')) {
      return 'Currency mismatch. Only IQD is supported.';
    }
    if (message.contains('ERR_WITHDRAWAL_AMOUNT_INVALID')) {
      return 'Invalid withdrawal amount.';
    }

    // Balance errors
    if (message.contains('ERR_INSUFFICIENT_FUNDS')) {
      return 'Insufficient available balance.';
    }

    // Ledger integrity errors
    if (message.contains('ERR_UNBALANCED_JOURNAL')) {
      return 'Internal error: Journal entry unbalanced. Please contact support.';
    }

    // Unique constraint errors (usually idempotency)
    if (message.contains('unique constraint') ||
        message.contains('uq_journal_entries')) {
      return 'This transaction was already processed.';
    }

    // Generic fallback
    return 'Payment failed to process. Please try again.';
  }
}
