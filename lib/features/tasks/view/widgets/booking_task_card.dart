import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/core/widgets/signed_image.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/core/app_enums.dart'; // Added for TaskStatus
import 'package:sline_app/features/profile/view/widgets/profile_preview_modal.dart';

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
    final AppColorScheme colorScheme = context.colorScheme;
    final String authorName = task.userName ?? 'Provider';
    final String initials = _getInitials(authorName);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(24), // Matches rounded-[24px]
        border: Border.all(color: colorScheme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.isDark
                ? AppColors.almostBlack.withValues(alpha: 0.2)
                : AppColors.almostBlack.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Section (Gradient + Featured Badge + Bookmark) ---
              SizedBox(
                height: 90,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image or Gradient
                    if (task.imagePaths.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: SignedImage(
                          storagePathOrUrl: task.imagePaths.first,
                          width: double.infinity,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.teal.withValues(alpha: 0.9),
                              AppColors.lightTeal.withValues(alpha: 0.9),
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
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
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

                    // Featured Badge (Left now)
                    if (isHot)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Featured',
                                style: AppTypography.micro.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Bookmark Button (Right)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Consumer<SavedTasksViewModel>(
                        builder: (context, savedVM, child) {
                          final isSaved = savedVM.isSaved(task.id);
                          return GestureDetector(
                            onTap: () {
                              savedVM.toggle(task.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSaved
                                    ? AppColors.lightRed
                                    : Colors.black.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSaved
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18,
                                color: Colors.white,
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + Rating Row (Avatar overlaps header)
                    Transform.translate(
                      offset: const Offset(
                        0,
                        -24,
                      ), // Negative margin to overlap
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Avatar Box
                          GestureDetector(
                            onTap: () {
                              showProfilePreview(context, task.userId);
                            },
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.cardBackground,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child:
                                  task.userAvatar != null &&
                                      task.userAvatar!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ), // Inner radius
                                      child: SignedAvatar(
                                        storagePathOrUrl: task.userAvatar!,
                                        size: 48, // 56 - border
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        initials,
                                        style: AppTypography.h5.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.almostBlack,
                                        ),
                                      ),
                                    ),
                            ),
                          ),

                          // Rating Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '4.9', // Placeholder rating
                                  style: AppTypography.captionBold.copyWith(
                                    fontSize: 11,
                                    color: colorScheme.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Title
                    Text(
                      task.title,
                      style: AppTypography.h6.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: colorScheme.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Author Name
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: colorScheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          authorName,
                          style: AppTypography.caption.copyWith(
                            fontSize: 12,
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: task.skills
                          .take(3)
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: AppTypography.micro.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 16),

                    // Footer
                    Container(
                      padding: const EdgeInsets.only(top: 12),
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
                                  fontSize: 10,
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.teal,
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
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.background,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: colorScheme.divider),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Completed',
                                    style: AppTypography.captionBold.copyWith(
                                      fontSize: 12,
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
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.teal,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.teal.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Book Now',
                                    style: AppTypography.captionBold.copyWith(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 14,
                                    color: Colors.white,
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
    // Split by spaces and filter out empty strings
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
