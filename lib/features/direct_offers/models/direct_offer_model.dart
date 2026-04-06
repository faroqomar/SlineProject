/// Model for a direct offer (chat-to-work, no task/booking).
/// Aligns with contract: currency, fee_rate_applied_bps, payment_*, delivered_at, review_expires_at.
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
    this.currency,
    this.feeRateAppliedBps,
    this.paymentRequestId,
    this.paymentGatewayId,
    this.paymentCorrelationId,
    this.paymentExpiresAt,
    this.paymentRecoveredAt,
    this.deliveredAt,
    this.reviewExpiresAt,
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
  final String? currency;
  final int? feeRateAppliedBps;
  final String? paymentRequestId;
  final String? paymentGatewayId;
  final String? paymentCorrelationId;
  final DateTime? paymentExpiresAt;
  final DateTime? paymentRecoveredAt;
  final DateTime? deliveredAt;
  final DateTime? reviewExpiresAt;

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
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
      currency: json['currency'] as String?,
      feeRateAppliedBps: json['fee_rate_applied_bps'] is int
          ? json['fee_rate_applied_bps'] as int
          : int.tryParse(json['fee_rate_applied_bps']?.toString() ?? ''),
      paymentRequestId: json['payment_request_id'] as String?,
      paymentGatewayId: json['payment_gateway_id'] as String?,
      paymentCorrelationId: json['payment_correlation_id'] as String?,
      paymentExpiresAt: json['payment_expires_at'] != null
          ? DateTime.parse(json['payment_expires_at'] as String).toUtc()
          : null,
      paymentRecoveredAt: json['payment_recovered_at'] != null
          ? DateTime.parse(json['payment_recovered_at'] as String).toUtc()
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String).toUtc()
          : null,
      reviewExpiresAt: json['review_expires_at'] != null
          ? DateTime.parse(json['review_expires_at'] as String).toUtc()
          : null,
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
