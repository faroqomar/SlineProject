import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
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
              floatingActionButton: widget.isOwner ? null : FloatingActionButton.extended(
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
      return const Center(child: CircularProgressIndicator());
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
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final TaskRequest req = c.items[index];
        return RequestTile(
          request: req,
          onAccept: c.canActOn(req) ? () => c.accept(req.id) : null,
          onReject: c.canActOn(req) ? () => c.reject(req.id) : null, isOwner: widget.isOwner,
        );
      },
    );
  }
}
