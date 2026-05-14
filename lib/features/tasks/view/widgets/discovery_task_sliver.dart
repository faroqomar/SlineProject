// Discovery task sliver — renders the task list for discovery/search screens.
//
// Handles four visual states: skeleton loading (initial fetch), error with
// optional retry, empty results (with icon + guidance copy), and the populated
// card list with staggered entrance animations and an infinite-scroll
// load-more sentinel.
//
// Phase 3 additions:
// - Staggered slide-up + fade entrance on initial load (first 10 cards).
// - Themed compact load-more indicator using design-system tokens.
// - Rich empty state with icon badge, title, and description.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';

/// Displays a scrollable sliver of task cards for the discovery feed.
///
/// Supports skeleton placeholders during initial fetch, an error state with
/// optional retry, a rich empty state when no results match, and staggered
/// card entrance animations that only play on the first load (not on
/// subsequent load-more appends).
class DiscoveryTaskSliver extends StatefulWidget {
  const DiscoveryTaskSliver({
    super.key,
    required this.tasks,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.emptyTitle,
    required this.emptyIcon,
    required this.taskBuilder,
    this.surface = 'unknown',
    this.bottomPadding = AppDimens.p100,
    this.skeletonItem,
    this.errorMessage,
    this.onRetry,
  });

  static const Key loadMoreIndicatorKey = ValueKey<String>(
    'discovery_load_more_indicator',
  );
  static const Key loadMoreSentinelKey = ValueKey<String>(
    'discovery_load_more_sentinel',
  );

  final List<Task> tasks;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Future<void> Function() onLoadMore;
  final String emptyTitle;
  final IconData emptyIcon;
  final Widget Function(BuildContext context, Task task) taskBuilder;
  final String surface;
  final double bottomPadding;
  final Widget? skeletonItem;

  /// Optional error message surfaced from the ViewModel. When non-null the
  /// sliver renders an error state with a danger-tinted icon instead of the
  /// task list or empty state.
  final String? errorMessage;

  /// Callback invoked when the user taps "Try Again" in the error state.
  /// Only shown when [errorMessage] is non-null.
  final VoidCallback? onRetry;

  @override
  State<DiscoveryTaskSliver> createState() => _DiscoveryTaskSliverState();
}

class _DiscoveryTaskSliverState extends State<DiscoveryTaskSliver> {
  /// Tracks whether this is the very first data load so we can enable
  /// staggered entrance animations only once. Subsequent load-more
  /// appends skip the animation to avoid distracting the user mid-scroll.
  bool _isFirstLoad = true;

  /// The task count when the first load completed. Any items beyond this
  /// index were appended via load-more and should not animate.
  int _firstLoadCount = 0;

  @override
  void didUpdateWidget(covariant DiscoveryTaskSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleFirstLoadTransition(oldWidget);
  }

  /// Handles first-load state transitions for stagger animation.
  ///
  /// The first transition from loading -> loaded captures the initial task count,
  /// allows one animation pass, then disables first-load mode after the frame.
  /// If the first response is empty, we disable first-load immediately.
  void _handleFirstLoadTransition(DiscoveryTaskSliver oldWidget) {
    if (!oldWidget.isInitialLoading || widget.isInitialLoading) return;

    _firstLoadCount = widget.tasks.length;
    if (widget.tasks.isEmpty) {
      _isFirstLoad = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isFirstLoad) return;
      setState(() {
        _isFirstLoad = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const amberColors = AmberDuskTokens.colors;
    final loadingChild = widget.skeletonItem ?? const SkeletonTaskCard();

    // ── Initial loading: skeleton placeholder cards ──
    if (widget.isInitialLoading) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(
          AmberDuskTokens.spacing.contentHorizontalPadding,
          0,
          AmberDuskTokens.spacing.contentHorizontalPadding,
          widget.bottomPadding,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => loadingChild,
            childCount: 5,
          ),
        ),
      );
    }

