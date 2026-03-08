/// Test helpers for invoking ledger RPC functions
///
/// Provides typed wrappers and utilities for testing the
/// process_payment_event_ledger RPC with various scenarios.
///
/// All operations are logged via AppLogger for traceability.
library;

import 'package:sline_app/core/services/logger_service.dart';

const String _logTag = 'test_ledger_rpc';

/// Result of a ledger RPC invocation
class LedgerRpcResult {
  final bool ok;
  final String? journalEntryId;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const LedgerRpcResult({
    required this.ok,
    this.journalEntryId,
    this.errorCode,
    this.errorMessage,
    this.metadata,
  });

  bool get isSuccess => ok && journalEntryId != null;
  bool get isError => !ok || errorCode != null;

  @override
  String toString() {
    if (isSuccess) {
      return 'LedgerRpcResult(success, journalEntryId: $journalEntryId)';
    } else {
      return 'LedgerRpcResult(error, code: $errorCode, message: $errorMessage)';
    }
  }
}

/// Builder for constructing RPC parameters
class LedgerRpcParams {
  final String eventType;
  final String relatedEntityType;
  final String relatedEntityId;
  final String idempotencyKey;
  final int? amountGross;
  final String currency;
  final Map<String, dynamic> meta;

  LedgerRpcParams({
    required this.eventType,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.idempotencyKey,
    this.amountGross,
    this.currency = 'IQD',
    this.meta = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'p_event_type': eventType,
      'p_related_entity_type': relatedEntityType,
      'p_related_entity_id': relatedEntityId,
      'p_idempotency_key': idempotencyKey,
      'p_amount_gross': amountGross,
      'p_currency': currency,
      'p_meta': meta,
    };
  }
}

/// Invokes the escrow_hold event via RPC
///
/// This simulates the client calling escrow_hold to lock funds
LedgerRpcParams createEscrowHoldParams({
  required String entityType, // 'booking', 'direct_offer', 'task_request'
  required String entityId,
  required String idempotencyKey,
  required int amountGross,
  Map<String, dynamic> meta = const {},
}) {
  AppLogger.d(
    'Creating escrow_hold params: entityType=$entityType, entityId=$entityId, amount=$amountGross',
    tag: _logTag,
  );

  return LedgerRpcParams(
    eventType: 'escrow_hold',
    relatedEntityType: entityType,
    relatedEntityId: entityId,
    idempotencyKey: idempotencyKey,
    amountGross: amountGross,
    meta: meta,
  );
}

/// Invokes the release_with_fee event via RPC
///
/// This simulates the client calling release_with_fee to release
/// funds with platform fee deduction
LedgerRpcParams createReleaseWithFeeParams({
  required String entityType,
  required String entityId,
  required String idempotencyKey,
  Map<String, dynamic> meta = const {},
}) {
  AppLogger.d(
    'Creating release_with_fee params: entityType=$entityType, entityId=$entityId',
    tag: _logTag,
  );

  return LedgerRpcParams(
    eventType: 'release_with_fee',
    relatedEntityType: entityType,
    relatedEntityId: entityId,
    idempotencyKey: idempotencyKey,
    meta: meta,
  );
}

/// Creates a spoof attempt params with custom fee rate in meta
///
/// This is used for testing that the RPC ignores client-provided
/// fee rates (security test)
LedgerRpcParams createSpoofAttemptParams({
  required String entityType,
  required String entityId,
  required String idempotencyKey,
  required int spoofedFeeRateBps,
  required int amountGross,
}) {
  AppLogger.w(
    'Creating SPOOF ATTEMPT params: feeRateBps=$spoofedFeeRateBps (should be ignored)',
    tag: _logTag,
  );

  return LedgerRpcParams(
    eventType: 'escrow_hold',
    relatedEntityType: entityType,
    relatedEntityId: entityId,
    idempotencyKey: idempotencyKey,
    amountGross: amountGross,
    meta: {'fee_rate_bps': spoofedFeeRateBps},
  );
}

/// Creates admin override params with custom fee rate
///
/// This is used for testing admin fee override capability
LedgerRpcParams createAdminOverrideParams({
  required String entityType,
  required String entityId,
  required String idempotencyKey,
  required int adminFeeRateBps,
  required int amountGross,
}) {
  AppLogger.i(
    'Creating ADMIN OVERRIDE params: feeRateBps=$adminFeeRateBps',
    tag: _logTag,
  );

  return LedgerRpcParams(
    eventType: 'escrow_hold',
    relatedEntityType: entityType,
    relatedEntityId: entityId,
    idempotencyKey: idempotencyKey,
    amountGross: amountGross,
    meta: {'fee_rate_bps': adminFeeRateBps, 'actor_role': 'admin'},
  );
}

