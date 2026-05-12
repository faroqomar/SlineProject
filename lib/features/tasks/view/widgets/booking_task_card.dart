import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/profile/view/widgets/profile_preview_modal.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';

/// Hero Amber Dusk card for booking-style discovery tasks.
///
/// The widget preserves the existing tap, profile preview, and saved callbacks
/// while giving bookings the stronger rust hero treatment from Phase 3.
class BookingTaskCard extends StatelessWidget {
  /// Creates a booking card for the discovery feed.
  const BookingTaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.isHot = false,
  });

  /// Booking task supplied by the existing discovery feed contract.
  final Task task;

  /// Opens the existing task details route.
  final VoidCallback onTap;

  /// Marks promoted booking cards with the featured badge.
  final bool isHot;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    const amberColors = AmberDuskTokens.colors;
    final heroSurface = AmberDuskTokens.surfaces.hero;
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    final authorName = task.userName ?? 'Provider';
    final initials = _getInitials(authorName);
    final details = _bookingDetails;
    final providerRole = _firstNonEmpty([
      details['role'],
      task.categoryName,
      task.category,
      if (task.skills.isNotEmpty) task.skills.first,
      task.title,
    ]);
    final providerLevel = _firstNonEmpty([
      task.authorSellerLevel,
      details['seniority'],
      'Available',
    ])!;
    final locationLabel = _firstNonEmpty([
      details['location'],
      task.categoryName,
      task.category,
      if (task.skills.isNotEmpty) task.skills.first,
    ]);
    final experienceLabel = _firstNonEmpty([
      details['experience'],
      if (task.skills.isNotEmpty) task.skills.first,
      'Available',
    ]);
    final ratingLabel =
        _formatRatingLabel(details['rating']) ??
        _formatRatingLabel(details['average_rating']) ??
        _formatRatingLabel(details['averageRating']);
    final providerIsOnline = _isTruthyDetail([
      details['isOnline'],
      details['is_online'],
      details['providerOnline'],
      details['provider_online'],
    ]);
    final periodLabel = _firstNonEmpty([details['period'], 'month'])!;
    final price = _splitFormattedPrice(_formatCardPrice(task.budget));

    return Semantics(
      button: true,
      label: '${task.title} booking task card',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.p12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: heroSurface.gradientStops,
            stops: const [0, 0.56, 1],
            begin: const Alignment(0.14, -1),
            end: const Alignment(-0.14, 1),
          ),
          borderRadius: BorderRadius.circular(heroSurface.radius),
          border: Border.all(
            color: heroSurface.border,
            width: AmberDuskTokens.spacing.borderWidth,
          ),
          boxShadow: AppDecorations.elevation(
            heroSurface.elevationLevel,
            isDark: colorScheme.isDark,
          ),
        ),
        child: ScaleButton(
          onPressed: () {
            AppLogger.d('BookingTaskCard tapped', tag: 'Cards');
            onTap();
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(heroSurface.radius),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.64, -1),
                        radius: 0.78,
                        colors: [
                          amberColors.heroText.withValues(alpha: 0.08),
                          amberColors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          amberColors.heroHighlight,
                          amberColors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          amberColors.scrim.withValues(alpha: 0.18),
                          amberColors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: cardTheme.bookingPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                showProfilePreview(context, task.userId),
                            child: _ProviderAvatar(
                              initials: initials,
                              avatarPath: task.userAvatar,
                              isOnline: providerIsOnline,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _BookingSaveButton(taskId: task.id),
                              SizedBox(width: cardTheme.bookingActionGap),
                              _BookingMessageButton(
                                taskId: task.id,
                                onTap: onTap,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: cardTheme.bookingTopSpacing),
                      Text(
                        authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: cardTheme.bookingNameStyle.copyWith(
                          color: amberColors.heroText,
                        ),
                      ),
                      SizedBox(height: cardTheme.bookingNameGap),
                      Text(
                        _roleLine(providerLevel, providerRole).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: cardTheme.bookingRoleStyle.copyWith(
                          color: amberColors.heroMuted,
                        ),
                      ),
                      const SizedBox(height: AppDimens.p14),
                      Wrap(
                        spacing: AppDimens.p6,
                        runSpacing: AppDimens.p6,
                        children: [
                          if (ratingLabel != null)
                            _HeroChip(icon: Icons.star, label: ratingLabel),
                          if (locationLabel != null)
                            _HeroChip(
                              icon: Icons.location_on_outlined,
                              label: locationLabel,
                            ),
                          if (experienceLabel != null)
                            _HeroChip(
                              icon: Icons.workspace_premium_outlined,
                              label: experienceLabel,
                            ),
                          if (isHot) const _FeaturedPill(),
                        ],
                      ),
                      const SizedBox(height: AppDimens.p14),
                      Container(height: 1, color: amberColors.heroDivider),
                      SizedBox(height: cardTheme.bookingDividerBottomSpacing),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        price.amount,
                                        style: cardTheme.bookingPriceStyle
                                            .copyWith(
                                              color: amberColors.heroText,
                                            ),
                                      ),
                                      if (price.suffix != null) ...[
                                        const SizedBox(width: AppDimens.p4),
                                        Text(
                                          price.suffix!,
                                          style: AmberDuskTokens.typography.chip
                                              .copyWith(
                                                color: amberColors.heroMuted,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppDimens.p4),
                                Text(
                                  'PER ${periodLabel.toUpperCase()}',
                                  style: cardTheme.bookingPeriodStyle.copyWith(
                                    color: amberColors.heroMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _BookingActionPill(isClosed: _isClosed),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _isClosed =>
      task.status == TaskStatus.completed || task.status == TaskStatus.closed;

  Map<String, dynamic> get _bookingDetails {
    return Task.packageDetailsFrom(task.packages) ?? const <String, dynamic>{};
  }

  String _roleLine(String level, String? role) {
    final trimmedRole = role?.trim();
    if (trimmedRole == null || trimmedRole.isEmpty) return level;
    return '$level · $trimmedRole';
  }

  String? _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  String? _formatRatingLabel(Object? value) {
    final rating = switch (value) {
      final num number => number.toDouble(),
      final String text => double.tryParse(text.trim()),
      _ => null,
    };
    if (rating == null || rating <= 0) return null;
    return rating.toStringAsFixed(1);
  }

  bool _isTruthyDetail(List<Object?> values) {
    for (final value in values) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == 'online') return true;
        if (normalized == 'false' || normalized == 'offline') return false;
      }
    }
    return false;
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

class _BookingSaveButton extends StatelessWidget {
  const _BookingSaveButton({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    const amberColors = AmberDuskTokens.colors;
    final cardTheme = AmberDuskTokens.widgetTheme.cards;

    return Consumer<SavedTasksViewModel>(
      builder: (context, savedVM, child) {
        final isSaved = savedVM.isSaved(taskId);
        return Semantics(
          button: true,
          label: isSaved ? 'Unsave booking' : 'Save booking',
          child: GestureDetector(
            onTap: () => unawaited(savedVM.toggle(taskId)),
            child: Container(
              width: cardTheme.bookingRoundActionSize,
              height: cardTheme.bookingRoundActionSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSaved
                    ? amberColors.rust.withValues(alpha: 0.18)
                    : cardTheme.bookingRoundActionFill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                size: cardTheme.bookingRoundActionIconSize,
                color: isSaved ? amberColors.rust : amberColors.heroMuted,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BookingMessageButton extends StatelessWidget {
  const _BookingMessageButton({required this.taskId, required this.onTap});

  final String taskId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const amberColors = AmberDuskTokens.colors;
    final cardTheme = AmberDuskTokens.widgetTheme.cards;

    return Semantics(
      button: true,
      label: 'View booking details',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppLogger.d('BookingTaskCard details action tapped', tag: 'Cards');
          onTap();
        },
        child: Container(
          width: cardTheme.bookingRoundActionSize,
          height: cardTheme.bookingRoundActionSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cardTheme.bookingRoundActionFill,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            size: cardTheme.bookingRoundActionIconSize,
            color: amberColors.heroMuted,
          ),
        ),
      ),
    );
  }
}

class _FeaturedPill extends StatelessWidget {
  const _FeaturedPill();

  @override
  Widget build(BuildContext context) {
    const amberColors = AmberDuskTokens.colors;
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    return Container(
      padding: cardTheme.bookingChipPadding,
      decoration: BoxDecoration(
        color: amberColors.heroChip,
        borderRadius: BorderRadius.circular(AmberDuskTokens.spacing.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: cardTheme.bookingChipIconSize,
            color: amberColors.star,
          ),
          SizedBox(width: cardTheme.bookingChipGap),
          Text(
            'Featured',
            style: cardTheme.bookingChipStyle.copyWith(
              color: amberColors.heroText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderAvatar extends StatelessWidget {
  const _ProviderAvatar({
    required this.initials,
    required this.avatarPath,
    required this.isOnline,
  });

  final String initials;
  final String? avatarPath;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    final media = AmberDuskTokens.widgetTheme.media;
    final colorScheme = context.colorScheme;
    const amberColors = AmberDuskTokens.colors;
    final photoSize = cardTheme.bookingPhotoSize;
    final path = avatarPath;

    if (path != null && path.isNotEmpty) {
      return SignedAvatar(
        storagePathOrUrl: path,
        radius: photoSize / 2,
        borderColor: amberColors.heroRim,
        borderWidth: 2,
        initials: initials,
        showOnlineIndicator: isOnline,
      );
    }

    return SizedBox(
      width: photoSize,
      height: photoSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: photoSize,
            height: photoSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: media.avatarFallback,
              shape: BoxShape.circle,
              boxShadow: AppDecorations.elevation(
                1,
                isDark: colorScheme.isDark,
              ),
            ),
            child: Text(initials, style: media.initialsTextStyle(photoSize)),
          ),
          if (isOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: AppDimens.p14,
                height: AppDimens.p14,
                decoration: BoxDecoration(
                  color: media.onlineDot,
                  shape: BoxShape.circle,
                  border: Border.all(color: amberColors.hero, width: 2.5),
                  boxShadow: AppDecorations.elevation(
                    1,
                    isDark: colorScheme.isDark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    const amberColors = AmberDuskTokens.colors;
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    return Container(
      padding: cardTheme.bookingChipPadding,
      decoration: BoxDecoration(
        color: amberColors.heroChip,
        borderRadius: BorderRadius.circular(AmberDuskTokens.spacing.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: cardTheme.bookingChipIconSize,
            color: amberColors.star,
          ),
          SizedBox(width: cardTheme.bookingChipGap),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 112),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cardTheme.bookingChipStyle.copyWith(
                color: amberColors.heroText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingActionPill extends StatelessWidget {
  const _BookingActionPill({required this.isClosed});

  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    const amberColors = AmberDuskTokens.colors;
    final cardTheme = AmberDuskTokens.widgetTheme.cards;

    if (isClosed) {
      return Container(
        height: cardTheme.cardActionHeight,
        padding: cardTheme.bookingActionPadding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: amberColors.heroChip,
          borderRadius: BorderRadius.circular(
            AmberDuskTokens.spacing.pillRadius,
          ),
          border: Border.all(color: amberColors.heroDivider),
        ),
        child: Text(
          'Completed',
          style: cardTheme.cardActionStyle.copyWith(
            color: amberColors.heroMuted,
          ),
        ),
      );
    }

    return Container(
      height: cardTheme.cardActionHeight,
      padding: cardTheme.bookingActionPadding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: amberColors.text,
        borderRadius: BorderRadius.circular(AmberDuskTokens.spacing.pillRadius),
        boxShadow: AppDecorations.elevation(2, isDark: colorScheme.isDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'See details',
            style: cardTheme.cardActionStyle.copyWith(
              color: amberColors.textInverse,
            ),
          ),
          const SizedBox(width: AppDimens.p8),
          Icon(
            Icons.arrow_forward,
            size: cardTheme.bookingCtaIconSize,
            color: amberColors.textInverse,
          ),
        ],
      ),
    );
  }
}

({String amount, String? suffix}) _splitFormattedPrice(String value) {
  final trimmed = value.trim();
  final suffixMatch = RegExp(r'\s+([A-Z]{2,5})$').firstMatch(trimmed);
  if (suffixMatch == null) return (amount: trimmed, suffix: null);
  return (
    amount: trimmed.substring(0, suffixMatch.start).trim(),
    suffix: suffixMatch.group(1),
  );
}

String _formatCardPrice(
  double amount, {
  String suffix = PriceFormatter.defaultCurrency,
  String? locale,
}) {
  final rounded = amount.round();
  final prefix = rounded < 0 ? '-' : '';
  final formatter = NumberFormat.decimalPattern(
    locale ?? Intl.getCurrentLocale(),
  );
  return '$prefix${formatter.format(rounded.abs())} $suffix';
}
