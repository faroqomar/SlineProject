import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/core/widgets/signed_image.dart';
import 'package:sline_app/features/profile/view/widgets/profile_preview_modal.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';

class BookingTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final bool isHot;

  const BookingTaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.isHot = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final authorName = task.userName ?? 'Provider';
    final initials = _getInitials(authorName);

    return Semantics(
      button: true,
      label: '${task.title} booking task card',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.p12),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.r24),
          border: Border.all(color: colorScheme.cardBorder, width: 1),
          boxShadow: AppDecorations.elevation(1, isDark: colorScheme.isDark),
        ),
        child: ScaleButton(
          onPressed: () {
            AppLogger.d('BookingTaskCard tapped: ${task.id}', tag: 'Cards');
            onTap();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Section (Reduced to 60px) ---
              SizedBox(
                height: 60,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image or Gradient
                    if (task.imagePaths.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppDimens.r24),
                          topRight: Radius.circular(AppDimens.r24),
                        ),
                        child: SignedImage(
                          storagePathOrUrl: task.imagePaths.first,
                          width: double.infinity,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppDimens.r24),
                            topRight: Radius.circular(AppDimens.r24),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.success.withValues(alpha: 0.9),
                              colorScheme.success.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),

                    // Gradient Overlay
                    if (task.imagePaths.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppDimens.r24),
                            topRight: Radius.circular(AppDimens.r24),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),

                    // Featured Badge (Left)
                    if (isHot)
                      Positioned(
                        top: AppDimens.p12,
                        left: AppDimens.p12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.p8,
                            vertical: AppDimens.p4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppDimens.r8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: colorScheme.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Featured',
                                style: AppTypography.micro.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Bookmark Button (Right)
                    Positioned(
                      top: AppDimens.p8,
                      right: AppDimens.p8,
                      child: Consumer<SavedTasksViewModel>(
                        builder: (context, savedVM, child) {
                          final isSaved = savedVM.isSaved(task.id);
                          return GestureDetector(
                            onTap: () {
                              savedVM.toggle(task.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(AppDimens.p8),
                              decoration: BoxDecoration(
                                color: isSaved
                                    ? colorScheme.danger
                                    : Colors.black.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSaved
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18,
                                color: AppColors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // --- Content Section ---
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.p20,
                  AppDimens.p16,
                  AppDimens.p20,
                  AppDimens.p20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + Name + Rating Row (inline, no Transform.translate)
                    Row(
                      children: [
                        // Avatar Box
                        GestureDetector(
                          onTap: () {
                            showProfilePreview(context, task.userId);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(
                                AppDimens.r12,
                              ),
                              boxShadow: AppDecorations.elevation(
                                1,
                                isDark: colorScheme.isDark,
                              ),
                            ),
                            child:
                                task.userAvatar != null &&
                                    task.userAvatar!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.r12,
                                    ),
                                    child: SignedAvatar(
                                      storagePathOrUrl: task.userAvatar,
                                      size: 44,
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.r12,
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      initials,
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.almostBlack,
                                      ),
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(width: AppDimens.p12),

                        // Name + Rating
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorName,
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppDimens.p2),
                              // Rating Pill
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 12,
                                    color: colorScheme.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.9',
                                    style: AppTypography.captionBold.copyWith(
                                      color: colorScheme.text,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimens.p12),

                    // Title
                    Text(
                      task.title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: colorScheme.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppDimens.p12),

                    // Tags
                    Wrap(
                      spacing: AppDimens.p8,
                      runSpacing: AppDimens.p4,
                      children: task.skills
                          .take(3)
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.p8,
                                vertical: AppDimens.p4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.tagBackground,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.r8,
                                ),
                                border: Border.all(
                                  color: colorScheme.tagBorder,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: AppTypography.micro.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: AppDimens.p16),

                    // Footer
                    Container(
                      padding: const EdgeInsets.only(top: AppDimens.p12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: colorScheme.divider),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FROM',
                                style: AppTypography.micro.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.textSecondary.withValues(
                                    alpha: 0.6,
                                  ),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                PriceFormatter.formatPrice(task.budget),
                                style: AppTypography.h5.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.success,
                                ),
                              ),
                            ],
                          ),

                          // Action Button (Book Now or Completed)
                          if (task.status == TaskStatus.completed ||
                              task.status == TaskStatus.closed)
                            Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.p12,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.background,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.r18,
                                ),
                                border: Border.all(color: colorScheme.divider),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Completed',
                                    style: AppTypography.captionBold.copyWith(
                                      color: colorScheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.p16,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.success,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.r18,
                                ),
                                boxShadow: AppDecorations.elevation(
                                  1,
                                  isDark: colorScheme.isDark,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Book Now',
                                    style: AppTypography.captionBold.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(width: AppDimens.p8),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 14,
                                    color: AppColors.white,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
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

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
