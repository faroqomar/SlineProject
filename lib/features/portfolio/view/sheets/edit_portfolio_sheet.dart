import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/portfolio/models/portfolio_item.dart';
import 'package:sline_app/features/portfolio/viewmodels/portfolio_view_model.dart';

/// Bottom sheet for editing portfolio title and description fields.
///
/// Image storage stays intentionally out of this sheet so existing portfolio
/// path/public URL behavior remains owned by the ViewModel/repository layer.
class EditPortfolioSheet extends StatefulWidget {
  const EditPortfolioSheet({
    super.key,
    required this.item,
    required this.controller,
  });
  final PortfolioItem item;
  final PortfolioViewModel controller;

  static Future<bool?> open(
    BuildContext context,
    PortfolioItem item,
    PortfolioViewModel controller,
  ) {
    AppLogger.d(
      'Opening edit portfolio sheet',
      tag: 'EditPortfolioSheet',
      json: {'itemId': item.id},
    );
    return showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      barrierColor: context.amberColors.scrim,
      backgroundColor: AmberDuskTokens.colors.transparent,
      builder: (ctx) => _InsetSheetFrame(
        child: EditPortfolioSheet(item: item, controller: controller),
      ),
    );
  }

  @override
  State<EditPortfolioSheet> createState() => _EditPortfolioSheetState();
}

class _EditPortfolioSheetState extends State<EditPortfolioSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(
    text: widget.item.title,
  );
  late final TextEditingController _desc = TextEditingController(
    text: widget.item.description ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      AppLogger.d('Form validation failed', tag: 'EditPortfolioSheet');
      return;
    }

    AppLogger.i(
      'Saving portfolio item changes',
      tag: 'EditPortfolioSheet',
      json: {'itemId': widget.item.id, 'newTitle': _title.text.trim()},
    );

    setState(() => _saving = true);
    try {
      final ok = await widget.controller.updateItem(
        id: widget.item.id,
        title: _title.text.trim(),
        description: _desc.text.trim(),
      );
      if (!mounted) return;
      if (ok) {
        AppLogger.i(
          'Portfolio item updated successfully',
          tag: 'EditPortfolioSheet',
        );
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Updated successfully')));
      } else {
        AppLogger.w(
          'Portfolio item update failed',
          tag: 'EditPortfolioSheet',
          json: {'error': widget.controller.error},
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.controller.error ?? 'Update failed. Please try again.',
            ),
          ),
        );
      }
    } on Exception catch (e, st) {
      AppLogger.e(
        'Error saving portfolio item',
        tag: 'EditPortfolioSheet',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = context.colorScheme;
    final amberColors = context.amberColors;
    final buttonTheme = AmberDuskTokens.widgetTheme.buttons;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.p16,
            AppDimens.p16,
            AppDimens.p16,
            AppDimens.p24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                const SizedBox(height: AppDimens.p12),
                Text(
                  'Edit Portfolio Item',
                  style: AppTypography.h5.copyWith(color: colorScheme.text),
                ),
                const SizedBox(height: AppDimens.p16),
                TextFormField(
                  controller: _title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.text,
                  ),
                  decoration: _fieldDecoration(context, 'Title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppDimens.p12),
                TextFormField(
                  controller: _desc,
                  minLines: 2,
                  maxLines: 5,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.text,
                  ),
                  decoration: _fieldDecoration(
                    context,
                    'Description (optional)',
                  ),
                ),
                const SizedBox(height: AppDimens.p16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: amberColors.primary,
                      foregroundColor: amberColors.textInverse,
                      minimumSize: Size.fromHeight(buttonTheme.minHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(buttonTheme.radius),
                      ),
                      textStyle: buttonTheme.textStyle,
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? SizedBox(
                            height: AppInteractionStates.loadingSize,
                            width: AppInteractionStates.loadingSize,
                            child: CircularProgressIndicator(
                              strokeWidth:
                                  AppInteractionStates.loadingStrokeWidth,
                              color: amberColors.textInverse,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    final colorScheme = context.colorScheme;
    final fieldTheme = AmberDuskTokens.widgetTheme.fields;

    return InputDecoration(
      labelText: label,
      labelStyle: fieldTheme.labelStyle.copyWith(
        color: colorScheme.textSecondary,
      ),
      filled: true,
      fillColor: fieldTheme.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldTheme.radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldTheme.radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldTheme.radius),
        borderSide: BorderSide(color: context.amberColors.primary),
      ),
      contentPadding: fieldTheme.padding,
    );
  }
}

/// Inset frame for edit sheets using the Open Design rounded sheet geometry.
class _InsetSheetFrame extends StatelessWidget {
  const _InsetSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sheetRecipe = AmberDuskTokens.surfaces.sheet;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p10,
        AppDimens.p0,
        AppDimens.p10,
        AppDimens.p10,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: sheetRecipe.fill,
          borderRadius: BorderRadius.circular(sheetRecipe.radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

/// Visual drag affordance for Amber Dusk bottom sheets.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimens.p40,
      height: AppDimens.p4,
      decoration: BoxDecoration(
        color: context.colorScheme.textSecondary.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppDimens.r4),
      ),
    );
  }
}
