import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/categories/models/category_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/view/create_task_screen.dart';

/// Step 1 of Create Task: task type selection and category picker.
///
/// Displays two type cards (Tender / Booking) and a grid of categories.
/// All state changes are communicated back via callbacks.
class TaskConceptSection extends StatelessWidget {
  final TaskType selectedTaskType;
  final String? selectedCategoryId;
  final String? selectedCategoryName;
  final List<CategoryModel> categories;
  final bool categoriesLoading;
  final ValueChanged<TaskType> onTaskTypeChanged;
  final void Function(String? id, String name) onCategorySelected;

  const TaskConceptSection({
    super.key,
    required this.selectedTaskType,
    required this.selectedCategoryId,
    required this.selectedCategoryName,
    required this.categories,
    required this.categoriesLoading,
    required this.onTaskTypeChanged,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    final popularCategories = [
      {
        'icon': Icons.palette_outlined,
        'name': 'Design',
        'color': AppColors.lightRed,
      },
      {'icon': Icons.code, 'name': 'Development', 'color': AppColors.lightTeal},
      {'icon': Icons.edit_note, 'name': 'Writing', 'color': AppColors.sand},
      {'icon': Icons.phone_iphone, 'name': 'Mobile', 'color': AppColors.gold},
      {
        'icon': Icons.campaign_outlined,
        'name': 'Marketing',
        'color': AppColors.mediumGreyBlue,
      },
      {'icon': Icons.movie_outlined, 'name': 'Video', 'color': AppColors.teal},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Task Type',
          style: AppTypography.h5.copyWith(color: colorScheme.text),
        ),
        const SizedBox(height: AppDimens.p12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                cardKey: CreateTaskScreen.tenderTypeCardKey,
                icon: Icons.assignment_outlined,
                label: 'Tender',
                subLabel: 'Open proposals',
                type: TaskType.tender,
                colorScheme: colorScheme,
                color: AppColors.lightRed,
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: _buildTypeCard(
                cardKey: CreateTaskScreen.bookingTypeCardKey,
                icon: Icons.calendar_today_outlined,
                label: 'Booking',
                subLabel: 'Direct hire',
                type: TaskType.booking,
                colorScheme: colorScheme,
                color: AppColors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.p24),
        Text(
          'Choose Category',
          style: AppTypography.h5.copyWith(color: colorScheme.text),
        ),
        const SizedBox(height: AppDimens.p12),
        if (categoriesLoading)
          const Center(child: CircularProgressIndicator())
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppDimens.p10,
              mainAxisSpacing: AppDimens.p10,
              childAspectRatio: 1.0,
            ),
            itemCount: categories.isNotEmpty
                ? categories.length
                : popularCategories.length,
            itemBuilder: (context, index) {
              if (categories.isNotEmpty) {
                final cat = categories[index];
                final isSelected = selectedCategoryId == cat.id;
                final icon = _getCategoryIcon(cat.name);
                final catColor = _getCategoryColor(cat.name);

                return _buildCategoryCard(
                  icon: icon,
                  name: cat.name,
                  isSelected: isSelected,
                  color: catColor,
                  colorScheme: colorScheme,
                  onTap: () => onCategorySelected(cat.id, cat.name),
                );
              } else {
                final cat = popularCategories[index];
                final catName = cat['name']! as String;
                final isSelected = selectedCategoryName == catName;

                return _buildCategoryCard(
                  icon: cat['icon']! as IconData,
                  name: catName,
                  isSelected: isSelected,
                  color: cat['color']! as Color,
                  colorScheme: colorScheme,
                  onTap: () => onCategorySelected(null, catName),
                );
              }
            },
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
    return GestureDetector(
      onTap: () => onTaskTypeChanged(type),
      child: AnimatedContainer(
        key: cardKey,
        duration: const Duration(milliseconds: 200),
        height: 100,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.r18),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: isSelected ? color : colorScheme.text),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : colorScheme.text,
              ),
            ),
            Text(
              subLabel,
              style: AppTypography.micro.copyWith(
                color: colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String name,
    required bool isSelected,
    required Color color,
    required AppColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.r16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: isSelected ? color : colorScheme.text),
            const SizedBox(height: 6),
            Text(
              name,
              style: AppTypography.captionBold.copyWith(
                color: colorScheme.text,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('design')) return Icons.palette_outlined;
    if (lowerName.contains('dev') || lowerName.contains('code')) {
      return Icons.code;
    }
    if (lowerName.contains('writ') || lowerName.contains('content')) {
      return Icons.edit_note;
    }
    if (lowerName.contains('mobile') || lowerName.contains('app')) {
      return Icons.phone_iphone;
    }
    if (lowerName.contains('market') || lowerName.contains('seo')) {
      return Icons.campaign_outlined;
    }
    if (lowerName.contains('video') || lowerName.contains('media')) {
      return Icons.movie_outlined;
    }
    return Icons.folder_outlined;
  }

  Color _getCategoryColor(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('design')) return AppColors.lightRed;
    if (lowerName.contains('dev') || lowerName.contains('code')) {
      return AppColors.lightTeal;
    }
    if (lowerName.contains('writ') || lowerName.contains('content')) {
      return AppColors.sand;
    }
    if (lowerName.contains('mobile') || lowerName.contains('app')) {
      return AppColors.gold;
    }
    if (lowerName.contains('market') || lowerName.contains('seo')) {
      return AppColors.mediumGreyBlue;
    }
    if (lowerName.contains('video') || lowerName.contains('media')) {
      return AppColors.teal;
    }
    return AppColors.teal;
  }
}
