class WalletBalanceModel {
  final num availableBalance;
  final num heldBalance;

  const WalletBalanceModel({
    required this.availableBalance,
    required this.heldBalance,
  });

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    return WalletBalanceModel(
      availableBalance: json['available_balance'] as num? ?? 0,
      heldBalance: json['held_balance'] as num? ?? 0,
    );
  }

  factory WalletBalanceModel.zero() {
    return const WalletBalanceModel(availableBalance: 0, heldBalance: 0);
  }
}
