import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/loading_utils.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';

/// Compact pill showing the linked Task or Booking at the top of a chat screen.
///
/// Phase 5 redesign: replaced hardcoded `AppColors.gold/teal` with semantic
/// tokens (`colorScheme.warning/primary`), replaced raw icon sizes and spacing
/// with `AppDimens`/`AppLayout` tokens, added haptic feedback on tap, and
/// full Semantics coverage for accessibility. View-layer only.
///
/// Phase 6 pill polish: collapsed the card + icon-circle + CONTEXT label into a
/// single compact pill (stadium shape) with icon + title + chevron in one row.
/// Uses `BorderRadius.circular(AppDimens.r20)` for stadium corners and a
/// translucent accent background instead of the heavier `AppCardContainer`.
class ChatContextWidget extends StatelessWidget {
  const ChatContextWidget({super.key, required this.conversation});

  final Conversation conversation;

  Future<void> _handleTap(BuildContext context) async {
    final taskId = conversation.taskId;
    if (taskId == null || taskId.isEmpty) return;

    AppInteractionStates.hapticTap();
    AppLogger.i('ChatContextWidget: navigating to task $taskId', tag: 'Chat');

    final taskVm = context.read<TaskViewModel>();

    final loader = LoadingUtils.show(context, debugLabel: 'chat_context_task');
    try {
      final task = await taskVm.getTaskById(taskId);
      if (!context.mounted) return;

      if (task != null) {
        unawaited(
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load task details.')),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        AppLogger.e('Error loading task for context nav', error: e);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open task details. Please try again.'),
          ),
        );
      }
    } finally {
      loader.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (conversation.taskId == null ||
        conversation.taskId!.isEmpty ||
        conversation.taskId == '00000000-0000-0000-0000-000000000000') {
      return const SizedBox.shrink();
    }

    final isBooking = conversation.taskType == 'booking';
    final title = conversation.taskTitle ?? 'Untitled Task';
    final colorScheme = context.colorScheme;
    // Semantic tokens — warning for bookings, primary for tasks
    final accentColor = isBooking ? colorScheme.warning : colorScheme.primary;
    final contextLabel = isBooking ? 'BOOKING CONTEXT' : 'TASK CONTEXT';

    // Phase 6: compact pill — Center prevents full-width stretch
    return Center(
      child: Semantics(
        label: '$contextLabel: $title, tap to view details',
        button: true,
        child: GestureDetector(
          onTap: () => _handleTap(context),
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppDimens.p12,
              vertical: AppDimens.p8,
            ),
            // Compact pill padding — tighter than the old card
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p12,
              vertical: AppDimens.p8,
            ),
            decoration: BoxDecoration(
              // Translucent accent fill replaces the heavier card background
              color: accentColor.withValues(alpha: 0.08),
              // Stadium / pill shape via r20
              borderRadius: BorderRadius.circular(AppDimens.r20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Leading icon — booking calendar vs task assignment
                Icon(
                  isBooking
                      ? Icons.calendar_today_rounded
                      : Icons.assignment_rounded,
                  size: AppDimens.iconSizeSmall,
                  color: accentColor,
                ),
                const SizedBox(width: AppLayout.spacingTight),
                // Title — flexible so long names ellipsize gracefully
                Flexible(
                  child: Text(
                    title,
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppLayout.spacingTight),
                // Trailing chevron — hints the pill is tappable
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppDimens.iconSizeSmall,
                  color: colorScheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
