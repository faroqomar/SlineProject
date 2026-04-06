// Schema ref: wallet_balances table in SUPABASE_SETUP.md
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/wallet/models/wallet_balance_model.dart';

/// Full valid JSON fixture matching Supabase `wallet_balances` table columns.
Map<String, dynamic> _fullJson() {
  return <String, dynamic>{
    'available_balance': 150000,
    'pending_withdrawal_balance': 25000,
    'held_balance': 50000,
  };
}

void main() {
  group('WalletBalanceModel.fromJson', () {
    test('parses all fields from valid JSON', () {
      final balance = WalletBalanceModel.fromJson(_fullJson());

      expect(balance.availableBalance, 150000);
      expect(balance.pendingWithdrawalBalance, 25000);
      expect(balance.heldBalance, 50000);
    });

    test('parses decimal numeric values', () {
      final balance = WalletBalanceModel.fromJson(<String, dynamic>{
        'available_balance': 1500.75,
        'pending_withdrawal_balance': 250.50,
        'held_balance': 500.25,
      });

      expect(balance.availableBalance, 1500.75);
      expect(balance.pendingWithdrawalBalance, 250.50);
      expect(balance.heldBalance, 500.25);
    });

    test('all fields default to 0 when null', () {
      final balance = WalletBalanceModel.fromJson(<String, dynamic>{
        'available_balance': null,
        'pending_withdrawal_balance': null,
        'held_balance': null,
      });

      expect(balance.availableBalance, 0);
      expect(balance.pendingWithdrawalBalance, 0);
      expect(balance.heldBalance, 0);
    });

    test('all fields default to 0 when missing', () {
      final balance = WalletBalanceModel.fromJson(<String, dynamic>{});

      expect(balance.availableBalance, 0);
      expect(balance.pendingWithdrawalBalance, 0);
      expect(balance.heldBalance, 0);
    });

    test('handles mix of present and missing fields', () {
      final balance = WalletBalanceModel.fromJson(<String, dynamic>{
        'available_balance': 100000,
      });

      expect(balance.availableBalance, 100000);
      expect(balance.pendingWithdrawalBalance, 0);
      expect(balance.heldBalance, 0);
    });

    test('handles zero values correctly', () {
      final balance = WalletBalanceModel.fromJson(<String, dynamic>{
        'available_balance': 0,
        'pending_withdrawal_balance': 0,
        'held_balance': 0,
      });

      expect(balance.availableBalance, 0);
      expect(balance.pendingWithdrawalBalance, 0);
      expect(balance.heldBalance, 0);
    });
  });

  group('WalletBalanceModel.zero', () {
    test('factory produces model with all balances at 0', () {
      final balance = WalletBalanceModel.zero();

      expect(balance.availableBalance, 0);
      expect(balance.pendingWithdrawalBalance, 0);
      expect(balance.heldBalance, 0);
    });

    test('zero() is equivalent to fromJson with empty map', () {
      final zero = WalletBalanceModel.zero();
      final empty = WalletBalanceModel.fromJson(<String, dynamic>{});

      expect(zero.availableBalance, empty.availableBalance);
      expect(zero.pendingWithdrawalBalance, empty.pendingWithdrawalBalance);
      expect(zero.heldBalance, empty.heldBalance);
    });
  });
}