    // ── Error state: danger icon + message + optional retry button ──
    if (widget.errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Semantics(
            label: 'Error loading tasks',
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.p24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Error icon in danger-tinted circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: amberColors.rust.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: amberColors.rust,
                    ),
                  ),
                  const SizedBox(height: AppDimens.p16),
                  Text(
                    widget.errorMessage!,
                    style: AmberDuskTokens.typography.sectionTitle.copyWith(
                      color: amberColors.text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.p8),
                  Text(
                    'Please try again',
                    style: AmberDuskTokens.typography.bodySmall.copyWith(
                      color: amberColors.muted,
                    ),
                  ),
                  if (widget.onRetry != null) ...[
                    const SizedBox(height: AppDimens.p24),
                    OutlinedButton(
                      onPressed: widget.onRetry,
                      child: const Text('Try Again'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Empty state: icon badge + title + description ──
    if (widget.tasks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Semantics(
            label:
                '${widget.emptyTitle}. '
                'Try adjusting your filters or check back later.',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon inside a circular badge with primary tint
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    // A muted primary wash keeps missing states on the
                    // Amber Dusk palette without inventing a new state color.
                    color: amberColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    widget.emptyIcon,
                    size: 36,
                    color: amberColors.primary,
                  ),
                ),
                const SizedBox(height: AppDimens.p16),
                Text(
                  widget.emptyTitle,
                  style: AmberDuskTokens.typography.sectionTitle.copyWith(
                    color: amberColors.text,
                  ),
                ),
                const SizedBox(height: AppDimens.p8),
                Text(
                  'Try adjusting your filters or check back later.',
                  style: AmberDuskTokens.typography.bodySmall.copyWith(
                    color: amberColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Normal state: task list + load-more footer ──
    final showFooter = widget.hasMore || widget.isLoadingMore;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AmberDuskTokens.spacing.contentHorizontalPadding,
        0,
        AmberDuskTokens.spacing.contentHorizontalPadding,
        widget.bottomPadding,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index < widget.tasks.length) {
            final taskCard = widget.taskBuilder(context, widget.tasks[index]);

            // Only animate cards from the initial load batch,
            // capped to first 10 cards (indices 0–9) to keep the stagger tight.
            final shouldAnimate =
                _isFirstLoad && index < _firstLoadCount && index < 10;

            return _StaggeredTaskItem(
              key: ValueKey<String>('stagger_${widget.tasks[index].id}'),
              index: index,
              shouldAnimate: shouldAnimate,
              child: taskCard,
            );
          }

          // ── Load-more indicator: compact themed spinner ──
          if (widget.isLoadingMore) {
            return Padding(
              key: DiscoveryTaskSliver.loadMoreIndicatorKey,
              padding: const EdgeInsets.symmetric(vertical: AppDimens.p24),
              child: Center(
                child: SizedBox(
                  width: AppInteractionStates.loadingSize,
                  height: AppInteractionStates.loadingSize,
                  child: CircularProgressIndicator(
                    strokeWidth: AppInteractionStates.loadingStrokeWidth,
                    color: amberColors.primary,
                  ),
                ),
              ),
            );
          }

          return _LoadMoreSentinel(
            key: ValueKey<String>('discovery_load_more_${widget.tasks.length}'),
            onLoadMore: widget.onLoadMore,
            surface: widget.surface,
          );
        }, childCount: widget.tasks.length + (showFooter ? 1 : 0)),
      ),
    );
  }
}

/// Wraps a single task card with a staggered slide-up + fade entrance animation.
///
/// Each card delays its start by `index * AppMotion.staggerMedium` (50ms),
/// capped at 10 items, producing a cascading reveal effect. The animation
/// only fires when [shouldAnimate] is true (initial load only) and respects
/// the user's reduced-motion accessibility preference via [AppMotion.respectMotion].
class _StaggeredTaskItem extends StatefulWidget {
  const _StaggeredTaskItem({
    super.key,
    required this.index,
    required this.shouldAnimate,
    required this.child,
  });

