/// Model for a direct offer (chat-to-work, no task/booking).
class DirectOffer {
  const DirectOffer({
    required this.id,
    required this.conversationId,
    required this.clientId,
    required this.freelancerId,
    this.taskId,
    this.title,
    this.description,
    required this.price,
    required this.days,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String conversationId;
  final String clientId;
  final String freelancerId;
  final String? taskId;
  final String? title;
  final String? description;
  final num price;
  final int days;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory DirectOffer.fromJson(Map<String, dynamic> json) {
    return DirectOffer(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      clientId: json['client_id'] as String,
      freelancerId: json['freelancer_id'] as String,
      taskId: json['task_id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      price: (json['price'] is num)
          ? json['price'] as num
          : num.tryParse(json['price']?.toString() ?? '0') ?? 0,
      days: (json['days'] is int)
          ? json['days'] as int
          : int.tryParse(json['days']?.toString() ?? '0') ?? 0,
      status: json['status'] as String? ?? 'sent',
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  bool get isSent => status == 'sent';
  bool get isAcceptedPendingPayment =>
      status == 'accepted' && paymentStatus == 'unpaid';
  bool get isActive => status == 'active';
  bool get isDelivered => status == 'delivered';
  bool get isCompleted => status == 'completed';
  bool get isRejectedOrCanceled =>
      status == 'rejected' || status == 'canceled' || status == 'refunded';
}
