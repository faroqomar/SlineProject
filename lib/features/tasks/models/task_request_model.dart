// Task Requests (Offers/Bids) domain model.
// Represents a freelancer's offer on a task, including price,
// estimated days, an optional note, status, and timestamps.
import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';

/// Status values must match DB CHECK constraint:
/// 'pending' | 'accepted' | 'rejected'
enum TaskRequestStatus { pending, accepted, rejected }

extension TaskRequestStatusX on TaskRequestStatus {
  String get dbValue {
    switch (this) {
      case TaskRequestStatus.pending:
        return 'pending';
      case TaskRequestStatus.accepted:
        return 'accepted';
      case TaskRequestStatus.rejected:
        return 'rejected';
    }
  }

  bool get isPending => this == TaskRequestStatus.pending;
  bool get isAccepted => this == TaskRequestStatus.accepted;
  bool get isRejected => this == TaskRequestStatus.rejected;

  static TaskRequestStatus fromDb(String? value) {
    switch (value) {
      case 'pending':
        return TaskRequestStatus.pending;
      case 'accepted':
        return TaskRequestStatus.accepted;
      case 'rejected':
        return TaskRequestStatus.rejected;
      default:
        return TaskRequestStatus.pending;
    }
  }
}

@immutable
class TaskRequest {
  final String id;
  final String taskId;
  final String bidderId;
  final int price; // Use int for price as DB schema uses BIGINT
  final int days;
  final String? note;
  final TaskRequestStatus status;
  final DateTime createdAt;
  
  // Joined fields from profiles table
  final String? bidderName;
  final String? bidderAvatar;

  const TaskRequest({
    required this.id,
    required this.taskId,
    required this.bidderId,
    required this.price, // price is int to match DB
    required this.days,
    this.note,
    required this.status,
    required this.createdAt,
    this.bidderName,
    this.bidderAvatar,
  });

  bool get isPending => status.isPending;
  bool get isAccepted => status.isAccepted;
  bool get isRejected => status.isRejected;

  factory TaskRequest.fromMap(Map<String, dynamic> map) {
    try {
      // Parsing price as int to match DB BIGINT type
      final priceValue = (map['price'] as num).toInt();
      
      // Extract profile data from nested 'profiles' object if it exists (from JOIN)
      final profileData = map['profiles'] as Map<String, dynamic>?;
      final String? parsedBidderName = profileData?['full_name'] as String?;
      final String? parsedBidderAvatar = profileData?['avatar_url'] as String?;

      return TaskRequest(
        id: map['id'] as String,
        taskId: map['task_id'] as String,
        bidderId: map['bidder_id'] as String,
        price: priceValue,
        days: map['days'] as int,
        note: map['note'] as String?,
        status: TaskRequestStatusX.fromDb(map['status'] as String?),
        createdAt: DateTime.parse(map['created_at'] as String),
        bidderName: parsedBidderName,
        bidderAvatar: parsedBidderAvatar,
      );
    } catch (e, st) {
      AppLogger.e('Failed to parse TaskRequest', tag: 'Tasks', error: e, stackTrace: st);
      rethrow;
    }
  }

  Map<String, dynamic> toMap({bool forInsert = false}) {
    final data = <String, dynamic>{
      'id': id,
      'task_id': taskId,
      'bidder_id': bidderId,
      'price': price, // price remains int
      'days': days,
      'note': note,
      'status': status.dbValue,
      'created_at': createdAt.toIso8601String(),
    };

    if (forInsert) {
      return <String, dynamic>{
        'task_id': taskId,
        'bidder_id': bidderId,
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
    TaskRequestStatus? status,
    DateTime? createdAt,
    String? bidderName,
    String? bidderAvatar,
  }) {
    return TaskRequest(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      bidderId: bidderId ?? this.bidderId,
      price: price ?? this.price,
      days: days ?? this.days,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      bidderName: bidderName ?? this.bidderName,
      bidderAvatar: bidderAvatar ?? this.bidderAvatar,
    );
  }

  @override
  String toString() =>
      'TaskRequest(id: $id, taskId: $taskId, bidderId: $bidderId, price: $price, days: $days, status: ${status.dbValue}, bidderName: $bidderName)';

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
          other.createdAt == createdAt &&
          other.bidderName == bidderName &&
          other.bidderAvatar == bidderAvatar);

  @override
  int get hashCode =>
      Object.hash(id, taskId, bidderId, price, days, note, status, createdAt, bidderName, bidderAvatar);
}
