/// TaskRequest factory for generating test data.
///
/// Provides factory methods for creating TaskRequest model instances
/// and raw database row maps for testing purposes.
library;

import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';

/// Log tag for test fixture operations
const String _logTag = 'test_fixture';

// Sample UUIDs for consistent testing
const String _defaultTaskId = 'task-550e8400-e29b-41d4-a716-446655440000';
const String _defaultBidderId = 'bidder-550e8400-e29b-41d4-a716-446655440001';
const String _defaultRequestId = 'req-550e8400-e29b-41d4-a716-446655440002';
const String _defaultClientId = 'client-550e8400-e29b-41d4-a716-446655440003';

/// Default values for TaskRequest fields
const int _defaultPrice = 50000; // 500.00 in cents
const int _defaultDays = 5;
const String _defaultNote = 'I can complete this task with high quality.';
const String _defaultBidderName = 'Test Freelancer';
const String _defaultBidderAvatar = 'avatars/test-freelancer.png';
const String _defaultTaskTitle = 'Test Task Title';

/// Creates a TaskRequest model with sensible defaults.
///
/// All parameters are optional and will use default values if not provided.
TaskRequest createTaskRequest({
  String? id,
  String? taskId,
  String? bidderId,
  int? price,
  int? days,
  String? note,
  OfferStatus? status,
  PaymentStatus? paymentStatus,
  DateTime? createdAt,
  String? bidderName,
  String? bidderAvatar,
  String? taskTitle,
}) {
  final now = DateTime.now();
  final requestId = id ?? '$_defaultRequestId-${now.millisecondsSinceEpoch}';

  AppLogger.d(
    'Creating TaskRequest fixture',
    tag: _logTag,
    json: {
      'id': requestId,
      'status': (status ?? OfferStatus.pending).name,
      'price': price ?? _defaultPrice,
    },
  );

  return TaskRequest(
    id: requestId,
    taskId: taskId ?? _defaultTaskId,
    bidderId: bidderId ?? _defaultBidderId,
    price: price ?? _defaultPrice,
    days: days ?? _defaultDays,
    note: note ?? _defaultNote,
    status: status ?? OfferStatus.pending,
    paymentStatus: paymentStatus ?? PaymentStatus.unpaid,
    createdAt: createdAt ?? now,
    bidderName: bidderName ?? _defaultBidderName,
    bidderAvatar: bidderAvatar ?? _defaultBidderAvatar,
    taskTitle: taskTitle ?? _defaultTaskTitle,
  );
}

/// Creates a raw database row map for TaskRequest.
///
/// Useful for mocking Supabase responses or testing fromMap parsing.
Map<String, dynamic> createTaskRequestRow({
  String? id,
  String? taskId,
  String? bidderId,
  String? freelancerId,
  int? price,
  int? days,
  int? durationDays,
  String? note,
  String? message,
  String? status,
  String? paymentStatus,
  String? createdAt,
  String? paymentDeadline,
  String? awardedAt,
  String? awardedBy,
  String? clientId,
  Map<String, dynamic>? profiles,
  Map<String, dynamic>? tasks,
}) {
  final now = DateTime.now();
  final requestId = id ?? '$_defaultRequestId-${now.millisecondsSinceEpoch}';
  final effectiveBidderId = bidderId ?? freelancerId ?? _defaultBidderId;

  AppLogger.d(
    'Creating TaskRequest DB row fixture',
    tag: _logTag,
    json: {
      'id': requestId,
      'status': status ?? 'pending',
      'price': price ?? _defaultPrice,
    },
  );

  return <String, dynamic>{
    'id': requestId,
    'task_id': taskId ?? _defaultTaskId,
    'bidder_id': effectiveBidderId,
    'freelancer_id': effectiveBidderId,
    'client_id': clientId ?? _defaultClientId,
    'price': price ?? _defaultPrice,
    'amount': (price ?? _defaultPrice) / 100, // cents to currency
    'days': days ?? _defaultDays,
    'duration_days': durationDays ?? days ?? _defaultDays,
    'note': note ?? message ?? _defaultNote,
    'message': message ?? note ?? _defaultNote,
    'status': status ?? 'pending',
    'payment_status': paymentStatus ?? 'unpaid',
    'created_at': createdAt ?? now.toIso8601String(),
    'payment_deadline': paymentDeadline,
    'awarded_at': awardedAt,
    'awarded_by': awardedBy,
    if (profiles != null) 'profiles': profiles,
    if (tasks != null) 'tasks': tasks,
  };
}

