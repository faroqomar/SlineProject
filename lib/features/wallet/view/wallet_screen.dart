import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/features/wallet/view/widgets/wallet_shared_body.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.text),
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