  /// Position in the list, used to calculate the stagger delay.
  final int index;

  /// Whether the entrance animation should play. False for load-more items.
  final bool shouldAnimate;

  /// The actual task card widget to display.
  final Widget child;

  @override
  State<_StaggeredTaskItem> createState() => _StaggeredTaskItemState();
}

class _StaggeredTaskItemState extends State<_StaggeredTaskItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  /// Timer for the stagger delay before starting the animation.
  Timer? _staggerTimer;

  @override
  void initState() {
    super.initState();

    // Default to AppMotion.standard — will be updated in didChangeDependencies
    // if the user has reduced-motion enabled. Cannot access MediaQuery in
    // initState (context.dependOnInheritedWidgetOfExactType not allowed here).
    _controller = AnimationController(
      duration: AppMotion.standard,
      vsync: this,
    );

    // Slide from 5% below to natural position — subtle enough to feel polished
    // without being distracting. curveDecel (easeOutQuart) gives a smooth
    // deceleration that matches Material entrance patterns.
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: AppMotion.curveDecel),
        );

    // Fade from fully transparent to fully opaque
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.curveDecel,
    );

    _initAnimations();
  }

  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      // Apply reduced-motion preference now that context is available.
      // respectMotion returns Duration.zero if the user has animations disabled.
      final duration = AppMotion.respectMotion(context, AppMotion.standard);
      if (duration != _controller.duration) {
        _controller.duration = duration;
      }
    }
  }

  /// Initializes slide/fade animations and schedules the stagger delay.
  void _initAnimations() {
    if (widget.shouldAnimate) {
      // Calculate the stagger delay from the shared motion token, capped at
      // index 10 so the feed is ready quickly on slower phones.
      final cappedIndex = widget.index > 10 ? 10 : widget.index;
      final delay = AppMotion.staggerMedium * cappedIndex;

      if (delay > Duration.zero) {
        _staggerTimer = Timer(delay, () {
          if (mounted) {
            _controller.forward();
          }
        });
      } else {
        // First card starts immediately
        _controller.forward();
      }

      // Log only first/last animated cards in debug mode to reduce noise.
      if (kDebugMode && (widget.index == 0 || widget.index == 9)) {
        AppLogger.d(
          'stagger_animation_start',
          tag: 'DiscoveryUI',
          json: {'index': widget.index, 'delayMs': delay.inMilliseconds},
        );
      }
    } else {
      // No animation — show the card immediately at full opacity
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _staggerTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

/// Invisible sentinel widget that triggers load-more when it enters the viewport.
///
/// Fires the [onLoadMore] callback exactly once via a post-frame callback
/// in [initState], ensuring the Supabase fetch starts as soon as the user
/// scrolls near the bottom of the list.
class _LoadMoreSentinel extends StatefulWidget {
  const _LoadMoreSentinel({
    super.key,
    required this.onLoadMore,
    required this.surface,
  });

  final Future<void> Function() onLoadMore;
  final String surface;

  @override
  State<_LoadMoreSentinel> createState() => _LoadMoreSentinelState();
}

class _LoadMoreSentinelState extends State<_LoadMoreSentinel> {
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _scheduleLoad();
  }

  void _scheduleLoad() {
    if (_requested) return;
    _requested = true;
    AppLogger.d(
      'discovery_load_more_triggered',
      tag: 'DiscoveryUI',
      json: {'surface': widget.surface},
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        widget.onLoadMore().catchError((error, stackTrace) {
          AppLogger.e(
            'discovery_load_more_failed',
            tag: 'DiscoveryUI',
            error: error,
            stackTrace: stackTrace,
          );
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: DiscoveryTaskSliver.loadMoreSentinelKey,
      height: AppDimens.p32,
    );
  }
}
