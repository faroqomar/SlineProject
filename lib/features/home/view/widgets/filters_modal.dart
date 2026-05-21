import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

/// Filters modal shown as a draggable bottom sheet from the HomeScreen.
///
/// Allows users to set sort order, budget range, delivery time, and seller
/// level filters before applying them to the task feed. The route owns the
/// modal sheet; this widget owns one surface, one handle, and one scroll body.
/// All filter state is local until the user taps "Apply Filters", at which
/// point it is pushed to [TaskFilterViewModel].
class FiltersModal extends StatefulWidget {
  const FiltersModal({super.key});

  static const Key resetButtonKey = ValueKey<String>('filters_reset_button');
  static const Key applyButtonKey = ValueKey<String>('filters_apply_button');
  static const Key sheetHandleKey = ValueKey<String>('filters_sheet_handle');

  @override
  State<FiltersModal> createState() => _FiltersModalState();
}

class _FiltersModalState extends State<FiltersModal> {
  static const double _defaultMaxBudgetDraft = 1000;
  static const double _maxBudgetLimit = 5000;

  // Local state for the form before applying
  String _sortBy = TaskFilterViewModel.sortRelevance;
  double _maxBudget = _defaultMaxBudgetDraft;
  bool _hasMaxBudgetFilter = false;
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();
  final List<String> _deliveryTimes = [];
  final List<String> _sellerLevels = [];

  @override
  void initState() {
    super.initState();
    // Initialize local state from ViewModel so existing filters are reflected
    final vm = context.read<TaskFilterViewModel>();
    _sortBy = vm.sortBy;
    _maxBudget = vm.maxBudget ?? _defaultMaxBudgetDraft;
    _hasMaxBudgetFilter = vm.maxBudget != null;
    _minBudgetController.text = vm.minBudget?.toInt().toString() ?? '';
    _maxBudgetController.text = vm.maxBudget?.toInt().toString() ?? '';
    _deliveryTimes.addAll(vm.deliveryTimes);
    _sellerLevels.addAll(vm.sellerLevels);
  }

