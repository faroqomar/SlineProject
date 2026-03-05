// Typed payload for opening the proposal payment screen from any launcher.
// Server-derived taskTitle and paymentDeadline when available.
import 'package:flutter/foundation.dart';

@immutable
class ProposalPaymentSummary {
  final String requestId;
  final String taskId;
  final String taskTitle;
  final String freelancerName;
  final double amount;
  final DateTime? paymentDeadline;

  const ProposalPaymentSummary({
    required this.requestId,
    required this.taskId,
    required this.taskTitle,
    required this.freelancerName,
    required this.amount,
    this.paymentDeadline,
  });
}
