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
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';

/// Context banner at the top of a chat screen showing the linked Task or Booking.
///
/// Phase 5 redesign: replaced hardcoded `AppColors.gold/teal` with semantic
/// tokens (`colorScheme.warning/primary`), replaced raw icon sizes and spacing
/// with `AppDimens`/`AppLayout` tokens, added haptic feedback on tap, and
/// full Semantics coverage for accessibility. View-layer only.
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

    return Semantics(
      label: '$contextLabel: $title, tap to view details',
      button: true,
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: AppCardContainer(
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimens.p12,
            vertical: AppDimens.p8,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p12,
            vertical: AppDimens.p10,
          ),
          borderRadius: BorderRadius.circular(AppDimens.r16),
          child: Row(
            children: [
              // Icon circle with accent background
              Container(
                padding: const EdgeInsets.all(AppDimens.p8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isBooking
                      ? Icons.calendar_today_rounded
                      : Icons.assignment_rounded,
                  size: AppDimens.iconSizeSmall,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          contextLabel,
                          style: AppTypography.micro.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: AppLayout.spacingTight),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: AppLayout.iconTiny,
                          color: accentColor.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.p2),
                    Text(
                      title,
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
