import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/portfolio/viewmodels/portfolio_view_model.dart';

/// Bottom sheet for adding a portfolio proof item with an optional image.
///
/// The sheet gathers UI input only; [PortfolioViewModel.addItem] still owns
/// storage upload, repository writes, and public portfolio bucket behavior.
class AddPortfolioSheet extends StatefulWidget {
  /// Creates the add-portfolio sheet for the supplied ViewModel.
  const AddPortfolioSheet({
    super.key,
    required this.controller,
    required this.onCreated,
  });

  /// Controller that owns portfolio validation, storage upload, and persistence.
  final PortfolioViewModel controller;

  /// Called after a successful create so the host route can close the sheet.
  final VoidCallback onCreated;

  @override
  State<AddPortfolioSheet> createState() => _AddPortfolioSheetState();
}

class _AddPortfolioSheetState extends State<AddPortfolioSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageFilename;
  bool _submitting = false;

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery and store bytes + filename locally.
  Future<void> _pickImage() async {
    AppLogger.i('Picking portfolio image', tag: 'AddPortfolioSheet');
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (picked == null) {
        AppLogger.d('User cancelled image picker', tag: 'AddPortfolioSheet');
        return;
      }

      final bytes = await picked.readAsBytes();
      AppLogger.i(
        'Image picked',
        tag: 'AddPortfolioSheet',
        json: {'filename': picked.name, 'size': bytes.length},
      );

      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageFilename = picked.name;
      });
    } on Exception catch (e, st) {
      AppLogger.e(
        'Image pick failed',
        tag: 'AddPortfolioSheet',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick image. Please try again.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      AppLogger.d('Form validation failed', tag: 'AddPortfolioSheet');
      return;
    }

    AppLogger.i(
      'Submitting portfolio item',
      tag: 'AddPortfolioSheet',
      json: {'title': _title.text.trim(), 'hasImage': _imageBytes != null},
    );

    setState(() => _submitting = true);

    final ok = await widget.controller.addItem(
      title: _title.text.trim(),
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      imageBytes: _imageBytes,
      imageFilename: _imageFilename,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      AppLogger.i(
        'Portfolio item added successfully',
        tag: 'AddPortfolioSheet',
      );
      widget.onCreated();
    } else {
      AppLogger.w(
        'Failed to add portfolio item',
        tag: 'AddPortfolioSheet',
        json: {'error': widget.controller.error},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.error ??
                'Failed to create item. Please try again.',
          ),
        ),
      );
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
                  'Add Portfolio Item',
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
                const SizedBox(height: AppDimens.p12),
                AppCardContainer(
                  padding: const EdgeInsets.all(AppDimens.p12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.image,
                        color: amberColors.primary,
                        size: AppLayout.iconStandard,
                      ),
                      const SizedBox(width: AppDimens.p12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _imageFilename ?? 'No image selected',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                color: colorScheme.text,
                              ),
                            ),
                            Text(
                              'Image is optional',
                              style: AppTypography.caption.copyWith(
                                color: colorScheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _pickImage,
                        child: const Text('Pick image'),
                      ),
                    ],
                  ),
                ),
                if (_imageBytes != null) ...[
                  const SizedBox(height: AppDimens.p12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.r12),
                    child: Image.memory(
                      _imageBytes!,
                      height: AppDimens.p80 + AppDimens.p80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
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
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? SizedBox(
                            height: AppInteractionStates.loadingSize,
                            width: AppInteractionStates.loadingSize,
                            child: CircularProgressIndicator(
                              strokeWidth:
                                  AppInteractionStates.loadingStrokeWidth,
                              color: amberColors.textInverse,
                            ),
                          )
                        : const Text('Create'),
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
