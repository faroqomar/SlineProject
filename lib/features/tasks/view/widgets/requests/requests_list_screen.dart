import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/favorites/viewmodels/favorites_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/proposals/data/proposal_repository.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:sline_app/features/proposals/routes/proposal_payment_route.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:intl/intl.dart';
import 'widgets/request_tile.dart';
import 'submit_request_sheet.dart';

/// Filter options for expired bids
enum ExpiredBidFilter { hideExpired, showAll, showOnlyExpired }

extension ExpiredBidFilterExtension on ExpiredBidFilter {
  String get label {
    switch (this) {
      case ExpiredBidFilter.hideExpired:
        return 'Hide Expired';
      case ExpiredBidFilter.showAll:
        return 'Show All';
      case ExpiredBidFilter.showOnlyExpired:
        return 'Show Only Expired';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpiredBidFilter.hideExpired:
        return Icons.visibility_off;
      case ExpiredBidFilter.showAll:
        return Icons.visibility;
      case ExpiredBidFilter.showOnlyExpired:
        return Icons.timer_off;
    }
  }
}

/// Displays paginated offers (task requests) for a given task.
class RequestsListScreen extends StatefulWidget {
  final String taskId;
  final bool autoOpenSubmitSheet;
  final bool isTender;

  /// True when the viewer is the owner of the task (can accept/reject)
  final bool isOwner;
  final String? budget; // Added budget

  const RequestsListScreen({
    super.key,
    required this.taskId,
    this.autoOpenSubmitSheet = false,
    this.isTender = true,
    this.isOwner = false,
    this.budget,
  });

  @override
  State<RequestsListScreen> createState() => _RequestsListScreenState();
}

class _RequestsListScreenState extends State<RequestsListScreen> {
  BuildContext? _providerCtx;
  late final ScrollController _scroll;
  bool _isAwarding = false;

  // Filter state for expired bids
  ExpiredBidFilter _filter = ExpiredBidFilter.hideExpired;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
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

  /// Apply filter to items and return filtered list
  List<TaskRequest> _getFilteredItems(List<TaskRequest> items) {
    switch (_filter) {
      case ExpiredBidFilter.hideExpired:
        return items.where((r) => !r.isExpired).toList();
      case ExpiredBidFilter.showAll:
        return items;
      case ExpiredBidFilter.showOnlyExpired:
        return items.where((r) => r.isExpired).toList();
    }
  }

  /// Get count string for app bar subtitle
  String _getCountString(int total, int filtered) {
    if (_filter == ExpiredBidFilter.showAll || total == filtered) {
      return '$total offers';
    }
    return '$filtered of $total offers';
  }

  void _onFilterChanged(ExpiredBidFilter newFilter) {
    if (_filter != newFilter) {
      AppLogger.d(
        'Bid filter changed: ${_filter.label} → ${newFilter.label}',
        tag: 'TaskRequests',
      );
      setState(() => _filter = newFilter);
    }
  }

