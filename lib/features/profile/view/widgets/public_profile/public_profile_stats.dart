import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';

class PublicProfileStats extends StatelessWidget {
  final FreelancerProfile profile;

  const PublicProfileStats({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimens.p12),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _buildStatItem('Job Success', profile.jobSuccess, colorScheme),
          _buildDivider(),
          _buildStatItem('Total Jobs', profile.jobsCompleted.toString(), colorScheme),
          _buildDivider(),
          _buildStatItem('Hourly', profile.hourlyRate, colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, AppColorScheme colorScheme) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.h6.copyWith(
              color: label == 'Job Success' ? AppColors.teal : colorScheme.text,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: AppTypography.micro.copyWith(
              color: colorScheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.1));
  }
}
