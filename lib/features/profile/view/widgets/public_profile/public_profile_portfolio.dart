import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
// Canonical PortfolioItem from portfolio feature
import 'package:sline_app/features/portfolio/models/portfolio_item.dart'
    show PortfolioItem;

/// Shows public portfolio proof tiles without changing portfolio storage rules.
class PublicProfilePortfolio extends StatelessWidget {
  /// Portfolio rows already resolved by the public profile ViewModel.
  final List<PortfolioItem> portfolio;

  /// Creates the public portfolio section for the current profile.
  const PublicProfilePortfolio({super.key, required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;

    if (portfolio.isEmpty) {
      return const _EmptyPortfolioCard();
    }

    final visibleItems = portfolio.take(2).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Portfolio',
              style: AppTypography.h5.copyWith(color: amberColors.text),
            ),
            Text(
              'Proof of work',
              style: AppTypography.caption.copyWith(
                color: amberColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.p12),
        Row(
          children: [
            for (final entry in visibleItems.asMap().entries) ...[
              Expanded(
                child: _PortfolioProofTile(
                  item: entry.value,
                  accent: entry.key.isEven
                      ? amberColors.primary
                      : amberColors.success,
                ),
              ),
              if (entry.key != visibleItems.length - 1)
                const SizedBox(width: AppDimens.p10),
            ],
          ],
        ),
      ],
    );
  }
}

/// Compact project proof tile matching the Open Design portfolio strip.
class _PortfolioProofTile extends StatelessWidget {
  final PortfolioItem item;
  final Color accent;

  const _PortfolioProofTile({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;
    final raisedSurface = AmberDuskTokens.surfaces.raised;
    final description = item.description?.trim();

    return Container(
      constraints: const BoxConstraints(
        minHeight: AppDimens.p100 + AppDimens.p24,
      ),
      padding: const EdgeInsets.all(AppDimens.p12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.18), raisedSurface.fill],
        ),
        borderRadius: BorderRadius.circular(raisedSurface.radius),
        boxShadow: AppDecorations.elevation(
          raisedSurface.elevationLevel,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProofPill(label: 'Project', color: accent),
          const SizedBox(height: AppDimens.p10),
          Text(
            item.title,
            style: AppTypography.bodySmall.copyWith(
              color: amberColors.text,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: AppDimens.p4),
            Text(
              description,
              style: AppTypography.micro.copyWith(color: amberColors.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppDimens.p12),
          Text(
            '${item.createdAt.year} proof',
            style: AppTypography.micro.copyWith(color: amberColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Empty-state panel used when the public profile has no proof work yet.
class _EmptyPortfolioCard extends StatelessWidget {
  const _EmptyPortfolioCard();

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;
    final colorScheme = context.colorScheme;
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
            Icons.work_outline,
            color: amberColors.primary,
            size: AppDimens.iconSizeMedium,
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            'No portfolio yet',
            style: AppTypography.h6.copyWith(color: colorScheme.text),
          ),
          const SizedBox(height: AppDimens.p4),
          Text(
            'Proof projects will appear here when this freelancer adds them.',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small proof classification pill for portfolio tiles.
class _ProofPill extends StatelessWidget {
  final String label;
  final Color color;

  const _ProofPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AmberDuskTokens.widgetTheme.statusPills.smallPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(
          AmberDuskTokens.widgetTheme.statusPills.radius,
        ),
      ),
      child: Text(
        label,
        style: AmberDuskTokens.widgetTheme.statusPills.smallTextStyle.copyWith(
          color: color,
        ),
      ),
    );
  }
}
