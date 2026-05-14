import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart' show AppColorScheme;
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/tasks/view/create_task_screen.dart';
import 'package:sline_app/l10n/app_localizations.dart';

/// Booking details fields for the Create Task details step.
///
/// Displays the Open Design booking details cluster: role, seniority, package
/// pricing, period, location, and experience, while preserving existing package
/// tier state via [onTierChanged].
class BookingLogisticsSection extends StatelessWidget {
  final int selectedPackageTier;
  final TextEditingController bookingRoleController;
  final TextEditingController bookingSeniorityController;
  final TextEditingController bookingPeriodController;
  final TextEditingController bookingLocationController;
  final TextEditingController bookingExperienceController;
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
    required this.bookingRoleController,
    required this.bookingSeniorityController,
    required this.bookingPeriodController,
    required this.bookingLocationController,
    required this.bookingExperienceController,
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
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: buildLabeledInput(
                l10n?.roleLabel ?? 'Role',
                AppTextField(
                  hintText: l10n?.roleHint ?? 'e.g., UX designer',
                  controller: bookingRoleController,
                ),
                colorScheme,
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: buildLabeledInput(
                l10n?.seniorityLabel ?? 'Seniority',
                AppTextField(
                  hintText: l10n?.seniorityHint ?? 'e.g., Senior',
                  controller: bookingSeniorityController,
                ),
                colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.p16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(AppDimens.r14),
            border: Border.all(color: colorScheme.cardBorder),
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
                  key: tierKey,
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTierChanged(index),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.p10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primary : null,
                      borderRadius: BorderRadius.circular(AppDimens.r10),
                      boxShadow: isSelected
                          ? AppDecorations.elevation(
                              1,
                              isDark: colorScheme.isDark,
                            )
                          : AppDecorations.elevation(0),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTypography.captionBold.copyWith(
                        color: isSelected
                            ? colorScheme.phoneBackground
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
                'Price (IQD)',
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
        Row(
          children: [
            Expanded(
              child: buildLabeledInput(
                'Period',
                AppTextField(
                  hintText: 'e.g., Per session',
                  controller: bookingPeriodController,
                ),
                colorScheme,
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: buildLabeledInput(
                'Location',
                AppTextField(
                  hintText: 'Remote or city',
                  controller: bookingLocationController,
                ),
                colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.p16),
        buildLabeledInput(
          'Experience',
          AppTextField(
            hintText: 'e.g., 5+ years with SaaS apps',
            controller: bookingExperienceController,
          ),
          colorScheme,
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
