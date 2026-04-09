import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';

/// Pre-built skeleton card that mimics a TenderTaskCard loading state.
///
/// Matches the exact layout of TenderTaskCard for seamless visual consistency.
class SkeletonTaskCard extends StatelessWidget {
  const SkeletonTaskCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
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
      child: IntrinsicHeight(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Accent Bar
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightRed.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),

                // Content Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Date + Heart
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SkeletonLoader(
                              width: 70,
                              height: 12,
                              borderRadius: AppDimens.r4,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Title
                        const SkeletonLoader(
                          width: 180,
                          height: 18,
                          borderRadius: AppDimens.r4,
                        ),

                        const SizedBox(height: 8),

                        // Description lines
                        const SkeletonText(lines: 2),

                        const SizedBox(height: 16),

                        // Footer with divider
                        Container(
                          padding: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: colorScheme.divider),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left: Time + Bids
                              Row(
                                children: [
                                  SkeletonLoader(
                                    width: 50,
                                    height: 12,
                                    borderRadius: AppDimens.r4,
                                  ),
                                  SizedBox(width: 16),
                                  SkeletonLoader(
                                    width: 50,
                                    height: 12,
                                    borderRadius: AppDimens.r4,
                                  ),
                                ],
                              ),
                              // Right: Price
                              SkeletonLoader(
                                width: 70,
                                height: 16,
                                borderRadius: AppDimens.r4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Heart icon placeholder (top right)
            const Positioned(
              top: 8,
              right: 8,
              child: SkeletonLoader(width: 36, height: 36, borderRadius: 18),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pre-built skeleton card that mimics a BookingTaskCard loading state.
///
/// Matches the exact layout of BookingTaskCard for seamless visual consistency.
class SkeletonBookingCard extends StatelessWidget {
  const SkeletonBookingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header Section (Gradient placeholder) ---
          Stack(
            children: [
              // Gradient background placeholder
              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.teal.withValues(alpha: 0.3),
                      AppColors.lightTeal.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              // Bookmark placeholder (top right)
              const Positioned(
                top: 12,
                right: 12,
                child: SkeletonLoader(width: 34, height: 34, borderRadius: 17),
              ),
            ],
          ),

          // --- Content Section ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + Rating Row (Avatar overlaps header)
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Avatar Box placeholder
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.cardBackground,
                            width: 4,
                          ),
                        ),
                        child: const SkeletonLoader(
                          width: 48,
                          height: 48,
                          borderRadius: 12,
                        ),
                      ),
                      // Rating Pill placeholder
                      const SkeletonLoader(
                        width: 50,
                        height: 20,
                        borderRadius: AppDimens.r8,
                      ),
                    ],
                  ),
                ),

                // Title
                const SkeletonLoader(
                  width: 200,
                  height: 18,
                  borderRadius: AppDimens.r4,
                ),

                const SizedBox(height: 8),

                // Author Name
                const SkeletonLoader(
                  width: 100,
                  height: 12,
                  borderRadius: AppDimens.r4,
                ),

                const SizedBox(height: 16),

                // Tags
                const Row(
                  children: [
                    SkeletonLoader(width: 50, height: 22, borderRadius: 6),
                    SizedBox(width: 8),
                    SkeletonLoader(width: 60, height: 22, borderRadius: 6),
                    SizedBox(width: 8),
                    SkeletonLoader(width: 45, height: 22, borderRadius: 6),
                  ],
                ),

                const SizedBox(height: 16),

                // Footer with divider
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colorScheme.divider)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(
                            width: 30,
                            height: 10,
                            borderRadius: AppDimens.r4,
                          ),
                          SizedBox(height: 4),
                          SkeletonLoader(
                            width: 70,
                            height: 20,
                            borderRadius: AppDimens.r4,
                          ),
                        ],
                      ),
                      // Book Now Button placeholder
                      SkeletonLoader(width: 100, height: 36, borderRadius: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonOfferCard extends StatelessWidget {
  const SkeletonOfferCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: const Row(
        children: [
          SkeletonAvatar(size: 48),
          SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 100,
                  height: 14,
                  borderRadius: AppDimens.r4,
                ),
                SizedBox(height: AppDimens.p8),
                SkeletonLoader(
                  width: 150,
                  height: 12,
                  borderRadius: AppDimens.r4,
                ),
              ],
            ),
          ),
          SkeletonLoader(width: 60, height: 28, borderRadius: AppDimens.r8),
        ],
      ),
    );
  }
}

