import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/favorites/models/favorite_with_profile_model.dart';

/// A card displaying a favorited freelancer with chat and remove actions.
///
/// Uses [ScaleButton] for tactile press feedback and [SignedAvatar] for
/// proper signed-URL avatar rendering. Styled with design system tokens
/// from Layer 1 (theme) and Layer 2 (layout).
class FavoriteCard extends StatelessWidget {
  /// The favorite data including freelancer profile info.
  final FavoriteWithProfile favorite;

  /// Callback fired when the user taps "Start Chat".
  final VoidCallback onStartChat;

  /// Callback fired when the user taps the delete/remove button.
  final VoidCallback onRemove;

  const FavoriteCard({
    super.key,
    required this.favorite,
    required this.onStartChat,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Semantics(
      label: '${favorite.freelancerName ?? 'Freelancer'} favorite card',
      child: ScaleButton(
        onPressed: () {
          // Haptic on card tap — navigates to chat
          AppInteractionStates.hapticTap();
          onStartChat();
        },
        child: Container(
          key: Key('favorite_card_${favorite.freelancerId}'),
          margin: const EdgeInsets.only(bottom: AppDimens.p12),
          padding: const EdgeInsets.all(AppDimens.p16),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(AppDimens.r16),
            border: Border.all(color: colorScheme.cardBorder),
            boxShadow: AppDecorations.elevation(1, isDark: colorScheme.isDark),
          ),
          child: Row(
            children: [
              // Freelancer avatar — uses SignedAvatar for signed URL support
              SignedAvatar(
                storagePathOrUrl: favorite.freelancerAvatar,
                size: AppDimens.avatarMedium,
                radius: AppDimens.avatarRadius,
              ),

              const SizedBox(width: AppDimens.p12),

              // Name and date column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Freelancer name — bold, single line with ellipsis
                    Text(
                      favorite.freelancerName ?? 'Freelancer',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppDimens.p4),

                    // Date added — caption style, secondary color
                    Text(
                      'Added: ${formatUtcToLocal(favorite.createdAt)}',
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDimens.p8),

              // "Start Chat" outlined button — Uses AppDimens.touchTarget to meet minimum touch target
              SizedBox(
                height: AppDimens.touchTarget,
                child: OutlinedButton(
                  key: Key('favorite_card_start_chat_${favorite.freelancerId}'),
                  onPressed: onStartChat,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p12,
                    ),
                    side: BorderSide(color: colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.r8),
                    ),
                  ),
                  child: Text(
                    'Start Chat',
                    style: AppTypography.captionBold.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),

              // Remove/delete button — danger color
              IconButton(
                key: Key('favorite_card_remove_${favorite.freelancerId}'),
                tooltip: 'Remove from favorites',
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.danger,
                  size: AppDimens.iconSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
