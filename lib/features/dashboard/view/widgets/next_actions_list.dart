import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

class NextActionsList extends StatelessWidget {
  const NextActionsList({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data for "Next Actions"
    // In Phase 1+ this comes from VM filtering logic
    final actions = [
      _ActionItem(
        title: "Confirm Booking",
        subtitle: "Logo Design with Alice",
        time: "Due: 2h",
        cta: "Confirm",
      ),
      _ActionItem(
        title: "Start Work",
        subtitle: "Mobile App MVP",
        time: "Due: Today",
        cta: "Start",
      ),
    ];

    return Column(
      children: actions.map((item) => _ActionCard(item: item)).toList(),
    );
  }
}

class _ActionItem {
  final String title;
  final String subtitle;
  final String time;
  final String cta;

  _ActionItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.cta,
  });
}

class _ActionCard extends StatelessWidget {
  final _ActionItem item;

  const _ActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.accent, // Gold for urgency
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.time,
                style: AppTypography.caption.copyWith(color: colorScheme.error),
              ),
              const SizedBox(height: 4),
              Text(
                item.cta.toUpperCase(),
                style: AppTypography.captionBold.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
