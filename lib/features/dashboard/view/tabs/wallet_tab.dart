import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/features/wallet/view/widgets/wallet_shared_body.dart';

class WalletTab extends StatelessWidget {
  const WalletTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const WalletSharedBody(
      padding: EdgeInsets.all(AppDimens.p16),
      bottomSpacing: AppDimens.p100,
    );
  }
}
