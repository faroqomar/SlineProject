import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

/// Simple token-normalized tile for a saved task identifier.
///
/// The tile keeps the legacy MVP contract of showing only [taskId] while using
/// the shared surface, spacing, typography, and Amber Dusk action tokens.
class SavedTaskTile extends StatelessWidget {
  /// Identifier of the saved task displayed in the tile.
  final String taskId;

  /// Callback fired when the user removes this saved task.
  final VoidCallback onRemove;

  const SavedTaskTile({
    super.key,
    required this.taskId,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amber = colorScheme.isDark
        ? AmberDuskTokens.colors.dark
        : AmberDuskTokens.colors.light;

    return Semantics(
      label: 'Saved task $taskId, delete available',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.p12),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.r16),
          border: Border.all(color: colorScheme.cardBorder),
          boxShadow: AppDecorations.elevation(1, isDark: colorScheme.isDark),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p16,
            vertical: AppDimens.p4,
          ),
          leading: Container(
            width: AppDimens.p40,
            height: AppDimens.p40,
            decoration: BoxDecoration(
              color: amber.activeGlow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark,
              color: amber.primary,
              size: AppDimens.iconSmall,
            ),
          ),
          title: Text(
            'Task: $taskId',
            style: AppTypography.bodyMedium.copyWith(color: colorScheme.text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            tooltip: 'Remove saved task',
            onPressed: onRemove,
            icon: Icon(
              Icons.delete_outline,
              color: amber.danger,
              size: AppDimens.iconSmall,
            ),
          ),
        ),
      ),
    );
  }
}
