import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/loading_utils.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';

/// Widget to display context (Task or Booking) at the top of a Chat Screen.
/// Tapping this navigates to the associated Task/Booking details.
class ChatContextWidget extends StatelessWidget {
  const ChatContextWidget({super.key, required this.conversation});

  final Conversation conversation;

  Future<void> _handleTap(BuildContext context) async {
    final taskId = conversation.taskId;
    if (taskId == null || taskId.isEmpty) return;

    final taskVm = context.read<TaskViewModel>();

    // Show a small loading indicator or just fetch optimistically
    // Ideally we would have a loading state, but for a quick action we can just await
    final loader = LoadingUtils.show(context, debugLabel: 'chat_context_task');
    try {
      final task = await taskVm.getTaskById(taskId);
      if (!context.mounted) return;

      if (task != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load task details.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppLogger.e('Error loading task for context nav: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
    final accentColor = isBooking ? AppColors.gold : AppColors.teal;

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.p12,
          vertical: 8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p12,
          vertical: AppDimens.p10,
        ),
        borderRadius: BorderRadius.circular(AppDimens.r16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isBooking
                    ? Icons.calendar_today_rounded
                    : Icons.assignment_rounded,
                size: 16,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        isBooking ? 'BOOKING CONTEXT' : 'TASK CONTEXT',
                        style: AppTypography.micro.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 8,
                        color: accentColor.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
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
    );
  }
}
