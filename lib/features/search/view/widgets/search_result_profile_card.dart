import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/glass_card.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/profile/models/profile_model.dart';

class SearchResultProfileCard extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback onTap;

  const SearchResultProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Show top 3 skills
    final skillsToShow = profile.skills.take(3).toList();
    final remainingSkills = profile.skills.length - skillsToShow.length;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SignedAvatar(
                storagePathOrUrl: profile.avatarUrl,
                radius: AppDimens.p24,
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName ?? 'SLine User',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimens.p4),
                    Text(
                      profile.bio ?? 'No bio avaliable.',
                      style: AppTypography.bodySmall.copyWith(
                        color: context.colorScheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (skillsToShow.isNotEmpty) ...[
            const SizedBox(height: AppDimens.p12),
            Wrap(
              spacing: AppDimens.p8,
              runSpacing: AppDimens.p4,
              children: [
                ...skillsToShow.map((skill) => _buildSkillChip(context, skill)),
                if (remainingSkills > 0)
                  _buildSkillChip(context, '+$remainingSkills more'),
              ],
            ),
          ],

          const SizedBox(height: AppDimens.p16),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'View Profile',
              onPressed: onTap,
              isPrimary: false,
              height: 32,
              textStyle: AppTypography.captionBold.copyWith(
                color: context.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p8,
        vertical: AppDimens.p4,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        // Replaced labelSmall with caption as labelSmall was undefined
        style: AppTypography.caption.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
