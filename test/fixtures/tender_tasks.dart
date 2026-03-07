/// Test fixtures for tender task lifecycle scenarios.
///
/// These fixtures provide consistent test data for unit and widget tests
/// related to tender tasks, offers, and the complete lifecycle from
/// creation through acceptance, payment, delivery, and completion.
library;

import 'package:sline_app/core/services/logger_service.dart';

import 'fixtures.dart';

/// Log tag for test fixture operations
const String _logTag = 'test_fixture';

// Sample UUIDs for tender task testing - unique to tender fixtures
const String tenderTestTaskId = 'task-550e8400-e29b-41d4-a716-446655440000';
const String tenderTestTaskIdOpen = 'task-open-e29b-41d4-a716-446655440001';
const String tenderTestTaskIdAssigned = 'task-assigned-e29b-41d4-a716-446655440002';
const String tenderTestTaskIdInProgress = 'task-inprogress-e29b-41d4-a716-446655440003';
const String tenderTestRequestId = 'req-550e8400-e29b-41d4-a716-446655440000';
const String tenderTestRequestIdPending = 'req-pending-e29b-41d4-a716-446655440001';
const String tenderTestRequestIdAccepted = 'req-accepted-e29b-41d4-a716-446655440002';
const String tenderTestClientId = '550e8400-e29b-41d4-a716-446655440001';
const String tenderTestFreelancerId = '550e8400-e29b-41d4-a716-446655440002';

/// Task fixture: Open tender task awaiting offers
///
/// Status: open
/// No assigned freelancer
/// Ready for freelancers to submit offers
final Map<String, dynamic> openTenderTask = () {
  AppLogger.d('Creating openTenderTask fixture', tag: _logTag);
  return <String, dynamic>{
    'id': tenderTestTaskIdOpen,
    'title': 'Open Tender Task - Looking for Flutter Developer',
    'description': 'I need a Flutter developer to build a mobile app for my business.',
    'budget': 500.0,
    'budget_cents': 50000,
    'status': 'open',
    'task_type': 'tender',
    'client_id': tenderTestClientId,
    'owner_id': tenderTestClientId,
    'assigned_freelancer_id': null,
    'freelancer_id': null,
    'skills': <String>['Flutter', 'Dart', 'Mobile Development'],
    'category_id': 'category-mobile-dev',
    'image_paths': <String>['tasks/test-task-1/image1.png'],
    'delivered_at': null,
    'review_expires_at': null,
    'revisions_total': 3,
    'revisions_used': 0,
    'revision_note': null,
    'revision_requested_at': null,
    'created_at': '2026-03-01T10:00:00.000Z',
    'updated_at': '2026-03-01T10:00:00.000Z',
  };
}();

/// Task fixture: Assigned task (offer accepted, awaiting payment)
///
/// Status: assigned
/// Accepted offer exists but not paid yet
/// 24 hours until auto-expiry
final Map<String, dynamic> assignedTenderTask = () {
  AppLogger.d('Creating assignedTenderTask fixture', tag: _logTag);
  final awardedAt = DateTime.now().subtract(const Duration(hours: 24));
  return <String, dynamic>{
    'id': tenderTestTaskIdAssigned,
    'title': 'Assigned Task - Payment Pending',
    'description': 'Flutter app development project',
    'budget': 750.0,
    'budget_cents': 75000,
    'status': 'assigned',
    'task_type': 'tender',
    'client_id': tenderTestClientId,
    'owner_id': tenderTestClientId,
    'assigned_freelancer_id': tenderTestFreelancerId,
    'freelancer_id': null,
    'skills': <String>['Flutter', 'Firebase'],
    'category_id': 'category-mobile-dev',
    'image_paths': <String>[],
    'delivered_at': null,
    'review_expires_at': null,
    'revisions_total': 3,
    'revisions_used': 0,
    'revision_note': null,
    'revision_requested_at': null,
    'created_at': '2026-03-01T10:00:00.000Z',
    'updated_at': awardedAt.toIso8601String(),
  };
}();

/// Task fixture: In-progress task (payment completed)
///
/// Status: in_progress
/// Freelancer actively working
/// Payment held in escrow
final Map<String, dynamic> inProgressTenderTask = () {
  AppLogger.d('Creating inProgressTenderTask fixture', tag: _logTag);
  return <String, dynamic>{
    'id': tenderTestTaskIdInProgress,
    'title': 'In Progress Task - Work Underway',
    'description': 'Flutter app development - payment complete',
    'budget': 1000.0,
    'budget_cents': 100000,
    'status': 'in_progress',
    'task_type': 'tender',
    'client_id': tenderTestClientId,
    'owner_id': tenderTestClientId,
    'assigned_freelancer_id': tenderTestFreelancerId,
    'freelancer_id': tenderTestFreelancerId,
    'skills': <String>['Flutter', 'Firebase', 'State Management'],
    'category_id': 'category-mobile-dev',
    'image_paths': <String>['tasks/test-task-3/design_mock.png'],
    'delivered_at': null,
    'review_expires_at': null,
    'revisions_total': 3,
    'revisions_used': 0,
    'revision_note': null,
    'revision_requested_at': null,
    'created_at': '2026-03-01T10:00:00.000Z',
    'updated_at': '2026-03-02T14:00:00.000Z',
  };
}();

