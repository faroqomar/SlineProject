import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/features/wallet/utils/wallet_presentation_helper.dart';

class WalletTimelineCard extends StatelessWidget {
  const WalletTimelineCard({super.key, required this.summary});

  final WalletPresentationSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey<String>('wallet_timeline_card'),
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent activity',
            style: AppTypography.h5.copyWith(color: context.colorScheme.text),
          ),
          const SizedBox(height: AppDimens.p6),
          Text(
            'Money received, money spent, and release events in one timeline.',
            style: AppTypography.bodySmall.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.p18),
          if (!summary.hasActivity)
            const _WalletEmptyActivityState()
          else
            ...summary.timelineSections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.p18),
                child: _TimelineSection(section: section),
              ),
            ),
        ],
      ),
    );
  }
}

class _WalletEmptyActivityState extends StatelessWidget {
  const _WalletEmptyActivityState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('wallet_empty_state'),
      padding: const EdgeInsets.all(AppDimens.p20),
      decoration: BoxDecoration(
        color: context.colorScheme.inputBackground,
        borderRadius: BorderRadius.circular(AppDimens.r18),
        border: Border.all(color: context.colorScheme.inputBorder),
      ),
      child: Column(
        children: [
          Container(
            width: AppDimens.p48,
            height: AppDimens.p48,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timeline_rounded,
              color: AppColors.teal,
              size: AppDimens.iconSizeMedium,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          Text(
            'No wallet activity yet',
            style: AppTypography.h6.copyWith(color: context.colorScheme.text),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            'When releases, refunds, or escrow moves happen, they will land here.',
            style: AppTypography.bodyMedium.copyWith(
              color: context.colorScheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.section});

  final WalletTimelineSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: AppTypography.captionBold.copyWith(
            color: context.colorScheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimens.p10),
        ...List.generate(section.entries.length, (index) {
          final entry = section.entries[index];
          final isLast = index == section.entries.length - 1;
          return Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? AppDimens.p0 : AppDimens.p12,
            ),
            child: _TimelineEntry(entry: entry, isLast: isLast),
          );
        }),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.entry, required this.isLast});

  final WalletTimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final accent = entry.isReceived ? AppColors.teal : AppColors.lightRed;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppDimens.p24,
          child: Column(
            children: [
              Container(
                width: AppDimens.p12,
                height: AppDimens.p12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: AppDimens.p60,
                  margin: const EdgeInsets.only(top: AppDimens.p4),
                  color: colorScheme.inputBorder,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.p12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppDimens.p16),
            decoration: BoxDecoration(
              color: colorScheme.inputBackground,
              borderRadius: BorderRadius.circular(AppDimens.r16),
              border: Border.all(color: colorScheme.inputBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.label,
                        style: AppTypography.bodyLarge.copyWith(
                          color: colorScheme.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimens.p4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.p8,
                          vertical: AppDimens.p4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppDimens.r30),
                        ),
                        child: Text(
                          entry.eventName,
                          style: AppTypography.micro.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.p8),
                      Text(
                        entry.timestampLabel,
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                Text(
                  '${entry.isReceived ? '+' : '-'}${PriceFormatter.formatPrice(entry.displayAmount)}',
                  style: AppTypography.bodyLarge.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
