// Task Requests (Offers/Bids) domain model.
// Represents a freelancer's offer on a task, including price,
// estimated days, an optional note, status, and timestamps.
import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/proposals/models/proposal_model.dart';

@immutable
class TaskRequest {
  final String id;
  final String taskId;
  final String bidderId;
  final int price; // Use int for price as DB schema uses BIGINT
  final int days;
  final String? note;
  final OfferStatus status;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;

  // Joined fields from profiles table
  final String? bidderName;
  final String? bidderAvatar;

  // Joined fields from tasks table
  final String? taskTitle;

  const TaskRequest({
    required this.id,
    required this.taskId,
    required this.bidderId,
    required this.price, // price is int to match DB
    required this.days,
    this.note,
    required this.status,
    this.paymentStatus = PaymentStatus.unpaid,
    required this.createdAt,
    this.bidderName,
    this.bidderAvatar,
    this.taskTitle,
  });

  bool get isPending => status == OfferStatus.pending;
  bool get isAccepted => status == OfferStatus.accepted;
  bool get isRejected => status == OfferStatus.rejected;
  bool get isUnknown => status == OfferStatus.unknown;

  factory TaskRequest.fromMap(Map<String, dynamic> map) {
    try {
      // Parsing price as int to match DB BIGINT type
      final priceValue = (map['price'] as num).toInt();

      // Extract profile data from nested 'profiles' object if it exists (from JOIN)
      final profileData = map['profiles'] as Map<String, dynamic>?;
      final String? parsedBidderName = profileData?['full_name'] as String?;
      final String? parsedBidderAvatar = profileData?['avatar_url'] as String?;

      // Extract task title from nested 'tasks' object if it exists (from JOIN)
      final taskData = map['tasks'] as Map<String, dynamic>?;
      final String? parsedTaskTitle = taskData?['title'] as String?;

      return TaskRequest(
        id: map['id'] as String,
        taskId: map['task_id'] as String,
        // Map from freelancer_id (canonical) or bidder_id (legacy)
        // Handle null case safely
        bidderId:
            (map['freelancer_id'] as String?) ??
            (map['bidder_id'] as String?) ??
            '', // Fallback to empty string if both are null
        price: priceValue,
        days: (map['days'] as int?) ?? (map['duration_days'] as int?) ?? 0,
        note: (map['note'] ?? map['message']) as String?,
        status: _mapDbOfferStatusToEnum(map['status'] as String?),
        paymentStatus: _mapDbPaymentStatusToEnum(
          map['payment_status'] as String?,
        ),
        createdAt: DateTime.parse(map['created_at'] as String),
        bidderName: parsedBidderName,
        bidderAvatar: parsedBidderAvatar,
        taskTitle: parsedTaskTitle,
      );
    } catch (e, st) {
      AppLogger.e(
        'Failed to parse TaskRequest',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Builds a TaskRequest from a ProposalModel (e.g. when owner list uses ProposalRepository).
  factory TaskRequest.fromProposal(ProposalModel p) {
    return TaskRequest(
      id: p.id,
      taskId: p.taskId,
      bidderId: p.bidderId,
      price: p.price,
      days: p.days,
      note: p.note,
      status: p.status,
      paymentStatus: p.paymentStatus,
      createdAt: p.createdAt,
      bidderName: p.bidderName,
      bidderAvatar: p.bidderAvatar,
      taskTitle: p.taskTitle,
    );
  }

  Map<String, dynamic> toMap({bool forInsert = false}) {
    final data = <String, dynamic>{
      'id': id,
      'task_id': taskId,
      'freelancer_id': bidderId, // Write to canonical column
      'bidder_id': bidderId, // Write to legacy column for backward compat
      'price': price, // price remains int
      'days': days,
      'note': note,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };

    if (forInsert) {
      return <String, dynamic>{
        'task_id': taskId,
        'freelancer_id': bidderId, // Write to canonical column
        'bidder_id': bidderId, // Write to legacy column for backward compat
        'price': price, // price remains int
        'days': days,
        if (note != null && note!.trim().isNotEmpty) 'note': note,
      };
    }

    return data;
  }

  TaskRequest copyWith({
    String? id,
    String? taskId,
    String? bidderId,
    int? price, // price is int to match DB
    int? days,
    String? note,
    OfferStatus? status,
    PaymentStatus? paymentStatus,
    DateTime? createdAt,
    String? bidderName,
    String? bidderAvatar,
    String? taskTitle,
  }) {
    return TaskRequest(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      bidderId: bidderId ?? this.bidderId,
      price: price ?? this.price,
      days: days ?? this.days,
      note: note ?? this.note,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      bidderName: bidderName ?? this.bidderName,
      bidderAvatar: bidderAvatar ?? this.bidderAvatar,
      taskTitle: taskTitle ?? this.taskTitle,
    );
  }

  @override
  String toString() =>
      'TaskRequest(id: $id, taskId: $taskId, bidderId: $bidderId, price: $price, days: $days, status: ${status.name}, bidderName: $bidderName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRequest &&
          other.id == id &&
          other.taskId == taskId &&
          other.bidderId == bidderId &&
          other.price == price &&
          other.days == days &&
          other.note == note &&
          other.status == status &&
          other.paymentStatus == paymentStatus &&
          other.createdAt == createdAt &&
          other.bidderName == bidderName &&
          other.bidderAvatar == bidderAvatar &&
          other.taskTitle == taskTitle);

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    bidderId,
    price,
    days,
    note,
    status,
    paymentStatus,
    createdAt,
    bidderName,
    bidderAvatar,
    taskTitle,
  );

  static PaymentStatus _mapDbPaymentStatusToEnum(String? status) {
    if (status == null) return PaymentStatus.unpaid;
    return PaymentStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => PaymentStatus.unpaid,
    );
  }

  static OfferStatus _mapDbOfferStatusToEnum(String? status) {
    if (status == null) return OfferStatus.unknown;
    return OfferStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => OfferStatus.unknown,
    );
  }
}
