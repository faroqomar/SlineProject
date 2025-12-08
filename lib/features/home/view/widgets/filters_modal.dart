import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

class FiltersModal extends StatefulWidget {
  const FiltersModal({super.key});

  @override
  State<FiltersModal> createState() => _FiltersModalState();
}

class _FiltersModalState extends State<FiltersModal> {
  // Local state for the form before applying
  String _sortBy = 'Relevance';
  double _maxBudget = 1000;
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();
  final List<String> _deliveryTimes = [];
  final List<String> _sellerLevels = [];

  @override
  void initState() {
    super.initState();
    // Initialize local state from ViewModel
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

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.r30)),
        border: Border(top: BorderSide(color: colorScheme.cardBorder)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppDimens.p24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: AppTypography.h4.copyWith(color: colorScheme.text),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _sortBy = 'Relevance';
                      _maxBudget = 1000;
                      _minBudgetController.clear();
                      _maxBudgetController.clear();
                      _deliveryTimes.clear();
                      _sellerLevels.clear();
                    });
                    // Optional: Apply clear immediately or wait for Apply button?
                    // Usually "Reset" implies action.
                    context.read<TaskFilterViewModel>().clearFilters();
                  },
                  child: Text(
                    'Reset All',
                    style: AppTypography.captionBold.copyWith(color: AppColors.teal),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort By
                  Text('Sort By', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: colorScheme.text)),
                  const SizedBox(height: AppDimens.p12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Relevance', 'Newest', 'Price: Low to High', 'Price: High to Low'].map((sort) {
                        final isSelected = _sortBy == sort;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(sort),
                            selected: isSelected,
                            onSelected: (v) => setState(() => _sortBy = sort),
                            selectedColor: AppColors.teal,
                            backgroundColor: colorScheme.inputBackground,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : colorScheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimens.r12),
                              side: BorderSide(color: isSelected ? AppColors.teal : colorScheme.inputBorder),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppDimens.p24),

                  // Budget Range
                  Text('Budget Range', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: colorScheme.text)),
                  Slider(
                    value: _maxBudget,
                    min: 0,
                    max: 5000,
                    activeColor: AppColors.teal,
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
                        padding: EdgeInsets.symmetric(horizontal: 12),
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
                            if (v != null) setState(() => _maxBudget = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.p24),

                  // Delivery Time
                  Text('Delivery Time', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: colorScheme.text)),
                  const SizedBox(height: AppDimens.p12),
                  Wrap(
                    spacing: 8,
                    children: ['Up to 24h', 'Up to 3 days', 'Up to 7 days', 'Anytime'].map((time) {
                      final isSelected = _deliveryTimes.contains(time);
                      return ChoiceChip(
                        label: Text(time),
                        selected: isSelected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _deliveryTimes.add(time);
                          } else {
                            _deliveryTimes.remove(time);
                          }
                        }),
                        selectedColor: AppColors.teal,
                        backgroundColor: colorScheme.inputBackground,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : colorScheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.r12),
                          side: BorderSide(color: isSelected ? AppColors.teal : colorScheme.inputBorder),
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimens.p24),

                  // Seller Level
                  Text('Seller Level', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: colorScheme.text)),
                  const SizedBox(height: AppDimens.p12),
                  Column(
                    children: ['Top Rated Seller', 'Level 2', 'Level 1', 'New Seller'].map((level) {
                      final isSelected = _sellerLevels.contains(level);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _sellerLevels.remove(level);
                          } else {
                            _sellerLevels.add(level);
                          }
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(AppDimens.p12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.teal.withValues(alpha: 0.1) : colorScheme.inputBackground,
                            border: Border.all(color: isSelected ? AppColors.teal : colorScheme.inputBorder),
                            borderRadius: BorderRadius.circular(AppDimens.r14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                level,
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? AppColors.teal : colorScheme.text,
                                ),
                              ),
                              if (isSelected) Icon(Icons.check, color: AppColors.teal, size: 18),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Apply Button
          Padding(
            padding: const EdgeInsets.all(AppDimens.p24),
            child: AppButton(
              text: 'Apply Filters',
              onPressed: () {
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
          ),
        ],
      ),
    );
  }
}
