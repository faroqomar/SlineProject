import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';

/// Extended skeleton card variants for loading states across the app.
///
/// These complement the original 6 skeletons in `skeleton_card.dart`:
/// SkeletonTaskCard, SkeletonBookingCard, SkeletonOfferCard,
/// SkeletonMessageBubble, SkeletonConversationTile, SkeletonDetailsScreen.
///
/// Each skeleton matches the real widget's layout (dimensions, spacing, shapes)
/// for a seamless loading-to-content transition.

/// Skeleton for WalletHeroCard — gradient placeholder with balance shimmer.
class SkeletonWalletHeroCard extends StatelessWidget {
  const SkeletonWalletHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final panelCard = AmberDuskTokens.widgetTheme.cards.panel;
    return Container(
      padding: const EdgeInsets.all(AppDimens.p24),
      decoration: BoxDecoration(
        color: panelCard.background,
        borderRadius: BorderRadius.circular(AppDimens.r24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(width: 60, height: 12),
          SizedBox(height: AppDimens.p8),
          SkeletonLoader(width: 80, height: 10),
          SizedBox(height: AppDimens.p16),
          SkeletonLoader(width: 160, height: 34),
          SizedBox(height: AppDimens.p16),
          SkeletonLoader(height: AppDimens.p12, borderRadius: 6),
          SizedBox(height: AppDimens.p12),
          Row(
            children: [
              SkeletonLoader(width: 70, height: 32, borderRadius: 16),
              SizedBox(width: AppDimens.p8),
              SkeletonLoader(width: 70, height: 32, borderRadius: 16),
              SizedBox(width: AppDimens.p8),
              SkeletonLoader(width: 70, height: 32, borderRadius: 16),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for ProposalTile — avatar + text lines + price.
class SkeletonProposalTile extends StatelessWidget {
  const SkeletonProposalTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.p16,
        vertical: AppDimens.p12,
      ),
      child: Row(
        children: [
          SkeletonAvatar(size: 44),
          SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 120, height: 14),
                SizedBox(height: AppDimens.p6),
                SkeletonLoader(width: 180, height: 12),
                SizedBox(height: AppDimens.p6),
                SkeletonLoader(width: 80, height: 12),
              ],
            ),
          ),
          SizedBox(width: AppDimens.p8),
          SkeletonLoader(width: 60, height: 16),
        ],
      ),
    );
  }
}

/// Skeleton for WorkItemCard — colored header + body lines + button.
class SkeletonWorkItemCard extends StatelessWidget {
  const SkeletonWorkItemCard({super.key});

  static const Key rootKey = ValueKey<String>('skeleton_work_item_card_root');

  @override
  Widget build(BuildContext context) {
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    final panelCard = cardTheme.panel;
    return Container(
      key: rootKey,
      margin: const EdgeInsets.only(bottom: AppDimens.p16),
      decoration: BoxDecoration(
        color: panelCard.background,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(
          color: cardTheme.border,
          width: cardTheme.borderWidth,
        ),
      ),
      child: Column(
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p16,
              vertical: AppDimens.p12,
            ),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimens.r16),
              ),
            ),
            child: const Row(
              children: [
                SkeletonLoader(width: 16, height: 16, isCircle: true),
                SizedBox(width: AppDimens.p8),
                SkeletonLoader(width: 80, height: 12),
                Spacer(),
                SkeletonLoader(width: 60, height: 12),
              ],
            ),
          ),
          // Body
          const Padding(
            padding: EdgeInsets.all(AppDimens.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(height: 16),
                SizedBox(height: AppDimens.p12),
                Row(
                  children: [
                    SkeletonAvatar(size: 24),
                    SizedBox(width: AppDimens.p8),
                    SkeletonLoader(width: 100, height: 12),
                  ],
                ),
                SizedBox(height: AppDimens.p16),
                SkeletonLoader(height: 40, borderRadius: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for NotificationTile — icon circle + text lines + time.
class SkeletonNotificationTile extends StatelessWidget {
  const SkeletonNotificationTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.p16,
        vertical: AppDimens.p12,
      ),
      child: Row(
        children: [
          SkeletonLoader(width: 40, height: 40, isCircle: true),
          SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(height: 14),
                SizedBox(height: AppDimens.p6),
                SkeletonLoader(width: 200, height: 12),
              ],
            ),
          ),
          SizedBox(width: AppDimens.p8),
          SkeletonLoader(width: 40, height: 10),
        ],
      ),
    );
  }
}

/// Skeleton for ServiceCard — image rect + title + price.
class SkeletonServiceCard extends StatelessWidget {
  const SkeletonServiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    final panelCard = cardTheme.panel;
    return Container(
      decoration: BoxDecoration(
        color: panelCard.background,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(
          color: cardTheme.border,
          width: cardTheme.borderWidth,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 120, borderRadius: 0),
          Padding(
            padding: EdgeInsets.all(AppDimens.p12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(height: 16),
                SizedBox(height: AppDimens.p8),
                SkeletonLoader(width: 100, height: 12),
                SizedBox(height: AppDimens.p8),
                SkeletonLoader(width: 60, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for FavoriteCard — avatar + name + stats.
class SkeletonFavoriteCard extends StatelessWidget {
  const SkeletonFavoriteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.p16,
        vertical: AppDimens.p12,
      ),
      child: Row(
        children: [
          SkeletonAvatar(),
          SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 120, height: 16),
                SizedBox(height: AppDimens.p6),
                SkeletonLoader(width: 160, height: 12),
                SizedBox(height: AppDimens.p6),
                Row(
                  children: [
                    SkeletonLoader(width: 40, height: 12),
                    SizedBox(width: AppDimens.p12),
                    SkeletonLoader(width: 40, height: 12),
                    SizedBox(width: AppDimens.p12),
                    SkeletonLoader(width: 40, height: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for SearchResultCard — avatar + text lines + tag row.
class SkeletonSearchResultCard extends StatelessWidget {
  const SkeletonSearchResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.p16,
        vertical: AppDimens.p12,
      ),
      child: Row(
        children: [
          SkeletonAvatar(size: 52),
          SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 140, height: 16),
                SizedBox(height: AppDimens.p6),
                SkeletonLoader(height: 12),
                SizedBox(height: AppDimens.p8),
                Row(
                  children: [
                    SkeletonLoader(width: 50, height: 20, borderRadius: 10),
                    SizedBox(width: AppDimens.p6),
                    SkeletonLoader(width: 50, height: 20, borderRadius: 10),
                    SizedBox(width: AppDimens.p6),
                    SkeletonLoader(width: 50, height: 20, borderRadius: 10),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for ProfileCard — large avatar + text lines + stats row.
class SkeletonProfileCard extends StatelessWidget {
  const SkeletonProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: AppDimens.p24),
        SkeletonAvatar(size: 80),
        SizedBox(height: AppDimens.p16),
        SkeletonLoader(width: 140, height: 20),
        SizedBox(height: AppDimens.p8),
        SkeletonLoader(width: 200, height: 14),
        SizedBox(height: AppDimens.p8),
        SkeletonLoader(width: 100, height: 12),
        SizedBox(height: AppDimens.p24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                SkeletonLoader(width: 40, height: 20),
                SizedBox(height: 4),
                SkeletonLoader(width: 60, height: 12),
              ],
            ),
            Column(
              children: [
                SkeletonLoader(width: 40, height: 20),
                SizedBox(height: 4),
                SkeletonLoader(width: 60, height: 12),
              ],
            ),
            Column(
              children: [
                SkeletonLoader(width: 40, height: 20),
                SizedBox(height: 4),
                SkeletonLoader(width: 60, height: 12),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
