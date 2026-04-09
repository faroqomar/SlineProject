import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

/// Filters modal shown as a draggable bottom sheet from the HomeScreen.
///
/// Allows users to set sort order, budget range, delivery time, and seller
/// level filters before applying them to the task feed. Uses a
/// [DraggableScrollableSheet] so users can swipe to expand or dismiss.
/// All filter state is local until the user taps "Apply Filters", at which
/// point it is pushed to [TaskFilterViewModel].
class FiltersModal extends StatefulWidget {
  const FiltersModal({super.key});

  static const Key resetButtonKey = ValueKey<String>('filters_reset_button');
  static const Key applyButtonKey = ValueKey<String>('filters_apply_button');

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
    final colorScheme = context.colorScheme;

    // Wrap in Semantics so screen readers announce the panel purpose
    return Semantics(
      label: 'Filters panel',
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        snap: true,
        snapSizes: const [0.5, 0.7, 0.9],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimens.r24),
              ),
            ),
            child: Column(
              children: [
                // --- Drag handle ---
                // Visual affordance indicating the sheet is draggable
                Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(
                    top: AppDimens.p12,
                    bottom: AppDimens.p8,
                  ),
                  decoration: BoxDecoration(
                    // textTertiary provides a subtle neutral tone for the handle
                    color: colorScheme.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // --- Header (non-scrollable) ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: AppTypography.h4.copyWith(
                          color: colorScheme.text,
                        ),
                      ),
                      // Accessible TextButton replaces GestureDetector so
                      // screen readers and keyboard users can activate it.
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
                            color: AppColors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Scrollable filter sections ---
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p24,
                      vertical: AppDimens.p12,
                    ),
                    children: [
                      // -- Sort By --
                      _buildSortBySection(colorScheme),
                      const SizedBox(height: AppDimens.p24),

                      // -- Budget Range --
                      _buildBudgetRangeSection(colorScheme),
                      const SizedBox(height: AppDimens.p24),

                      // -- Delivery Time --
                      _buildDeliveryTimeSection(colorScheme),
                      const SizedBox(height: AppDimens.p24),

                      // -- Seller Level --
                      _buildSellerLevelSection(colorScheme),

                      // Extra padding so the last section isn't hidden
                      // behind the fixed apply button
                      const SizedBox(height: AppDimens.p24),
                    ],
                  ),
                ),

                // --- Apply Button (fixed at bottom) ---
                _buildApplyButton(colorScheme),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section builders — extracted for readability and maintainability
  // ---------------------------------------------------------------------------

  /// Builds the "Sort By" horizontal chip row.
  /// Uses [AppTypography.h5] for the section header per design-system tokens.
  Widget _buildSortBySection(AppColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: AppTypography.h5.copyWith(color: colorScheme.text),
        ),
        const SizedBox(height: AppDimens.p12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                [
                  TaskFilterViewModel.sortRelevance,
                  TaskFilterViewModel.sortNewest,
                  TaskFilterViewModel.sortPriceLowToHigh,
                  TaskFilterViewModel.sortPriceHighToLow,
                ].map((sort) {
                  final isSelected = _sortBy == sort;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppDimens.p8),
                    child: ChoiceChip(
                      label: Text(sort),
                      selected: isSelected,
                      onSelected: (v) {
                        // Haptic feedback on chip selection for tactile response
                        AppInteractionStates.hapticSelection();
                        setState(() => _sortBy = sort);
                      },
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.inputBackground,
                      labelStyle: AppTypography.captionBold.copyWith(
                        color: isSelected
                            ? Colors.white
                            : colorScheme.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.inputBorder,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  /// Builds the "Budget Range" section with a slider and min/max text fields.
  /// The slider uses design-system primary/secondary tokens instead of
  /// hardcoded colors so it adapts to theme changes automatically.
  Widget _buildBudgetRangeSection(AppColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Range',
          style: AppTypography.h5.copyWith(color: colorScheme.text),
        ),
        Slider(
          value: _maxBudget,
          min: 0,
          max: 5000,
          activeColor: colorScheme.primary,
          inactiveColor: colorScheme.textSecondary.withValues(alpha: 0.2),
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
                prefixIcon: const Icon(Icons.attach_money, size: 16),
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
                prefixIcon: const Icon(Icons.attach_money, size: 16),
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
  Widget _buildDeliveryTimeSection(AppColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Time',
          style: AppTypography.h5.copyWith(color: colorScheme.text),
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
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.inputBackground,
              labelStyle: AppTypography.captionBold.copyWith(
                color: isSelected ? Colors.white : colorScheme.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.r12),
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.inputBorder,
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
  /// levels using design-system primary color at 10% opacity.
  Widget _buildSellerLevelSection(AppColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seller Level',
          style: AppTypography.h5.copyWith(color: colorScheme.text),
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
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : colorScheme.inputBackground,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.inputBorder,
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
                              ? colorScheme.primary
                              : colorScheme.text,
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check, color: colorScheme.primary, size: 18),
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
  Widget _buildApplyButton(AppColorScheme colorScheme) {
    final count = _activeFilterCount;
    // Singular/plural: "Apply 1 Filter" vs "Apply N Filters"
    final label = count == 0
        ? 'Apply Filters'
        : count == 1
        ? 'Apply 1 Filter'
        : 'Apply $count Filters';

    return Padding(
      padding: const EdgeInsets.all(AppDimens.p24),
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
