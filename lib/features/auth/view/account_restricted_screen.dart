import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/auth/viewmodels/auth_view_model.dart';

class AccountRestrictedScreen extends StatelessWidget {
  const AccountRestrictedScreen({super.key, required this.status, this.reason});

  final String status;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final label = status == 'banned' ? 'Account Banned' : 'Account Suspended';

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.p24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 64, color: AppColors.lightRed),
                const SizedBox(height: AppDimens.p16),
                Text(
                  label,
                  style: AppTypography.h3.copyWith(color: colorScheme.text),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.p12),
                Text(
                  reason?.isNotEmpty == true
                      ? reason!
                      : 'Your account is currently restricted. Please contact support for details.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.p24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.p14,
                      ),
                    ),
                    onPressed: () async {
                      final authVm = context.read<AuthViewModel>();
                      await authVm.logout();
                      if (!context.mounted) return;
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                    child: const Text('Log Out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
