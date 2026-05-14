import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_price.dart' as price_utils;
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/viewmodels/submit_request_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';

/// Callback type for when a bid is successfully replaced.
typedef OnBidReplacedCallback = void Function(TaskRequest newBid);

/// Shows a bottom sheet to submit a new offer or replace an existing one for the given task.
///
/// Business logic delegated to [SubmitRequestViewModel].
/// UI presentation stays in this file.
Future<void> showSubmitRequestSheet(
  BuildContext context, {
  required String taskId,
  required TaskRequestsViewModel controller,
  required String budget,
  OnBidReplacedCallback? onReplaced,
}) async {
  // Create the ViewModel with services from the widget tree
  final vm = SubmitRequestViewModel(
    taskService: context.read<TaskService>(),
    requestsService: context.read<TaskRequestsService>(),
    controller: controller,
    taskId: taskId,
    userId: context.read<AuthSessionViewModel>().currentUserId,
    budget: budget,
  );

  // Guard: validate task before showing sheet
  final valid = await vm.validateTask();
  if (!valid) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.guardError ?? 'Unable to load task.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  // Check for existing bid (determine replace mode)
  final preFill = await vm.checkReplaceability();

  final priceCtrl = TextEditingController(text: preFill?.price ?? '');
  final daysCtrl = TextEditingController(text: preFill?.days ?? '');
  final noteCtrl = TextEditingController(text: preFill?.note ?? '');
  final formKey = GlobalKey<FormState>();

  if (!context.mounted) {
    AppLogger.w(
      'Context not mounted, aborting submit request sheet',
      tag: 'SubmitRequestSheet',
    );
    return;
  }

  await showModalBottomSheet<TaskRequest>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      // Scoped provider: VM lifecycle tied to sheet
      return ChangeNotifierProvider<SubmitRequestViewModel>.value(
        value: vm,
        child: _SubmitRequestSheetContent(
          formKey: formKey,
          priceCtrl: priceCtrl,
          daysCtrl: daysCtrl,
          noteCtrl: noteCtrl,
          budget: budget,
          taskId: taskId,
          controller: controller,
          onReplaced: onReplaced,
        ),
      );
    },
  );
}

