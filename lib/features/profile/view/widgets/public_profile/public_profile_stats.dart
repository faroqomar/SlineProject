import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';

/// Shows compact public-profile proof metrics in Amber Dusk stat cells.
class PublicProfileStats extends StatelessWidget {
  /// Profile metrics exposed by [PublicProfileViewModel].
  final FreelancerProfile profile;

  /// Creates proof cells for job success, completed jobs, and hourly rate.
  const PublicProfileStats({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amberColors = context.amberColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatItem(
          context,
          'Job Success',
          profile.jobSuccess,
          colorScheme,
          amberColors.success,
        ),
        const SizedBox(width: AppDimens.p8),
        _buildStatItem(
          context,
          'Total Jobs',
          profile.jobsCompleted.toString(),
          colorScheme,
          colorScheme.text,
        ),
        const SizedBox(width: AppDimens.p8),
        _buildStatItem(
          context,
          'Hourly',
          profile.hourlyRate,
          colorScheme,
          colorScheme.text,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    AppColorScheme colorScheme,
    Color valueColor,
  ) {
    final cardTheme = AmberDuskTokens.widgetTheme.cards.panel;

    return Expanded(
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppDimens.publicProfileMetricMinHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p10,
          vertical: AppDimens.p12,
        ),
        decoration: BoxDecoration(
          color: cardTheme.background,
          borderRadius: BorderRadius.circular(cardTheme.radius),
          boxShadow: AppDecorations.elevation(
            cardTheme.elevationLevel,
            isDark: colorScheme.isDark,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h6.copyWith(color: valueColor),
                  ),
                  const SizedBox(height: AppDimens.p8),
                  Text(
                    label.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.micro.copyWith(
                      color: colorScheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