/// Creates a list of TaskRequest objects.
///
/// [count] - Number of TaskRequests to create
/// [baseOverrides] - Optional base overrides applied to all items
/// [indexOverrides] - Optional function to generate per-index overrides
List<TaskRequest> createTaskRequestList(
  int count, {
  TaskRequest? baseOverrides,
  TaskRequest Function(int index)? indexOverrides,
}) {
  AppLogger.d(
    'Creating TaskRequest list',
    tag: _logTag,
    json: {'count': count},
  );

  return List.generate(count, (index) {
    final base = baseOverrides;
    final indexSpecific = indexOverrides?.call(index);

    // Start with defaults, apply base overrides, then index-specific
    return createTaskRequest(
      id: indexSpecific?.id ?? base?.id ?? '$_defaultRequestId-$index',
      taskId: indexSpecific?.taskId ?? base?.taskId,
      bidderId:
          indexSpecific?.bidderId ??
          base?.bidderId ??
          '$_defaultBidderId-$index',
      price: indexSpecific?.price ?? base?.price,
      days: indexSpecific?.days ?? base?.days,
      note: indexSpecific?.note ?? base?.note ?? 'Bid $index: $_defaultNote',
      status: indexSpecific?.status ?? base?.status,
      paymentStatus: indexSpecific?.paymentStatus ?? base?.paymentStatus,
      createdAt: indexSpecific?.createdAt ?? base?.createdAt,
      bidderName:
          indexSpecific?.bidderName ?? base?.bidderName ?? 'Freelancer $index',
      bidderAvatar: indexSpecific?.bidderAvatar ?? base?.bidderAvatar,
      taskTitle: indexSpecific?.taskTitle ?? base?.taskTitle,
    );
  });
}

/// Creates a pending bid TaskRequest.
///
/// Status: pending
/// PaymentStatus: unpaid
/// Client has not yet responded to the bid
TaskRequest createPendingBid({
  String? id,
  String? taskId,
  String? bidderId,
  int? price,
  int? days,
  String? note,
  DateTime? createdAt,
  String? bidderName,
  String? bidderAvatar,
  String? taskTitle,
}) {
  AppLogger.d('Creating pending bid fixture', tag: _logTag);

  return createTaskRequest(
    id: id,
    taskId: taskId,
    bidderId: bidderId,
    price: price,
    days: days,
    note: note ?? 'Pending bid awaiting client response',
    status: OfferStatus.pending,
    paymentStatus: PaymentStatus.unpaid,
    createdAt: createdAt,
    bidderName: bidderName,
    bidderAvatar: bidderAvatar,
    taskTitle: taskTitle,
  );
}

/// Creates an accepted bid TaskRequest.
///
/// Status: accepted
/// PaymentStatus: unpaid (awaiting payment)
/// Client accepted the offer but hasn't paid yet
TaskRequest createAcceptedBid({
  String? id,
  String? taskId,
  String? bidderId,
  int? price,
  int? days,
  String? note,
  DateTime? createdAt,
  String? bidderName,
  String? bidderAvatar,
  String? taskTitle,
}) {
  AppLogger.d('Creating accepted bid fixture', tag: _logTag);

  final now = DateTime.now();
  final awardedAt = createdAt ?? now.subtract(const Duration(hours: 12));

  return createTaskRequest(
    id: id,
    taskId: taskId,
    bidderId: bidderId,
    price: price,
    days: days,
    note: note ?? 'Accepted bid - awaiting client payment',
    status: OfferStatus.accepted,
    paymentStatus: PaymentStatus.unpaid,
    createdAt: awardedAt,
    bidderName: bidderName,
    bidderAvatar: bidderAvatar,
    taskTitle: taskTitle,
  );
}

