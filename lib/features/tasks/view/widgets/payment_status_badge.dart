import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

/// Compact badge showing payment status with icon and color coding.
///
/// Color scheme:
/// - unpaid: orange/amber (warning - action needed)
/// - held: green (success - funds secured)
/// - released: blue (info - payment completed)
/// - refunded: grey (neutral - transaction reversed)
///
/// Screen reader accessible via Semantics wrapper.
class PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;
  final DateTime? deadline;
  final bool showDeadline;
  final double iconSize;
  final double fontSize;

  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.deadline,
    this.showDeadline = true,
    this.iconSize = 14,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(context);
    final label = _getSemanticLabel();

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p8,
          vertical: AppDimens.p4,
        ),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(AppDimens.r8),
          border: Border.all(color: config.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: iconSize, color: config.textColor),
            const SizedBox(width: AppDimens.p4),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: config.textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showDeadline &&
                      deadline != null &&
                      status == PaymentStatus.unpaid)
                    _buildDeadlineText(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineText(BuildContext context) {
    final now = DateTime.now();
    final diff = deadline!.difference(now);
    final isExpired = diff.isNegative;

    String deadlineText;
    if (isExpired) {
      deadlineText = 'Expired';
    } else if (diff.inDays > 0) {
      deadlineText = '${diff.inDays}d ${diff.inHours.remainder(24)}h left';
    } else if (diff.inHours > 0) {
      deadlineText = '${diff.inHours}h ${diff.inMinutes.remainder(60)}m left';
    } else {
      deadlineText = '${diff.inMinutes}m left';
    }

    return Text(
      deadlineText,
      style: TextStyle(
        fontSize: fontSize - 1,
        color: isExpired ? AppColors.lightRed : AppColors.mediumGrey,
      ),
    );
  }

  String _getSemanticLabel() {
    final baseLabel = switch (status) {
      PaymentStatus.unpaid => 'Payment pending',
      PaymentStatus.held => 'Escrow held',
      PaymentStatus.released => 'Payment released',
      PaymentStatus.refunded => 'Payment refunded',
    };

    if (deadline != null && status == PaymentStatus.unpaid) {
      final now = DateTime.now();
      final diff = deadline!.difference(now);
      if (diff.isNegative) {
        return '$baseLabel, deadline expired';
      }
      return '$baseLabel, ${diff.inDays > 0
          ? '${diff.inDays} days'
          : diff.inHours > 0
          ? '${diff.inHours} hours'
          : '${diff.inMinutes} minutes'} remaining';
    }

    return baseLabel;
  }

  _BadgeConfig _getConfig(BuildContext context) {
    final amberColors = context.amberColors;

    switch (status) {
      case PaymentStatus.unpaid:
        return _BadgeConfig(
          icon: Icons.warning_amber_rounded,
          label: 'Payment Pending',
          backgroundColor: amberColors.warning.withValues(alpha: 0.12),
          borderColor: amberColors.warning.withValues(alpha: 0.3),
          textColor: amberColors.warning,
        );
      case PaymentStatus.held:
        return _BadgeConfig(
          icon: Icons.verified_rounded,
          label: 'Escrow Held',
          backgroundColor: amberColors.success.withValues(alpha: 0.12),
          borderColor: amberColors.success.withValues(alpha: 0.3),
          textColor: amberColors.success,
        );
      case PaymentStatus.released:
        return _BadgeConfig(
          icon: Icons.check_circle_rounded,
          label: 'Paid',
          backgroundColor: AppColors.teal.withValues(alpha: 0.12),
          borderColor: AppColors.teal.withValues(alpha: 0.3),
          textColor: AppColors.teal,
        );
      case PaymentStatus.refunded:
        return _BadgeConfig(
          icon: Icons.replay_rounded,
          label: 'Refunded',
          backgroundColor: AppColors.mediumGrey.withValues(alpha: 0.15),
          borderColor: AppColors.mediumGrey.withValues(alpha: 0.3),
          textColor: AppColors.darkerGrey,
        );
    }
  }
}

class _BadgeConfig {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _BadgeConfig({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}
