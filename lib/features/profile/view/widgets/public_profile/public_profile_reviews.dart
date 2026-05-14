import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';

/// Shows client review proof for public profiles.
class PublicProfileReviews extends StatelessWidget {
  /// Review rows already loaded for this public profile.
  final List<ReviewItem> reviews;

  /// Creates the public profile review section.
  const PublicProfileReviews({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    if (reviews.isEmpty) {
      return _EmptyReviewsCard(colorScheme: colorScheme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: AppTypography.h5.copyWith(color: colorScheme.text),
            ),
            Text(
              'Recent',
              style: AppTypography.caption.copyWith(
                color: colorScheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.p12),
        ...reviews.map((review) => _ReviewCard(review: review)),
      ],
    );
  }
}

/// Individual review card with compact client identity and rating.
class _ReviewCard extends StatelessWidget {
  final ReviewItem review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amberColors = context.amberColors;
    final cardTheme = AmberDuskTokens.widgetTheme.cards.panel;
    final mediaTheme = AmberDuskTokens.widgetTheme.media;
    final initials = _getInitials(review.client);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: cardTheme.background,
        borderRadius: BorderRadius.circular(cardTheme.radius),
        boxShadow: AppDecorations.elevation(
          cardTheme.elevationLevel,
          isDark: colorScheme.isDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Avatar initials use the shared media fallback so review
                    // cards stay aligned with missing profile photos.
                    Container(
                      width: AppDimens.p32,
                      height: AppDimens.p32,
                      decoration: BoxDecoration(
                        color: mediaTheme.avatarFallback,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: AppTypography.micro.copyWith(
                            color: mediaTheme.foreground,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.p8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.client,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppDimens.p2),
                          Row(
                            children: List.generate(5, (index) {
                              final isFilled = index < review.rating;
                              return Padding(
                                padding: const EdgeInsets.only(
                                  right: AppDimens.p2,
                                ),
                                child: Icon(
                                  Icons.star,
                                  size: AppDimens.p12,
                                  color: isFilled
                                      ? amberColors.star
                                      : colorScheme.textTertiary,
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.p8),
              Flexible(
                child: Text(
                  review.date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTypography.micro.copyWith(
                    color: colorScheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p12),
          Text(
            '"${review.comment}"',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'C';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

/// Empty-state panel for profiles with no received reviews yet.
class _EmptyReviewsCard extends StatelessWidget {
  final AppColorScheme colorScheme;

  const _EmptyReviewsCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;
    final cardTheme = AmberDuskTokens.widgetTheme.cards.panel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: cardTheme.background,
        borderRadius: BorderRadius.circular(cardTheme.radius),
        boxShadow: AppDecorations.elevation(
          cardTheme.elevationLevel,
          isDark: colorScheme.isDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.star_outline,
            color: amberColors.star,
            size: AppDimens.iconSizeMedium,
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            'No reviews yet',
            style: AppTypography.h6.copyWith(color: colorScheme.text),
          ),
          const SizedBox(height: AppDimens.p4),
          Text(
            'Client feedback will appear after completed work.',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
