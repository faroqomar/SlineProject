/// Test fixtures for booking and fee locking tests
///
/// Provides standardized test data for bookings, platform settings,
/// and related entities to ensure deterministic test scenarios.
///
/// All operations are logged via AppLogger for traceability.
library;

import 'package:uuid/uuid.dart';
import 'package:sline_app/core/services/logger_service.dart';

const String _logTag = 'test_fixture';

/// Default fee rate in basis points (10% = 1000 bps)
const int defaultFeeRateBps = 1000;

/// Test fee rate in basis points (12% = 1200 bps)
const int testFeeRateBps = 1200;

/// Maximum fee rate in basis points (30% = 3000 bps)
const int maxFeeRateBps = 3000;

/// Generates a UUID v4 for test entities
String generateTestId() {
  return const Uuid().v4();
}

/// Platform settings fixture for fee locking tests
///
/// Creates a map representing a platform_settings row
Map<String, dynamic> createPlatformSettingsFixture({
  String key = 'fee_rate_default_bps',
  int feeRateBps = defaultFeeRateBps,
  bool feeLockingEnabled = false,
  String? updatedBy,
}) {
  AppLogger.d(
    'Creating platform_settings fixture: key=$key, feeRateBps=$feeRateBps',
    tag: _logTag,
  );

  return {
    'key': key,
    'value': {'value': feeRateBps},
    'updated_at': DateTime.now().toIso8601String(),
    'updated_by': updatedBy,
  };
}

/// Booking fixture with fee locking fields
///
/// Creates a map representing a booking row with fee columns
Map<String, dynamic> createBookingFixture({
  String? id,
  required String clientId,
  required String providerId,
  required int price,
  String status = 'pending',
  String paymentStatus = 'unpaid',
  int? feeRateAppliedBps,
  int? feeAmount,
  int? netAmount,
  DateTime? createdAt,
}) {
  final bookingId = id ?? generateTestId();

  // Calculate fee amounts if fee rate is provided
  final calculatedFeeAmount =
      feeAmount ??
      (feeRateAppliedBps != null ? (price * feeRateAppliedBps ~/ 10000) : null);
  final calculatedNetAmount =
      netAmount ??
      (calculatedFeeAmount != null ? price - calculatedFeeAmount : null);

  AppLogger.d(
    'Creating booking fixture: id=$bookingId, price=$price, feeRateAppliedBps=$feeRateAppliedBps',
    tag: _logTag,
  );

  return {
    'id': bookingId,
    'client_id': clientId,
    'provider_id': providerId,
    'price': price,
    'status': status,
    'payment_status': paymentStatus,
    'fee_rate_applied_bps': feeRateAppliedBps,
    'fee_amount': calculatedFeeAmount,
    'net_amount': calculatedNetAmount,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
  };
}

/// Direct offer fixture with fee locking fields
///
/// Creates a map representing a direct_offer row with fee columns
Map<String, dynamic> createDirectOfferFixture({
  String? id,
  required String clientId,
  required String providerId,
  required int price,
  required String conversationId,
  String status = 'pending',
  String paymentStatus = 'unpaid',
  int? feeRateAppliedBps,
  int? feeAmount,
  int? netAmount,
  DateTime? createdAt,
}) {
  final offerId = id ?? generateTestId();

  final calculatedFeeAmount =
      feeAmount ??
      (feeRateAppliedBps != null ? (price * feeRateAppliedBps ~/ 10000) : null);
  final calculatedNetAmount =
      netAmount ??
      (calculatedFeeAmount != null ? price - calculatedFeeAmount : null);

  AppLogger.d(
    'Creating direct_offer fixture: id=$offerId, price=$price, feeRateAppliedBps=$feeRateAppliedBps',
    tag: _logTag,
  );

  return {
    'id': offerId,
    'client_id': clientId,
    'provider_id': providerId,
    'conversation_id': conversationId,
    'price': price,
    'status': status,
    'payment_status': paymentStatus,
    'fee_rate_applied_bps': feeRateAppliedBps,
    'fee_amount': calculatedFeeAmount,
    'net_amount': calculatedNetAmount,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
  };
}

/// Task request fixture with fee locking fields
///
/// Creates a map representing a task_request row with fee columns
Map<String, dynamic> createTaskRequestFixture({
  String? id,
  required String taskId,
  required String clientId,
  required String freelancerId,
  required int proposedPrice,
  String status = 'pending',
  String paymentStatus = 'unpaid',
  int? feeRateAppliedBps,
  int? feeAmount,
  int? netAmount,
  DateTime? createdAt,
}) {
  final requestId = id ?? generateTestId();

  final calculatedFeeAmount =
      feeAmount ??
      (feeRateAppliedBps != null
          ? (proposedPrice * feeRateAppliedBps ~/ 10000)
          : null);
  final calculatedNetAmount =
      netAmount ??
      (calculatedFeeAmount != null
          ? proposedPrice - calculatedFeeAmount
          : null);

  AppLogger.d(
    'Creating task_request fixture: id=$requestId, price=$proposedPrice, feeRateAppliedBps=$feeRateAppliedBps',
    tag: _logTag,
  );

  return {
    'id': requestId,
    'task_id': taskId,
    'client_id': clientId,
    'freelancer_id': freelancerId,
    'proposed_price': proposedPrice,
    'status': status,
    'payment_status': paymentStatus,
    'fee_rate_applied_bps': feeRateAppliedBps,
    'fee_amount': calculatedFeeAmount,
    'net_amount': calculatedNetAmount,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
  };
}

