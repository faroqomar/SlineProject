import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/auth/viewmodels/auth_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/tasks/view/tender_payment_screen.dart';
import 'widgets/request_tile.dart';
import 'submit_request_sheet.dart';

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

  /// Show award confirmation dialog (Step 1: Award without payment)
  Future<void> _showAwardDialog(TaskRequest request, TaskRequestsViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Award this freelancer?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to award ${request.bidderName ?? "this freelancer"}'),
            const SizedBox(height: 8),
            Text(
              'Price: ${PriceFormatter.formatPrice(request.price.toDouble())}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Delivery: ${request.days} days'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Step: Complete Payment',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'After awarding, you will have 24 hours to complete payment. '
                    'Work starts only after payment is confirmed.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Award'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _awardOffer(request, vm);
    }
  }

  /// Award the offer and navigate to payment screen
  Future<void> _awardOffer(TaskRequest request, TaskRequestsViewModel vm) async {
    setState(() => _isAwarding = true);

    final result = await vm.award(request.id);

    setState(() => _isAwarding = false);

    if (result != null && result['success'] == true) {
      // Navigate to payment screen
      if (mounted) {
        final clientId = context.read<AuthViewModel>().currentUserId ?? '';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TenderPaymentScreen(
              requestId: request.id,
              taskId: request.taskId,
              taskTitle: widget.taskId, // We should get this from somewhere
              freelancerName: request.bidderName ?? 'Freelancer',
              amount: request.price.toDouble(),
              paymentDeadline: DateTime.parse(result['payment_deadline'] as String),
              clientId: clientId,
            ),
          ),
        );
      }
    } else {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['error'] ?? 'Failed to award offer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      create: (_) {
        final c = TaskRequestsViewModel(
          taskId: widget.taskId,
          isOwner: widget.isOwner,
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
            return Scaffold(
              appBar: AppBar(title: const Text('Offers')),
              body: RefreshIndicator(
                onRefresh: () async => c.loadInitial(),
                child: _buildBody(c),
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

  Widget _buildBody(TaskRequestsViewModel c) {
    if (c.isLoadingInitial) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: 5,
        itemBuilder: (_, __) => const SkeletonOfferCard(),
      );
    }
    if (c.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(c.errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }
    if (c.items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No offers yet')),
        ],
      );
    }
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: c.items.length + (c.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= c.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: SkeletonOfferCard(),
          );
        }
        final TaskRequest req = c.items[index];
        return RequestTile(
          request: req,
          onAccept: c.canActOn(req) && !_isAwarding
              ? () => _showAwardDialog(req, c)
              : null,
          onReject: c.canActOn(req) && !_isAwarding
              ? () => c.reject(req.id)
              : null,
          isOwner: widget.isOwner,
          isLoading: _isAwarding,
        );
      },
    );
  }
}
