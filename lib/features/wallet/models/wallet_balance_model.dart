class WalletBalanceModel {
  final num availableBalance;
  final num pendingWithdrawalBalance;
  final num heldBalance;

  const WalletBalanceModel({
    required this.availableBalance,
    required this.pendingWithdrawalBalance,
    required this.heldBalance,
  });

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    return WalletBalanceModel(
      availableBalance: json['available_balance'] as num? ?? 0,
      pendingWithdrawalBalance: json['pending_withdrawal_balance'] as num? ?? 0,
      heldBalance: json['held_balance'] as num? ?? 0,
    );
  }

  factory WalletBalanceModel.zero() {
    return const WalletBalanceModel(
      availableBalance: 0,
      pendingWithdrawalBalance: 0,
      heldBalance: 0,
    );
  }
}
