import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';

/// Original SLine V2 Amber Dusk card for tender-style discovery tasks.
///
/// The card keeps task navigation and saved-state callbacks untouched while
/// rendering tender work as a full client task post, not a dashboard row.
class TenderTaskCard extends StatelessWidget {
  /// Creates a tender task card for the discovery feed.
  const TenderTaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.isHot = false,
  });

  /// Task model supplied by the discovery ViewModel.
  final Task task;

  /// Opens the existing task details route when the card is pressed.
  final VoidCallback onTap;

  /// Highlights urgent or promoted tender cards without changing data flow.
  final bool isHot;

  @override
  Widget build(BuildContext context) {
    const amberColors = AmberDuskTokens.colors;
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    final authorName = task.userName ?? 'Client';
    final details = _tenderDetails;
    final locationLabel =
        _firstNonEmpty([
          details['location'],
          task.categoryName,
          task.category,
          if (task.skills.isNotEmpty) task.skills.first,
        ]) ??
        'Task';
    final scheduleLabel =
        _firstNonEmpty([
          details['workType'],
          if (task.skills.isNotEmpty) task.skills.first,
        ]) ??
        'Fixed';
    final deadlineLabel = task.deadline == null
        ? 'Open'
        : _formatDeadline(task.deadline!);
    final statusLabel = isHot ? 'URGENT' : 'TASK';

    return Semantics(
      button: true,
      label: '${task.title} tender task card',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.p12),
        decoration: AmberDuskMaterial.taskCardDecoration(
          radius: AmberDuskTokens.spacing.taskCardRadius,
        ),
        child: ScaleButton(
          onPressed: () {
            AppLogger.d('TenderTaskCard tapped', tag: 'Cards');
            onTap();
          },
          child: Padding(
            padding: cardTheme.taskPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _AuthorAvatar(
                      name: authorName,
                      avatarPath: task.userAvatar,
                    ),
                    const SizedBox(width: AppDimens.p12),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: cardTheme.taskAuthorStyle.copyWith(
                                color: amberColors.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimens.p4),
                          Text(
                            formatFriendlyTime(task.createdAt),
                            style: cardTheme.taskCopyStyle.copyWith(
                              color: amberColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimens.p8),
                    _StatusPill(label: statusLabel, isUrgent: isHot),
                  ],
                ),
                SizedBox(height: cardTheme.taskSectionSpacing),
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cardTheme.taskTitleStyle.copyWith(
                    color: amberColors.text,
                  ),
                ),
                const SizedBox(height: AppDimens.p6),
                Text(
                  task.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cardTheme.taskCopyStyle.copyWith(
                    color: amberColors.muted,
                  ),
                ),
                const SizedBox(height: AppDimens.p10),
                Wrap(
                  spacing: AppDimens.p6,
                  runSpacing: AppDimens.p6,
                  children: [
                    _MetadataChip(
                      icon: Icons.location_on_outlined,
                      label: locationLabel,
                    ),
                    _MetadataChip(icon: Icons.tune, label: scheduleLabel),
                    _MetadataChip(
                      icon: Icons.schedule,
                      label: deadlineLabel,
                      isEmphasized: deadlineLabel != 'Open',
                    ),
                  ],
                ),
                SizedBox(height: cardTheme.taskSectionSpacing),
                Row(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: AppDimens.iconSizeSmall,
                      color: amberColors.muted,
                    ),
                    const SizedBox(width: AppDimens.p6),
                    Expanded(
                      child: Text(
                        '${task.offers} offers',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmberDuskTokens.typography.bodySmall.copyWith(
                          color: amberColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.p8),
                    _PricePill(amount: task.budget),
                    const SizedBox(width: AppDimens.p8),
                    Container(
                      height: cardTheme.cardActionHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.p14,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: amberColors.primary.withValues(alpha: 0.105),
                        borderRadius: BorderRadius.circular(
                          AmberDuskTokens.spacing.pillRadius,
                        ),
                      ),
                      child: Text(
                        'Make offer',
                        style: cardTheme.taskActionStyle.copyWith(
                          color: amberColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> get _tenderDetails {
    return Task.packageDetailsFrom(task.packages) ?? const <String, dynamic>{};
  }

  String? _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  String _formatDeadline(DateTime date) {
    if (task.status == TaskStatus.completed) return 'Completed';
    if (task.status == TaskStatus.closed) return 'Closed';

    final diff = date.difference(DateTime.now().toUtc());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.name, required this.avatarPath});

  final String name;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    final media = AmberDuskTokens.widgetTheme.media;
    const amberColors = AmberDuskTokens.colors;
    final avatarSize = cardTheme.taskAvatarSize;
    final path = avatarPath;

    if (path != null && path.isNotEmpty) {
      return SignedAvatar(
        storagePathOrUrl: path,
        radius: avatarSize / 2,
        borderColor: amberColors.surfaceHighest,
      );
    }

    return Container(
      width: avatarSize,
      height: avatarSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: media.avatarFallback,
        shape: BoxShape.circle,
      ),
      child: Text(_initials(name), style: media.initialsTextStyle(avatarSize)),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.isUrgent});

  final String label;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    const amberColors = AmberDuskTokens.colors;
    final pillTheme = AmberDuskTokens.widgetTheme.statusPills;
    final foreground = isUrgent ? amberColors.rust : amberColors.primary;
    return Container(
      padding: pillTheme.padding,
      decoration: BoxDecoration(
        color: isUrgent
            ? pillTheme.urgent.background
            : pillTheme.primary.background,
        borderRadius: BorderRadius.circular(AmberDuskTokens.spacing.pillRadius),
      ),
      child: Text(
        label,
        style: pillTheme.textStyle.copyWith(color: foreground),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    const amberColors = AmberDuskTokens.colors;
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    final price = _splitFormattedPrice(_formatCardPrice(amount));
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 112),
      child: Container(
        padding: cardTheme.taskPricePadding,
        decoration: BoxDecoration(
          color: cardTheme.taskPillFill,
          borderRadius: BorderRadius.circular(cardTheme.taskPriceRadius),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                price.amount,
                style: cardTheme.taskPriceStyle.copyWith(
                  color: amberColors.primary,
                ),
              ),
              if (price.suffix != null) ...[
                SizedBox(width: cardTheme.taskInlineGap - AppDimens.p2),
                Text(
                  price.suffix!,
                  style: AmberDuskTokens.typography.chip.copyWith(
                    color: amberColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.icon,
    required this.label,
    this.isEmphasized = false,
  });

  final IconData icon;
  final String label;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    const amberColors = AmberDuskTokens.colors;
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    final foreground = isEmphasized ? amberColors.star : amberColors.text;
    return Container(
      padding: cardTheme.taskTagPadding,
      decoration: BoxDecoration(
        color: isEmphasized
            ? amberColors.star.withValues(alpha: 0.12)
            : cardTheme.taskPillFill,
        borderRadius: BorderRadius.circular(AmberDuskTokens.spacing.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimens.iconSizeSmall, color: foreground),
          SizedBox(width: cardTheme.taskInlineGap),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cardTheme.taskChipStyle.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

({String amount, String? suffix}) _splitFormattedPrice(String value) {
  final trimmed = value.trim();
  final suffixMatch = RegExp(r'\s+([A-Z]{2,5})$').firstMatch(trimmed);
  if (suffixMatch == null) return (amount: trimmed, suffix: null);
  return (
    amount: trimmed.substring(0, suffixMatch.start).trim(),
    suffix: suffixMatch.group(1),
  );
}

String _formatCardPrice(
  double amount, {
  String suffix = PriceFormatter.defaultCurrency,
}) {
  final rounded = amount.round();
  final prefix = rounded < 0 ? '-' : '';
  return '$prefix${_groupThousands(rounded.abs().toString())} $suffix';
}

String _groupThousands(String digits) {
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index += 1) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}
