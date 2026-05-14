import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/wallet/view/widgets/wallet_shared_body.dart';

/// Wallet screen variant used from dashboard-style navigation.
///
/// It provides only a local header and delegates all wallet state rendering to
/// [WalletSharedBody].
class WalletDashboardScreen extends StatelessWidget {
  const WalletDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const typography = AmberDuskTokens.typography;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: amber.page,
      body: WalletSharedBody(
        padding: EdgeInsets.fromLTRB(
          AppDimens.p24,
          topPadding + AppDimens.p24,
          AppDimens.p24,
          AppDimens.p100,
        ),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Wallet',
              style: typography.screenTitle.copyWith(color: amber.text),
            ),
            const SizedBox(height: AppDimens.p4),
            Text(
              'Manage your earnings',
              style: typography.bodySmall.copyWith(color: amber.textSubtle),
            ),
          ],
        ),
      ),
    );
  }
}
