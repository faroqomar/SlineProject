import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key, required this.minimumVersion});

  final String minimumVersion;

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
                const Icon(Icons.system_update_alt, size: 64),
                const SizedBox(height: AppDimens.p16),
                Text(
                  'Update Required',
                  style: AppTypography.h3.copyWith(color: colorScheme.text),
                ),
                const SizedBox(height: AppDimens.p12),
                Text(
                  'Please update the app to continue. Minimum supported version: $minimumVersion',
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
