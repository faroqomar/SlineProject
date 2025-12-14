import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/signed_image.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';

/// A card widget to display task info matching the new design system.
/// Features: colored header, HOT badge, type badge, glassmorphism.
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final bool isHot;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.isHot = false,
  });

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    final bool isTender = task.isTender;

    // Card header background color based on task type or category
    final Color headerBgColor = _getHeaderColor();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r20),
        border: Border.all(
          color: colorScheme.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.isDark
                ? AppColors.almostBlack.withValues(alpha: 0.3)
                : AppColors.almostBlack.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.r20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.r20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Colored Header Section ---
              _buildHeader(context, headerBgColor, isTender),

              // --- Content Section ---
              _buildContent(context, colorScheme, isTender),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color bgColor, bool isTender) {
    final bool hasImage = task.imagePaths.isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppDimens.r20),
        topRight: Radius.circular(AppDimens.r20),
      ),
      child: SizedBox(
        height: 120,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background: Image or solid color
            if (hasImage)
              SignedImage(
                storagePathOrUrl: task.imagePaths.first,
                width: double.infinity,
                height: 120,
                borderRadius: 0, // ClipRRect handles the corners
                fit: BoxFit.cover,
                placeholder: Container(
                  width: double.infinity,
                  height: 120,
                  color: bgColor,
                ),
              )
            else
              Container(color: bgColor),

            // Gradient overlay (for both image and color backgrounds)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.almostBlack.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // HOT Badge (top-left)
            if (isHot)
              Positioned(
                top: AppDimens.p12,
                left: AppDimens.p12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p10,
                    vertical: AppDimens.p4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightRed,
                    borderRadius: BorderRadius.circular(AppDimens.r8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightRed.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🔥',
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'HOT',
                        style: AppTypography.micro.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.offWhite,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Type Badge (top-right)
            Positioned(
              top: AppDimens.p12,
              right: AppDimens.p12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.p12,
                  vertical: AppDimens.p6,
                ),
                decoration: BoxDecoration(
                  color: isTender
                      ? AppColors.lightRed.withValues(alpha: 0.9)
                      : AppColors.teal.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppDimens.r8),
                  border: Border.all(
                    color: isTender
                        ? AppColors.offWhite.withValues(alpha: 0.3)
                        : AppColors.lightTeal.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.almostBlack.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  isTender ? 'TENDER' : 'BOOKING',
                  style: AppTypography.micro.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.offWhite,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, AppColorScheme colorScheme, bool isTender) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            task.title,
            style: AppTypography.h6.copyWith(
              color: colorScheme.text,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimens.p8),

          // Description
          Text(
            task.description,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.textSecondary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimens.p12),

          // Footer with divider
          Container(
            padding: const EdgeInsets.only(top: AppDimens.p12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colorScheme.cardBorder),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Time Left / Offers info
                Row(
                  children: [
                    if (task.deadline != null) ...[
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: isTender ? AppColors.lightRed : AppColors.teal,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDeadline(task.deadline!),
                        style: AppTypography.captionBold.copyWith(
                          color:
                              isTender ? AppColors.lightRed : AppColors.teal,
                        ),
                      ),
                    ] else
                      Text(
                        isTender ? 'Open' : 'Available',
                        style: AppTypography.captionBold.copyWith(
                          color:
                              isTender ? AppColors.lightRed : AppColors.teal,
                        ),
                      ),
                  ],
                ),

                // Budget
                Text(
                  PriceFormatter.formatPrice(task.budget),
                  style: AppTypography.h5.copyWith(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get header color based on task category or type
  Color _getHeaderColor() {
    // Use category-based colors if available
    final category = task.categoryName?.toLowerCase() ?? task.category?.toLowerCase() ?? '';

    switch (category) {
      case 'design':
        return AppColors.lightRed;
      case 'development':
      case 'dev':
        return AppColors.lightTeal;
      case 'writing':
        return const Color(0xFFF7D69C); // Sand/beige color
      case 'marketing':
        return AppColors.mediumGreyBlue;
      case 'mobile':
        return AppColors.gold;
      default:
        // Fallback to type-based color
        return task.isTender ? AppColors.lightRed : AppColors.lightTeal;
    }
  }

  String _formatDeadline(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    return '${diff.inHours}h left';
  }
}
