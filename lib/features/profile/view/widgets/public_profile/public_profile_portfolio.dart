import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';

/// Portfolio grid widget with masonry-style layout matching the new design.
class PublicProfilePortfolio extends StatelessWidget {
  final List<PortfolioItem> portfolio;

  const PublicProfilePortfolio({super.key, required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    if (portfolio.isEmpty) {
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
              'Portfolio',
              style: AppTypography.h5.copyWith(color: colorScheme.text),
            ),
            Text(
              'View All',
              style: AppTypography.caption.copyWith(
                color: AppColors.teal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.p12),

        // Masonry-style grid (using two columns)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                children: portfolio.asMap().entries
                    .where((e) => e.key % 2 == 0)
                    .map((e) => _PortfolioCard(
                          item: e.value,
                          aspectRatio: e.key == 0 ? 0.8 : 1.0,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            // Right column
            Expanded(
              child: Column(
                children: portfolio.asMap().entries
                    .where((e) => e.key % 2 == 1)
                    .map((e) => _PortfolioCard(
                          item: e.value,
                          aspectRatio: e.key == 1 ? 1.2 : 0.9,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual portfolio card with gradient overlay.
class _PortfolioCard extends StatelessWidget {
  final PortfolioItem item;
  final double aspectRatio;

  const _PortfolioCard({
    required this.item,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(AppDimens.r16),
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimens.r16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: AppDimens.p12,
                left: AppDimens.p12,
                right: AppDimens.p12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.category,
                      style: AppTypography.micro.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
