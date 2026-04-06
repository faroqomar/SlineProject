import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/tasks/view/create_task_screen.dart';

/// Step 3 booking variant: package tier tabs and per-tier input fields.
///
/// Displays a segmented control for Basic / Standard / Premium tiers and
/// price, delivery, revisions, and description fields for the selected tier.
/// All state changes are communicated back via [onTierChanged].
class BookingLogisticsSection extends StatelessWidget {
  final int selectedPackageTier;
  final TextEditingController packagePriceController;
  final TextEditingController packageDeliveryController;
  final TextEditingController packageRevisionsController;
  final TextEditingController packageDescriptionController;
  final ValueChanged<int> onTierChanged;

  /// Helper shared with the parent to render a label above any input.
  final Widget Function(String label, Widget input, AppColorScheme colorScheme)
  buildLabeledInput;

  const BookingLogisticsSection({
    super.key,
    required this.selectedPackageTier,
    required this.packagePriceController,
    required this.packageDeliveryController,
    required this.packageRevisionsController,
    required this.packageDescriptionController,
    required this.onTierChanged,
    required this.buildLabeledInput,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.inputBackground,
            borderRadius: BorderRadius.circular(AppDimens.r14),
            border: Border.all(color: colorScheme.inputBorder),
          ),
          child: Row(
            children: ['Basic', 'Standard', 'Premium'].asMap().entries.map((
              entry,
            ) {
              final index = entry.key;
              final label = entry.value;
              final isSelected = selectedPackageTier == index;
              final tierKey = switch (index) {
                0 => CreateTaskScreen.packageTierBasicKey,
                1 => CreateTaskScreen.packageTierStandardKey,
                _ => CreateTaskScreen.packageTierPremiumKey,
              };
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTierChanged(index),
                  child: AnimatedContainer(
                    key: tierKey,
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.p10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimens.r10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.teal.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTypography.captionBold.copyWith(
                        color: isSelected
                            ? Colors.white
                            : colorScheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppDimens.p16),
        Row(
          children: [
            Expanded(
              child: buildLabeledInput(
                r'Price ($)',
                AppTextField(
                  hintText: '0',
                  fieldKey: CreateTaskScreen.packagePriceFieldKey,
                  controller: packagePriceController,
                  keyboardType: TextInputType.number,
                ),
                colorScheme,
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: buildLabeledInput(
                'Delivery (Days)',
                AppTextField(
                  hintText: '1',
                  controller: packageDeliveryController,
                  keyboardType: TextInputType.number,
                ),
                colorScheme,
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: buildLabeledInput(
                'Revisions',
                AppTextField(
                  hintText: '1',
                  controller: packageRevisionsController,
                ),
                colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.p16),
        buildLabeledInput(
          'Package Description',
          AppTextField(
            hintText: 'What is included?',
            fieldKey: CreateTaskScreen.packageDescriptionFieldKey,
            controller: packageDescriptionController,
            maxLines: 3,
          ),
          colorScheme,
        ),
      ],
    );
  }
}
