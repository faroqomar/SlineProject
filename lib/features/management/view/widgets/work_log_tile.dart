import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
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
    final amberColors = context.amberColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p12,
            vertical: AppDimens.p4,
          ),
          decoration: BoxDecoration(
            color: amberColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDimens.r12),
            border: Border.all(color: amberColors.surfaceHighest),
          ),
          child: Text(
            log.content,
            style: AppTypography.caption.copyWith(color: amberColors.muted),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    // Style based on private vs public
    final amberColors = context.amberColors;
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
            SignedAvatar(
              storagePathOrUrl: log.authorAvatar,
              radius: AppLayout.avatarSmall / 2,
            ),
            const SizedBox(width: AppDimens.p8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppDimens.p12),
              decoration: BoxDecoration(
                color: isPrivate
                    ? amberColors.warningMuted
                    : (isMe
                          ? amberColors.primary.withValues(alpha: 0.12)
                          : amberColors.surfaceRaised),
                borderRadius: BorderRadius.circular(AppDimens.r12),
                border: isPrivate
                    ? Border.all(
                        color: amberColors.warning.withValues(alpha: 0.3),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPrivate)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppDimens.p4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock,
                            size: AppDimens.iconSizeSmall,
                            color: amberColors.warning,
                          ),
                          const SizedBox(width: AppDimens.p4),
                          Text(
                            'Private Note',
                            style: AppTypography.caption.copyWith(
                              color: amberColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    log.content,
                    style: AppTypography.bodySmall.copyWith(
                      color: amberColors.text,
                    ),
                  ),
                  const SizedBox(height: AppDimens.p4),
                  Text(
                    formatUtcToLocal(log.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: amberColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: AppDimens.p8),
            SignedAvatar(
              storagePathOrUrl: log.authorAvatar,
              radius: AppLayout.avatarSmall / 2,
            ),
          ],
        ],
      ),
    );
  }
}
