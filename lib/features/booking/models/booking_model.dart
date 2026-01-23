/// Booking model for the `bookings` table.
/// All timestamps are UTC.
library;

import 'package:sline_app/core/app_enums.dart';

class BookingModel {
  final String id;
  final String? taskId;
  final String providerId;
  final String clientId;
  final String slotId;
  final BookingStatus status;
  final String? note;
  final DateTime createdAtUtc;
  final DateTime? scheduledAt; // Derived from availability_slots.starts_at
  final DateTime? completedAt; // Auto-set when status changes to 'completed'
  final Map<String, dynamic>? taskData; // Joined task data

  const BookingModel({
    required this.id,
    required this.taskId,
    required this.providerId,
    required this.clientId,
    required this.slotId,
    required this.status,
    required this.note,
    required this.createdAtUtc,
    this.scheduledAt,
    this.completedAt,
    this.taskData,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String?,
      providerId: json['provider_id'] as String,
      clientId: json['client_id'] as String,
      slotId: json['slot_id'] as String,
      status: _mapDbStatusToEnum(json['status'] as String),
      note: json['note'] as String?,
      createdAtUtc: DateTime.parse(json['created_at'] as String).toUtc(),
      scheduledAt: json['availability_slots']?['starts_at'] != null
          ? DateTime.parse(
              json['availability_slots']['starts_at'] as String,
            ).toUtc()
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String).toUtc()
          : null,
      taskData: json['tasks'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'provider_id': providerId,
      'client_id': clientId,
      'slot_id': slotId,
      'status': status.name,
      'note': note,
      'created_at': createdAtUtc.toUtc().toIso8601String(),
    };
  }

  static BookingStatus _mapDbStatusToEnum(String status) {
    switch (status) {
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'no_show':
        return BookingStatus.noShow;
      case 'canceled': // Handle alternative spelling if needed
      case 'cancelled':
        return BookingStatus.canceled;
      default:
        return BookingStatus.values.firstWhere(
          (e) => e.name == status,
          orElse: () => BookingStatus.pending,
        );
    }
  }
}