/// The actual sheet content widget.
class _SubmitRequestSheetContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController priceCtrl;
  final TextEditingController daysCtrl;
  final TextEditingController noteCtrl;
  final String budget;
  final String taskId;
  final TaskRequestsViewModel controller;
  final OnBidReplacedCallback? onReplaced;

  const _SubmitRequestSheetContent({
    required this.formKey,
    required this.priceCtrl,
    required this.daysCtrl,
    required this.noteCtrl,
    required this.budget,
    required this.taskId,
    required this.controller,
    this.onReplaced,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SubmitRequestViewModel>();
    final amberColors = context.amberColors;
    final insets = MediaQuery.of(context).viewInsets;

    return Container(
      key: Key(
        vm.isReplaceMode ? 'replace_bid_sheet' : 'submit_proposal_sheet',
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: amberColors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.r30),
        ),
        border: Border(top: BorderSide(color: amberColors.surfaceHighest)),
        boxShadow: AppDecorations.elevation(
          AmberDuskTokens.surfaces.sheet.elevationLevel,
          isDark: amberColors.isDark,
        ),
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
                color: amberColors.surfaceHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          _buildHeader(amberColors, vm.isReplaceMode),

          // Existing bid summary
          if (vm.isReplaceMode && vm.existingBid != null)
            _buildExistingBidSummary(amberColors, vm.existingBid!),

          const SizedBox(height: AppDimens.p16),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.p24),
              child: _buildForm(amberColors),
            ),
          ),

          // Submit Button
          Padding(
            padding: const EdgeInsets.all(AppDimens.p24),
            child: AppButton(
              text: vm.isReplaceMode ? 'Replace Bid' : 'Submit Proposal',
              onPressed: () => _onSubmit(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AmberDuskColorScheme amberColors, bool isReplace) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.p24),
      child: Row(
        children: [
          if (isReplace)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: amberColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(
                  AmberDuskTokens.spacing.pillRadius,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, color: amberColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'REPLACE',
                    style: AppTypography.captionBold.copyWith(
                      color: amberColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Text(
              isReplace ? 'Replace Your Bid' : 'Submit Proposal',
              style: AppTypography.h4.copyWith(color: amberColors.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingBidSummary(
    AmberDuskColorScheme amberColors,
    TaskRequest existingBid,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.p24),
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: amberColors.surface,
        borderRadius: BorderRadius.circular(AmberDuskTokens.spacing.lg),
        border: Border.all(color: amberColors.surfaceHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Bid (will be archived)',
            style: AppTypography.captionBold.copyWith(color: amberColors.muted),
          ),
          const SizedBox(height: AppDimens.p8),
          Row(
            children: [
              Expanded(
                child: _ExistingBidInfo(
                  icon: Icons.payments_outlined,
                  label: 'Amount',
                  value: price_utils.PriceFormatter.formatPrice(
                    existingBid.price.toDouble(),
                  ),
                ),
              ),
              Expanded(
                child: _ExistingBidInfo(
                  icon: Icons.calendar_today,
                  label: 'Days',
                  value: '${existingBid.days} days',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AmberDuskColorScheme amberColors) {
    return Form(
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
                      'Amount (IQD)',
                      style: AppTypography.captionBold.copyWith(
                        color: amberColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p8),
                    AppTextField(
                      controller: priceCtrl,
                      hintText: budget,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(
                        Icons.payments_outlined,
                        color: amberColors.primary,
                        size: 18,
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) {
                          return 'Enter a price greater than 0';
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
                        color: amberColors.muted,
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
            style: AppTypography.captionBold.copyWith(color: amberColors.muted),
          ),
          const SizedBox(height: AppDimens.p8),
          AppTextField(
            controller: noteCtrl,
            hintText: 'Explain why you are the best fit for this job...',
            maxLines: 6,
          ),
          const SizedBox(height: AppDimens.p24),
          // Upload Placeholder
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: amberColors.surfaceHighest),
              borderRadius: BorderRadius.circular(AppDimens.r14),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file,
                    color: amberColors.muted.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload Files (Coming Soon)',
                    style: AppTypography.captionBold.copyWith(
                      color: amberColors.muted.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSubmit(BuildContext context) async {
    final vm = context.read<SubmitRequestViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!formKey.currentState!.validate()) return;

    final priceDouble = double.parse(priceCtrl.text.trim());
    final days = int.parse(daysCtrl.text.trim());
    final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();

    if (vm.isReplaceMode || vm.isResubmitMode) {
      // Replace or resubmit existing bid
      final priceIqd = priceDouble.round();
      if (vm.isReplaceMode && vm.existingBid != null) {
        // Show confirmation dialog before replacing
        if (!context.mounted) return;
        final confirmed = await _showConfirmReplaceDialog(
          context,
          existing: vm.existingBid!,
          newPriceIqd: priceIqd,
          newDays: days,
          newNote: note,
        );
        if (!confirmed) return;
      }

      final replaced = await vm.replaceBid(
        price: priceDouble,
        days: days,
        note: note,
      );
      if (!context.mounted) return;

      if (replaced != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  vm.isReplaceMode
                      ? 'Bid replaced successfully'
                      : 'Bid submitted successfully',
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        onReplaced?.call(replaced);
        if (context.mounted) navigator.pop(replaced);
      } else {
        // Check if task was closed
        if (vm.isTaskClosedError) {
          await controller.loadForTask(taskId);
        }
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(vm.submitError ?? 'Failed to submit bid'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // First-time submission
      final ok = await vm.submitNewBid(
        price: priceDouble,
        days: days,
        note: note,
      );
      if (!context.mounted) return;
      if (ok) {
        navigator.pop();
      }
      // Error shown via VM errorMessage in controller
    }
  }

  /// Confirmation dialog for bid replacement with comparison.
  Future<bool> _showConfirmReplaceDialog(
    BuildContext context, {
    required TaskRequest existing,
    required int newPriceIqd,
    required int newDays,
    String? newNote,
  }) async {
    final priceDiff = newPriceIqd - existing.price;
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

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dCtx) {
            final amberColors = dCtx.amberColors;
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.swap_horiz, color: amberColors.primary),
                  const SizedBox(width: 8),
                  const Text('Replace your bid?'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _WarningBanner(
                      text:
                          'Your current bid will be archived and replaced with the new one. This action cannot be undone.',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'CURRENT BID',
                      style: AppTypography.captionBold.copyWith(
                        color: amberColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ComparisonRow(
                      label: 'Price',
                      value: price_utils.PriceFormatter.formatPrice(
                        existing.price.toDouble(),
                      ),
                    ),
                    _ComparisonRow(
                      label: 'Delivery',
                      value: '${existing.days} days',
                    ),
                    if ((existing.note ?? '').isNotEmpty)
                      _ComparisonRow(
                        label: 'Note',
                        value: existing.note!,
                        isMultiline: true,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'NEW BID',
                      style: AppTypography.captionBold.copyWith(
                        color: amberColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ComparisonRow(
                      label: 'Price',
                      value: price_utils.PriceFormatter.formatPrice(
                        newPriceIqd.toDouble(),
                      ),
                      changeIndicator: priceDiffText,
                      changeColor: priceDiff > 0
                          ? amberColors.success
                          : priceDiff < 0
                          ? amberColors.danger
                          : amberColors.muted,
                    ),
                    _ComparisonRow(
                      label: 'Delivery',
                      value: '$newDays days',
                      changeIndicator: daysDiffText,
                      changeColor: daysDiff > 0
                          ? amberColors.danger
                          : daysDiff < 0
                          ? amberColors.success
                          : amberColors.muted,
                    ),
                    if ((newNote ?? '').isNotEmpty)
                      _ComparisonRow(
                        label: 'Note',
                        value: newNote!,
                        isMultiline: true,
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dCtx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: amberColors.primary,
                    foregroundColor: amberColors.textInverse,
                  ),
                  onPressed: () => Navigator.pop(dCtx, true),
                  child: const Text('Replace Bid'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

// ---------------------------------------------------------------------------
// Extracted widget components
// ---------------------------------------------------------------------------

/// Displays a single info item for the existing bid summary.
class _ExistingBidInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ExistingBidInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;
    return Row(
      children: [
        Icon(icon, size: 16, color: amberColors.muted),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: amberColors.muted,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: amberColors.text,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A comparison row for the replace confirmation dialog.
class _ComparisonRow extends StatelessWidget {
  final String label;
  final String value;
  final String? changeIndicator;
  final Color? changeColor;
  final bool isMultiline;

  const _ComparisonRow({
    required this.label,
    required this.value,
    this.changeIndicator,
    this.changeColor,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;
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
              style: AppTypography.caption.copyWith(color: amberColors.muted),
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
                    color: amberColors.text,
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
                      color: (changeColor ?? Colors.grey).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      changeIndicator!,
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
}

/// Warning banner used in the replace confirmation dialog.
class _WarningBanner extends StatelessWidget {
  final String text;
  const _WarningBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: amberColors.warningMuted,
        borderRadius: BorderRadius.circular(AppDimens.r8),
        border: Border.all(color: amberColors.warning),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: amberColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(color: amberColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
