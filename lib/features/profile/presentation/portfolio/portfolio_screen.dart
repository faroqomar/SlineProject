import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/profile/presentation/portfolio/%20sheets/%20add_portfolio_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/portfolio_controller.dart';
import '../../models/portfolio_item.dart';
import 'widgets/portfolio_tile.dart';

/// PortfolioScreen
/// Hosts the controller/provider scope, grid, refresh, infinite scroll,
/// and opens bottom-sheets for add/details/edit.
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key, this.ownerId});
  final String? ownerId;

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final ScrollController _scroll = ScrollController();
  bool _bootstrapped = false; // ensure first load once
  PortfolioController? _ctrlRef; // controller reference for listeners

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final ctrl = _ctrlRef;
    if (ctrl == null) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 160) {
      if (ctrl.hasMore && !ctrl.loadingMore) {
        ctrl.loadMore();
      }
    }
  }

  Future<void> _reload() async {
    final ctrl = _ctrlRef;
    if (ctrl == null) return;
    await ctrl.load(ownerId: widget.ownerId);
  }

  void _openAddSheet() {
    final ctrl = _ctrlRef;
    if (ctrl == null) return;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => AddPortfolioSheet(
        controller: ctrl,
        onCreated: () {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Portfolio item added')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PortfolioController>(
      create: (_) => PortfolioController(client: Supabase.instance.client),
      child: Consumer<PortfolioController>(
        builder: (context, ctrl, _) {
          // capture controller reference for listeners/callbacks
          _ctrlRef = ctrl;

          // first bootstrap load under provider context
          if (!_bootstrapped) {
            _bootstrapped = true;
            Future.microtask(() {
              context.read<PortfolioController>().load(ownerId: widget.ownerId);
            });
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('My Portfolio'),
              actions: [
                if (ctrl.error != null)
                  IconButton(
                    tooltip: 'Retry',
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _reload,
              child: _buildBody(context, ctrl),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _openAddSheet,
              tooltip: 'Add item',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, PortfolioController ctrl) {
    if (ctrl.initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (ctrl.error != null) {
      return Center(child: Text('Failed to load: ${ctrl.error}'));
    }
    if (ctrl.items.isEmpty) {
      return const _EmptyState();
    }

    final items = ctrl.items;
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: items.length + (ctrl.loadingMore ? 2 : 0),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return const _LoadingTile();
              }
              final PortfolioItem item = items[index];
              return PortfolioTile(
                item: item,
                controller: ctrl,
                onLongPress: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete item?'),
                      content: const Text('This will remove the portfolio entry.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await ctrl.deleteItem(item.id);
                    messenger.showSnackBar(
                      SnackBar(content: Text(success ? 'Deleted' : 'Delete failed: ${ctrl.error ?? ''}')),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            const Text('No portfolio items yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first work sample.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}