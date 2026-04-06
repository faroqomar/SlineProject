import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/management/models/work_log_model.dart';

class WorkLogTile extends StatelessWidget {
  final WorkLog log;
  final bool isMe;

  const WorkLogTile({super.key, required this.log, required this.isMe});

  @override
  Widget build(BuildContext context) {
    if (log.isSystemEvent) {
      return _buildSystemEvent(context);
    }
    return _buildMessage(context);
  }

  Widget _buildSystemEvent(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p12,
            vertical: AppDimens.p4,
          ),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppDimens.r12),
            border: Border.all(
              color: colorScheme.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            log.content,
            style: AppTypography.caption.copyWith(
              color: colorScheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    // Style based on private vs public
    final colorScheme = context.colorScheme;
    final isPrivate = log.isPrivate;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            SignedAvatar(storagePathOrUrl: log.authorAvatar, radius: 16),
            const SizedBox(width: AppDimens.p8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppDimens.p12),
              decoration: BoxDecoration(
                color: isPrivate
                    ? AppColors.gold.withValues(alpha: 0.1)
                    : (isMe
                          ? AppColors.teal.withValues(alpha: 0.1)
                          : colorScheme.cardBackground),
                borderRadius: BorderRadius.circular(AppDimens.r12),
                border: isPrivate
                    ? Border.all(color: AppColors.gold.withValues(alpha: 0.3))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPrivate)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 12, color: AppColors.gold),
                          const SizedBox(width: 4),
                          Text(
                            'Private Note',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.gold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    log.content,
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatUtcToLocal(log.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: AppDimens.p8),
            SignedAvatar(storagePathOrUrl: log.authorAvatar, radius: 16),
          ],
        ],
      ),
    );
  }
}