/// Task fixture: Delivered task awaiting client approval
///
/// Status: delivered
/// Freelancer submitted work
/// Client has 7 days to approve or request revision
final Map<String, dynamic> deliveredTenderTask = () {
  AppLogger.d('Creating deliveredTenderTask fixture', tag: _logTag);
  final deliveredAt = DateTime.now().subtract(const Duration(days: 3));
  final reviewExpiresAt = deliveredAt.add(const Duration(days: 7));
  return <String, dynamic>{
    'id': 'task-delivered-e29b-41d4-a716-446655440004',
    'title': 'Delivered Task - Awaiting Approval',
    'description': 'Flutter app complete - please review',
    'budget': 1000.0,
    'budget_cents': 100000,
    'status': 'delivered',
    'task_type': 'tender',
    'client_id': tenderTestClientId,
    'owner_id': tenderTestClientId,
    'assigned_freelancer_id': tenderTestFreelancerId,
    'freelancer_id': tenderTestFreelancerId,
    'skills': <String>['Flutter'],
    'category_id': 'category-mobile-dev',
    'image_paths': <String>[],
    'delivered_at': deliveredAt.toIso8601String(),
    'review_expires_at': reviewExpiresAt.toIso8601String(),
    'revisions_total': 3,
    'revisions_used': 0,
    'revision_note': null,
    'revision_requested_at': null,
    'created_at': '2026-03-01T10:00:00.000Z',
    'updated_at': deliveredAt.toIso8601String(),
  };
}();

/// Task fixture: Closed completed task
///
/// Status: closed
/// Work approved, payment released
/// Task lifecycle complete
final Map<String, dynamic> closedTenderTask = () {
  AppLogger.d('Creating closedTenderTask fixture', tag: _logTag);
  return <String, dynamic>{
    'id': 'task-closed-e29b-41d4-a716-446655440005',
    'title': 'Closed Task - Successfully Completed',
    'description': 'Flutter app development - completed',
    'budget': 1000.0,
    'budget_cents': 100000,
    'status': 'closed',
    'task_type': 'tender',
    'client_id': testClientId,
    'owner_id': testClientId,
    'assigned_freelancer_id': testFreelancerId,
    'freelancer_id': testFreelancerId,
    'skills': <String>['Flutter'],
    'category_id': 'category-mobile-dev',
    'image_paths': <String>[],
    'delivered_at': '2026-03-05T10:00:00.000Z',
    'review_expires_at': '2026-03-12T10:00:00.000Z',
    'revisions_total': 3,
    'revisions_used': 1,
    'revision_note': null,
    'revision_requested_at': null,
    'created_at': '2026-03-01T10:00:00.000Z',
    'updated_at': '2026-03-06T10:00:00.000Z',
  };
}();

/// Task fixture: Canceled task
///
/// Status: canceled
/// Task canceled before or after acceptance
final Map<String, dynamic> canceledTenderTask = () {
  AppLogger.d('Creating canceledTenderTask fixture', tag: _logTag);
  return <String, dynamic>{
    'id': 'task-canceled-e29b-41d4-a716-446655440006',
    'title': 'Canceled Task - No Longer Needed',
    'description': 'Flutter app - project canceled',
    'budget': 500.0,
    'budget_cents': 50000,
    'status': 'canceled',
    'task_type': 'tender',
    'client_id': tenderTestClientId,
    'owner_id': tenderTestClientId,
    'assigned_freelancer_id': null,
    'freelancer_id': null,
    'skills': <String>['Flutter'],
    'category_id': 'category-mobile-dev',
    'image_paths': <String>[],
    'delivered_at': null,
    'review_expires_at': null,
    'revisions_total': 3,
    'revisions_used': 0,
    'revision_note': null,
    'revision_requested_at': null,
    'created_at': '2026-03-01T10:00:00.000Z',
    'updated_at': '2026-03-02T10:00:00.000Z',
  };
}();

