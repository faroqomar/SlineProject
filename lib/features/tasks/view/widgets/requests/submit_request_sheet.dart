import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

/// Shows a bottom sheet to submit a new offer for the given task.
Future<void> showSubmitRequestSheet(
  BuildContext context, {
  required String taskId,
  required TaskRequestsViewModel controller,
  required String budget, // Pass budget for hint
}) async {
  final priceCtrl = TextEditingController();
  final daysCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Helper to show confirm replace dialog
  Future<bool> confirmReplaceDialog(
    BuildContext ctx, {
    required TaskRequest existing,
    required int newPriceCents,
    required int newDays,
    String? newNote,
  }) async {
    // We can stick to standard dialog for critical confirmation or custom one. Standard is safer for now.
    return await showDialog<bool>(
          context: ctx,
          builder: (dCtx) {
            return AlertDialog(
              title: const Text('Replace your existing offer?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('You already have an active offer for this task.'),
                  const SizedBox(height: 12),
                  Text(
                    'Current: ${price_utils.PriceFormatter.formatPrice(existing.price.toDouble())} / ${existing.days} days',
                  ),
                  if ((existing.note ?? '').isNotEmpty)
                    Text('Note: ${existing.note}'),
                  const SizedBox(height: 12),
                  Text(
                    'New: ${price_utils.PriceFormatter.formatPrice(newPriceCents.toDouble())} / $newDays days',
                  ),
                  if ((newNote ?? '').isNotEmpty) Text('Note: $newNote'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dCtx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dCtx, true),
                  child: const Text('Replace'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Important for glass
    builder: (ctx) {
      final AppColorScheme colorScheme = ctx.colorScheme;
      final insets = MediaQuery.of(ctx).viewInsets;

      return Container(
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

            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimens.p24),
              child: Row(
                children: [
                  Text(
                    'Submit Proposal',
                    style: AppTypography.h4.copyWith(color: colorScheme.text),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.p24),
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
                                    if (n == null || n < 0) return 'Invalid';
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
                                    if (n == null || n <= 0) return 'Invalid';
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
                          borderRadius: BorderRadius.circular(AppDimens.r14),
                          // Mocking dashed border by using solid for now or custom painter
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
                                  color: colorScheme.textSecondary.withValues(
                                    alpha: 0.5,
                                  ),
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
                text: 'Submit Proposal',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(ctx);
                  final navigator = Navigator.of(ctx);
                  final tasksService = ctx.read<TaskRequestsService>();

                  if (!formKey.currentState!.validate()) return;

                  final priceDouble = double.parse(priceCtrl.text.trim());
                  final priceCents = (priceDouble).toInt();
                  final days = int.parse(daysCtrl.text.trim());
                  final note = noteCtrl.text.trim().isEmpty
                      ? null
                      : noteCtrl.text.trim();

                  // Check if there is an existing active offer
                  final existing = await controller.getExistingActiveOffer();

                  if (existing != null) {
                    if (!ctx.mounted) return;
                    final confirmed = await confirmReplaceDialog(
                      ctx,
                      existing: existing,
                      newPriceCents: priceCents,
                      newDays: days,
                      newNote: note,
                    );
                    if (!confirmed) return;

                    try {
                      final replaced = await tasksService.replaceOffer(
                        taskId: taskId,
                        price: priceDouble,
                        days: days,
                        note: note,
                      );
                      if (!ctx.mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Offer replaced successfully.'),
                        ),
                      );
                      await controller.loadForTask(taskId);
                      if (!ctx.mounted) return;
                      navigator.pop(replaced);
                    } catch (e) {
                      if (!ctx.mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  } else {
                    // First time submit
                    final ok = await controller.submitOfferUI(
                      taskId: taskId,
                      price: priceDouble,
                      days: days,
                      note: note,
                    );
                    if (!ctx.mounted) return;
                    if (ok) {
                      navigator.pop();
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
}
