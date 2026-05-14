import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';

/// Renders the public-profile hero material and avatar proof point.
class PublicProfileHeader extends StatelessWidget {
  /// Profile data already loaded by [PublicProfileViewModel].
  final FreelancerProfile profile;

  /// Small hero actions such as share, favorite, and report.
  final Widget? trailingActions;

  /// Creates the visual header for a public profile.
  const PublicProfileHeader({
    super.key,
    required this.profile,
    this.trailingActions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amberColors = context.amberColors;
    final heroSurface = AmberDuskTokens.surfaces.hero;
    final mediaTheme = AmberDuskTokens.widgetTheme.media;
    final roleLine = [
      profile.title,
      if (profile.location.trim().isNotEmpty) profile.location,
    ].where((part) => part.trim().isNotEmpty).join(' · ');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.p20,
          AppDimens.p16,
          AppDimens.p20,
          AppDimens.p14,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.p18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(heroSurface.radius),
            gradient: LinearGradient(
              colors: heroSurface.gradientStops,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: AppDecorations.elevation(
              heroSurface.elevationLevel,
              isDark: colorScheme.isDark,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox.square(
                    dimension: AppDimens.touchTarget,
                    child: IconButton(
                      tooltip: 'Back',
                      style: IconButton.styleFrom(
                        backgroundColor: amberColors.heroChip,
                        foregroundColor: amberColors.heroText,
                        shape: const CircleBorder(),
                      ),
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  if (trailingActions != null) trailingActions!,
                ],
              ),
              const SizedBox(height: AppDimens.p12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: AppDimens.publicProfileAvatarSize,
                    height: AppDimens.publicProfileAvatarSize,
                    decoration: BoxDecoration(
                      color: mediaTheme.profilePhotoFallback,
                      borderRadius: BorderRadius.circular(AppDimens.r24),
                      boxShadow: AppDecorations.elevation(
                        heroSurface.elevationLevel,
                        isDark: colorScheme.isDark,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.r24),
                      child: SignedAvatar(
                        storagePathOrUrl: profile.avatarUrl,
                        size: AppDimens.publicProfileAvatarSize,
                        borderRadius: BorderRadius.circular(AppDimens.r24),
                        placeholder: ColoredBox(
                          color: mediaTheme.profilePhotoFallback,
                          child: Center(
                            child: Text(
                              profile.initials,
                              style: AppTypography.h3.copyWith(
                                color: amberColors.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.p14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AmberDuskTokens.typography.bookingName
                              .copyWith(color: amberColors.heroText),
                        ),
                        if (roleLine.isNotEmpty) ...[
                          const SizedBox(height: AppDimens.p4),
                          Text(
                            roleLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: amberColors.heroMuted,
                            ),
                          ),
                        ],
                        if (profile.verified) ...[
                          const SizedBox(height: AppDimens.p8),
                          _VerifiedPill(color: amberColors.success),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.p16),
              Text(
                profile.bio,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: amberColors.heroMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Verified freelancer pill inside the hero card.
class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p10,
        vertical: AppDimens.p6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AmberDuskTokens.spacing.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: color, size: AppDimens.iconSizeSmall),
          const SizedBox(width: AppDimens.p4),
          Text(
            'Verified freelancer',
            style: AppTypography.captionBold.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