/// Creates an expired bid TaskRequest.
///
/// Status: accepted (but expired due to non-payment)
/// PaymentStatus: unpaid
/// Created more than 24 hours ago, past payment deadline
TaskRequest createExpiredBid({
  String? id,
  String? taskId,
  String? bidderId,
  int? price,
  int? days,
  String? note,
  DateTime? createdAt,
  DateTime? awardedAt,
  String? bidderName,
  String? bidderAvatar,
  String? taskTitle,
}) {
  AppLogger.d('Creating expired bid fixture', tag: _logTag);

  final now = DateTime.now();
  // Default to 49 hours ago (past the 48h payment window)
  final expiredTime = awardedAt ?? now.subtract(const Duration(hours: 49));

  return createTaskRequest(
    id: id,
    taskId: taskId,
    bidderId: bidderId,
    price: price,
    days: days,
    note: note ?? 'Expired bid - payment deadline passed',
    status: OfferStatus.accepted,
    paymentStatus: PaymentStatus.unpaid,
    createdAt: createdAt ?? expiredTime.subtract(const Duration(hours: 24)),
    bidderName: bidderName,
    bidderAvatar: bidderAvatar,
    taskTitle: taskTitle,
  );
}

/// Creates a TaskRequest with payment held in escrow.
///
/// Status: accepted
/// PaymentStatus: held
/// Payment completed, funds locked in escrow
TaskRequest createPaidBid({
  String? id,
  String? taskId,
  String? bidderId,
  int? price,
  int? days,
  String? note,
  DateTime? createdAt,
  String? bidderName,
  String? bidderAvatar,
  String? taskTitle,
}) {
  AppLogger.d('Creating paid bid fixture', tag: _logTag);

  return createTaskRequest(
    id: id,
    taskId: taskId,
    bidderId: bidderId,
    price: price,
    days: days,
    note: note ?? 'Paid bid - funds in escrow',
    status: OfferStatus.accepted,
    paymentStatus: PaymentStatus.held,
    createdAt: createdAt,
    bidderName: bidderName,
    bidderAvatar: bidderAvatar,
    taskTitle: taskTitle,
  );
}

/// Creates a rejected bid TaskRequest.
///
/// Status: rejected
/// PaymentStatus: unpaid
/// Client declined the offer
TaskRequest createRejectedBid({
  String? id,
  String? taskId,
  String? bidderId,
  int? price,
  int? days,
  String? note,
  DateTime? createdAt,
  String? bidderName,
  String? bidderAvatar,
  String? taskTitle,
}) {
  AppLogger.d('Creating rejected bid fixture', tag: _logTag);

  return createTaskRequest(
    id: id,
    taskId: taskId,
    bidderId: bidderId,
    price: price,
    days: days,
    note: note ?? 'Rejected bid - client chose another freelancer',
    status: OfferStatus.rejected,
    paymentStatus: PaymentStatus.unpaid,
    createdAt: createdAt,
    bidderName: bidderName,
    bidderAvatar: bidderAvatar,
    taskTitle: taskTitle,
  );
}

/// Creates a withdrawn bid TaskRequest.
///
/// Status: withdrawn
/// PaymentStatus: unpaid
/// Freelancer withdrew their offer
TaskRequest createWithdrawnBid({
  String? id,
  String? taskId,
  String? bidderId,
  int? price,
  int? days,
  String? note,
  DateTime? createdAt,
  String? bidderName,
  String? bidderAvatar,
  String? taskTitle,
}) {
  AppLogger.d('Creating withdrawn bid fixture', tag: _logTag);

  return createTaskRequest(
    id: id,
    taskId: taskId,
    bidderId: bidderId,
    price: price,
    days: days,
    note: note ?? 'Withdrawn bid - freelancer no longer available',
    status: OfferStatus.withdrawn,
    paymentStatus: PaymentStatus.unpaid,
    createdAt: createdAt,
    bidderName: bidderName,
    bidderAvatar: bidderAvatar,
    taskTitle: taskTitle,
  );
}

