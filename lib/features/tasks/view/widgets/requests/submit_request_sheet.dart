import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';
import 'package:sline_app/core/utils/format_price.dart' as price_utils;

/// Callback type for when a bid is successfully replaced.
typedef OnBidReplacedCallback = void Function(TaskRequest newBid);

/// Shows a bottom sheet to submit a new offer or replace an existing one for the given task.
///
/// If the freelancer already has a pending bid, this will show a "Replace Bid" flow
/// that archives the old bid and creates a new one.
Future<void> showSubmitRequestSheet(
  BuildContext context, {
  required String taskId,
  required TaskRequestsViewModel controller,
  required String budget,
  OnBidReplacedCallback? onReplaced,
}) async {
  final priceCtrl = TextEditingController();
  final daysCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Detect existing bid at initialization
  BidReplaceabilityResult? replaceabilityResult;
  TaskRequest? existingBid;

  try {
    AppLogger.d(
      'Checking bid replaceability for task $taskId',
      tag: 'SubmitRequestSheet',
    );
    replaceabilityResult = await controller.checkBidReplaceability();
    existingBid = replaceabilityResult.existingBid;

    if (existingBid != null) {
      AppLogger.i(
        'Found existing bid ${existingBid.id} for task $taskId - replace mode',
        tag: 'SubmitRequestSheet',
      );
      // Pre-fill with existing values for easier editing
      priceCtrl.text = (existingBid.price / 100).toStringAsFixed(0);
      daysCtrl.text = existingBid.days.toString();
      noteCtrl.text = existingBid.note ?? '';
    } else {
      AppLogger.d(
        'No existing bid found for task $taskId - new bid mode',
        tag: 'SubmitRequestSheet',
      );
    }
  } catch (e, st) {
    AppLogger.e(
      'Failed to check bid replaceability',
      tag: 'SubmitRequestSheet',
      error: e,
      stackTrace: st,
    );
    // Continue in new bid mode if check fails
  }

  final bool isReplaceMode = existingBid != null;

  // Check if the original context is still valid before showing the sheet
  if (!context.mounted) {
    AppLogger.w(
      'Context not mounted, aborting submit request sheet',
      tag: 'SubmitRequestSheet',
    );
    return;
  }

  // Helper to show confirm replace dialog with detailed comparison
  Future<bool> confirmReplaceDialog(
    BuildContext ctx, {
    required TaskRequest existing,
    required int newPriceCents,
    required int newDays,
    String? newNote,
  }) async {
    // Calculate differences
    final priceDiff = newPriceCents - existing.price;
    final daysDiff = newDays - existing.days;
    final priceDiffText = priceDiff > 0
        ? '+${price_utils.PriceFormatter.formatPrice(priceDiff.toDouble())}'
        : priceDiff < 0
        ? '-${price_utils.PriceFormatter.formatPrice(priceDiff.abs().toDouble())}'
        : 'No change';
    final daysDiffText = daysDiff > 0
        ? '+$daysDiff days'
        : daysDiff < 0
        ? '-${daysDiff.abs()} days'
        : 'No change';

    AppLogger.d(
      'Showing replace confirmation dialog: '
      'old price=${existing.price}, new price=$newPriceCents, diff=$priceDiffText | '
      'old days=${existing.days}, new days=$newDays, diff=$daysDiffText',
      tag: 'SubmitRequestSheet',
    );

    return await showDialog<bool>(
          context: ctx,
          barrierDismissible: false,
          builder: (dCtx) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.swap_horiz, color: AppColors.teal),
                  const SizedBox(width: 8),
                  const Text('Replace your bid?'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Explanation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimens.r8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your current bid will be archived and replaced with the new one. This action cannot be undone.',
                              style: AppTypography.caption.copyWith(
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Current bid section
                    Text(
                      'CURRENT BID',
                      style: AppTypography.captionBold.copyWith(
                        color: ctx.colorScheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildComparisonRow(
                      context: dCtx,
                      label: 'Price',
                      value: price_utils.PriceFormatter.formatPrice(
                        existing.price.toDouble(),
                      ),
                    ),
                    _buildComparisonRow(
                      context: dCtx,
                      label: 'Delivery',
                      value: '${existing.days} days',
                    ),
                    if ((existing.note ?? '').isNotEmpty)
                      _buildComparisonRow(
                        context: dCtx,
                        label: 'Note',
                        value: existing.note!,
                        isMultiline: true,
                      ),
                    const SizedBox(height: 16),

                    // New bid section
                    Text(
                      'NEW BID',
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildComparisonRow(
                      context: dCtx,
                      label: 'Price',
                      value: price_utils.PriceFormatter.formatPrice(
                        newPriceCents.toDouble(),
                      ),
                      changeIndicator: priceDiffText,
                      changeColor: priceDiff > 0
                          ? Colors.green
                          : priceDiff < 0
                          ? Colors.red
                          : Colors.grey,
                    ),
                    _buildComparisonRow(
                      context: dCtx,
                      label: 'Delivery',
                      value: '$newDays days',
                      changeIndicator: daysDiffText,
                      changeColor: daysDiff > 0
                          ? Colors
                                .red // More days = negative
                          : daysDiff < 0
                          ? Colors
                                .green // Fewer days = positive
                          : Colors.grey,
                    ),
                    if ((newNote ?? '').isNotEmpty)
                      _buildComparisonRow(
                        context: dCtx,
                        label: 'Note',
                        value: newNote!,
                        isMultiline: true,
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    AppLogger.d(
                      'User cancelled bid replacement',
                      tag: 'SubmitRequestSheet',
                    );
                    Navigator.pop(dCtx, false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    AppLogger.d(
                      'User confirmed bid replacement',
                      tag: 'SubmitRequestSheet',
                    );
                    Navigator.pop(dCtx, true);
                  },
                  child: const Text('Replace Bid'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  await showModalBottomSheet<TaskRequest>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final AppColorScheme colorScheme = ctx.colorScheme;
      final insets = MediaQuery.of(ctx).viewInsets;

      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            key: Key(
              isReplaceMode ? 'replace_bid_sheet' : 'submit_proposal_sheet',
            ),
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimens.r30),
              ),
              border: Border(top: BorderSide(color: colorScheme.cardBorder)),
            ),
            padding: EdgeInsets.only(bottom: insets.bottom),
            child: Column(
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(
                      top: AppDimens.p12,
                      bottom: AppDimens.p8,
                    ),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header with dynamic title
                Padding(
                  padding: const EdgeInsets.all(AppDimens.p24),
                  child: Row(
                    children: [
                      if (isReplaceMode)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppDimens.r8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.swap_horiz,
                                color: AppColors.teal,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'REPLACE',
                                style: AppTypography.captionBold.copyWith(
                                  color: AppColors.teal,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: Text(
                          isReplaceMode
                              ? 'Replace Your Bid'
                              : 'Submit Proposal',
                          style: AppTypography.h4.copyWith(
                            color: colorScheme.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Existing bid summary (only in replace mode)
                if (isReplaceMode && existingBid != null)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p24,
                    ),
                    padding: const EdgeInsets.all(AppDimens.p16),
                    decoration: BoxDecoration(
                      color: colorScheme.cardBackground.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppDimens.r12),
                      border: Border.all(
                        color: colorScheme.inputBorder.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Bid (will be archived)',
                          style: AppTypography.captionBold.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimens.p8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildExistingBidInfo(
                                icon: Icons.attach_money,
                                label: 'Price',
                                value: price_utils.PriceFormatter.formatPrice(
                                  existingBid.price.toDouble(),
                                ),
                              ),
                            ),
                            Expanded(
                              child: _buildExistingBidInfo(
                                icon: Icons.calendar_today,
                                label: 'Days',
                                value: '${existingBid.days} days',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppDimens.p16),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p24,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bid Amount',
                                      style: AppTypography.captionBold.copyWith(
                                        color: colorScheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: AppDimens.p8),
                                    AppTextField(
                                      controller: priceCtrl,
                                      hintText: budget,
                                      keyboardType: TextInputType.number,
                                      prefixIcon: Icon(
                                        Icons.attach_money,
                                        color: AppColors.teal,
                                        size: 18,
                                      ),
                                      validator: (v) {
                                        final n = double.tryParse(v ?? '');
                                        if (n == null || n < 0) {
                                          return 'Invalid';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppDimens.p16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delivery (Days)',
                                      style: AppTypography.captionBold.copyWith(
                                        color: colorScheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: AppDimens.p8),
                                    AppTextField(
                                      controller: daysCtrl,
                                      hintText: 'e.g. 7',
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        final n = int.tryParse(v ?? '');
                                        if (n == null || n <= 0) {
                                          return 'Invalid';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.p24),

                          Text(
                            'Cover Letter',
                            style: AppTypography.captionBold.copyWith(
                              color: colorScheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppDimens.p8),
                          AppTextField(
                            controller: noteCtrl,
                            hintText:
                                'Explain why you are the best fit for this job...',
                            maxLines: 6,
                          ),

                          const SizedBox(height: AppDimens.p24),

                          // Upload Placeholder
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colorScheme.inputBorder,
                                style: BorderStyle.solid,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppDimens.r14,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    color: colorScheme.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Upload Files (Coming Soon)',
                                    style: AppTypography.captionBold.copyWith(
                                      color: colorScheme.textSecondary
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Submit Button
                Padding(
                  padding: const EdgeInsets.all(AppDimens.p24),
                  child: AppButton(
                    text: isReplaceMode ? 'Replace Bid' : 'Submit Proposal',
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(ctx);
                      final navigator = Navigator.of(ctx);
                      final tasksService = ctx.read<TaskRequestsService>();

                      if (!formKey.currentState!.validate()) return;

                      final priceDouble = double.parse(priceCtrl.text.trim());
                      final priceCents = (priceDouble * 100).toInt();
                      final days = int.parse(daysCtrl.text.trim());
                      final note = noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim();

                      // Replace mode: show confirmation dialog
                      if (isReplaceMode && existingBid != null) {
                        AppLogger.i(
                          'Initiating bid replacement for task $taskId',
                          tag: 'SubmitRequestSheet',
                          json: {
                            'existingBidId': existingBid.id,
                            'newPrice': priceCents,
                            'newDays': days,
                          },
                        );

                        if (!ctx.mounted) return;
                        final confirmed = await confirmReplaceDialog(
                          ctx,
                          existing: existingBid,
                          newPriceCents: priceCents,
                          newDays: days,
                          newNote: note,
                        );

                        if (!confirmed) {
                          AppLogger.d(
                            'Bid replacement cancelled by user',
                            tag: 'SubmitRequestSheet',
                          );
                          return;
                        }

                        try {
                          AppLogger.d(
                            'Calling replaceOffer RPC for task $taskId',
                            tag: 'SubmitRequestSheet',
                          );

                          final replaced = await tasksService.replaceOffer(
                            taskId: taskId,
                            price: priceDouble,
                            days: days,
                            note: note,
                          );

                          AppLogger.i(
                            'Bid replaced successfully: ${replaced.id}',
                            tag: 'SubmitRequestSheet',
                          );

                          if (!ctx.mounted) return;

                          // Show success message
                          messenger.showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Bid replaced successfully'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );

                          // Refresh the list
                          await controller.loadForTask(taskId);

                          // Call the callback if provided
                          if (onReplaced != null) {
                            AppLogger.d(
                              'Calling onReplaced callback with new bid ${replaced.id}',
                              tag: 'SubmitRequestSheet',
                            );
                            onReplaced(replaced);
                          }

                          if (!ctx.mounted) return;
                          navigator.pop(replaced);
                        } catch (e, st) {
                          AppLogger.e(
                            'Failed to replace bid for task $taskId',
                            tag: 'SubmitRequestSheet',
                            error: e,
                            stackTrace: st,
                          );
                          if (!ctx.mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to replace bid: ${e.toString()}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        // First time submit
                        AppLogger.i(
                          'Submitting new bid for task $taskId',
                          tag: 'SubmitRequestSheet',
                          json: {'price': priceCents, 'days': days},
                        );

                        final ok = await controller.submitOfferUI(
                          taskId: taskId,
                          price: priceDouble,
                          days: days,
                          note: note,
                        );

                        if (!ctx.mounted) return;

                        if (ok) {
                          AppLogger.i(
                            'New bid submitted successfully for task $taskId',
                            tag: 'SubmitRequestSheet',
                          );
                          navigator.pop();
                        } else {
                          AppLogger.w(
                            'Bid submission failed for task $taskId: ${controller.errorMessage}',
                            tag: 'SubmitRequestSheet',
                          );
                          // Error is shown via ViewModel's errorMessage
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Builds a row showing existing bid info.
Widget _buildExistingBidInfo({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey),
      const SizedBox(width: 4),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ],
  );
}

/// Builds a comparison row for the confirmation dialog.
Widget _buildComparisonRow({
  required BuildContext context,
  required String label,
  required String value,
  String? changeIndicator,
  Color? changeColor,
  bool isMultiline = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: isMultiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(color: Colors.grey),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (changeIndicator != null)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (changeColor ?? Colors.grey).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    changeIndicator,
                    style: AppTypography.captionBold.copyWith(
                      color: changeColor,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
