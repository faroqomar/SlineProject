/// Model table `wallet_transactions`
/// Tracks financial movements (escrow, release, refund)
library;

class WalletTransactionModel {
  final String id;
  final String userId;
  final num amount;
  final String type; // 'escrow', 'release', 'refund'
  final String status; // 'held', 'released', 'completed', 'refunded'
  final String? relatedEntityId;
  final String? relatedEntityType;
  final String? relatedTxnId;
  final DateTime createdAtUtc;

  const WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    this.relatedEntityId,
    this.relatedEntityType,
    this.relatedTxnId,
    required this.createdAtUtc,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: json['amount'] as num,
      type: json['type'] as String,
      status: json['status'] as String,
      relatedEntityId: json['related_entity_id'] as String?,
      relatedEntityType: json['related_entity_type'] as String?,
      relatedTxnId: json['related_txn_id'] as String?,
      createdAtUtc: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'type': type,
      'status': status,
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
      'related_txn_id': relatedTxnId,
      'created_at': createdAtUtc.toUtc().toIso8601String(),
    };
  }
}
