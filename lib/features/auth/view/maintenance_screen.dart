import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.p24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.build_circle_outlined, size: 64),
                const SizedBox(height: AppDimens.p16),
                Text(
                  'Under Maintenance',
                  style: AppTypography.h3.copyWith(color: colorScheme.text),
                ),
                const SizedBox(height: AppDimens.p12),
                Text(
                  message?.isNotEmpty ?? false
                      ? message!
                      : 'We are improving SLine right now. Please try again shortly.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
