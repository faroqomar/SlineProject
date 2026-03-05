// Proposal (task request) domain model for the proposals feature.
// Mirrors task_requests table; use for typed proposal list and actions.
import 'package:flutter/foundation.dart';
import 'package:sline_app/core/app_enums.dart';

@immutable
class ProposalModel {
  final String id;
  final String taskId;
  final String bidderId;
  final int price;
  final int days;
  final String? note;
  final OfferStatus status;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;

  final String? bidderName;
  final String? bidderAvatar;
  final String? taskTitle;
  final DateTime? paymentDeadline;

  const ProposalModel({
    required this.id,
    required this.taskId,
    required this.bidderId,
    required this.price,
    required this.days,
    this.note,
    required this.status,
    this.paymentStatus = PaymentStatus.unpaid,
    required this.createdAt,
    this.bidderName,
    this.bidderAvatar,
    this.taskTitle,
    this.paymentDeadline,
  });

  bool get isPending => status == OfferStatus.pending;
  bool get isAccepted => status == OfferStatus.accepted;
  bool get isRejected => status == OfferStatus.rejected;
}
