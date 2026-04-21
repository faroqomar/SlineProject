import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/wallet/utils/wallet_presentation_helper.dart';

/// Wallet hero card — SLine brand identity, warm and professional.
///
/// Design skills applied:
/// - Content-first: massive balance number is THE focal point
/// - Brand warmth: teal primary surface (headerBackground) not cold dark grey
/// - Generous whitespace: content breathes, not cramped
/// - Asymmetric layout: balance left-aligned, breakdown offset right
/// - Rewarding: composition bar animates on data change
/// - NO gradients, NO glow orbs, NO glassmorphism (per .impeccable.md)
/// - Solid surface + elevation shadow (per design system rules)
class WalletHeroCard extends StatelessWidget {
  const WalletHeroCard({super.key, required this.summary});

  final WalletPresentationSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      key: const ValueKey<String>('wallet_hero_card'),
      decoration: BoxDecoration(
        // Warm teal-tinted surface — NOT cold grey cardBackground.
        // headerBackground is a subtle teal tint that feels branded.
        color: colorScheme.headerBackground,
        borderRadius: BorderRadius.circular(AppDimens.r24),
        border: Border.all(
          color: colorScheme.headerBorder,
        ),
        boxShadow: AppDecorations.elevation(2, isDark: colorScheme.isDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: wallet icon + label ──
            // Small, understated — the balance is the star, not the label
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: AppDimens.iconSizeSmall,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppDimens.p6),
                Text(
                  'Wallet',
                  style: AppTypography.captionBold.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.p20),

            // ── Hero balance amount ──
            // 36px/900 — largest text on the screen, left-aligned (not centered)
            // "Content first, chrome second" — this IS the content
            Text(
              PriceFormatter.formatPrice(summary.totalFunds),
              style: AppTypography.h1.copyWith(
                color: colorScheme.text,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),

            const SizedBox(height: AppDimens.p6),

            // ── Activity context line ──
            Text(
              summary.activityCaption,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.textSecondary,
              ),
            ),

            const SizedBox(height: AppDimens.p24),

            // ── Composition bar — 6px, rounded, animated segments ──
            // Thicker than a hairline but not chunky — noticeable, informative
            _CompositionBar(slices: summary.balanceSlices),

            const SizedBox(height: AppDimens.p18),

            // ── Balance breakdown chips — wrapped in subtle containers ──
            // Each balance state gets its own mini "card" for scannability
            Wrap(
              spacing: AppDimens.p10,
              runSpacing: AppDimens.p10,
              children: summary.balanceSlices
                  .map(
                    (slice) => _BalanceChip(
                      slice: slice,
                      color: _sliceColor(slice.kind, colorScheme),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated composition bar — 6px height with smooth segment transitions.
/// Uses AppMotion tokens for animation duration and curves.
class _CompositionBar extends StatelessWidget {
  const _CompositionBar({required this.slices});

  final List<WalletBalanceSlice> slices;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final totalRatio = slices.fold<double>(
      0,
      (sum, slice) => sum + slice.ratio,
    );

    return Container(
      height: AppDimens.p6,
      decoration: BoxDecoration(
        color: colorScheme.divider,
        borderRadius: BorderRadius.circular(AppDimens.r4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (totalRatio == 0) return const SizedBox.expand();

          var left = 0.0;
          final bars = <Widget>[];
          for (var i = 0; i < slices.length; i++) {
            final slice = slices[i];
            final width = i == slices.length - 1
                ? constraints.maxWidth - left
                : constraints.maxWidth * slice.ratio;
            bars.add(
              AnimatedPositioned(
                duration: AppMotion.slow,
                curve: AppMotion.curveStandard,
                left: left,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: AppMotion.slow,
                  width: width.clamp(0.0, constraints.maxWidth),
                  decoration: BoxDecoration(
                    color: _sliceColor(slice.kind, colorScheme),
                    borderRadius: BorderRadius.horizontal(
                      left: i == 0
                          ? const Radius.circular(AppDimens.r4)
                          : Radius.zero,
                      right: i == slices.length - 1
                          ? const Radius.circular(AppDimens.r4)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),
            );
            left += width;
          }
          return Stack(children: bars);
        },
      ),
    );
  }
}

/// Balance chip — colored dot + label + amount in a subtle container.
///
/// Warm design: uses a tinted background matching the dot color at low alpha
/// so each chip has visual identity without being noisy. Generous padding
/// for touch comfort and scannability.
class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.slice, required this.color});

  final WalletBalanceSlice slice;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p8,
      ),
      decoration: BoxDecoration(
        // Subtle tinted background from the slice color — warm, not flat grey
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.r12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Colored dot matching the composition bar
          Container(
            width: AppDimens.p8,
            height: AppDimens.p8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimens.p8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slice.label,
                style: AppTypography.micro.copyWith(
                  color: colorScheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                PriceFormatter.formatPrice(slice.amount),
                style: AppTypography.captionBold.copyWith(
                  color: colorScheme.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Semantic slice colors — primary (available), danger (pending), accent (held).
Color _sliceColor(WalletBalanceSliceKind kind, AppColorScheme colorScheme) {
  switch (kind) {
    case WalletBalanceSliceKind.available:
      return colorScheme.primary;
    case WalletBalanceSliceKind.pendingWithdrawal:
      return colorScheme.danger;
    case WalletBalanceSliceKind.held:
      return colorScheme.accent;
  }
}