/// Task Request fixture: Pending offer
///
/// Status: pending
/// Freelancer submitted offer, client hasn't decided
final Map<String, dynamic> pendingTaskRequest = () {
  AppLogger.d('Creating pendingTaskRequest fixture', tag: _logTag);
  return <String, dynamic>{
    'id': tenderTestRequestIdPending,
    'task_id': tenderTestTaskIdOpen,
    'freelancer_id': tenderTestFreelancerId,
    'bidder_id': tenderTestFreelancerId,
    'client_id': tenderTestClientId,
    'price': 450.0,
    'amount': 450.0,
    'days': 5,
    'duration_days': 5,
    'note': 'I can complete this in 5 days with high quality.',
    'message': 'I can complete this in 5 days with high quality.',
    'status': 'pending',
    'payment_status': 'unpaid',
    'awarded_at': null,
    'awarded_by': null,
    'payment_deadline': null,
    'fee_rate_applied_bps': null,
    'fee_amount': null,
    'net_amount': null,
    'initiated_by': tenderTestFreelancerId,
    'deleted_at': null,
    'updated_at': '2026-03-01T12:00:00.000Z',
    'created_at': '2026-03-01T12:00:00.000Z',
  };
}();

/// Task Request fixture: Accepted offer (awaiting payment)
///
/// Status: accepted
/// Client accepted, payment not yet made
/// Will auto-expire if not paid within 48 hours
final Map<String, dynamic> acceptedUnpaidTaskRequest = () {
  AppLogger.d('Creating acceptedUnpaidTaskRequest fixture', tag: _logTag);
  final awardedAt = DateTime.now().subtract(const Duration(hours: 24));
  final paymentDeadline = awardedAt.add(const Duration(hours: 48));
  return <String, dynamic>{
    'id': tenderTestRequestIdAccepted,
    'task_id': tenderTestTaskIdAssigned,
    'freelancer_id': tenderTestFreelancerId,
    'bidder_id': tenderTestFreelancerId,
    'client_id': tenderTestClientId,
    'price': 500.0,
    'amount': 500.0,
    'days': 7,
    'duration_days': 7,
    'note': 'I will build a complete Flutter app',
    'message': 'I will build a complete Flutter app',
    'status': 'accepted',
    'payment_status': 'unpaid',
    'awarded_at': awardedAt.toIso8601String(),
    'awarded_by': tenderTestClientId,
    'payment_deadline': paymentDeadline.toIso8601String(),
    'fee_rate_applied_bps': 1000, // 10% locked at award time
    'fee_amount': 5000, // 50.00 IQD in cents
    'net_amount': 45000, // 450.00 IQD in cents
    'initiated_by': tenderTestFreelancerId,
    'deleted_at': null,
    'updated_at': awardedAt.toIso8601String(),
    'created_at': '2026-03-01T12:00:00.000Z',
  };
}();

/// Task Request fixture: Accepted and paid (escrow held)
///
/// Status: accepted
/// Payment_status: held
/// Funds locked in escrow
final Map<String, dynamic> acceptedPaidTaskRequest = () {
  AppLogger.d('Creating acceptedPaidTaskRequest fixture', tag: _logTag);
  return <String, dynamic>{
    'id': 'req-paid-e29b-41d4-a716-446655440003',
    'task_id': tenderTestTaskIdInProgress,
    'freelancer_id': tenderTestFreelancerId,
    'bidder_id': tenderTestFreelancerId,
    'client_id': tenderTestClientId,
    'price': 1000.0,
    'amount': 1000.0,
    'days': 10,
    'duration_days': 10,
    'note': 'Complete Flutter development with Firebase backend',
    'message': 'Complete Flutter development with Firebase backend',
    'status': 'accepted',
    'payment_status': 'held',
    'awarded_at': '2026-03-02T10:00:00.000Z',
    'awarded_by': tenderTestClientId,
    'payment_deadline': null,
    'fee_rate_applied_bps': 1000,
    'fee_amount': 10000,
    'net_amount': 90000,
    'initiated_by': tenderTestFreelancerId,
    'deleted_at': null,
    'updated_at': '2026-03-02T14:00:00.000Z',
    'created_at': '2026-03-01T12:00:00.000Z',
  };
}();

/// Task Request fixture: Expired offer (auto-expired)
///
/// Created for testing the cleanup cron functionality
final Map<String, dynamic> expiredTaskRequest = () {
  AppLogger.d('Creating expiredTaskRequest fixture', tag: _logTag);
  final awardedAt = DateTime.now().subtract(const Duration(hours: 49));
  return <String, dynamic>{
    'id': 'req-expired-e29b-41d4-a716-446655440004',
    'task_id': 'task-expired-e29b-41d4-a716-446655440007',
    'freelancer_id': tenderTestFreelancerId,
    'bidder_id': tenderTestFreelancerId,
    'client_id': tenderTestClientId,
    'price': 300.0,
    'amount': 300.0,
    'days': 3,
    'duration_days': 3,
    'note': 'This offer will auto-expire',
    'message': 'This offer will auto-expire',
    'status': 'accepted',
    'payment_status': 'unpaid',
    'awarded_at': awardedAt.toIso8601String(),
    'awarded_by': tenderTestClientId,
    'payment_deadline': awardedAt.add(const Duration(hours: 48)).toIso8601String(),
    'fee_rate_applied_bps': 1000,
    'fee_amount': 3000,
    'net_amount': 27000,
    'initiated_by': tenderTestFreelancerId,
    'deleted_at': null,
    'updated_at': awardedAt.toIso8601String(),
    'created_at': '2026-03-01T12:00:00.000Z',
  };
}();