  /// Show award confirmation dialog (Step 1: Award without payment)
  Future<void> _showAwardDialog(
    TaskRequest request,
    TaskRequestsViewModel vm,
  ) async {
    // Capture the price at the moment the dialog opens (optimistic concurrency).
    // DB stores task_requests.price in IQD; RPC expects p_expected_price_cents = price * 100.
    final expectedPriceCents = request.price * 100;

    // Log dialog open event
    AppLogger.i(
      'Award dialog opened',
      tag: 'TaskRequests',
      json: {
        'requestId': request.id,
        'bidderName': request.bidderName,
        'price': request.price,
        'taskBudget': widget.budget,
      },
    );

    // Calculate payment deadline (24 hours from now)
    final paymentDeadline = DateTime.now().add(const Duration(hours: 24));
    final formattedDeadline = DateFormat(
      'MMM d, h:mm a',
    ).format(paymentDeadline);

    // Parse budget for comparison
    final budgetValue = double.tryParse(widget.budget ?? '0') ?? 0;
    final bidPrice = request.price.toDouble();

    // Determine budget status and colors
    final budgetDiff = bidPrice - budgetValue;
    final isUnderBudget = budgetDiff < 0;
    final isAtBudget = budgetDiff.abs() < 0.01; // Within 1 cent

    Color budgetColor;
    IconData budgetIcon;
    String budgetMessage;

    if (isUnderBudget) {
      budgetColor = Colors.green.shade700;
      budgetIcon = Icons.trending_down;
      budgetMessage =
          'Under budget by ${PriceFormatter.formatPrice(budgetDiff.abs())}';
    } else if (isAtBudget) {
      budgetColor = Colors.orange.shade700;
      budgetIcon = Icons.check_circle;
      budgetMessage = 'At budget limit';
    } else {
      budgetColor = Colors.red.shade700;
      budgetIcon = Icons.trending_up;
      budgetMessage =
          'Over budget by ${PriceFormatter.formatPrice(budgetDiff)}';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Award ${request.bidderName ?? "Freelancer"}?',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price Comparison Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price Comparison',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Budget:',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          PriceFormatter.formatPrice(budgetValue),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bid Price:',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          PriceFormatter.formatPrice(bidPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Icon(budgetIcon, color: budgetColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          budgetMessage,
                          style: TextStyle(
                            color: budgetColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Delivery Info
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery: ${request.days} days',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment Deadline Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Required Within 24 Hours',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'After awarding, you have until $formattedDeadline to complete payment.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Work starts only after payment is confirmed.',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // What Happens Next Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStepRow(
                      number: 1,
                      title: 'Award the bid',
                      description: 'Now',
                      isActive: true,
                    ),
                    _buildStepRow(
                      number: 2,
                      title: 'Complete payment',
                      description: 'Within 24 hours',
                      isActive: false,
                    ),
                    _buildStepRow(
                      number: 3,
                      title: 'Work begins',
                      description: 'After payment confirmed',
                      isActive: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Risk Acknowledgment
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'By awarding, you commit to completing payment within 24 hours. '
                        'Failure to pay will cancel this award.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              AppLogger.i(
                'Award dialog cancelled by user',
                tag: 'TaskRequests',
                json: {'requestId': request.id},
              );
              Navigator.pop(ctx, false);
            },
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          ),
          ElevatedButton.icon(
            onPressed: () {
              AppLogger.i(
                'Award dialog confirmed by user',
                tag: 'TaskRequests',
                json: {
                  'requestId': request.id,
                  'bidPrice': bidPrice,
                  'budget': budgetValue,
                },
              );
              Navigator.pop(ctx, true);
            },
            icon: const Icon(Icons.check),
            label: const Text(
              'Award Freelancer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );

    if (confirmed == true) {
      AppLogger.i(
        'Award attempt started',
        tag: 'TaskRequests',
        json: {
          'requestId': request.id,
          'expectedPriceCents': expectedPriceCents,
        },
      );
      await _awardOffer(request, vm, expectedPriceCents: expectedPriceCents);
    }
  }

  /// Build a step row for the "What happens next" section
  Widget _buildStepRow({
    required int number,
    required String title,
    required String description,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? Colors.green.shade800
                        : Colors.grey.shade800,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Award the offer and navigate to payment screen
  Future<void> _awardOffer(
    TaskRequest request,
    TaskRequestsViewModel vm, {
    required int expectedPriceCents,
  }) async {
    setState(() => _isAwarding = true);

    try {
      final result = await vm.award(
        request.id,
        expectedPriceCents: expectedPriceCents,
      );

      if (!mounted) return;
      setState(() => _isAwarding = false);

      if (result != null && result['success'] == true) {
        final paymentDeadline = result['payment_deadline'] != null
            ? DateTime.tryParse(result['payment_deadline'] as String)
            : null;
        final summary = ProposalPaymentSummary(
          requestId: request.id,
          taskId: request.taskId,
          taskTitle: request.taskTitle ?? 'Task',
          freelancerName: request.bidderName ?? 'Freelancer',
          amount: request.price.toDouble(),
          paymentDeadline: paymentDeadline,
        );
        await openProposalPayment(
          context,
          summary: summary,
          launcherSource: 'requests_list',
        );
        if (!mounted) return;
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['error'] ?? 'Failed to award offer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on PriceMismatchException catch (e) {
      if (!mounted) return;
      setState(() => _isAwarding = false);

      // Show price mismatch dialog
      await _showPriceMismatchDialog(e);
    } on OfferAlreadyAcceptedException {
      if (!mounted) return;
      setState(() => _isAwarding = false);

      // Already accepted - refresh and show success
      await vm.loadInitial();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This offer has already been awarded.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Show price mismatch error dialog with refresh option
  Future<void> _showPriceMismatchDialog(PriceMismatchException e) async {
    final expectedDollars = (e.expectedCents / 100).toStringAsFixed(2);
    final actualDollars = (e.actualCents / 100).toStringAsFixed(2);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.price_change, color: Colors.orange, size: 48),
        title: const Text('Offer Updated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The freelancer changed their offer while you were reviewing it.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Old Price:'),
                      Text(
                        '\$$expectedDollars',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('New Price:'),
                      Text(
                        '\$$actualDollars',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please review the new price before awarding.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              // Refresh the list
              final vm = context.read<TaskRequestsViewModel>();
              vm.loadInitial();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Review New Price'),
          ),
        ],
      ),
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
      create: (ctx) {
        final proposalRepo = widget.isOwner
            ? ctx.read<ProposalRepository>()
            : null;
        final c = TaskRequestsViewModel(
          taskId: widget.taskId,
          isOwner: widget.isOwner,
          proposalRepo: proposalRepo,
        );
        c.loadInitial();
        return c;
      },
      builder: (ctx, _) {
        _providerCtx = ctx;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (widget.autoOpenSubmitSheet && !widget.isOwner) {
            final c = ctx.read<TaskRequestsViewModel>();
            await showSubmitRequestSheet(
              ctx,
              taskId: widget.taskId,
              controller: c,
              budget: widget.budget ?? '0',
            );
          }
        });
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
                      onPressed: () {
                        final prov = _providerCtx ?? context;
                        showSubmitRequestSheet(
                          prov,
                          taskId: widget.taskId,
                          controller: c,
                          budget: widget.budget ?? '0',
                        );
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
        final TaskRequest req = filteredItems[index];
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
    final String title = isOwner ? 'No offers yet' : 'No bids on this task';
    final String subtitle = isOwner
        ? 'Share your task to attract more freelancers'
        : 'Be the first to submit a bid and start the conversation';
    final IconData icon = isOwner
        ? Icons.inbox_outlined
        : Icons.local_offer_outlined;

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
                      onPressed: () {
                        AppLogger.d(
                          'Freelancer tapped submit bid CTA',
                          tag: 'TaskRequests',
                        );
                        final prov = _providerCtx ?? context;
                        final vm = context.read<TaskRequestsViewModel>();
                        showSubmitRequestSheet(
                          prov,
                          taskId: widget.taskId,
                          controller: vm,
                          budget: widget.budget ?? '0',
                        );
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
