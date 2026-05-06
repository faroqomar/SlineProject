import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/favorites/viewmodels/favorites_view_model.dart';
import 'package:sline_app/features/tasks/models/expired_bid_filter.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/view/widgets/requests/request_award_dialog.dart';
import 'package:sline_app/features/tasks/view/widgets/requests/submit_request_sheet.dart';
import 'package:sline_app/features/tasks/view/widgets/requests/widgets/request_tile.dart';
import 'package:sline_app/features/tasks/viewmodels/requests_filter_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';

typedef SubmitRequestSheetLauncher =
    Future<void> Function(
      BuildContext context, {
      required String taskId,
      required TaskRequestsViewModel controller,
      required String budget,
    });

typedef TaskRequestsViewModelBuilder =
    TaskRequestsViewModel Function({
      required String taskId,
      required bool isOwner,
    });

/// Displays paginated offers (task requests) for a given task.
class RequestsListScreen extends StatefulWidget {
  final String taskId;
  final bool autoOpenSubmitSheet;
  final bool isTender;

  /// True when the viewer is the owner of the task (can accept/reject)
  final bool isOwner;
  final String? budget; // Added budget
  final SubmitRequestSheetLauncher? submitSheetLauncher;
  final TaskRequestsViewModelBuilder? viewModelBuilder;

  const RequestsListScreen({
    super.key,
    required this.taskId,
    this.autoOpenSubmitSheet = false,
    this.isTender = true,
    this.isOwner = false,
    this.budget,
    this.submitSheetLauncher,
    this.viewModelBuilder,
  });

  @override
  State<RequestsListScreen> createState() => _RequestsListScreenState();
}

