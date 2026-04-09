import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';
import 'package:sline_app/features/notifications/view/widgets/notification_tile.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';

/// Stable keys for tests (see .TODO/TEST_notifications_2026-03-01.md).
class NotificationsModalKeys {
  NotificationsModalKeys._();
  static const Key modal = ValueKey<String>('notifications_modal');
  static const Key loading = ValueKey<String>('notifications_loading');
  static const Key empty = ValueKey<String>('notifications_empty');
  static const Key error = ValueKey<String>('notifications_error');
  static Key row(String id) => ValueKey<String>('notification_row_$id');
}

/// Notifications modal with skeleton loading, stagger entrance animation,
/// rich empty/error states, and full Semantics coverage.
///
/// Phase 5 redesign: replaced CircularProgressIndicator with SkeletonLoader
/// list, added stagger entrance for tiles, enhanced empty/error states with
/// icon + descriptive text, added haptic and AppLogger tracking.
/// View-layer only.
class NotificationsModal extends StatefulWidget {
  const NotificationsModal({super.key});

  /// Shows the modal and returns the selected [NotificationItem] when user
  /// taps a row, or null if dismissed.
  static Future<NotificationItem?> show(BuildContext context) {
    return showModalBottomSheet<NotificationItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    _staggerController.forward();
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
        return Semantics(
          label: 'Notifications panel',
          child: AppCardContainer(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimens.r20),
            ),
            child: Column(
              children: [
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
                          controller: scrollController,
                          itemCount: vm.notifications.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final notification = vm.notifications[index];
                            final tile = NotificationTile(
                              key: NotificationsModalKeys.row(notification.id),
                              notification: notification,
                              onTap: () {
                                vm.markAsRead(notification.id).then((_) {
                                  if (context.mounted) {
                                    Navigator.pop(context, notification);
                                  }
                                });
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

  /// Header with title, mark-all-read action, and close button.
  Widget _buildHeader(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Notifications',
            style: AppTypography.h3.copyWith(color: colorScheme.text),
          ),
          Row(
            children: [
              Semantics(
                button: true,
                label: 'Mark all notifications as read',
                child: TextButton(
                  onPressed: () async {
                    AppInteractionStates.hapticTap();
                    AppLogger.d(
                      'NotificationsModal: mark all as read tapped',
                      tag: 'Notifications',
                    );
                    try {
                      await context
                          .read<NotificationViewModel>()
                          .markAllAsRead();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All marked as read')),
                        );
                      }
                    } on Exception catch (e) {
                      AppLogger.e(
                        'NotificationsModal: markAllAsRead failed',
                        tag: 'Notifications',
                        error: e,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to mark all as read: $e'),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Mark all as read',
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Close notifications',
                child: IconButton(
                  icon: Icon(Icons.close, color: colorScheme.text),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Skeleton loading state — 5 placeholder tiles.
  Widget _buildSkeletonList() {
    return ListView.separated(
      key: NotificationsModalKeys.loading,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.p12),
      itemBuilder: (_, __) => const _SkeletonNotificationTile(),
    );
  }

  /// Rich empty state with icon and descriptive text.
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Center(
      key: NotificationsModalKeys.empty,
      child: Semantics(
        label: 'No notifications. You are all caught up.',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: AppLayout.iconFeature,
              color: colorScheme.textSecondary,
            ),
            const SizedBox(height: AppLayout.spacingSection),
            Text(
              "You're all caught up!",
              style: AppTypography.h5.copyWith(
                color: colorScheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppLayout.spacingStandard),
            Text(
              'No new notifications',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Error state with icon, message, and styled retry button.
  Widget _buildErrorState(BuildContext context, NotificationViewModel vm) {
    final colorScheme = context.colorScheme;

    return Center(
      key: NotificationsModalKeys.error,
      child: Semantics(
        label: 'Error loading notifications. Tap retry.',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: AppLayout.iconFeature,
              color: colorScheme.danger,
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
                  color: colorScheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppLayout.spacingStandard),
            TextButton.icon(
              onPressed: () {
                AppInteractionStates.hapticTap();
                vm.retry();
              },
              icon: Icon(Icons.refresh, color: colorScheme.primary),
              label: Text(
                'Retry',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimens.p8),
      child: Row(
        children: [
          // Icon circle skeleton
          SkeletonLoader(width: 40, height: 40, isCircle: true),
          SizedBox(width: AppDimens.p12),
          // Text lines skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 180,
                  height: AppDimens.p14,
                  borderRadius: AppDimens.r4,
                ),
                SizedBox(height: AppDimens.p8),
                SkeletonLoader(
                  height: AppDimens.p12,
                  borderRadius: AppDimens.r4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
