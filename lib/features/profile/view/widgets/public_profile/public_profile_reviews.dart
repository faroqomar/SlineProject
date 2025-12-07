import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';

class PublicProfileReviews extends StatelessWidget {
  final List<ReviewItem> reviews;

  const PublicProfileReviews({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reviews', style: AppTypography.h5.copyWith(color: colorScheme.text)),
            Text('Recent', style: AppTypography.micro.copyWith(color: colorScheme.textSecondary)),
          ],
        ),
        const SizedBox(height: AppDimens.p12),
        ...reviews.map((review) => Container(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.lightTeal,
                        child: Text(
                          review.client.isNotEmpty ? review.client[0] : 'C',
                          style: AppTypography.captionBold.copyWith(color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                Icons.star,
                                size: 12,
                                color: index < review.rating ? AppColors.gold : Colors.grey,
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    review.date,
                    style: AppTypography.micro.copyWith(color: colorScheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '"${review.comment}"',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
