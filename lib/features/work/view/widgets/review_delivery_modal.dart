import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';

class ReviewDeliveryModal extends StatefulWidget {
  final Future<void> Function() onApprove;
  final Future<void> Function(String reason) onReject;

  const ReviewDeliveryModal({
    super.key,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<ReviewDeliveryModal> createState() => _ReviewDeliveryModalState();
}

enum _ReviewMode { initial, rejecting }

class _ReviewDeliveryModalState extends State<ReviewDeliveryModal> {
  _ReviewMode _mode = _ReviewMode.initial;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove() async {
    setState(() => _isLoading = true);
    try {
      await widget.onApprove();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      // Error handling by parent usually, but loading state reset needed
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReject() async {
    if (_reasonController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await widget.onReject(_reasonController.text);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimens.p24,
        right: AppDimens.p24,
        top: AppDimens.p24,
        bottom: AppDimens.p24 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _mode == _ReviewMode.initial
                    ? 'Review Delivery'
                    : 'Request Revision',
                style: AppTypography.h3.copyWith(
                  color: context.colorScheme.text,
                ),
              ),
              if (_mode == _ReviewMode.rejecting)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: context.colorScheme.textSecondary,
                  ),
                  onPressed: () => setState(() => _mode = _ReviewMode.initial),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.p16),

          if (_mode == _ReviewMode.initial) ...[
            Text(
              'Review the delivered work. If relevant, verify all files and requirements are met.',
              style: AppTypography.bodyMedium.copyWith(
                color: context.colorScheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.p24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Request Changes',
                    isPrimary: false,
                    onPressed: () =>
                        setState(() => _mode = _ReviewMode.rejecting),
                  ),
                ),
                const SizedBox(width: AppDimens.p16),
                Expanded(
                  child: AppButton(
                    text: 'Approve',
                    isLoading: _isLoading,
                    onPressed: _handleApprove,
                  ),
                ),
              ],
            ),
          ] else ...[
            AppTextField(
              controller: _reasonController,
              hintText: 'Describe what needs to be changed...',
              maxLines: 4,
            ),
            const SizedBox(height: AppDimens.p24),
            AppButton(
              text: 'Submit Request',
              isLoading: _isLoading,
              onPressed: _handleReject,
              backgroundColor: AppColors.lightRed, // Use warning color?
              // Or standard primary but logic implies "Negative" path
            ),
            const SizedBox(height: AppDimens.p12),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _mode = _ReviewMode.initial),
                child: Text(
                  'Back',
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.colorScheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