/// Skeleton for chat message bubbles.
class SkeletonMessageBubble extends StatelessWidget {
  const SkeletonMessageBubble({super.key, this.isMe = false});

  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.p12),
        margin: const EdgeInsets.only(bottom: AppDimens.p8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? colorScheme.primary.withValues(alpha: 0.2)
              : colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.r16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLoader(
              width: isMe ? 120 : 180,
              height: 14,
              borderRadius: AppDimens.r4,
            ),
            const SizedBox(height: AppDimens.p4),
            SkeletonLoader(
              width: isMe ? 80 : 140,
              height: 14,
              borderRadius: AppDimens.r4,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for conversation list tile.
class SkeletonConversationTile extends StatelessWidget {
  const SkeletonConversationTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.divider)),
      ),
      child: const Row(
        children: [
          SkeletonAvatar(size: 52),
          SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 120,
                  height: 16,
                  borderRadius: AppDimens.r4,
                ),
                SizedBox(height: AppDimens.p8),
                SkeletonLoader(height: 12, borderRadius: AppDimens.r4),
              ],
            ),
          ),
          SizedBox(width: AppDimens.p12),
          SkeletonLoader(width: 40, height: 12, borderRadius: AppDimens.r4),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for search result cards.
///
/// Matches the layout of search result profile/task cards: avatar + two text
/// lines + trailing tag pill. Used in SearchScreen loading state.
class SkeletonSearchResultCard extends StatelessWidget {
  const SkeletonSearchResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: const Row(
        children: [
          // Avatar circle
          SkeletonAvatar(size: 36),
          SizedBox(width: AppDimens.p12),
          // Name + subtitle lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 120,
                  height: 14,
                  borderRadius: AppDimens.r4,
                ),
                SizedBox(height: AppDimens.p8),
                SkeletonLoader(
                  width: 180,
                  height: 12,
                  borderRadius: AppDimens.r4,
                ),
              ],
            ),
          ),
          SizedBox(width: AppDimens.p12),
          // Trailing tag pill
          SkeletonLoader(width: 50, height: 22, borderRadius: AppDimens.r8),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for category grid tiles.
///
/// Matches the redesigned category card layout: icon circle + title + subtitle.
/// Designed for 2-column grid usage in CategoriesScreen.
class SkeletonCategoryTile extends StatelessWidget {
  const SkeletonCategoryTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimens.p12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle placeholder
          SkeletonAvatar(size: 40),
          SizedBox(height: AppDimens.p8),
          // Category name
          SkeletonLoader(width: 80, height: 14, borderRadius: AppDimens.r4),
          SizedBox(height: AppDimens.p4),
          // Item count
          SkeletonLoader(width: 40, height: 10, borderRadius: AppDimens.r4),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for favorite cards.
///
/// Matches the redesigned FavoriteCard layout: avatar + name/date lines +
/// action button placeholder. Used in FavoritesScreen loading state.
class SkeletonFavoriteCard extends StatelessWidget {
  const SkeletonFavoriteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: const Row(
        children: [
          // Avatar
          SkeletonAvatar(size: 44),
          SizedBox(width: AppDimens.p12),
          // Name + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 130,
                  height: 14,
                  borderRadius: AppDimens.r4,
                ),
                SizedBox(height: AppDimens.p8),
                SkeletonLoader(
                  width: 80,
                  height: 12,
                  borderRadius: AppDimens.r4,
                ),
              ],
            ),
          ),
          SizedBox(width: AppDimens.p8),
          // Action button placeholder
          SkeletonLoader(width: 80, height: 32, borderRadius: AppDimens.r8),
        ],
      ),
    );
  }
}

/// Skeleton for booking/task details screen.
class SkeletonDetailsScreen extends StatelessWidget {
  const SkeletonDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header image placeholder
          const SkeletonLoader(height: 200, borderRadius: AppDimens.r20),
          const SizedBox(height: AppDimens.p20),
          // Title
          const SkeletonLoader(
            width: 250,
            height: 24,
            borderRadius: AppDimens.r8,
          ),
          const SizedBox(height: AppDimens.p12),
          // Subtitle/meta
          const Row(
            children: [
              SkeletonAvatar(size: 32),
              SizedBox(width: AppDimens.p8),
              SkeletonLoader(
                width: 100,
                height: 14,
                borderRadius: AppDimens.r4,
              ),
              Spacer(),
              SkeletonLoader(width: 80, height: 14, borderRadius: AppDimens.r4),
            ],
          ),
          const SizedBox(height: AppDimens.p24),
          // Description section
          const SkeletonLoader(
            width: 100,
            height: 18,
            borderRadius: AppDimens.r4,
          ),
          const SizedBox(height: AppDimens.p12),
          const SkeletonText(lines: 4),
          const SizedBox(height: AppDimens.p24),
          // Price card
          AppCardContainer(
            padding: const EdgeInsets.all(AppDimens.p16),
            borderRadius: BorderRadius.circular(AppDimens.r16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonLoader(
                  width: 80,
                  height: 20,
                  borderRadius: AppDimens.r4,
                ),
                SkeletonLoader(
                  width: 100,
                  height: 32,
                  borderRadius: AppDimens.r8,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.p20),
          // Action button
          const SkeletonLoader(height: 50, borderRadius: AppDimens.r12),
        ],
      ),
    );
  }
}
