/// Booking model for the `bookings` table.
/// All timestamps are UTC.
class BookingModel {
  final String id;
  final String? taskId;
  final String providerId;
  final String clientId;
  final String slotId;
  final BookingStatus status;
  final String? note;
  final DateTime createdAtUtc;
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
    this.taskData,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String?,
      providerId: json['provider_id'] as String,
      clientId: json['client_id'] as String,
      slotId: json['slot_id'] as String,
      status: BookingStatusX.fromString(json['status'] as String?),
      note: json['note'] as String?,
      createdAtUtc: DateTime.parse(json['created_at'] as String).toUtc(),
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
}

/// Booking status enum aligned with DB `booking_status_enum`.
enum BookingStatus { pending, confirmed, canceled, completed, noShow }

extension BookingStatusX on BookingStatus {
  static BookingStatus fromString(String? value) {
    switch (value) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'canceled':
        return BookingStatus.canceled;
      case 'completed':
        return BookingStatus.completed;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }
}
