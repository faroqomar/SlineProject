/// Model representing a row from vw_wallet_activity_user
class WalletActivityModel {
  final String journalEntryId;
  final DateTime createdAtUtc;
  final String eventType;
  final num amountGross;
  final num amountNet;
  final num feeAmount;
  final String currency;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final String? counterpartyUserId;

  const WalletActivityModel({
    required this.journalEntryId,
    required this.createdAtUtc,
    required this.eventType,
    required this.amountGross,
    required this.amountNet,
    required this.feeAmount,
    required this.currency,
    this.relatedEntityType,
    this.relatedEntityId,
    this.counterpartyUserId,
  });

  factory WalletActivityModel.fromJson(Map<String, dynamic> json) {
    return WalletActivityModel(
      journalEntryId: json['journal_entry_id'] as String,
      createdAtUtc: DateTime.parse(json['created_at'] as String).toUtc(),
      eventType: json['event_type'] as String,
      amountGross: json['amount_gross'] as num? ?? 0,
      amountNet: json['amount_net'] as num? ?? 0,
      feeAmount: json['fee_amount'] as num? ?? 0,
      currency: json['currency'] as String? ?? 'IQD',
      relatedEntityType: json['related_entity_type'] as String?,
      relatedEntityId: json['related_entity_id'] as String?,
      counterpartyUserId: json['counterparty_user_id'] as String?,
    );
  }
}
