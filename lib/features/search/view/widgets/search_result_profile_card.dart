import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/profile/models/profile_model.dart';

/// Displays one freelancer search result with profile metadata and an action.
///
/// The card intentionally owns presentation only; tap behavior stays with the
/// parent search screen so [SearchViewModel] and routing contracts are preserved.
class SearchResultProfileCard extends StatelessWidget {
  /// Profile data rendered in the result card.
  final ProfileModel profile;

  /// Callback fired when the user opens the profile result.
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
    final displayName = profile.fullName ?? 'SLine User';
    final amber = context.amberColors;

    return Semantics(
      button: true,
      label: 'View $displayName profile',
      child: AppCard(
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
                        displayName,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: amber.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimens.p4),
                      Text(
                        profile.bio ?? 'No bio available.',
                        style: AppTypography.bodySmall.copyWith(
                          color: amber.textSubtle,
                        ),
                        maxLines: 2,
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
                  ...skillsToShow.map(
                    (skill) => _buildSkillChip(context, skill),
                  ),
                  if (remainingSkills > 0)
                    _buildSkillChip(context, '+$remainingSkills more'),
                ],
              ),
            ],

            const SizedBox(height: AppDimens.p16),
            SizedBox(
              width: double.infinity,
              child: ExcludeSemantics(
                child: AppButton(
                  text: 'View Profile',
                  onPressed: onTap,
                  isPrimary: false,
                  // Profile result actions use the compact 48dp height so
                  // touch targets stay accessible on narrow secondary screens.
                  height: AppLayout.buttonHeightCompact,
                  textStyle: AppTypography.captionBold.copyWith(
                    color: amber.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(BuildContext context, String label) {
    final amber = context.amberColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p8,
        vertical: AppDimens.p4,
      ),
      decoration: BoxDecoration(
        color: amber.activeGlow,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(color: amber.primary.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: amber.primary,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
