import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/circle_icon_button.dart';
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
    final canMessage =
        status == UnifiedWorkStatus.active ||
        status == UnifiedWorkStatus.delivered;

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
        !canMessage &&
        !canShowReportIssue &&
        !isAwaitingClientReview) {
      return const SizedBox.shrink();
    }

    final useMessageAsPrimary =
        !canAccept &&
        !canCancel &&
        !canSubmit &&
        !canReview &&
        !isAwaitingClientReview &&
        canMessage;
    final primaryActionBlock = _buildPrimaryAction(
      context,
      canAccept: canAccept,
      canCancel: canCancel,
      canSubmit: canSubmit,
      canReview: canReview,
      isAwaitingClientReview: isAwaitingClientReview,
      useMessageAsPrimary: useMessageAsPrimary,
    );
    final secondaryActionButtons = <Widget>[
      if (canAccept)
        CircleIconButton(
          icon: Icons.close,
          tooltip: 'Decline',
          iconColor: context.colorScheme.danger,
          size: AppDimens.p40,
          onTap: onDeclineBooking,
        ),
      if (canRequestExtension)
        CircleIconButton(
          icon: Icons.timer_outlined,
          tooltip: 'Request extension',
          size: AppDimens.p40,
          onTap: onRequestExtension,
        ),
      if (!useMessageAsPrimary && canMessage)
        CircleIconButton(
          icon: Icons.chat_bubble_outline,
          tooltip: 'Open chat',
          size: AppDimens.p40,
          onTap: onMessage,
        ),
      if (canShowReportIssue)
        SizedBox(
          width: AppLayout.minTouchTarget,
          height: AppLayout.minTouchTarget,
          child: Center(
            child: ReportIssueGuard(
              sourceType: sourceType,
              entityId: entityId,
              onReportIssue: onReportIssue,
              safetyViewModel: safetyViewModel,
              reserveSpace: true,
              builder: (ctx, onPressed) => CircleIconButton(
                icon: Icons.warning_amber_rounded,
                tooltip: 'Report issue',
                iconColor: ctx.colorScheme.danger,
                size: AppDimens.p40,
                onTap: onPressed,
              ),
            ),
          ),
        ),
    ];

    if (primaryActionBlock == null && secondaryActionButtons.isEmpty) {
      return const SizedBox.shrink();
    }

    final spacedSecondaryActions = <Widget>[];
    for (final action in secondaryActionButtons) {
      if (spacedSecondaryActions.isNotEmpty) {
        spacedSecondaryActions.add(const SizedBox(width: AppDimens.p6));
      }
      spacedSecondaryActions.add(action);
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AmberDuskSpacing.contentHorizontalPadding,
          AppDimens.p6,
          AmberDuskSpacing.contentHorizontalPadding,
          AppDimens.p10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (primaryActionBlock != null) Expanded(child: primaryActionBlock),
            if (primaryActionBlock != null && spacedSecondaryActions.isNotEmpty)
              const SizedBox(width: AppDimens.p8),
            ...spacedSecondaryActions,
          ],
        ),
      ),
    );
  }

  /// Picks one dominant action for the dock so secondary actions stay quiet
  /// and the work state remains easy to scan.
  Widget? _buildPrimaryAction(
    BuildContext context, {
    required bool canAccept,
    required bool canCancel,
    required bool canSubmit,
    required bool canReview,
    required bool isAwaitingClientReview,
    required bool useMessageAsPrimary,
  }) {
    if (canAccept) {
      return AppButton(
        text: 'Accept',
        icon: Icons.check,
        height: AppDimens.publicProfileActionButtonHeight,
        onPressed: onAcceptBooking,
      );
    }
    if (canCancel) {
      return AppButton(
        text: 'Cancel Request',
        isPrimary: false,
        backgroundColor: context.colorScheme.danger,
        height: AppDimens.publicProfileActionButtonHeight,
        onPressed: onCancelBooking,
      );
    }
    if (canSubmit) {
      return AppButton(
        text: 'Submit Work',
        icon: Icons.outbox_outlined,
        height: AppDimens.publicProfileActionButtonHeight,
        onPressed: onSubmitWork,
      );
    }
    if (canReview) {
      return ReviewWithDisputeGuard(
        sourceType: sourceType,
        entityId: entityId,
        onReview: onReview,
        safetyViewModel: safetyViewModel,
        height: AppDimens.publicProfileActionButtonHeight,
      );
    }
    if (isAwaitingClientReview) {
      return const AppButton(
        text: 'Waiting for Client Review',
        isPrimary: false,
        onPressed: null,
        height: AppDimens.publicProfileActionButtonHeight,
      );
    }
    if (useMessageAsPrimary) {
      return AppButton(
        text: 'Message',
        isPrimary: false,
        icon: Icons.chat_bubble_outline,
        height: AppDimens.publicProfileActionButtonHeight,
        onPressed: onMessage,
      );
    }
    return null;
  }
}
