import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';
import 'package:sline_app/features/dashboard/models/activity_log.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';

/// Activity feed preview with enhanced timeline visual, stagger entrance,
/// skeleton loading, and full Semantics coverage.
///
/// Phase 5 redesign: replaced CircularProgressIndicator with skeleton list,
/// replaced hardcoded spacing/icon sizes with tokens, added type-colored
/// timeline dots, stagger entrance animation, and accessibility labels.
/// View-layer only.
class ActivityFeedPreview extends StatefulWidget {
  final int? limit;

  const ActivityFeedPreview({super.key, this.limit});

  @override
  State<ActivityFeedPreview> createState() => _ActivityFeedPreviewState();
}

class _ActivityFeedPreviewState extends State<ActivityFeedPreview>
    with SingleTickerProviderStateMixin {
  // ── Stagger entrance animation ─────────────────────────────
  late final AnimationController _staggerController;
  bool _hasAnimatedEntrance = false;
  static const int _maxStaggerCount = 6;

  // Cached per-item animations — built once in _triggerStaggerIfNeeded to
  // avoid allocating new Animation objects on every rebuild.
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: AppMotion.emphasis,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _triggerStaggerIfNeeded(int itemCount) {
    if (_hasAnimatedEntrance || itemCount == 0) return;
    _hasAnimatedEntrance = true;

    // Build and cache per-item animations now that itemCount is known.
    // We cap at _maxStaggerCount to match the stagger window used in build().
    final count = itemCount.clamp(0, _maxStaggerCount);
    for (var i = 0; i < count; i++) {
      final staggerFraction = i / (_maxStaggerCount + 2);
      final begin = staggerFraction;
      final end = (staggerFraction + 0.3).clamp(0.0, 1.0);

      _slideAnimations.add(
        Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(begin, end, curve: AppMotion.curveDecel),
          ),
        ),
      );

      _fadeAnimations.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(begin, end, curve: AppMotion.curveDecel),
          ),
        ),
      );
    }

    AppLogger.d(
      'ActivityFeedPreview: stagger entrance ($itemCount items)',
      tag: 'Dashboard',
    );
    _staggerController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final colorScheme = context.colorScheme;
    var activities = vm.activityFeed;

    if (widget.limit != null && activities.length > widget.limit!) {
      activities = activities.sublist(0, widget.limit);
    }

    // Skeleton loading state
    if (vm.isLoading && activities.isEmpty) {
      return _buildSkeletonList(colorScheme);
    }

    // Enhanced empty state
    if (activities.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    // Schedule stagger trigger after the current frame to avoid mutating
    // controller state during build, which would cause assertion errors.
    if (!_hasAnimatedEntrance) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _triggerStaggerIfNeeded(activities.length),
      );
    }

    return Semantics(
      label: 'Recent activity feed',
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final row = _ActivityRow(
            item: activities[index],
            isLast: index == activities.length - 1,
          );

          // Use cached animations for the stagger entrance window.
          if (_hasAnimatedEntrance && index < _maxStaggerCount) {
            return SlideTransition(
              position: _slideAnimations[index],
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: row,
              ),
            );
          }

          return row;
        },
      ),
    );
  }

  /// Skeleton loading — 3 placeholder timeline rows.
  Widget _buildSkeletonList(AppColorScheme colorScheme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (_, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.p12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                const SkeletonLoader(width: 36, height: 36, isCircle: true),
                if (index < 2)
                  Container(width: 1, height: 32, color: colorScheme.divider),
              ],
            ),
            const SizedBox(width: AppDimens.p12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 140,
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
      ),
    );
  }

  /// Enhanced empty state with icon and descriptive text.
  Widget _buildEmptyState(AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Semantics(
        label: 'No recent activity',
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: AppLayout.iconFeature,
                color: colorScheme.textTertiary,
              ),
              const SizedBox(height: AppLayout.spacingStandard),
              Text(
                'No recent activity',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single activity timeline row with type-colored dot and connecting line.
class _ActivityRow extends StatelessWidget {
  final ActivityLog item;
  final bool isLast;

  const _ActivityRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final info = _ActivityRow._mapActivityToInfo(item, colorScheme);
    final deepLinkService = context.read<DeepLinkService>();

    return Semantics(
      label:
          '${info.title}: ${info.description}, '
          '${formatFriendlyTime(item.createdAt)}',
      button: true,
      child: InkWell(
        onTap: () {
          AppInteractionStates.hapticTap();
          AppLogger.d(
            'ActivityFeedPreview: tapped ${item.entityType}/${item.entityId}',
            tag: 'Dashboard',
          );
          deepLinkService.handleActivity(
            context,
            entityType: item.entityType,
            entityId: item.entityId,
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot + connecting line
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimens.p8),
                  decoration: BoxDecoration(
                    // Type-colored dot background
                    color: info.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    info.icon,
                    size: AppDimens.iconSizeSmall,
                    color: info.color,
                  ),
                ),
                // Vertical connecting line between timeline dots
                if (!isLast)
                  Container(width: 1, height: 32, color: colorScheme.divider),
              ],
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppLayout.spacingTight,
                  bottom: AppLayout.spacingSection,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            info.title,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.text,
                            ),
                          ),
                        ),
                        Text(
                          formatFriendlyTime(item.createdAt),
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppLayout.spacingTight),
                    Text(
                      info.description,
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Map activity log to display info with type-specific color.
  ///
  /// Static because it has no dependency on instance state — it transforms
  /// a pure [ActivityLog] value into display data using the provided scheme.
  static _ActivityInfo _mapActivityToInfo(
    ActivityLog log,
    AppColorScheme colorScheme,
  ) {
    var title = 'Notification';
    var description = 'New activity';
    var icon = Icons.notifications_none;
    // Default to primary; booking = primary, task = info, status = warning
    var color = colorScheme.primary;

    final type = log.eventType;
    final entity = log.entityType;

    if (entity == 'booking') {
      icon = Icons.calendar_today;
      color = colorScheme.primary; // booking → primary
      if (type == 'created') {
        title = 'New Booking Request';
        description = 'You have a new booking request.';
      } else if (type == 'status_change') {
        // Guard against missing metadata key — fall back to 'updated' string.
        final newStatus =
            log.metadata['new_status'] as String? ?? 'updated';
        title = 'Booking $newStatus';
        description = 'Booking status changed to $newStatus.';
        color = colorScheme.warning; // status_change → warning
        if (newStatus == 'confirmed') icon = Icons.check_circle_outline;
        if (newStatus == 'canceled') icon = Icons.cancel_outlined;
      }
    } else if (entity == 'task') {
      icon = Icons.assignment;
      color = colorScheme.info; // task → info
      if (type == 'status_change') {
        // Guard against missing metadata key — fall back to 'updated' string.
        final newStatus =
            log.metadata['new_status'] as String? ?? 'updated';
        description = 'Task status updated to $newStatus.';
        title = 'Task Update';
        color = colorScheme.warning; // status_change → warning
      }
    }

    return _ActivityInfo(title, description, icon, color);
  }
}

class _ActivityInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _ActivityInfo(this.title, this.description, this.icon, this.color);
}
