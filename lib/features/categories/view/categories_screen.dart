import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/categories/viewmodels/categories_view_model.dart';

/// CategoriesScreen — Phase 7 Redesign
///
/// A browsable, searchable grid of service categories. Uses a 2-column
/// [GridView] with design-token-driven category cards, skeleton loading,
/// and accessible empty/error states.
///
/// MVVM pattern: this screen is a StatefulWidget that owns the
/// [CategoriesViewModel] and provides it to the tree via
/// [ChangeNotifierProvider]. The inner [_CategoriesView] consumes the VM
/// with [context.watch] and renders the appropriate state.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final CategoriesViewModel _vm;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = CategoriesViewModel();
    // Initial load without search filter
    _vm.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CategoriesViewModel>.value(
      value: _vm,
      child: const _CategoriesView(),
    );
  }
}

/// Internal stateless view that rebuilds when [CategoriesViewModel] notifies.
///
/// Renders four visual states: loading skeleton grid, populated category grid,
/// empty state with icon + message, and error state with retry button.
class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  /// Number of columns in the category grid.
  static const int _gridColumns = 2;

  /// Cross-axis spacing between grid cells.
  static const double _gridCrossSpacing = 12;

  /// Main-axis spacing between grid cells.
  static const double _gridMainSpacing = 12;

  /// Aspect ratio for grid children (width / height).
  static const double _childAspectRatio = 1.2;

  /// Number of skeleton tiles shown during loading.
  static const int _skeletonCount = 6;

  /// Horizontal padding applied to all grid content.
  static const EdgeInsets _contentPadding = EdgeInsets.symmetric(
    horizontal: AppDimens.p24,
  );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoriesViewModel>();
    final amber = context.amberColors;

    return Scaffold(
      backgroundColor: amber.page,
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: amber.page,
        foregroundColor: amber.text,
        surfaceTintColor: AmberDuskColors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: CustomScrollView(
          slivers: [
            // -- Search field --
            SliverToBoxAdapter(
              child: Padding(
                padding: _contentPadding.copyWith(
                  top: AppDimens.p16,
                  bottom: AppDimens.p16,
                ),
                child: AppTextField(
                  hintText: 'Search categories',
                  prefixIcon: const Icon(Icons.search),
                  onChanged: vm.setSearchQuery,
                ),
              ),
            ),

            // -- Content area: loading / error / empty / grid --
            if (vm.isLoading)
              _buildLoadingSkeleton()
            else if (vm.error != null)
              _buildErrorState(context, vm)
            else if (vm.items.isEmpty)
              _buildEmptyState(context)
            else
              _buildCategoryGrid(context, vm),
          ],
        ),
      ),
    );
  }

  /// Builds a 2-column grid of [SkeletonCategoryTile] placeholders.
  ///
  /// Uses [SliverPadding] + [SliverGrid] to match the real grid layout
  /// so the transition from loading to loaded is visually seamless.
  Widget _buildLoadingSkeleton() {
    return SliverPadding(
      padding: _contentPadding,
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridColumns,
          crossAxisSpacing: _gridCrossSpacing,
          mainAxisSpacing: _gridMainSpacing,
          childAspectRatio: _childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, __) => const SkeletonCategoryTile(),
          childCount: _skeletonCount,
        ),
      ),
    );
  }

  /// Builds the error state with a danger icon, message, and retry button.
  ///
  /// Wrapped in [Semantics] for accessibility: screen readers announce
  /// the error context before the retry action.
  Widget _buildErrorState(BuildContext context, CategoriesViewModel vm) {
    final colorScheme = context.colorScheme;
    final amber = context.amberColors;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Semantics(
        label: 'Error loading categories. ${vm.error}',
        child: Center(
          child: Padding(
            padding: _contentPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Danger icon circle uses the Amber Dusk muted danger wash.
                Container(
                  width: AppDimens.p80,
                  height: AppDimens.p80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: amber.dangerMuted,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: AppDimens.p48,
                    color: amber.danger,
                  ),
                ),

                const SizedBox(height: AppDimens.p16),

                // Error message
                Text(
                  vm.error!,
                  style: AppTypography.h5.copyWith(color: colorScheme.text),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimens.p24),

                // Retry button
                ElevatedButton(
                  onPressed: vm.refresh,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the empty state with an informational icon, heading, and hint.
  ///
  /// Wrapped in [Semantics] so assistive technologies can convey
  /// the empty result to users.
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amber = context.amberColors;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Semantics(
        label: 'No categories found. Try a different search term.',
        child: Center(
          child: Padding(
            padding: _contentPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon circle uses the Amber Dusk active-state wash.
                Container(
                  width: AppDimens.p80,
                  height: AppDimens.p80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: amber.activeGlow,
                  ),
                  child: Icon(
                    Icons.category,
                    size: AppDimens.p48,
                    color: amber.primary,
                  ),
                ),

                const SizedBox(height: AppDimens.p16),

                // Heading
                Text(
                  'No categories found',
                  style: AppTypography.h5.copyWith(color: colorScheme.text),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimens.p8),

                // Hint
                Text(
                  'Try a different search term',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the main 2-column grid of category cards.
  ///
  /// Each card is wrapped in [ScaleButton] for a tactile press effect
  /// with haptic feedback via [AppInteractionStates.hapticTap].
  Widget _buildCategoryGrid(BuildContext context, CategoriesViewModel vm) {
    return SliverPadding(
      padding: _contentPadding.copyWith(bottom: AppDimens.p24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridColumns,
          crossAxisSpacing: _gridCrossSpacing,
          mainAxisSpacing: _gridMainSpacing,
          childAspectRatio: _childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final category = vm.items[index];
          return _CategoryCard(
            name: category.name,
            onTap: () {
              AppLogger.i(
                'CategoriesScreen: tapped category "${category.name}" '
                '(id=${category.id})',
              );
            },
          );
        }, childCount: vm.items.length),
      ),
    );
  }
}

/// A single category card for the grid.
///
/// Displays an icon circle (with a deterministic color derived from the
/// category name), the category name in [AppTypography.captionBold],
/// and is wrapped in [ScaleButton] for press feedback.
///
/// The accent role is picked from existing Amber Dusk semantic tokens using
/// the name hash, giving each category a distinct but token-owned treatment.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.name, required this.onTap});

  /// Display name of the category.
  final String name;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Maps a category name to one of the Amber Dusk semantic accent colors.
  ///
  /// Uses bitmask (& 0x7fffffff) instead of .abs() to avoid overflow
  /// when hashCode == int.minValue (where .abs() returns negative).
  Color _colorForName(AmberDuskColorScheme amber, String name) {
    final categoryColors = [
      amber.primary,
      amber.amber,
      amber.forest,
      amber.star,
      amber.info,
      amber.rust,
    ];
    final index = (name.hashCode & 0x7fffffff) % categoryColors.length;
    return categoryColors[index];
  }

  /// Maps a category name to a deterministic icon from a curated set.
  ///
  /// Uses bitmask (& 0x7fffffff) instead of .abs() to avoid overflow
  /// when hashCode == int.minValue.
  IconData _iconForName(String name) {
    const icons = [
      Icons.design_services_outlined,
      Icons.code_outlined,
      Icons.brush_outlined,
      Icons.campaign_outlined,
      Icons.translate_outlined,
      Icons.videocam_outlined,
      Icons.music_note_outlined,
      Icons.analytics_outlined,
      Icons.build_outlined,
      Icons.school_outlined,
    ];
    return icons[(name.hashCode & 0x7fffffff) % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amber = context.amberColors;
    final categoryColor = _colorForName(amber, name);
    final categoryIcon = _iconForName(name);

    return Semantics(
      button: true,
      label: '$name category',
      onTap: onTap,
      // ExcludeSemantics prevents ScaleButton's own Semantics(button:true) node
      // from nesting inside the outer Semantics node declared above, which
      // would cause screen readers to announce the button role twice.
      child: ExcludeSemantics(
        child: ScaleButton(
          onPressed: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: BorderRadius.circular(AppDimens.r16),
              border: Border.all(color: colorScheme.cardBorder),
              boxShadow: AppDecorations.elevation(
                1,
                isDark: colorScheme.isDark,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon circle — 40px diameter with token-owned accent color.
                Container(
                  width: AppDimens.p40,
                  height: AppDimens.p40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Amber overlay keeps the icon well inside the staged
                    // palette while foreground color varies by category role.
                    color: amber.activeGlow,
                  ),
                  child: Icon(
                    categoryIcon,
                    size: AppDimens.p22,
                    color: categoryColor,
                  ),
                ),

                const SizedBox(height: AppDimens.p8),

                // Category name — captionBold, centered, single line with ellipsis
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.p8),
                  child: Text(
                    name,
                    style: AppTypography.captionBold.copyWith(
                      color: colorScheme.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
