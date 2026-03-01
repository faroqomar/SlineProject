import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';

import '../../models/task_model.dart';

class DiscoveryTaskSliver extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final loadingChild = skeletonItem ?? const SkeletonTaskCard();

    if (isInitialLoading) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(
          AppDimens.p16,
          0,
          AppDimens.p16,
          bottomPadding,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => loadingChild,
            childCount: 5,
          ),
        ),
      );
    }

    if (tasks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                emptyIcon,
                size: 64,
                color: colorScheme.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: AppTypography.h5.copyWith(
                  color: colorScheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final showFooter = hasMore || isLoadingMore;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppDimens.p16,
        0,
        AppDimens.p16,
        bottomPadding,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index < tasks.length) {
            return taskBuilder(context, tasks[index]);
          }

          if (isLoadingMore) {
            return const Padding(
              key: loadMoreIndicatorKey,
              padding: EdgeInsets.symmetric(vertical: AppDimens.p16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return _LoadMoreSentinel(
            key: ValueKey<String>('discovery_load_more_${tasks.length}'),
            onLoadMore: onLoadMore,
            surface: surface,
          );
        }, childCount: tasks.length + (showFooter ? 1 : 0)),
      ),
    );
  }
}

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
