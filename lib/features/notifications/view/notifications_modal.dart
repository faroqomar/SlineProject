import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';
import 'package:sline_app/features/notifications/view/widgets/notification_tile.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';

/// Stable keys for tests (see .TODO/TEST_notifications_2026-03-01.md).
class NotificationsModalKeys {
  NotificationsModalKeys._();
  static const Key modal = ValueKey<String>('notifications_modal');
  static const Key loading = ValueKey<String>('notifications_loading');
  static const Key list = ValueKey<String>('notifications_list');
  static const Key empty = ValueKey<String>('notifications_empty');
  static const Key error = ValueKey<String>('notifications_error');

  /// Stable row key so tests can target one notification without text coupling.
  static Key row(String id) => ValueKey<String>('notification_row_$id');
}

/// Notifications modal with skeleton loading, stagger entrance animation,
/// adaptation-only Amber Dusk sheet styling, and full Semantics coverage.
///
/// Phase 5 redesign: replaced CircularProgressIndicator with SkeletonLoader
/// list, added stagger entrance for tiles, enhanced empty/error states with
/// icon + descriptive text, added haptic and AppLogger tracking.
/// Phase 10 keeps this view-layer only and does not change notification
/// creation, realtime sync, mark-as-read authority, or deep-link routing.
class NotificationsModal extends StatefulWidget {
  const NotificationsModal({super.key});

  /// Shows the modal and returns the selected [NotificationItem] when user
  /// taps a row, or null if dismissed.
  static Future<NotificationItem?> show(BuildContext context) {
    return showModalBottomSheet<NotificationItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: context.amberColors.scrim,
      backgroundColor: AmberDuskColors.transparent,
      builder: (_) => const NotificationsModal(),
    );
  }

  @override
  State<NotificationsModal> createState() => _NotificationsModalState();
}