/// Parses the RPC response JSON into a typed result
LedgerRpcResult parseRpcResponse(Map<String, dynamic> response) {
  final ok = response['ok'] as bool? ?? false;
  final journalEntryId = response['journal_entry_id'] as String?;
  final error = response['error'] as Map<String, dynamic>?;
  final errorCode = error?['code'] as String?;
  final errorMessage = error?['message'] as String?;

  AppLogger.d(
    'Parsed RPC response: ok=$ok, journalEntryId=$journalEntryId, errorCode=$errorCode',
    tag: _logTag,
  );

  return LedgerRpcResult(
    ok: ok,
    journalEntryId: journalEntryId,
    errorCode: errorCode,
    errorMessage: errorMessage,
    metadata: response,
  );
}

/// Validates that escrow_hold correctly locked the fee rate
///
/// Returns true if the booking now has fee_rate_applied_bps set
bool validateEscrowFeeLock({
  required Map<String, dynamic> bookingBefore,
  required Map<String, dynamic> bookingAfter,
  required int expectedFeeRateBps,
}) {
  final beforeRate = bookingBefore['fee_rate_applied_bps'];
  final afterRate = bookingAfter['fee_rate_applied_bps'];

  final isLocked = beforeRate == null && afterRate == expectedFeeRateBps;

  if (isLocked) {
    AppLogger.i(
      '✅ Fee lock validated: NULL -> $expectedFeeRateBps bps',
      tag: _logTag,
    );
  } else {
    AppLogger.e(
      '❌ Fee lock FAILED: before=$beforeRate, after=$afterRate, expected=$expectedFeeRateBps',
      tag: _logTag,
    );
  }

  return isLocked;
}

/// Validates that release_with_fee used the locked rate (not global)
///
/// Returns true if fee_amount matches the locked rate calculation
bool validateReleaseUsedLockedRate({
  required Map<String, dynamic> booking,
  required int expectedGrossAmount,
}) {
  final feeRateBps = booking['fee_rate_applied_bps'] as int?;
  final feeAmount = booking['fee_amount'] as int?;
  final netAmount = booking['net_amount'] as int?;
  final grossAmount = booking['price'] as int? ?? expectedGrossAmount;

  if (feeRateBps == null || feeAmount == null || netAmount == null) {
    AppLogger.e(
      '❌ Release validation FAILED: Missing fee columns (feeRateBps=$feeRateBps, feeAmount=$feeAmount, netAmount=$netAmount)',
      tag: _logTag,
    );
    return false;
  }

  final expectedFee = (grossAmount * feeRateBps) ~/ 10000;
  final expectedNet = grossAmount - expectedFee;

  final isValid =
      feeAmount == expectedFee &&
      netAmount == expectedNet &&
      (feeAmount + netAmount == grossAmount);

  if (isValid) {
    AppLogger.i(
      '✅ Release validation passed: gross=$grossAmount, fee=$feeAmount, net=$netAmount @ $feeRateBps bps',
      tag: _logTag,
    );
  } else {
    AppLogger.e(
      '❌ Release validation FAILED: expectedFee=$expectedFee, actualFee=$feeAmount, expectedNet=$expectedNet, actualNet=$netAmount',
      tag: _logTag,
    );
  }

  return isValid;
}

/// Validates that immutability trigger prevented fee rate change
///
/// Returns true if the update was rejected
bool validateImmutabilityEnforced({
  required Object? error,
  required String expectedErrorCode,
}) {
  final errorString = error.toString().toLowerCase();
  final hasImmutabilityError =
      errorString.contains('immutable') || errorString.contains('fee_rate');

  if (hasImmutabilityError) {
    AppLogger.i(
      '✅ Immutability enforcement validated: update rejected',
      tag: _logTag,
    );
  } else {
    AppLogger.e('❌ Immutability validation FAILED: error=$error', tag: _logTag);
  }

  return hasImmutabilityError;
}

/// Test scenario runner for fee locking flow
///
/// Executes a complete escrow -> fee change -> release flow
class FeeLockingScenarioRunner {
  final String description;

  FeeLockingScenarioRunner(this.description);

  void logStart() {
    AppLogger.i('🏃 Starting scenario: $description', tag: _logTag);
  }

  void logPhase(String phase) {
    AppLogger.d('  → Phase: $phase', tag: _logTag);
  }

  void logComplete(bool success) {
    if (success) {
      AppLogger.i('✅ Scenario completed: $description', tag: _logTag);
    } else {
      AppLogger.e('❌ Scenario FAILED: $description', tag: _logTag);
    }
  }
}

/// Generates a unique idempotency key for testing
String generateIdempotencyKey(String prefix) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = timestamp % 10000;
  return '${prefix}_${timestamp}_$random';
}

/// Error codes expected from the fee locking RPC
class FeeLockingErrorCodes {
  static const String feeRateNotLocked = 'ERR_FEE_RATE_NOT_LOCKED';
  static const String feeCalculationMismatch = 'ERR_FEE_CALCULATION_MISMATCH';
  static const String immutabilityViolation = 'ERR_IMMUTABILITY_VIOLATION';
  static const String gateNotAllowed = 'ERR_GATE_NOT_ALLOWED';
  static const String entityNotFound = 'ERR_ENTITY_NOT_FOUND';
  static const String amountMismatch = 'ERR_AMOUNT_MISMATCH';
  static const String missingIdempotencyKey = 'ERR_MISSING_IDEMPOTENCY_KEY';
}
