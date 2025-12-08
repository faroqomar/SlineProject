import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';

/// Reviews section widget with star ratings matching the new design.
class PublicProfileReviews extends StatelessWidget {
  final List<ReviewItem> reviews;

  const PublicProfileReviews({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    if (reviews.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
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

        // Review cards
        ...reviews.map((review) => _ReviewCard(review: review)),
      ],
    );
  }
}

/// Individual review card widget.
class _ReviewCard extends StatelessWidget {
  final ReviewItem review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    final String initials = _getInitials(review.client);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client info
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.lightTeal,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: AppTypography.micro.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.p8),

                  // Name and rating
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.client,
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Star rating
                      Row(
                        children: List.generate(5, (index) {
                          final bool isFilled = index < review.rating;
                          return Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              Icons.star,
                              size: 12,
                              color: isFilled
                                  ? AppColors.gold
                                  : colorScheme.textTertiary,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),

              // Date
              Text(
                review.date,
                style: AppTypography.micro.copyWith(
                  color: colorScheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p12),

          // Comment
          Text(
            '"${review.comment}"',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.4,
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
