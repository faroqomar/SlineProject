import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';

class SubmitDeliveryModal extends StatefulWidget {
  final void Function(String note) onSubmit;
  final bool isLoading;

  const SubmitDeliveryModal({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<SubmitDeliveryModal> createState() => _SubmitDeliveryModalState();
}

class _SubmitDeliveryModalState extends State<SubmitDeliveryModal> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p24),
      decoration: BoxDecoration(
        color: context.colorScheme.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.r24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submit Delivery',
            style: AppTypography.h3.copyWith(color: context.colorScheme.text),
          ),
          const SizedBox(height: AppDimens.p16),
          AppTextField(
            controller: _noteController,
            hintText: 'Describe your delivery...',
            maxLines: 4,
          ),
          // Reserve space for delivery attachment upload controls.
          const SizedBox(height: AppDimens.p24),
          AppButton(
            text: 'Submit Work',
            isLoading: widget.isLoading,
            onPressed: () => widget.onSubmit(_noteController.text),
          ),
          const SizedBox(height: AppDimens.p24), // Bottom padding for safe area
        ],
      ),
    );
  }
}