/// RPC Response fixture: Successful acceptance
///
/// Response from accept_task_request on success
final Map<String, dynamic> acceptTaskRequestSuccessResponse = () {
  AppLogger.d('Creating acceptTaskRequestSuccessResponse fixture', tag: _logTag);
  return <String, dynamic>{
    'result': 'accepted',
    'task_id': tenderTestTaskIdOpen,
    'request_id': tenderTestRequestIdPending,
    'new_status': 'assigned',
  };
}();

/// RPC Response fixture: Idempotency hit
///
/// Response when task request was already accepted
final Map<String, dynamic> acceptTaskRequestAlreadyAcceptedResponse = () {
  AppLogger.d('Creating acceptTaskRequestAlreadyAcceptedResponse fixture', tag: _logTag);
  return <String, dynamic>{
    'result': 'already_accepted',
    'task_id': tenderTestTaskIdAssigned,
    'request_id': tenderTestRequestIdAccepted,
    'message': 'This offer has already been accepted',
  };
}();

/// RPC Response fixture: Price mismatch error
///
/// Response when expected price doesn't match actual
final Map<String, dynamic> acceptTaskRequestPriceMismatchResponse = () {
  AppLogger.d('Creating acceptTaskRequestPriceMismatchResponse fixture', tag: _logTag);
  return <String, dynamic>{
    'error': 'PRICE_MISMATCH',
    'message': 'Offer price changed from 45000 to 50000 cents',
    'expected_cents': 45000,
    'actual_cents': 50000,
    'task_id': tenderTestTaskIdOpen,
    'request_id': tenderTestRequestIdPending,
  };
}();

/// PostgrestException fixture: Price mismatch
///
/// Exception thrown when price mismatch occurs
final MockPostgrestExceptionPriceMismatch mockPriceMismatchException = () {
  AppLogger.d('Creating mockPriceMismatchException fixture', tag: _logTag);
  return MockPostgrestExceptionPriceMismatch(
    message: 'PRICE_MISMATCH: Offer price changed from 45000 to 50000 cents',
    code: 'P0001', // Custom error code
    details: 'The freelancer recently updated their offer price',
  );
}();

/// Exception class for price mismatch testing
class MockPostgrestExceptionPriceMismatch implements Exception {
  final String message;
  final String? code;
  final String? details;

  MockPostgrestExceptionPriceMismatch({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'PostgrestException: $message (code: $code)';
}

/// Helper to create a price mismatch exception with specific values
MockPostgrestExceptionPriceMismatch createPriceMismatchException({
  required int expectedCents,
  required int actualCents,
}) {
  AppLogger.d(
    'Creating price mismatch exception',
    tag: _logTag,
    json: {'expected_cents': expectedCents, 'actual_cents': actualCents},
  );
  return MockPostgrestExceptionPriceMismatch(
    message: 'PRICE_MISMATCH: Offer price changed from $expectedCents to $actualCents cents',
    code: 'P0001',
    details: 'The freelancer recently updated their offer price. Please review the new terms.',
  );
}

/// Helper to create a custom task fixture
///
/// [baseTask] - Base task to customize
/// [overrides] - Field values to override
Map<String, dynamic> createCustomTask(
  Map<String, dynamic> baseTask,
  Map<String, dynamic> overrides,
) {
  AppLogger.d(
    'Creating custom task fixture',
    tag: _logTag,
    json: {'base_status': baseTask['status'], 'overrides': overrides.keys.toList()},
  );
  return <String, dynamic>{
    ...baseTask,
    ...overrides,
  };
}

/// Helper to create a custom task request fixture
///
/// [baseRequest] - Base request to customize
/// [overrides] - Field values to override
Map<String, dynamic> createCustomTaskRequest(
  Map<String, dynamic> baseRequest,
  Map<String, dynamic> overrides,
) {
  AppLogger.d(
    'Creating custom task request fixture',
    tag: _logTag,
    json: {'base_status': baseRequest['status'], 'overrides': overrides.keys.toList()},
  );
  return <String, dynamic>{
    ...baseRequest,
    ...overrides,
  };
}
