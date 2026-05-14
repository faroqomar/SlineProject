import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/portfolio/view/sheets/add_portfolio_sheet.dart';
import 'package:sline_app/features/portfolio/view/widgets/portfolio_tile.dart';
import 'package:sline_app/features/portfolio/viewmodels/portfolio_view_model.dart';

/// PortfolioScreen
/// Hosts the controller/provider scope, grid, refresh, infinite scroll,
/// and opens bottom-sheets for add/details/edit.
///
/// MVVM Compliant: Uses PortfolioViewModel through Provider pattern.
/// Data access remains behind the ViewModel/repository boundary.
class PortfolioScreen extends StatefulWidget {
  /// Creates a portfolio route, optionally scoped to a public owner.
  const PortfolioScreen({super.key, this.ownerId});

  /// Owner profile id for public portfolio views; null means current user.
  final String? ownerId;

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final ScrollController _scroll = ScrollController();
  bool _bootstrapped = false; // ensure first load once
  PortfolioViewModel? _ctrlRef; // controller reference for listeners
  bool _isAddSheetOpen = false;

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
        unawaited(ctrl.loadMore());
      }
    }
  }

  Future<void> _reload() async {
    final ctrl = _ctrlRef;
    if (ctrl == null) {
      AppLogger.w(
        'Reload called but controller is null',
        tag: 'PortfolioScreen',
      );
      return;
    }
    AppLogger.i('Reloading portfolio', tag: 'PortfolioScreen');
    await ctrl.load(ownerId: widget.ownerId);
  }

  void _openAddSheet() {
    if (_isAddSheetOpen) {
      AppLogger.d(
        'Add portfolio sheet open request ignored because one is active',
        tag: 'PortfolioScreen',
      );
      return;
    }
    final ctrl = _ctrlRef;
    if (ctrl == null) {
      AppLogger.w(
        'Cannot open add sheet - controller is null',
        tag: 'PortfolioScreen',
      );
      return;
    }
    setState(() => _isAddSheetOpen = true);
    AppLogger.d('Opening add portfolio sheet', tag: 'PortfolioScreen');
    unawaited(
      showModalBottomSheet(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        barrierColor: context.amberColors.scrim,
        backgroundColor: AmberDuskTokens.colors.transparent,
        builder: (ctx) => _InsetSheetFrame(
          child: AddPortfolioSheet(
            controller: ctrl,
            onCreated: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Portfolio item added')),
              );
              AppLogger.i(
                'Portfolio item added via sheet',
                tag: 'PortfolioScreen',
              );
            },
          ),
        ),
      ).whenComplete(() {
        if (!mounted) return;
        setState(() => _isAddSheetOpen = false);
        AppLogger.d('Add portfolio sheet closed', tag: 'PortfolioScreen');
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PortfolioViewModel>(
      // MVVM boundary: the ViewModel creates its repository internally.
      // The view stays data-source agnostic.
      create: (ctx) {
        AppLogger.d(
          'Creating PortfolioViewModel from PortfolioScreen',
          tag: 'PortfolioScreen',
        );
        return PortfolioViewModel();
      },
      child: Consumer<PortfolioViewModel>(
        builder: (context, ctrl, _) {
          // capture controller reference for listeners/callbacks
          _ctrlRef = ctrl;

          // first bootstrap load under provider context
          if (!_bootstrapped) {
            _bootstrapped = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppLogger.i(
                'Bootstrapping portfolio load',
                tag: 'PortfolioScreen',
                json: {'ownerId': widget.ownerId},
              );
              unawaited(ctrl.load(ownerId: widget.ownerId));
            });
          }

          return Scaffold(
            backgroundColor: context.colorScheme.phoneBackground,
            appBar: AppBar(
              title: Text(
                'My Portfolio',
                style: AppTypography.h3.copyWith(
                  color: context.colorScheme.text,
                ),
              ),
              backgroundColor: context.colorScheme.phoneBackground,
              elevation: 0,
              actions: [
                if (ctrl.error != null)
                  IconButton(
                    tooltip: 'Retry',
                    onPressed: _reload,
                    icon: Icon(Icons.refresh, color: context.colorScheme.text),
                  ),
              ],
            ),
            body: RefreshIndicator(
              color: context.amberColors.primary,
              backgroundColor: context.colorScheme.cardBackground,
              onRefresh: _reload,
              child: _buildBody(context, ctrl),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _openAddSheet,
              tooltip: 'Add item',
              backgroundColor: context.amberColors.primary,
              foregroundColor: context.amberColors.textInverse,
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, PortfolioViewModel ctrl) {
    if (ctrl.initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (ctrl.error != null) {
      AppLogger.w(
        'Portfolio error state: ${ctrl.error}',
        tag: 'PortfolioScreen',
      );
      return const _ErrorState();
    }
    if (ctrl.items.isEmpty) {
      return const _EmptyState();
    }

    final items = ctrl.items;
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppDimens.p12),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppDimens.p12,
              mainAxisSpacing: AppDimens.p12,
              childAspectRatio: 0.9,
            ),
            itemCount: items.length + (ctrl.loadingMore ? 2 : 0),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return const _LoadingTile();
              }
              final item = items[index];
              return PortfolioTile(
                item: item,
                controller: ctrl,
                onLongPress: () async {
                  AppLogger.d(
                    'Long press on portfolio item',
                    tag: 'PortfolioScreen',
                    json: {'itemId': item.id, 'title': item.title},
                  );
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await showDialog<bool>(
                    context: context,
                    barrierColor: context.amberColors.scrim,
                    builder: (ctx) {
                      final dialogColors = ctx.colorScheme;
                      final amberColors = ctx.amberColors;
                      return AlertDialog(
                        backgroundColor: dialogColors.cardBackground,
                        title: Text(
                          'Delete item?',
                          style: AppTypography.h5.copyWith(
                            color: dialogColors.text,
                          ),
                        ),
                        content: Text(
                          'This will remove the portfolio entry.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: dialogColors.textSecondary,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: amberColors.dangerMuted,
                              foregroundColor: amberColors.text,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                  if (ok ?? false) {
                    AppLogger.i(
                      'User confirmed delete',
                      tag: 'PortfolioScreen',
                      json: {'itemId': item.id},
                    );
                    final success = await ctrl.deleteItem(item.id);
                    if (success) {
                      AppLogger.i(
                        'Item deleted successfully',
                        tag: 'PortfolioScreen',
                      );
                    } else {
                      AppLogger.w('Item delete failed', tag: 'PortfolioScreen');
                    }
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Deleted successfully'
                              : 'Delete failed. Please try again.',
                        ),
                      ),
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

/// Centered error state for portfolio load failures.
///
/// The text stays deliberately generic because detailed repository errors are
/// already mapped and logged by [PortfolioViewModel].
class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amberColors = context.amberColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: AppCardContainer(
          padding: const EdgeInsets.all(AppDimens.p20),
          borderRadius: BorderRadius.circular(AmberDuskTokens.spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: AppLayout.iconFeature,
                color: amberColors.danger,
              ),
              const SizedBox(height: AppDimens.p16),
              Text(
                'Failed to load portfolio',
                style: AppTypography.h5.copyWith(color: colorScheme.text),
              ),
              const SizedBox(height: AppDimens.p8),
              Text(
                'Please try again by pulling down to refresh.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
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

/// Empty portfolio proof state.
///
/// This mirrors the Amber Dusk profile rule that portfolio surfaces should be
/// compact proof tiles instead of oversized blank cards.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amberColors = context.amberColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.p24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: AppLayout.iconFeature,
              color: amberColors.primary,
            ),
            const SizedBox(height: AppDimens.p12),
            Text(
              'No portfolio items yet',
              style: AppTypography.h6.copyWith(color: colorScheme.text),
            ),
            const SizedBox(height: AppDimens.p8),
            Text(
              'Tap the + button to add your first work sample.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inset frame for portfolio bottom sheets.
///
/// Open Design uses a rounded sheet lifted away from the phone edges. The sheet
/// remains solid material here to respect the no-glass rule.
class _InsetSheetFrame extends StatelessWidget {
  const _InsetSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sheetRecipe = AmberDuskTokens.surfaces.sheet;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p10,
        AppDimens.p0,
        AppDimens.p10,
        AppDimens.p10,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: sheetRecipe.fill,
          borderRadius: BorderRadius.circular(sheetRecipe.radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

/// Loading-more placeholder that keeps the two-column grid stable.
class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    return AppCardContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(cardTheme.panel.radius),
      elevation: cardTheme.panel.elevationLevel,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
