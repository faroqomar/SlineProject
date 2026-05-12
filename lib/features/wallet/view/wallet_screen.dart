import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/wallet/view/widgets/wallet_shared_body.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';
import 'package:sline_app/l10n/app_localizations.dart';

/// Full wallet screen launched outside the dashboard tab.
///
/// The screen owns navigation chrome only; wallet loading and presentation are
/// delegated to [WalletSharedBody].
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;

    return Scaffold(
      backgroundColor: amber.page,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.navWallet ?? 'Wallet',
          style: AmberDuskTokens.typography.sectionTitle.copyWith(
            color: amber.text,
          ),
        ),
        backgroundColor: amber.dark.border,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(
            Icons.arrow_back,
            color: amber.text,
            size: AppDimens.iconSizeSmall,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh wallet',
            icon: Icon(
              Icons.refresh,
              color: amber.text,
              semanticLabel: 'Refresh wallet',
            ),
            onPressed: () => context.read<WalletViewModel>().loadWallet(),
          ),
        ],
      ),
      body: const WalletSharedBody(
        padding: EdgeInsets.fromLTRB(
          AppDimens.p24,
          AppDimens.p24,
          AppDimens.p24,
          AppDimens.p100,
        ),
        bottomSpacing: AppDimens.p24,
      ),
    );
  }
}
