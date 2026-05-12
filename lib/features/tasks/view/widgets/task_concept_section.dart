import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart' show AppColorScheme;
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/view/create_task_screen.dart';
import 'package:sline_app/l10n/app_localizations.dart';

/// Step 1 of Create Task: task type selection.
///
/// Displays the two Open Design concept cards only; all detailed fields move to
/// the details step so the progression stays Type -> Details -> Review.
class TaskConceptSection extends StatelessWidget {
  final TaskType selectedTaskType;
  final ValueChanged<TaskType> onTaskTypeChanged;

  const TaskConceptSection({
    super.key,
    required this.selectedTaskType,
    required this.onTaskTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    const colors = AmberDuskTokens.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.createPost ?? 'Create a post',
          style: AmberDuskTokens.typography.sectionTitle.copyWith(
            color: colors.text,
          ),
        ),
        const SizedBox(height: AppDimens.p12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                cardKey: CreateTaskScreen.tenderTypeCardKey,
                icon: Icons.assignment_outlined,
                label: l10n?.tenderPostTitle ?? 'Tender post',
                subLabel:
                    l10n?.tenderPostSubtitle ??
                    'Client request with budget, deadline, and offers.',
                type: TaskType.tender,
                colorScheme: colorScheme,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: _buildTypeCard(
                cardKey: CreateTaskScreen.bookingTypeCardKey,
                icon: Icons.calendar_today_outlined,
                label: l10n?.bookingPostTitle ?? 'Booking post',
                subLabel:
                    l10n?.bookingPostSubtitle ??
                    'Freelancer service package with price.',
                type: TaskType.booking,
                colorScheme: colorScheme,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    Key? cardKey,
    required IconData icon,
    required String label,
    required String subLabel,
    required TaskType type,
    required AppColorScheme colorScheme,
    required Color color,
  }) {
    final isSelected = selectedTaskType == type;
    return Semantics(
      label: '$label. $subLabel',
      selected: isSelected,
      button: true,
      onTap: () => onTaskTypeChanged(type),
      child: GestureDetector(
        key: cardKey,
        onTap: () => onTaskTypeChanged(type),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          constraints: const BoxConstraints(minHeight: 124),
          padding: const EdgeInsets.all(AppDimens.p14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.18)
                : AmberDuskTokens.colors.surface,
            borderRadius: BorderRadius.circular(
              AmberDuskTokens.spacing.moduleRadius,
            ),
            border: Border.all(
              color: isSelected ? color : AmberDuskTokens.colors.surfaceHighest,
            ),
            boxShadow: AppDecorations.elevation(
              isSelected ? 2 : 1,
              isDark: colorScheme.isDark,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppDimens.p40,
                height: AppDimens.p40,
                decoration: BoxDecoration(
                  color: AmberDuskTokens.colors.activeGlow,
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                ),
                child: Icon(
                  icon,
                  size: AppDimens.iconSmall,
                  color: isSelected ? color : AmberDuskTokens.colors.textSubtle,
                ),
              ),
              const SizedBox(height: AppDimens.p12),
              Text(
                label,
                style: AmberDuskTokens.typography.control.copyWith(
                  color: isSelected ? color : AmberDuskTokens.colors.text,
                ),
              ),
              const SizedBox(height: AppDimens.p4),
              Text(
                subLabel,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AmberDuskTokens.typography.bodySmall.copyWith(
                  color: AmberDuskTokens.colors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
