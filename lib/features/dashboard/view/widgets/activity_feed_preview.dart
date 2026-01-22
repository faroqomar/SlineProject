import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

class ActivityFeedPreview extends StatelessWidget {
  const ActivityFeedPreview({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final activities = [
      _ActivityInfo(
        "Booking Confirmed",
        "Alice confirmed your booking",
        "15m ago",
        Icons.check_circle_outline,
      ),
      _ActivityInfo(
        "New Offer",
        "Received offer for 'Logo Design'",
        "2h ago",
        Icons.local_offer_outlined,
      ),
      _ActivityInfo(
        "Work Started",
        "You started work on 'App MVP'",
        "1d ago",
        Icons.play_circle_outline,
      ),
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        return _ActivityRow(
          item: activities[index],
          isLast: index == activities.length - 1,
        );
      },
    );
  }
}

class _ActivityInfo {
  final String title;
  final String description;
  final String time;
  final IconData icon;

  _ActivityInfo(this.title, this.description, this.time, this.icon);
}

class _ActivityRow extends StatelessWidget {
  final _ActivityInfo item;
  final bool isLast;

  const _ActivityRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.inputBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                size: 16,
                color: colorScheme.textSecondary,
              ),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 30, // Connect line
                color: colorScheme.divider,
              ),
          ],
        ),
        const SizedBox(width: AppDimens.p12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.time,
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
