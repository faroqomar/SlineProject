import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';

class RequestExtensionModal extends StatefulWidget {
  final void Function(String note, int days) onSubmit;
  final bool isLoading;

  const RequestExtensionModal({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<RequestExtensionModal> createState() => _RequestExtensionModalState();
}

class _RequestExtensionModalState extends State<RequestExtensionModal> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    _daysController.dispose();
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
            'Request Extension',
            style: AppTypography.h3.copyWith(color: context.colorScheme.text),
          ),
          const SizedBox(height: AppDimens.p16),
          AppTextField(
            controller: _daysController,
            hintText: 'Days (e.g. 3)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppDimens.p16),
          AppTextField(
            controller: _noteController,
            hintText: 'Reason for extension...',
            maxLines: 3,
          ),
          const SizedBox(height: AppDimens.p24),
          AppButton(
            text: 'Request Extension',
            isLoading: widget.isLoading,
            onPressed: () {
              final days = int.tryParse(_daysController.text) ?? 0;
              if (days > 0) {
                widget.onSubmit(_noteController.text, days);
              }
            },
          ),
          const SizedBox(height: AppDimens.p24),
        ],
      ),
    );
  }
}
