import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';

/// A bottom sheet for creating custom offers in chat.
/// Matches the new design system.
class CreateOfferSheet extends StatefulWidget {
  final Function(String title, String description, String price, String deliveryDays) onSubmit;

  const CreateOfferSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<CreateOfferSheet> createState() => _CreateOfferSheetState();
}

class _CreateOfferSheetState extends State<CreateOfferSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveryController = TextEditingController(text: '3');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final price = _priceController.text.trim();
    final delivery = _deliveryController.text.trim();

    if (title.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and price')),
      );
      return;
    }

    widget.onSubmit(title, description, price, delivery);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.r30),
        ),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppDimens.p24,
          AppDimens.p16,
          AppDimens.p24,
          bottomPadding + AppDimens.p24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.p24),

            // Title
            Text(
              'Create Custom Offer',
              style: AppTypography.h4.copyWith(
                color: colorScheme.text,
              ),
            ),
            const SizedBox(height: AppDimens.p20),

            // Title input
            _buildLabel('Title', colorScheme),
            const SizedBox(height: AppDimens.p8),
            AppTextField(
              controller: _titleController,
              hintText: 'e.g., Performance Optimization Package',
            ),
            const SizedBox(height: AppDimens.p16),

            // Description input
            _buildLabel('Description', colorScheme),
            const SizedBox(height: AppDimens.p8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.inputBackground,
                borderRadius: BorderRadius.circular(AppDimens.r14),
                border: Border.all(color: colorScheme.inputBorder),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: TextStyle(color: colorScheme.text),
                decoration: InputDecoration(
                  hintText: 'Describe what you will deliver...',
                  hintStyle: TextStyle(color: colorScheme.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppDimens.p12),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.p16),

            // Price and Delivery row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Price (\$)', colorScheme),
                      const SizedBox(height: AppDimens.p8),
                      AppTextField(
                        controller: _priceController,
                        hintText: '450',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Delivery (Days)', colorScheme),
                      const SizedBox(height: AppDimens.p8),
                      AppTextField(
                        controller: _deliveryController,
                        hintText: '3',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.p24),

            // Submit button
            AppButton(
              text: 'Send Offer',
              width: double.infinity,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, AppColorScheme colorScheme) {
    return Text(
      text,
      style: AppTypography.captionBold.copyWith(
        color: colorScheme.textSecondary,
      ),
    );
  }
}

/// Show the create offer sheet as a modal bottom sheet.
void showCreateOfferSheet(
  BuildContext context, {
  required Function(String title, String description, String price, String deliveryDays) onSubmit,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => CreateOfferSheet(onSubmit: onSubmit),
  );
}

