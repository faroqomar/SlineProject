import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/wallet/view/widgets/wallet_shared_body.dart';

/// Dashboard wallet tab wrapper around the shared wallet body.
///
/// The wrapper only sets dashboard-specific padding so the wallet ViewModel and
/// ledger behavior stay centralized in [WalletSharedBody].
class WalletTab extends StatelessWidget {
  const WalletTab({super.key});

  @override
  Widget build(BuildContext context) {
    return WalletSharedBody(
      padding: EdgeInsets.fromLTRB(
        AmberDuskTokens.spacing.contentHorizontalPadding,
        0,
        AmberDuskTokens.spacing.contentHorizontalPadding,
        AppDimens.p16,
      ),
      bottomSpacing: AppDimens.p24,
    );
  }
}
