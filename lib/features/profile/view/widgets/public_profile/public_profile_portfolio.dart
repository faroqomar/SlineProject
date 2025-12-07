import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';

class PublicProfilePortfolio extends StatelessWidget {
  final List<PortfolioItem> portfolio;

  const PublicProfilePortfolio({super.key, required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Portfolio', style: AppTypography.h5.copyWith(color: colorScheme.text)),
        const SizedBox(height: AppDimens.p12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: portfolio.length,
          itemBuilder: (context, index) {
            final item = portfolio[index];
            return Container(
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(AppDimens.r16),
              ),
              padding: const EdgeInsets.all(12),
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item.category,
                    style: AppTypography.micro.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