class _NotificationsModalState extends State<NotificationsModal>
    with SingleTickerProviderStateMixin {
  // ── Stagger entrance animation ─────────────────────────────
  late final AnimationController _staggerController;

  /// Guard prevents stagger replay on subsequent rebuilds.
  bool _hasAnimatedEntrance = false;

  /// Prevents rapid taps from dispatching duplicate mark-all-read requests.
  bool _isMarkingAllRead = false;

  /// Max tiles to animate in stagger — cap to avoid long delays.
  static const int _maxStaggerCount = 8;

  /// Cache for slide animations keyed by tile index — avoids recreating
  /// CurvedAnimation objects on every build pass.
  final Map<int, Animation<Offset>> _slideCache = {};

  /// Cache for fade animations keyed by tile index — avoids recreating
  /// CurvedAnimation objects on every build pass.
  final Map<int, Animation<double>> _fadeCache = {};

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: AppMotion.emphasis,
      vsync: this,
    );
    AppLogger.d('NotificationsModal: opened', tag: 'Notifications');
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  /// Trigger stagger entrance once when data first arrives.
  void _triggerStaggerIfNeeded(int itemCount) {
    if (_hasAnimatedEntrance || itemCount == 0) return;
    _hasAnimatedEntrance = true;
    AppLogger.d(
      'NotificationsModal: stagger entrance triggered ($itemCount items)',
      tag: 'Notifications',
    );
    unawaited(_staggerController.forward());
  }

  /// Build slide animation for tile at [index], caching the result so
  /// it is created once rather than on every build pass.
  Animation<Offset> _buildSlide(int index, double begin, double end) {
    return _slideCache.putIfAbsent(
      index,
      () =>
          Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _staggerController,
              curve: Interval(begin, end, curve: AppMotion.curveDecel),
            ),
          ),
    );
  }

  /// Build fade animation for tile at [index], caching the result so
  /// it is created once rather than on every build pass.
  Animation<double> _buildFade(int index, double begin, double end) {
    return _fadeCache.putIfAbsent(
      index,
      () => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(begin, end, curve: AppMotion.curveDecel),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      key: NotificationsModalKeys.modal,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        final amberColors = context.amberColors;
        final colorScheme = context.colorScheme;
        final sheetRecipe = AmberDuskTokens.surfaces.sheet;

        return Semantics(
          label: 'Notifications panel',
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: sheetRecipe.fill,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(sheetRecipe.radius),
              ),
              boxShadow: AppDecorations.elevation(
                sheetRecipe.elevationLevel,
                isDark: colorScheme.isDark,
              ),
            ),
            child: Column(
              children: [
                _buildSheetHandle(amberColors),
                _buildHeader(context),
                Expanded(
                  child: Consumer<NotificationViewModel>(
                    builder: (context, vm, child) {
                      // Error state — icon + message + retry
                      if (vm.error != null && vm.notifications.isEmpty) {
                        return _buildErrorState(context, vm);
                      }

                      // Loading state — skeleton list
                      if (vm.isLoading && vm.notifications.isEmpty) {
                        return _buildSkeletonList();
                      }

                      // Empty state — rich with icon and text
                      if (vm.notifications.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      // Trigger stagger on first content arrival — deferred to
                      // post-frame to avoid mutating controller state during build.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _triggerStaggerIfNeeded(vm.notifications.length);
                      });

                      // Content — notification list with stagger
                      return Semantics(
                        label: 'Notifications list',
                        child: ListView.separated(
                          key: NotificationsModalKeys.list,
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(
                            AppDimens.p16,
                            AppDimens.p4,
                            AppDimens.p16,
                            _bottomListPadding(context),
                          ),
                          itemCount: vm.notifications.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppDimens.p10),
                          itemBuilder: (context, index) {
                            final notification = vm.notifications[index];
                            final tile = NotificationTile(
                              key: NotificationsModalKeys.row(notification.id),
                              notification: notification,
                              onTap: () {
                                unawaited(
                                  vm.markAsRead(notification.id).then((_) {
                                    if (context.mounted) {
                                      Navigator.pop(context, notification);
                                    }
                                  }),
                                );
                              },
                            );

                            // Stagger entrance for first N tiles
                            if (_hasAnimatedEntrance &&
                                index < _maxStaggerCount) {
                              final staggerFraction =
                                  index / (_maxStaggerCount + 2);
                              final begin = staggerFraction;
                              final end = (staggerFraction + 0.3).clamp(
                                0.0,
                                1.0,
                              );

                              return SlideTransition(
                                position: _buildSlide(index, begin, end),
                                child: FadeTransition(
                                  opacity: _buildFade(index, begin, end),
                                  child: tile,
                                ),
                              );
                            }

                            return tile;
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Small solid handle matching the Amber Dusk bottom-sheet affordance.
  Widget _buildSheetHandle(AmberDuskColorScheme amberColors) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.p8, bottom: AppDimens.p4),
      child: Container(
        width: AppDimens.p40,
        height: AppDimens.p4,
        decoration: BoxDecoration(
          color: amberColors.surfaceHighest,
          borderRadius: BorderRadius.circular(AppDimens.r50),
        ),
      ),
    );
  }

  /// Header with title, mark-all-read action, and close button.
  Widget _buildHeader(BuildContext context) {
    final amberColors = context.amberColors;

    return Consumer<NotificationViewModel>(
      builder: (context, vm, child) {
        final notificationCount = vm.notifications.length;
        final unreadCount = vm.unreadCount;
        final summary = notificationCount == 0
            ? 'No updates waiting'
            : unreadCount == 0
            ? '$notificationCount read updates'
            : '$unreadCount unread of $notificationCount updates';

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.p20,
            AppDimens.p8,
            AppDimens.p16,
            AppDimens.p14,
          ),
          child: Row(
            children: [
              _HeaderIconBadge(unreadCount: unreadCount),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: AmberDuskTokens.typography.sectionTitle.copyWith(
                        color: amberColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimens.p2),
                    Text(
                      summary,
                      style: AmberDuskTokens.typography.bodySmall.copyWith(
                        color: unreadCount == 0
                            ? amberColors.muted
                            : amberColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.p8),
              Semantics(
                button: true,
                label: 'Mark all notifications as read',
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      AppDimens.touchTarget,
                      AppDimens.touchTarget,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p12,
                    ),
                    foregroundColor: amberColors.primary,
                    backgroundColor: amberColors.infoMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AmberDuskTokens.radius.pill,
                      ),
                    ),
                  ),
                  onPressed: _isMarkingAllRead
                      ? null
                      : () async {
                          setState(() => _isMarkingAllRead = true);
                          AppInteractionStates.hapticTap();
                          AppLogger.d(
                            'NotificationsModal: mark all as read tapped',
                            tag: 'Notifications',
                          );
                          try {
                            final didMarkAllRead = await context
                                .read<NotificationViewModel>()
                                .markAllAsRead();
                            if (!didMarkAllRead) {
                              throw StateError('markAllAsRead returned false');
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All marked as read'),
                                ),
                              );
                            }
                          } on Object catch (e, st) {
                            AppLogger.w(
                              'NotificationsModal: markAllAsRead failed',
                              tag: 'Notifications',
                              error: e,
                              json: <String, dynamic>{
                                'stack_trace': st.toString(),
                              },
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not mark notifications as read. Please try again.',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isMarkingAllRead = false);
                            }
                          }
                        },
                  child: Text(
                    'Mark all as read',
                    style: AppTypography.caption.copyWith(
                      color: amberColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.p8),
              Semantics(
                button: true,
                label: 'Close notifications',
                child: IconButton(
                  tooltip: 'Close notifications',
                  style: IconButton.styleFrom(
                    backgroundColor: amberColors.surfaceRaised,
                    foregroundColor: amberColors.text,
                    minimumSize: const Size(
                      AppDimens.touchTarget,
                      AppDimens.touchTarget,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.r16),
                    ),
                  ),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Skeleton loading state — 5 placeholder tiles.
  Widget _buildSkeletonList() {
    return ListView.separated(
      key: NotificationsModalKeys.loading,
      padding: EdgeInsets.fromLTRB(
        AppDimens.p16,
        AppDimens.p4,
        AppDimens.p16,
        _bottomListPadding(context),
      ),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimens.p12),
      itemBuilder: (_, _) => const _SkeletonNotificationTile(),
    );
  }

  /// Rich empty state with icon and descriptive text.
  Widget _buildEmptyState(BuildContext context) {
    final amberColors = context.amberColors;

    return Center(
      key: NotificationsModalKeys.empty,
      child: Semantics(
        label: 'No notifications. You are all caught up.',
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimens.p24,
            AppDimens.p24,
            AppDimens.p24,
            _bottomListPadding(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StateIcon(
                icon: Icons.notifications_off_outlined,
                foreground: amberColors.muted,
                background: amberColors.surfaceRaised,
              ),
              const SizedBox(height: AppLayout.spacingSection),
              Text(
                "You're all caught up!",
                textAlign: TextAlign.center,
                style: AppTypography.h5.copyWith(color: amberColors.text),
              ),
              const SizedBox(height: AppLayout.spacingStandard),
              Text(
                'No new notifications',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: amberColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Error state with icon, message, and styled retry button.
  Widget _buildErrorState(BuildContext context, NotificationViewModel vm) {
    final amberColors = context.amberColors;

    return Center(
      key: NotificationsModalKeys.error,
      child: Semantics(
        label: 'Error loading notifications. Tap retry.',
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimens.p24,
            AppDimens.p24,
            AppDimens.p24,
            _bottomListPadding(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StateIcon(
                icon: Icons.error_outline,
                foreground: amberColors.danger,
                background: amberColors.dangerMuted,
              ),
              const SizedBox(height: AppLayout.spacingSection),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.spacingLarge,
                ),
                child: Text(
                  vm.error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: amberColors.textSubtle,
                  ),
                ),
              ),
              const SizedBox(height: AppLayout.spacingStandard),
              TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    AppDimens.touchTarget,
                    AppDimens.touchTarget,
                  ),
                  foregroundColor: amberColors.primary,
                ),
                onPressed: () {
                  AppInteractionStates.hapticTap();
                  vm.retry();
                },
                icon: Icon(Icons.refresh, color: amberColors.primary),
                label: Text(
                  'Retry',
                  style: AppTypography.bodySmall.copyWith(
                    color: amberColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom inset for scrollable notification states.
  ///
  /// The modal is draggable and can sit above the home indicator, so rows need
  /// explicit safe-area clearance inside the scroll view rather than relying on
  /// the route to pad only the sheet shell.
  double _bottomListPadding(BuildContext context) {
    return AppDimens.p24 + MediaQuery.viewPaddingOf(context).bottom;
  }
}

/// Decorative icon well for notification empty and error states.
///
/// The fill colors come from Amber Dusk semantic muted/danger surfaces so the
/// states read as solid material instead of old transparent/glass treatments.
class _StateIcon extends StatelessWidget {
  const _StateIcon({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimens.emptyStateIconContainer,
      height: AppDimens.emptyStateIconContainer,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: AppDimens.emptyStateIconSize, color: foreground),
    );
  }
}

/// Header icon well with an unread count badge.
///
/// The badge makes the notification center recognizable before users scan the
/// list, while all count authority remains in [NotificationViewModel].
class _HeaderIconBadge extends StatelessWidget {
  const _HeaderIconBadge({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;

    return SizedBox(
      width: AppDimens.p48,
      height: AppDimens.p48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: AppDimens.p48,
            height: AppDimens.p48,
            decoration: BoxDecoration(
              color: amberColors.infoMuted,
              borderRadius: BorderRadius.circular(AppDimens.r16),
            ),
            child: Icon(
              Icons.notifications_none,
              color: amberColors.primary,
              size: AppDimens.iconSizeMedium,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -AppDimens.p2,
              right: -AppDimens.p2,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: AppDimens.iconSizeMedium,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.p6,
                  vertical: AppDimens.p2,
                ),
                decoration: BoxDecoration(
                  color: amberColors.rust,
                  borderRadius: BorderRadius.circular(AppDimens.r50),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  textAlign: TextAlign.center,
                  style: AmberDuskTokens.typography.chip.copyWith(
                    color: amberColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder tile for notification loading state.
/// Mimics the layout of NotificationTile: circle icon + two text lines.
class _SkeletonNotificationTile extends StatelessWidget {
  const _SkeletonNotificationTile();

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;
    final skeletonTheme = AmberDuskTokens.widgetTheme.skeleton;

    return Container(
      padding: const EdgeInsets.all(AppDimens.p14),
      decoration: BoxDecoration(
        color: amberColors.surface,
        borderRadius: BorderRadius.circular(AmberDuskTokens.radius.taskCard),
      ),
      child: Row(
        children: [
          SkeletonLoader(
            width: AppDimens.p40,
            height: AppDimens.p40,
            isCircle: true,
            baseColor: skeletonTheme.base,
            highlightColor: skeletonTheme.highlight,
          ),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: AppDimens.p100 + AppDimens.p80,
                  height: AppDimens.p14,
                  borderRadius: AppDimens.r4,
                  baseColor: skeletonTheme.base,
                  highlightColor: skeletonTheme.highlight,
                ),
                const SizedBox(height: AppDimens.p8),
                SkeletonLoader(
                  height: AppDimens.p12,
                  borderRadius: AppDimens.r4,
                  baseColor: skeletonTheme.base,
                  highlightColor: skeletonTheme.highlight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
