import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/wallet/view/widgets/wallet_shared_body.dart';

class WalletDashboardScreen extends StatelessWidget {
  const WalletDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
              style: AppTypography.h2.copyWith(color: colorScheme.text),
            ),
            const SizedBox(height: AppDimens.p4),
            Text(
              'Manage your earnings',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