class _RequestsListScreenState extends State<RequestsListScreen> {
  BuildContext? _providerCtx;
  late final ScrollController _scroll;
  bool _isShowingBidSheet = false;
  bool _didAutoOpenSubmitSheet = false;
  RequestsFilterViewModel? _filterVm;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant RequestsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskId != widget.taskId) {
      _filterVm?.dispose();
      _filterVm = null; // Recreated lazily in build()
      _didAutoOpenSubmitSheet = false;
      _isShowingBidSheet = false;
    } else if (!oldWidget.autoOpenSubmitSheet && widget.autoOpenSubmitSheet) {
      _didAutoOpenSubmitSheet = false;
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _filterVm?.dispose();
    super.dispose();
  }

  void _onScroll() {
    final prov = _providerCtx;
    if (prov == null) return;
    final c = prov.read<TaskRequestsViewModel>();
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      if (c.hasMore && !c.isLoadingMore) c.loadMore();
    }
  }

  /// Apply filter to items via the filter VM.
  List<TaskRequest> _getFilteredItems(List<TaskRequest> items) =>
      _filterVm!.applyFilter(items);

  /// Get count string for app bar subtitle.
  String _getCountString(int total, int filtered) =>
      _filterVm!.getCountString(total, filtered);

  void _onFilterChanged(ExpiredBidFilter newFilter) {
    _filterVm!.setFilter(newFilter);
  }

  ExpiredBidFilter get _filter =>
      _filterVm?.filter ?? ExpiredBidFilter.hideExpired;
  bool get _isAwarding => _filterVm?.isAwarding ?? false;
  set _isAwarding(bool v) {
    assert(
      _filterVm != null,
      '_filterVm must be initialized before setting _isAwarding',
    );
    _filterVm!.isAwarding = v;
  }

  /// Delegates to extracted award dialog and flow.
  Future<void> _showAwardDialog(
    TaskRequest request,
    TaskRequestsViewModel vm,
  ) async {
    await showAwardDialog(
      context: context,
      request: request,
      vm: vm,
      budget: widget.budget,
      onAwardingChanged: (v) {
        if (mounted) {
          setState(() {
            _isAwarding = v;
          });
        }
      },
    );
  }

  void _scheduleAutoOpenSubmitSheet(
    BuildContext providerContext,
    TaskRequestsViewModel controller,
  ) {
    if (!widget.autoOpenSubmitSheet ||
        widget.isOwner ||
        _didAutoOpenSubmitSheet ||
        _isShowingBidSheet) {
      return;
    }

    _didAutoOpenSubmitSheet = true;
    _isShowingBidSheet = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _isShowingBidSheet = false;
        return;
      }

      try {
        await _launchSubmitSheet(providerContext, controller);
      } finally {
        _isShowingBidSheet = false;
      }
    });
  }

  Future<void> _openSubmitSheet(
    BuildContext providerContext,
    TaskRequestsViewModel controller,
  ) async {
    if (_isShowingBidSheet) return;

    _isShowingBidSheet = true;
    try {
      await _launchSubmitSheet(providerContext, controller);
    } finally {
      _isShowingBidSheet = false;
    }
  }

  Future<void> _launchSubmitSheet(
    BuildContext providerContext,
    TaskRequestsViewModel controller,
  ) {
    final launcher = widget.submitSheetLauncher;
    if (launcher != null) {
      return launcher(
        providerContext,
        taskId: widget.taskId,
        controller: controller,
        budget: widget.budget ?? '0',
      );
    }

    return showSubmitRequestSheet(
      providerContext,
      taskId: widget.taskId,
      controller: controller,
      budget: widget.budget ?? '0',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTender) {
      return Scaffold(
        appBar: AppBar(title: const Text('Offers')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Offers are only available for tender-type tasks.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return ChangeNotifierProvider<TaskRequestsViewModel>(
      key: ValueKey('requests_provider_${widget.taskId}'),
      create: (_) {
        final c =
            widget.viewModelBuilder?.call(
              taskId: widget.taskId,
              isOwner: widget.isOwner,
            ) ??
            TaskRequestsViewModel(
              taskId: widget.taskId,
              isOwner: widget.isOwner,
            );
        c.loadInitial();
        return c;
      },
      builder: (ctx, _) {
        _providerCtx = ctx;
        // Lazily create the filter VM (once per build cycle)
        _filterVm ??= RequestsFilterViewModel(
          requestsVm: ctx.read<TaskRequestsViewModel>(),
        );
        _scheduleAutoOpenSubmitSheet(ctx, ctx.read<TaskRequestsViewModel>());
        return Consumer<TaskRequestsViewModel>(
          builder: (context, c, __) {
            final filteredItems = _getFilteredItems(c.items);
            final countString = _getCountString(
              c.items.length,
              filteredItems.length,
            );

            return Scaffold(
              key: const Key('requests_list_screen'),
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Offers'),
                    if (!c.isLoadingInitial && c.errorMessage == null)
                      Text(
                        countString,
                        style: AppTypography.caption.copyWith(
                          color: context.colorScheme.textSecondary,
                        ),
                      ),
                  ],
                ),
                actions: [
                  // Filter popup menu
                  if (!c.isLoadingInitial && c.items.isNotEmpty)
                    PopupMenuButton<ExpiredBidFilter>(
                      icon: Icon(_filter.icon, color: context.colorScheme.text),
                      tooltip: 'Filter: ${_filter.label}',
                      initialValue: _filter,
                      onSelected: _onFilterChanged,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: ExpiredBidFilter.hideExpired,
                          child: Row(
                            children: [
                              Icon(
                                ExpiredBidFilter.hideExpired.icon,
                                size: 20,
                                color: context.colorScheme.text,
                              ),
                              const SizedBox(width: 8),
                              Text(ExpiredBidFilter.hideExpired.label),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: ExpiredBidFilter.showAll,
                          child: Row(
                            children: [
                              Icon(
                                ExpiredBidFilter.showAll.icon,
                                size: 20,
                                color: context.colorScheme.text,
                              ),
                              const SizedBox(width: 8),
                              Text(ExpiredBidFilter.showAll.label),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: ExpiredBidFilter.showOnlyExpired,
                          child: Row(
                            children: [
                              Icon(
                                ExpiredBidFilter.showOnlyExpired.icon,
                                size: 20,
                                color: AppColors.lightRed,
                              ),
                              const SizedBox(width: 8),
                              Text(ExpiredBidFilter.showOnlyExpired.label),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async => c.loadInitial(),
                child: _buildBody(c, filteredItems),
              ),
              floatingActionButton: widget.isOwner
                  ? null
                  : FloatingActionButton.extended(
                      onPressed: () async {
                        final prov = _providerCtx ?? context;
                        await _openSubmitSheet(prov, c);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('New Offer'),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(TaskRequestsViewModel c, List<TaskRequest> filteredItems) {
    final colorScheme = context.colorScheme;

    // Loading state
    if (c.isLoadingInitial) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: 5,
        itemBuilder: (_, __) => const SkeletonOfferCard(),
      );
    }

    // Error state
    if (c.errorMessage != null) {
      return _buildErrorState(c, colorScheme);
    }

    // Empty state (no offers at all)
    if (c.items.isEmpty) {
      AppLogger.d('Displaying empty state: no offers', tag: 'TaskRequests');
      return _buildEmptyState(colorScheme, hasOffers: false);
    }

    // Empty filtered state (has offers but all filtered out)
    if (filteredItems.isEmpty && c.items.isNotEmpty) {
      AppLogger.d(
        'Displaying empty filtered state: filter=${_filter.label}, total=${c.items.length}',
        tag: 'TaskRequests',
      );
      return _buildEmptyFilteredState(colorScheme);
    }

    // List with offers
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: filteredItems.length + (c.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= filteredItems.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: SkeletonOfferCard(),
          );
        }
        final req = filteredItems[index];
        final favoritesVM = context.read<FavoritesViewModel>();
        final viewerUserId = context.read<AuthSessionViewModel>().currentUserId;

        // Phase 3.5: Wire up error recovery UI parameters
        return RequestTile(
          request: req,
          onAccept: c.canActOn(req) && !_isAwarding
              ? () => _showAwardDialog(req, c)
              : null,
          onReject: c.canActOn(req) && !_isAwarding
              ? () => c.reject(req.id)
              : null,
          isOwner: widget.isOwner,
          isLoading: _isAwarding || c.isAwarding,
          favoritesVM: favoritesVM,
          viewerUserId: viewerUserId,
          // Phase 3.5: Error recovery UI parameters
          viewModel: c,
          errorMessage: c.errorMessage,
          onRetryError: c.isRetryableError(c.errorMessage)
              ? () {
                  AppLogger.d(
                    'User triggered error retry from tile',
                    tag: 'TaskRequests',
                  );
                  c.clearError();
                  c.loadInitial();
                }
              : null,
          onDismissError: c.errorMessage != null ? c.clearError : null,
        );
      },
    );
  }

  /// Polished error state with retry button
  Widget _buildErrorState(TaskRequestsViewModel c, AppColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTypography.h5.copyWith(color: colorScheme.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              c.errorMessage!,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                AppLogger.d(
                  'User triggered retry after error',
                  tag: 'TaskRequests',
                );
                c.clearError();
                c.loadInitial();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Contact support - navigate to support or open email
                AppLogger.d('User tapped contact support', tag: 'TaskRequests');
              },
              child: Text(
                'Contact Support',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Polished empty state when there are no offers at all
  Widget _buildEmptyState(
    AppColorScheme colorScheme, {
    required bool hasOffers,
  }) {
    final isOwner = widget.isOwner;

    // Determine message and CTA based on user role
    final title = isOwner ? 'No offers yet' : 'No bids on this task';
    final subtitle = isOwner
        ? 'Share your task to attract more freelancers'
        : 'Be the first to submit a bid and start the conversation';
    final icon = isOwner ? Icons.inbox_outlined : Icons.local_offer_outlined;

    AppLogger.d(
      'Empty state rendered: isOwner=$isOwner, hasOffers=$hasOffers',
      tag: 'TaskRequests',
    );

    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 48,
                      color: colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: AppTypography.h4.copyWith(color: colorScheme.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (isOwner)
                    // Owner CTA: Share task
                    FilledButton.icon(
                      onPressed: () {
                        AppLogger.d(
                          'Owner tapped share task CTA',
                          tag: 'TaskRequests',
                        );
                        _showShareOptions();
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share Task'),
                    )
                  else
                    // Freelancer CTA: Submit bid
                    FilledButton.icon(
                      onPressed: () async {
                        AppLogger.d(
                          'Freelancer tapped submit bid CTA',
                          tag: 'TaskRequests',
                        );
                        final prov = _providerCtx ?? context;
                        final vm = prov.read<TaskRequestsViewModel>();
                        await _openSubmitSheet(prov, vm);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Submit a Bid'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Empty state when filter hides all items
  Widget _buildEmptyFilteredState(AppColorScheme colorScheme) {
    String message;
    IconData icon;

    switch (_filter) {
      case ExpiredBidFilter.hideExpired:
        message = 'All offers have expired. Change the filter to see them.';
        icon = Icons.timer_off;
      case ExpiredBidFilter.showOnlyExpired:
        message = 'No expired offers. All bids are still active.';
        icon = Icons.check_circle_outline;
      case ExpiredBidFilter.showAll:
        message = 'No offers match your criteria.';
        icon = Icons.filter_list;
    }

    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 64,
                    color: colorScheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No matching offers',
                    style: AppTypography.h5.copyWith(color: colorScheme.text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => _onFilterChanged(ExpiredBidFilter.showAll),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Show All Offers'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showShareOptions() {
    // Placeholder for share functionality
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share Task',
                style: AppTypography.h5.copyWith(
                  color: context.colorScheme.text,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Link'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share via...'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
