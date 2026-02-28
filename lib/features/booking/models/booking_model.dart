/// Booking model for the `bookings` table.
/// All timestamps are UTC.
library;

import 'package:sline_app/core/app_enums.dart';

class BookingModel {
  final String id;
  final String? taskId;
  final String providerId;
  final String clientId;
  final String? slotId;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? note;
  final num? price;
  final String? packageId;
  final Map<String, dynamic>? requirements;
  final DateTime createdAtUtc;
  final DateTime? dueAtUtc;
  final int? deliveryDays;
  final DateTime? scheduledAt; // Legacy fallback for historical slot-based rows
  final DateTime? completedAt; // Auto-set when status changes to 'completed'
  final Map<String, dynamic>? taskData; // Joined task data

  const BookingModel({
    required this.id,
    required this.taskId,
    required this.providerId,
    required this.clientId,
    required this.slotId,
    required this.status,
    required this.paymentStatus,
    required this.note,
    this.price,
    this.packageId,
    this.requirements,
    required this.createdAtUtc,
    this.dueAtUtc,
    this.deliveryDays,
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
      slotId: json['slot_id'] as String?,
      status: _mapDbStatusToEnum(json['status'] as String),
      paymentStatus: _mapDbPaymentStatusToEnum(
        json['payment_status'] as String?,
      ),
      note: json['note'] as String?,
      price: json['price'] as num?,
      packageId: json['package_id'] as String?,
      requirements: json['requirements'] as Map<String, dynamic>?,
      createdAtUtc: DateTime.parse(json['created_at'] as String).toUtc(),
      dueAtUtc: json['due_at'] != null
          ? DateTime.parse(json['due_at'] as String).toUtc()
          : (json['availability_slots']?['starts_at'] != null
                ? DateTime.parse(
                    json['availability_slots']['starts_at'] as String,
                  ).toUtc()
                : null),
      deliveryDays: (json['delivery_days'] as num?)?.toInt(),
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
      'payment_status': paymentStatus.name,
      'note': note,
      'price': price,
      'package_id': packageId,
      'requirements': requirements,
      'created_at': createdAtUtc.toUtc().toIso8601String(),
      'due_at': dueAtUtc?.toUtc().toIso8601String(),
      'delivery_days': deliveryDays,
    };
  }

  BookingModel copyWith({
    String? id,
    String? taskId,
    String? providerId,
    String? clientId,
    String? slotId,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    String? note,
    num? price,
    String? packageId,
    Map<String, dynamic>? requirements,
    DateTime? createdAtUtc,
    DateTime? dueAtUtc,
    int? deliveryDays,
    DateTime? scheduledAt,
    DateTime? completedAt,
    Map<String, dynamic>? taskData,
  }) {
    return BookingModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      providerId: providerId ?? this.providerId,
      clientId: clientId ?? this.clientId,
      slotId: slotId ?? this.slotId,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      note: note ?? this.note,
      price: price ?? this.price,
      packageId: packageId ?? this.packageId,
      requirements: requirements ?? this.requirements,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      dueAtUtc: dueAtUtc ?? this.dueAtUtc,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      taskData: taskData ?? this.taskData,
    );
  }

  static PaymentStatus _mapDbPaymentStatusToEnum(String? status) {
    if (status == null) return PaymentStatus.unpaid;
    return PaymentStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => PaymentStatus.unpaid,
    );
  }

  static BookingStatus _mapDbStatusToEnum(String status) {
    switch (status) {
      case 'paid_request_pending':
        return BookingStatus.paidRequestPending;
      case 'active':
        return BookingStatus.active;
      case 'delivered':
        return BookingStatus.delivered;
      case 'refunded':
        return BookingStatus.refunded;
      case 'expired_unanswered':
        return BookingStatus.expiredUnanswered;
      case 'in_progress':
        return BookingStatus.active; // Map legacy/alternative to active
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
