import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';
import 'package:sline_app/features/work/view/widgets/work_item_guard_widgets.dart';

/// Bottom action bar for [WorkItemDetailsScreen].
///
/// Displays contextual primary and secondary actions based on the user's role
/// and the current work-item status.
class WorkItemBottomActions extends StatelessWidget {
  const WorkItemBottomActions({
    super.key,
    required this.status,
    required this.isFreelancer,
    required this.isClient,
    required this.isBooking,
    required this.canReview,
    required this.sourceType,
    required this.entityId,
    required this.onSubmitWork,
    required this.onReview,
    required this.onRequestExtension,
    required this.onMessage,
    required this.onReportIssue,
    required this.onAcceptBooking,
    required this.onDeclineBooking,
    required this.onCancelBooking,
    required this.canShowReportIssue,
    required this.safetyViewModel,
  });

  final UnifiedWorkStatus status;
  final bool isFreelancer;
  final bool isClient;
  final bool isBooking;
  final bool canReview;
  final String sourceType;
  final String entityId;
  final VoidCallback onSubmitWork;
  final VoidCallback onReview;
  final VoidCallback onRequestExtension;
  final VoidCallback onMessage;
  final VoidCallback onReportIssue;
  final VoidCallback onAcceptBooking;
  final VoidCallback onDeclineBooking;
  final VoidCallback onCancelBooking;
  final bool canShowReportIssue;
  final SafetyViewModel safetyViewModel;

  @override
  Widget build(BuildContext context) {
    final canSubmit = isFreelancer && status == UnifiedWorkStatus.active;
    final canRequestExtension = status == UnifiedWorkStatus.active;

    final isPendingBooking =
        isBooking &&
        (status == UnifiedWorkStatus.pending ||
            status == UnifiedWorkStatus.requestPending);
    final canAccept = isFreelancer && isPendingBooking;
    final canCancel = isClient && isPendingBooking;
    final isAwaitingClientReview =
        isFreelancer && status == UnifiedWorkStatus.delivered;

    if (!canSubmit &&
        !canRequestExtension &&
        !canAccept &&
        !canReview &&
        !canCancel &&
        !isAwaitingClientReview) {
      return const SizedBox.shrink();
    }

    Widget? primaryActionBlock;
    final secondaryActionButtons = <Widget>[];

    var promotedMessageToPrimary = false;

    if (canAccept) {
      final colorScheme = context.colorScheme;
      primaryActionBlock = Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Decline',
              isPrimary: false,
              backgroundColor: colorScheme.danger,
              onPressed: onDeclineBooking,
            ),
          ),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: AppButton(text: 'Accept', onPressed: onAcceptBooking),
          ),
        ],
      );
    } else if (canCancel) {
      final colorScheme = context.colorScheme;
      primaryActionBlock = AppButton(
        text: 'Cancel Request',
        isPrimary: false,
        backgroundColor: colorScheme.danger,
        onPressed: onCancelBooking,
      );
    } else {
      if (canSubmit) {
        primaryActionBlock = AppButton(
          text: 'Submit Work',
          onPressed: onSubmitWork,
        );
      } else if (canReview) {
        primaryActionBlock = ReviewWithDisputeGuard(
          sourceType: sourceType,
          entityId: entityId,
          onReview: onReview,
          safetyViewModel: safetyViewModel,
        );
      } else if (isAwaitingClientReview) {
        primaryActionBlock = const AppButton(
          text: 'Waiting for Client Review',
          isPrimary: false,
          onPressed: null,
        );
      } else if (status == UnifiedWorkStatus.active ||
          status == UnifiedWorkStatus.delivered) {
        promotedMessageToPrimary = true;
        primaryActionBlock = AppButton(
          text: 'Message',
          isPrimary: false,
          icon: Icons.chat_bubble_outline,
          onPressed: onMessage,
        );
      }

      if (canRequestExtension) {
        secondaryActionButtons.add(
          _buildVerticalIconAction(
            context: context,
            icon: Icons.timer_outlined,
            label: 'Extend',
            onPressed: onRequestExtension,
          ),
        );
      }

      if (!promotedMessageToPrimary &&
          (status == UnifiedWorkStatus.active ||
              status == UnifiedWorkStatus.delivered)) {
        secondaryActionButtons.add(
          _buildVerticalIconAction(
            context: context,
            icon: Icons.chat_bubble_outline,
            label: 'Message',
            onPressed: onMessage,
          ),
        );
      }

      if (canShowReportIssue) {
        secondaryActionButtons.add(
          ReportIssueGuard(
            sourceType: sourceType,
            entityId: entityId,
            onReportIssue: onReportIssue,
            safetyViewModel: safetyViewModel,
            builder: (ctx, onPressed) => _buildVerticalIconAction(
              context: ctx,
              icon: Icons.warning_amber_rounded,
              label: 'Report',
              color: ctx.colorScheme.danger,
              onPressed: onPressed,
            ),
          ),
        );
      }
    }

    if (primaryActionBlock == null && secondaryActionButtons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colorScheme.cardBackground,
        boxShadow: AppDecorations.elevation(
          2,
          isDark: context.colorScheme.isDark,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p16,
            vertical: AppDimens.p12,
          ),
          child: Row(
            children: [
              if (secondaryActionButtons.isNotEmpty) ...[
                ...secondaryActionButtons.map(
                  (btn) => Padding(
                    padding: const EdgeInsets.only(right: AppDimens.p12),
                    child: btn,
                  ),
                ),
              ],
              if (primaryActionBlock != null)
                Expanded(child: primaryActionBlock)
              else
                const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalIconAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimens.r8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p4,
            vertical: AppDimens.p4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppDimens.p22,
                color: color ?? context.colorScheme.textSecondary,
              ),
              const SizedBox(height: AppDimens.p2),
              Text(
                label,
                style: AppTypography.micro.copyWith(
                  color: color ?? context.colorScheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