/// Test scenario: Booking in escrow with fee locked
///
/// Creates a complete test scenario for fee locking verification
Map<String, dynamic> createEscrowScenario({
  required String clientId,
  required String providerId,
  required int price,
  int feeRateBps = testFeeRateBps,
}) {
  AppLogger.i(
    'Creating escrow scenario: client=$clientId, provider=$providerId, price=$price, feeRate=$feeRateBps',
    tag: _logTag,
  );

  final booking = createBookingFixture(
    clientId: clientId,
    providerId: providerId,
    price: price,
    status: 'paid_request_pending',
    paymentStatus: 'held',
    feeRateAppliedBps: feeRateBps,
  );

  return {
    'booking': booking,
    'expected_fee_amount': price * feeRateBps ~/ 10000,
    'expected_net_amount': price - (price * feeRateBps ~/ 10000),
  };
}

/// Test scenario: Fee rate change after escrow
///
/// Creates a test scenario where global fee rate changes but
/// locked booking should maintain original rate
Map<String, dynamic> createFeeChangeScenario({
  required String clientId,
  required String providerId,
  required int price,
  int initialFeeRateBps = testFeeRateBps,
  int newFeeRateBps = maxFeeRateBps,
}) {
  AppLogger.i(
    'Creating fee change scenario: initialRate=$initialFeeRateBps, newRate=$newFeeRateBps',
    tag: _logTag,
  );

  final booking = createBookingFixture(
    clientId: clientId,
    providerId: providerId,
    price: price,
    status: 'paid_request_pending',
    paymentStatus: 'held',
    feeRateAppliedBps: initialFeeRateBps, // Locked at initial rate
  );

  final platformSettings = createPlatformSettingsFixture(
    feeRateBps: newFeeRateBps, // New global rate
  );

  return {
    'booking': booking,
    'platform_settings': platformSettings,
    'locked_fee_rate_bps': initialFeeRateBps,
    'current_fee_rate_bps': newFeeRateBps,
    'expected_fee_amount': price * initialFeeRateBps ~/ 10000,
    'expected_net_amount': price - (price * initialFeeRateBps ~/ 10000),
  };
}

/// Validates fee calculation precision
///
/// Verifies that fee + net = gross (accounting for rounding)
bool validateFeeCalculation({
  required int grossAmount,
  required int feeRateBps,
  required int expectedFeeAmount,
  required int expectedNetAmount,
}) {
  final calculatedFee = (grossAmount * feeRateBps) ~/ 10000;
  final calculatedNet = grossAmount - calculatedFee;

  final isValid =
      calculatedFee == expectedFeeAmount &&
      calculatedNet == expectedNetAmount &&
      (expectedFeeAmount + expectedNetAmount == grossAmount);

  if (isValid) {
    AppLogger.d(
      'Fee calculation valid: gross=$grossAmount, fee=$expectedFeeAmount, net=$expectedNetAmount',
      tag: _logTag,
    );
  } else {
    AppLogger.e(
      'Fee calculation INVALID: gross=$grossAmount, fee=$expectedFeeAmount, net=$expectedNetAmount',
      tag: _logTag,
    );
  }

  return isValid;
}

/// Edge case test values for fee calculations
///
/// Returns a list of test cases that exercise rounding edge cases
List<Map<String, dynamic>> getFeeCalculationEdgeCases() {
  AppLogger.d('Generating fee calculation edge cases', tag: _logTag);

  return [
    // Standard case: 100 @ 12% = 12
    {
      'gross': 100,
      'fee_rate_bps': 1200,
      'expected_fee': 12,
      'expected_net': 88,
      'description': 'Standard 100 @ 12%',
    },
    // Rounding down: 99 @ 12% = 11 (not 12)
    {
      'gross': 99,
      'fee_rate_bps': 1200,
      'expected_fee': 11,
      'expected_net': 88,
      'description': 'Rounding down: 99 @ 12%',
    },
    // 1000 @ 10% = 100
    {
      'gross': 1000,
      'fee_rate_bps': 1000,
      'expected_fee': 100,
      'expected_net': 900,
      'description': '1000 @ 10%',
    },
    // Small amount: 10 @ 12% = 1
    {
      'gross': 10,
      'fee_rate_bps': 1200,
      'expected_fee': 1,
      'expected_net': 9,
      'description': 'Small amount: 10 @ 12%',
    },
    // Very small: 1 @ 12% = 0
    {
      'gross': 1,
      'fee_rate_bps': 1200,
      'expected_fee': 0,
      'expected_net': 1,
      'description': 'Minimum amount: 1 @ 12% = 0 fee',
    },
    // Large amount
    {
      'gross': 100000,
      'fee_rate_bps': 1200,
      'expected_fee': 12000,
      'expected_net': 88000,
      'description': 'Large amount: 100000 @ 12%',
    },
  ];
}