  @override
  void dispose() {
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

  /// Counts the number of active (non-default) filters to show in the
  /// apply button label so users know how many changes they are committing.
  int get _activeFilterCount {
    var count = 0;
    // Sort — default is Relevance
    if (_sortBy != TaskFilterViewModel.sortRelevance) count++;
    // Min budget — default is empty.
    if (_minBudgetController.text.trim().isNotEmpty) count++;
    // Max budget — default slider position is only a draft display value.
    if (_hasMaxBudgetFilter) count++;
    // Each selected delivery time counts as one filter
    count += _deliveryTimes.length;
    // Each selected seller level counts as one filter
    count += _sellerLevels.length;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final amberColors = _amberColors;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final sheetRecipe = AmberDuskTokens.surfaces.sheet;

    // Wrap in Semantics so screen readers announce the panel purpose
    return Semantics(
      label: 'Filters panel',
      child: FractionallySizedBox(
        alignment: Alignment.bottomCenter,
        heightFactor: 0.86,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: sheetRecipe.fill,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(sheetRecipe.radius),
            ),
            boxShadow: AppDecorations.elevation(
              sheetRecipe.elevationLevel,
              isDark: amberColors.isDark,
            ),
          ),
          child: Column(
            children: [
              _buildSheetHandle(amberColors),
              _buildHeader(amberColors),

              // --- Scrollable filter sections ---
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p24,
                    vertical: AppDimens.p12,
                  ),
                  children: [
                    _buildSortBySection(),
                    const SizedBox(height: AppDimens.p16),
                    _buildBudgetRangeSection(),
                    const SizedBox(height: AppDimens.p16),
                    _buildDeliveryTimeSection(),
                    const SizedBox(height: AppDimens.p16),
                    _buildSellerLevelSection(),
                    // Extra padding keeps the final seller-level row clear of
                    // the fixed apply area on short devices.
                    const SizedBox(height: AppDimens.p32),
                  ],
                ),
              ),

              // --- Apply Button (fixed at bottom) ---
              Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: _buildApplyButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section builders — extracted for readability and maintainability
  // ---------------------------------------------------------------------------

  AmberDuskColorScheme get _amberColors => context.amberColors;

  /// Builds the visible drag handle for the single bottom-sheet surface.
  Widget _buildSheetHandle(AmberDuskColorScheme amberColors) {
    return Container(
      key: FiltersModal.sheetHandleKey,
      width: AppDimens.p40,
      height: AppDimens.p4,
      margin: const EdgeInsets.only(
        top: AppDimens.p12,
        bottom: AppDimens.p8,
      ),
      decoration: BoxDecoration(
        // A raised neutral handle makes the sheet affordance visible without
        // reintroducing the old glass/blur treatment.
        color: amberColors.surfaceHighest,
        borderRadius: BorderRadius.circular(AppDimens.r50),
      ),
    );
  }

  /// Builds the fixed header with active-filter context and reset action.
  Widget _buildHeader(AmberDuskColorScheme amberColors) {
    final activeFilterCount = _activeFilterCount;
    final activeLabel = activeFilterCount == 0
        ? 'No filters active'
        : activeFilterCount == 1
        ? '1 filter active'
        : '$activeFilterCount filters active';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p24,
        AppDimens.p4,
        AppDimens.p24,
        AppDimens.p12,
      ),
      child: Row(
        children: [
          _FilterIconBadge(
            icon: Icons.tune,
            foreground: amberColors.primary,
            background: amberColors.infoMuted,
          ),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: AmberDuskTokens.typography.sectionTitle.copyWith(
                    color: amberColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppDimens.p2),
                Text(
                  activeLabel,
                  style: AmberDuskTokens.typography.bodySmall.copyWith(
                    color: activeFilterCount == 0
                        ? amberColors.muted
                        : amberColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.p12),
          // Reset only mutates local state. Users commit the cleared state with
          // Apply so accidental taps do not immediately alter the feed.
          TextButton(
            key: FiltersModal.resetButtonKey,
            style: TextButton.styleFrom(
              minimumSize: const Size(
                AppDimens.touchTarget,
                AppDimens.touchTarget,
              ),
              foregroundColor: amberColors.primary,
            ),
            onPressed: _resetLocalFilters,
            child: Text(
              'Reset',
              style: AppTypography.captionBold.copyWith(
                color: amberColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Restores the local draft filters to their defaults without committing.
  void _resetLocalFilters() {
    AppInteractionStates.hapticTap();
    AppLogger.d('home_filters_reset', tag: 'FiltersModal');
    setState(() {
      _sortBy = TaskFilterViewModel.sortRelevance;
      _maxBudget = _defaultMaxBudgetDraft;
      _hasMaxBudgetFilter = false;
      _minBudgetController.clear();
      _maxBudgetController.clear();
      _deliveryTimes.clear();
      _sellerLevels.clear();
    });
  }

  /// Builds the "Sort By" chip group.
  /// Uses Amber Dusk section typography for the section header.
  Widget _buildSortBySection() {
    return _FilterSection(
      icon: Icons.swap_vert,
      title: 'Sort By',
      subtitle: 'Choose how the feed should rank work.',
      child: Wrap(
        spacing: AppDimens.p8,
        runSpacing: AppDimens.p8,
        children:
            [
              TaskFilterViewModel.sortRelevance,
              TaskFilterViewModel.sortNewest,
              TaskFilterViewModel.sortPriceLowToHigh,
              TaskFilterViewModel.sortPriceHighToLow,
            ].map((sort) {
              final isSelected = _sortBy == sort;
              return _SelectableFilterPill(
                label: sort,
                icon: _sortIcon(sort),
                isSelected: isSelected,
                onTap: () {
                  AppInteractionStates.hapticSelection();
                  setState(() => _sortBy = sort);
                },
              );
            }).toList(),
      ),
    );
  }

  /// Builds the "Budget Range" section with a slider and min/max text fields.
  /// The slider uses design-system primary/secondary tokens instead of
  /// hardcoded colors so it adapts to theme changes automatically.
  Widget _buildBudgetRangeSection() {
    final amberColors = _amberColors;
    return _FilterSection(
      icon: Icons.payments_outlined,
      title: 'Budget Range',
      subtitle: 'Set the IQD window that matches your buying intent.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.p14,
              AppDimens.p12,
              AppDimens.p14,
              AppDimens.p8,
            ),
            decoration: BoxDecoration(
              color: amberColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppDimens.r18),
              border: Border.all(color: amberColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Up to',
                      style: AmberDuskTokens.typography.bodySmall.copyWith(
                        color: amberColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppDimens.p8),
                    Text(
                      _hasMaxBudgetFilter ? '${_maxBudget.round()} IQD' : 'Any',
                      style: AmberDuskTokens.typography.bookingName.copyWith(
                        color: amberColors.primary,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: AppDimens.p6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: AppDimens.p12,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: AppDimens.p20,
                    ),
                  ),
                  child: Slider(
                    value: _maxBudget.clamp(0, _maxBudgetLimit),
                    max: _maxBudgetLimit,
                    activeColor: amberColors.primary,
                    inactiveColor: amberColors.surfaceHighest,
                    onChanged: (value) => setState(() {
                      _maxBudget = value;
                      _hasMaxBudgetFilter = true;
                      _maxBudgetController.text = value.toInt().toString();
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.p12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  labelText: 'Minimum',
                  hintText: 'Min',
                  controller: _minBudgetController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const _CurrencyPrefix(),
                  onChanged: (_) {
                    // Rebuild so the active-filter count follows direct input.
                    setState(() {});
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.p10),
                child: Text(
                  'to',
                  style: AmberDuskTokens.typography.chip.copyWith(
                    color: amberColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: AppTextField(
                  labelText: 'Maximum',
                  hintText: 'Max',
                  controller: _maxBudgetController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const _CurrencyPrefix(),
                  onChanged: (value) {
                    final parsedValue = double.tryParse(value);
                    if (value.trim().isEmpty) {
                      setState(() {
                        _hasMaxBudgetFilter = false;
                        _maxBudget = _defaultMaxBudgetDraft;
                      });
                      return;
                    }
                    // Clamp to slider range so text input and slider stay in
                    // sync even when users paste a large number.
                    if (parsedValue != null) {
                      setState(
                        () {
                          _hasMaxBudgetFilter = true;
                          _maxBudget = parsedValue.clamp(
                            0.0,
                            _maxBudgetLimit,
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the "Delivery Time" chip wrap section.
  /// Each chip triggers haptic feedback on tap for consistent tactile response.
  Widget _buildDeliveryTimeSection() {
    return _FilterSection(
      icon: Icons.schedule,
      title: 'Delivery Time',
      subtitle: 'Prioritize posts by urgency and deadline fit.',
      child: Wrap(
        spacing: AppDimens.p8,
        runSpacing: AppDimens.p8,
        children: TaskFilterViewModel.deliveryTimeOptions.map((time) {
          final isSelected = _deliveryTimes.contains(time);
          return _SelectableFilterPill(
            label: time,
            icon: _deliveryIcon(time),
            isSelected: isSelected,
            onTap: () {
              AppInteractionStates.hapticSelection();
              setState(() {
                if (isSelected) {
                  _deliveryTimes.remove(time);
                } else {
                  _deliveryTimes.add(time);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  /// Builds the "Seller Level" list section.
  /// Each tile triggers haptic feedback on tap and highlights the selected
  /// levels using a subtle Amber Dusk primary wash.
  Widget _buildSellerLevelSection() {
    return _FilterSection(
      icon: Icons.verified_outlined,
      title: 'Seller Level',
      subtitle: 'Filter booking posts by provider proof and track record.',
      child: Column(
        children: TaskFilterViewModel.sellerLevelOptions.map((level) {
          final isSelected = _sellerLevels.contains(level);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.p8),
            child: _SellerLevelTile(
              label: level,
              description: _sellerLevelDescription(level),
              icon: _sellerLevelIcon(level),
              isSelected: isSelected,
              onTap: () {
                AppInteractionStates.hapticSelection();
                setState(() {
                  if (isSelected) {
                    _sellerLevels.remove(level);
                  } else {
                    _sellerLevels.add(level);
                  }
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Returns a compact icon for each sort option so the chips are scannable.
  IconData _sortIcon(String sort) {
    return switch (sort) {
      TaskFilterViewModel.sortNewest => Icons.fiber_new_outlined,
      TaskFilterViewModel.sortPriceLowToHigh => Icons.south_east,
      TaskFilterViewModel.sortPriceHighToLow => Icons.north_east,
      _ => Icons.auto_awesome_outlined,
    };
  }

  /// Returns an urgency icon for each delivery-time filter bucket.
  IconData _deliveryIcon(String deliveryTime) {
    return switch (deliveryTime) {
      TaskFilterViewModel.deliveryUpTo24h => Icons.flash_on_outlined,
      TaskFilterViewModel.deliveryUpTo3Days => Icons.av_timer,
      TaskFilterViewModel.deliveryUpTo7Days => Icons.date_range,
      _ => Icons.all_inclusive,
    };
  }

  /// Returns a proof icon for each seller-level filter bucket.
  IconData _sellerLevelIcon(String sellerLevel) {
    return switch (sellerLevel) {
      TaskFilterViewModel.sellerTopRated => Icons.workspace_premium_outlined,
      TaskFilterViewModel.sellerLevel2 => Icons.military_tech_outlined,
      TaskFilterViewModel.sellerLevel1 => Icons.badge_outlined,
      _ => Icons.person_add_alt_1_outlined,
    };
  }

  /// Returns short helper copy that makes seller-level filters recognizable.
  String _sellerLevelDescription(String sellerLevel) {
    return switch (sellerLevel) {
      TaskFilterViewModel.sellerTopRated => 'High trust and repeat delivery',
      TaskFilterViewModel.sellerLevel2 => 'Experienced marketplace providers',
      TaskFilterViewModel.sellerLevel1 => 'Verified rising providers',
      _ => 'Fresh providers building proof',
    };
  }

  /// Builds the fixed "Apply Filters" button at the sheet bottom.
  /// Shows the count of active (non-default) filters so users know how many
  /// changes they are about to commit — "Apply Filters" when 0, otherwise
  /// "Apply N Filters".
  Widget _buildApplyButton() {
    final count = _activeFilterCount;
    // Singular/plural: "Apply 1 Filter" vs "Apply N Filters"
    final label = count == 0
        ? 'Apply Filters'
        : count == 1
        ? 'Apply 1 Filter'
        : 'Apply $count Filters';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p24,
        AppDimens.p10,
        AppDimens.p24,
        AppDimens.p16,
      ),
      child: AppButton(
        key: FiltersModal.applyButtonKey,
        text: label,
        onPressed: () {
          // Log applied filters for analytics/debugging
          AppLogger.d(
            'home_filters_applied',
            tag: 'FiltersModal',
            json: {'filter_count': _activeFilterCount},
          );
          final minBudget = double.tryParse(_minBudgetController.text.trim());
          final maxBudget = _hasMaxBudgetFilter
              ? double.tryParse(_maxBudgetController.text.trim())
              : null;
          context.read<TaskFilterViewModel>().applyAdvancedFilters(
            minBudget: minBudget,
            maxBudget: maxBudget,
            deliveryTimes: _deliveryTimes,
            sellerLevels: _sellerLevels,
            sortBy: _sortBy,
          );
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Compact non-interactive IQD prefix for budget fields.
///
/// The filter sheet uses IQD to match marketplace pricing and avoid mixing
/// currencies with the rest of the Amber Dusk task feed.
class _CurrencyPrefix extends StatelessWidget {
  const _CurrencyPrefix();

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;
    return Padding(
      padding: const EdgeInsets.only(left: AppDimens.p12, right: AppDimens.p8),
      child: Text(
        'IQD',
        style: AmberDuskTokens.typography.chip.copyWith(
          color: amberColors.muted,
        ),
      ),
    );
  }
}

/// Reusable section shell for visually grouped filter controls.
///
/// The sheet uses one material surface, so this container groups related
/// controls with spacing, iconography, and copy instead of nested modal cards.
class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;

    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: amberColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.r20),
        border: Border.all(color: amberColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilterIconBadge(
                icon: icon,
                foreground: amberColors.primary,
                background: amberColors.infoMuted,
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AmberDuskTokens.typography.sectionTitle.copyWith(
                        color: amberColors.text,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p4),
                    Text(
                      subtitle,
                      style: AmberDuskTokens.typography.bodySmall.copyWith(
                        color: amberColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p14),
          child,
        ],
      ),
    );
  }
}

/// Compact icon well used by the sheet header and section titles.
///
/// Icon wells give the filter panel a stronger visual map while preserving the
/// Amber Dusk solid-surface language.
class _FilterIconBadge extends StatelessWidget {
  const _FilterIconBadge({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimens.p40,
      height: AppDimens.p40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimens.r14),
      ),
      child: Icon(icon, color: foreground, size: AppLayout.iconStandard),
    );
  }
}

/// Amber Dusk-native selectable pill for sort and delivery filters.
///
/// The component avoids the default Material chip look so the modal reads as a
/// designed marketplace control rather than a generic settings sheet.
class _SelectableFilterPill extends StatelessWidget {
  const _SelectableFilterPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;
    final foreground = isSelected ? amberColors.textInverse : amberColors.text;
    final background = isSelected
        ? amberColors.primary
        : amberColors.surfaceRaised;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AmberDuskTokens.spacing.pillRadius),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curveStandard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p12,
            vertical: AppDimens.p10,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(
              AmberDuskTokens.spacing.pillRadius,
            ),
            border: Border.all(
              color: isSelected ? amberColors.primary : amberColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: AppDimens.iconSizeSmall),
              const SizedBox(width: AppDimens.p6),
              Text(
                label,
                style: AmberDuskTokens.typography.chip.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selectable proof row for seller-level filters.
///
/// The richer row gives each seller-level option a recognizable purpose while
/// keeping the same multi-select behavior as the previous flat tile list.
class _SellerLevelTile extends StatelessWidget {
  const _SellerLevelTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;
    final borderColor = isSelected ? amberColors.primary : amberColors.border;
    final iconBackground = isSelected
        ? amberColors.primary
        : amberColors.surfaceRaised;
    final iconForeground = isSelected
        ? amberColors.textInverse
        : amberColors.primary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Seller level $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curveStandard,
          padding: const EdgeInsets.all(AppDimens.p12),
          decoration: BoxDecoration(
            color: isSelected
                ? amberColors.primary.withValues(alpha: 0.14)
                : amberColors.surfaceRaised,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(AppDimens.r16),
          ),
          child: Row(
            children: [
              Container(
                width: AppDimens.p40,
                height: AppDimens.p40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(AppDimens.r14),
                ),
                child: Icon(
                  icon,
                  color: iconForeground,
                  size: AppLayout.iconStandard,
                ),
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.captionBold.copyWith(
                        color: isSelected
                            ? amberColors.primary
                            : amberColors.text,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p2),
                    Text(
                      description,
                      style: AmberDuskTokens.typography.bodySmall.copyWith(
                        color: amberColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: isSelected ? 1 : 0,
                duration: AppMotion.fast,
                child: Icon(
                  Icons.check_circle,
                  color: amberColors.primary,
                  size: AppDimens.iconSizeMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
