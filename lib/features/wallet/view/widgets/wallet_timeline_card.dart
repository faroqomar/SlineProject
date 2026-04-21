import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/features/wallet/utils/wallet_presentation_helper.dart';

/// Wallet activity timeline — Stripe payment timeline aesthetic.
///
/// Phase 7 PREMIUM REDESIGN: Overline header, hairline dividers between
/// entries (no bordered containers), small dots without shadows, event
/// metadata on same row, right-aligned colored amounts with tabular figures.
class WalletTimelineCard extends StatelessWidget {
  const WalletTimelineCard({super.key, required this.summary});

  final WalletPresentationSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return AppCard(
      key: const ValueKey<String>('wallet_timeline_card'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Friendly section header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.p20,
              AppDimens.p20,
              AppDimens.p20,
              AppDimens.p16,
            ),
            child: Text(
              'Recent activity',
              style: AppTypography.h5.copyWith(color: colorScheme.text),
            ),
          ),

          // ── Content ──
          if (!summary.hasActivity)
            const _WalletEmptyActivityState()
          else
            Padding(
              padding: const EdgeInsets.all(AppDimens.p20),
              child: Column(
                children: [
                  for (final section in summary.timelineSections)
                    _TimelineSection(section: section),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Simplified empty state — no bordered container, just clean text on surface.
class _WalletEmptyActivityState extends StatelessWidget {
  const _WalletEmptyActivityState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Padding(
      key: const ValueKey<String>('wallet_empty_state'),
      padding: const EdgeInsets.all(AppDimens.p24),
      child: Column(
        children: [
          Icon(
            Icons.timeline_rounded,
            color: colorScheme.textTertiary,
            size: AppDimens.p32,
          ),
          const SizedBox(height: AppDimens.p12),
          Text(
            'No wallet activity yet',
            style: AppTypography.bodyLarge.copyWith(
              color: colorScheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimens.p4),
          Text(
            'Releases, refunds, and escrow moves will appear here.',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Date-grouped section with overline title and entry rows.
class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.section});

  final WalletTimelineSection section;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title: "Today", "This Week", "Earlier"
        Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.p12),
          child: Text(
            section.title,
            style: AppTypography.captionBold.copyWith(
              color: colorScheme.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ),

        // Entry rows separated by hairline dividers
        for (var i = 0; i < section.entries.length; i++) ...[
          _TimelineRow(entry: section.entries[i]),
          if (i < section.entries.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.p2),
              child: Container(height: 0.5, color: colorScheme.divider),
            ),
        ],
        const SizedBox(height: AppDimens.p16),
      ],
    );
  }
}

/// Single timeline entry — clean horizontal row with dot, label, metadata,
/// and right-aligned colored amount. No bordered container.
///
/// Stripe-like: compact, data-dense, color only on the amount.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry});

  final WalletTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final accentColor =
        entry.isReceived ? colorScheme.primary : colorScheme.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.p10),
      child: Row(
        children: [
          // ── Small direction dot (no shadow, no glow) ──
          Container(
            width: AppDimens.p8,
            height: AppDimens.p8,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimens.p12),

          // ── Label + metadata ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimens.p2),
                // Event name and timestamp on same row — de-emphasized metadata
                Row(
                  children: [
                    Text(
                      entry.eventName,
                      style: AppTypography.micro.copyWith(
                        color: colorScheme.textTertiary,
                      ),
                    ),
                    const SizedBox(width: AppDimens.p8),
                    Text(
                      entry.timestampLabel,
                      style: AppTypography.micro.copyWith(
                        color: colorScheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Right-aligned colored amount with tabular figures ──
          Text(
            '${entry.isReceived ? '+' : '-'}${PriceFormatter.formatPrice(entry.displayAmount)}',
            style: AppTypography.bodyLarge.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