/// Helper to create a DB row for a pending bid.
Map<String, dynamic> createPendingBidRow({
  String? id,
  String? taskId,
  String? bidderId,
  int? price,
  int? days,
  String? note,
  String? createdAt,
  Map<String, dynamic>? profiles,
  Map<String, dynamic>? tasks,
}) {
  AppLogger.d('Creating pending bid DB row fixture', tag: _logTag);

  return createTaskRequestRow(
    id: id,
    taskId: taskId,
    bidderId: bidderId,
    price: price,
    days: days,
    note: note ?? 'Pending bid awaiting client response',
    status: 'pending',
    paymentStatus: 'unpaid',
    createdAt: createdAt,
    profiles:
        profiles ??
        <String, dynamic>{
          'full_name': 'Test Freelancer',
          'avatar_url': 'avatars/test-freelancer.png',
        },
    tasks: tasks ?? <String, dynamic>{'title': 'Test Task Title'},
  );
}

/// Helper to create a DB row for an accepted bid.
Map<String, dynamic> createAcceptedBidRow({
  String? id,
  String? taskId,
  String? bidderId,
  int? price,
  int? days,
  String? note,
  String? createdAt,
  String? awardedAt,
  String? awardedBy,
  String? paymentDeadline,
  String? clientId,
  Map<String, dynamic>? profiles,
  Map<String, dynamic>? tasks,
}) {
  AppLogger.d('Creating accepted bid DB row fixture', tag: _logTag);

  final now = DateTime.now();
  final effectiveAwardedAt =
      awardedAt ?? now.subtract(const Duration(hours: 12)).toIso8601String();
  final effectiveDeadline =
      paymentDeadline ??
      DateTime.parse(
        effectiveAwardedAt,
      ).add(const Duration(hours: 48)).toIso8601String();

  return createTaskRequestRow(
    id: id,
    taskId: taskId,
    bidderId: bidderId,
    price: price,
    days: days,
    note: note ?? 'Accepted bid awaiting payment',
    status: 'accepted',
    paymentStatus: 'unpaid',
    createdAt: createdAt,
    awardedAt: effectiveAwardedAt,
    awardedBy: awardedBy ?? clientId ?? _defaultClientId,
    paymentDeadline: effectiveDeadline,
    clientId: clientId,
    profiles: profiles,
    tasks: tasks,
  );
}

/// Helper to create a DB row for an expired bid.
Map<String, dynamic> createExpiredBidRow({
  String? id,
  String? taskId,
  String? bidderId,
  int? price,
  int? days,
  String? note,
  String? createdAt,
  String? awardedAt,
  String? awardedBy,
  String? clientId,
  Map<String, dynamic>? profiles,
  Map<String, dynamic>? tasks,
}) {
  AppLogger.d('Creating expired bid DB row fixture', tag: _logTag);

  final now = DateTime.now();
  final expiredAwardedAt =
      awardedAt ?? now.subtract(const Duration(hours: 49)).toIso8601String();
  final expiredDeadline = DateTime.parse(
    expiredAwardedAt,
  ).add(const Duration(hours: 48)).toIso8601String();

  return createTaskRequestRow(
    id: id,
    taskId: taskId,
    bidderId: bidderId,
    price: price,
    days: days,
    note: note ?? 'Expired bid - payment deadline passed',
    status: 'accepted',
    paymentStatus: 'unpaid',
    createdAt:
        createdAt ??
        DateTime.parse(
          expiredAwardedAt,
        ).subtract(const Duration(hours: 24)).toIso8601String(),
    awardedAt: expiredAwardedAt,
    awardedBy: awardedBy ?? clientId ?? _defaultClientId,
    paymentDeadline: expiredDeadline,
    clientId: clientId,
    profiles: profiles,
    tasks: tasks,
  );
}
