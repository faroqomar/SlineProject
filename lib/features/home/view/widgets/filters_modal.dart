import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
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
  // Local state for the form before applying
  String _sortBy = TaskFilterViewModel.sortRelevance;
  double _maxBudget = 1000;
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
    _maxBudget = vm.maxBudget ?? 1000;
    _minBudgetController.text = vm.minBudget?.toInt().toString() ?? '';
    _maxBudgetController.text = vm.maxBudget?.toInt().toString() ?? '1000';
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
    // Min budget — default is empty
    if (_minBudgetController.text.isNotEmpty) count++;
    // Max budget — default is 1000 or empty. Parse numerically to handle
    // equivalents like "1000.0" or " 1000" instead of fragile string compare.
    final maxBudgetParsed = double.tryParse(_maxBudgetController.text.trim());
    if (maxBudgetParsed != null && maxBudgetParsed != 1000.0) {
      count++;
    }
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

    // Wrap in Semantics so screen readers announce the panel purpose
    return Semantics(
      label: 'Filters panel',
      child: FractionallySizedBox(
        alignment: Alignment.bottomCenter,
        heightFactor: 0.86,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: amberColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AmberDuskTokens.spacing.sheetRadius),
            ),
            boxShadow: AppDecorations.elevation(3, isDark: amberColors.isDark),
          ),
          child: Column(
            children: [
              // --- Drag handle ---
              // Single modal handle; the route owns drag-to-dismiss behavior.
              Container(
                key: FiltersModal.sheetHandleKey,
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(
                  top: AppDimens.p12,
                  bottom: AppDimens.p8,
                ),
                decoration: BoxDecoration(
                  // A raised neutral handle makes the sheet affordance visible
                  // without adding blur, transparency, or a nested sheet.
                  color: amberColors.surfaceHighest,
                  borderRadius: BorderRadius.circular(AppDimens.r4),
                ),
              ),

              // --- Header (non-scrollable) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.p24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: AmberDuskTokens.typography.sectionTitle.copyWith(
                        color: amberColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    // Accessible TextButton replaces GestureDetector so screen
                    // readers and keyboard users can activate it.
                    // Reset only mutates local state — user commits via Apply.
                    TextButton(
                      key: FiltersModal.resetButtonKey,
                      onPressed: () {
                        AppLogger.d(
                          'home_filters_reset',
                          tag: 'FiltersModal',
                        );
                        setState(() {
                          _sortBy = TaskFilterViewModel.sortRelevance;
                          _maxBudget = 1000;
                          _minBudgetController.clear();
                          _maxBudgetController.clear();
                          _deliveryTimes.clear();
                          _sellerLevels.clear();
                        });
                      },
                      child: Text(
                        'Reset All',
                        style: AppTypography.captionBold.copyWith(
                          color: amberColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Scrollable filter sections ---
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p24,
                    vertical: AppDimens.p12,
                  ),
                  children: [
                    _buildSortBySection(),
                    const SizedBox(height: AppDimens.p24),
                    _buildBudgetRangeSection(),
                    const SizedBox(height: AppDimens.p24),
                    _buildDeliveryTimeSection(),
                    const SizedBox(height: AppDimens.p24),
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

  /// Builds the "Sort By" chip group.
  /// Uses Amber Dusk section typography for the section header.
  Widget _buildSortBySection() {
    final amberColors = _amberColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: AmberDuskTokens.typography.sectionTitle.copyWith(
            color: amberColors.text,
          ),
        ),
        const SizedBox(height: AppDimens.p12),
        Wrap(
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
                return ChoiceChip(
                  label: Text(sort),
                  selected: isSelected,
                  onSelected: (v) {
                    // Haptic feedback on chip selection for tactile response.
                    AppInteractionStates.hapticSelection();
                    setState(() => _sortBy = sort);
                  },
                  selectedColor: amberColors.primary,
                  backgroundColor: amberColors.surface,
                  labelStyle: AmberDuskTokens.typography.chip.copyWith(
                    color: isSelected
                        ? amberColors.textInverse
                        : amberColors.muted,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AmberDuskTokens.spacing.pillRadius,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? amberColors.primary
                          : amberColors.border,
                    ),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
        ),
      ],
    );
  }

  /// Builds the "Budget Range" section with a slider and min/max text fields.
  /// The slider uses design-system primary/secondary tokens instead of
  /// hardcoded colors so it adapts to theme changes automatically.
  Widget _buildBudgetRangeSection() {
    final amberColors = _amberColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Range',
          style: AmberDuskTokens.typography.sectionTitle.copyWith(
            color: amberColors.text,
          ),
        ),
        Slider(
          value: _maxBudget,
          max: 5000,
          activeColor: amberColors.primary,
          inactiveColor: amberColors.surfaceHighest,
          onChanged: (v) => setState(() {
            _maxBudget = v;
            _maxBudgetController.text = v.toInt().toString();
          }),
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                hintText: 'Min',
                controller: _minBudgetController,
                keyboardType: TextInputType.number,
                prefixIcon: const _CurrencyPrefix(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.p12),
              child: Text('-'),
            ),
            Expanded(
              child: AppTextField(
                hintText: 'Max',
                controller: _maxBudgetController,
                keyboardType: TextInputType.number,
                prefixIcon: const _CurrencyPrefix(),
                onChanged: (val) {
                  final v = double.tryParse(val);
                  // Clamp to slider range so text input and slider stay in sync
                  if (v != null) {
                    setState(() => _maxBudget = v.clamp(0.0, 5000.0));
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the "Delivery Time" chip wrap section.
  /// Each chip triggers haptic feedback on tap for consistent tactile response.
  Widget _buildDeliveryTimeSection() {
    final amberColors = _amberColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Time',
          style: AmberDuskTokens.typography.sectionTitle.copyWith(
            color: amberColors.text,
          ),
        ),
        const SizedBox(height: AppDimens.p12),
        Wrap(
          spacing: AppDimens.p8,
          children: TaskFilterViewModel.deliveryTimeOptions.map((time) {
            final isSelected = _deliveryTimes.contains(time);
            return ChoiceChip(
              label: Text(time),
              selected: isSelected,
              onSelected: (v) {
                // Haptic feedback for tactile response
                AppInteractionStates.hapticSelection();
                setState(() {
                  if (v) {
                    _deliveryTimes.add(time);
                  } else {
                    _deliveryTimes.remove(time);
                  }
                });
              },
              selectedColor: amberColors.primary,
              backgroundColor: amberColors.surface,
              labelStyle: AmberDuskTokens.typography.chip.copyWith(
                color: isSelected ? amberColors.textInverse : amberColors.muted,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AmberDuskTokens.spacing.pillRadius,
                ),
                side: BorderSide(
                  color: isSelected ? amberColors.primary : amberColors.border,
                ),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Builds the "Seller Level" list section.
  /// Each tile triggers haptic feedback on tap and highlights the selected
  /// levels using a subtle Amber Dusk primary wash.
  Widget _buildSellerLevelSection() {
    final amberColors = _amberColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seller Level',
          style: AmberDuskTokens.typography.sectionTitle.copyWith(
            color: amberColors.text,
          ),
        ),
        const SizedBox(height: AppDimens.p12),
        Column(
          children: TaskFilterViewModel.sellerLevelOptions.map((level) {
            final isSelected = _sellerLevels.contains(level);
            return Semantics(
              button: true,
              selected: isSelected,
              label: 'Seller level $level',
              child: InkWell(
                onTap: () {
                  // Haptic feedback for each seller level toggle
                  AppInteractionStates.hapticSelection();
                  setState(() {
                    if (isSelected) {
                      _sellerLevels.remove(level);
                    } else {
                      _sellerLevels.add(level);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(AppDimens.r14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppDimens.p8),
                  padding: const EdgeInsets.all(AppDimens.p12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? amberColors.primary.withValues(alpha: 0.14)
                        : amberColors.surface,
                    border: Border.all(
                      color: isSelected
                          ? amberColors.primary
                          : amberColors.border,
                    ),
                    borderRadius: BorderRadius.circular(AppDimens.r14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        level,
                        style: AppTypography.captionBold.copyWith(
                          color: isSelected
                              ? amberColors.primary
                              : amberColors.text,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          color: amberColors.primary,
                          size: AppDimens.iconSizeSmall,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
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
        AppDimens.p12,
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
          context.read<TaskFilterViewModel>().applyAdvancedFilters(
            minBudget: double.tryParse(_minBudgetController.text),
            maxBudget: double.tryParse(_maxBudgetController.text),
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
