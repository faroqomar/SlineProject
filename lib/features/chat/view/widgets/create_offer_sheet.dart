import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';

/// Bottom sheet for creating custom offers in chat.
///
/// Phase 5 redesign: normalized all dimension tokens, added shake animation
/// on validation failure using `AppInteractionStates.shakeAmplitude` and
/// `shakeDuration`, added Semantics labels to all form fields and submit
/// button. View-layer only.
class CreateOfferSheet extends StatefulWidget {
  final Function(
    String title,
    String description,
    String price,
    String deliveryDays,
  )
  onSubmit;

  const CreateOfferSheet({super.key, required this.onSubmit});

  @override
  State<CreateOfferSheet> createState() => _CreateOfferSheetState();
}

class _CreateOfferSheetState extends State<CreateOfferSheet>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveryController = TextEditingController(text: '3');

  // ── Shake animation for validation failure ────────────────
  // Horizontal shake using AppInteractionStates tokens
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: AppInteractionStates.shakeDuration,
      vsync: this,
    );

    // Sine-wave shake: 0 → amplitude → 0 → -amplitude → 0 (3 oscillations)
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(begin: 0, end: AppInteractionStates.shakeAmplitude),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: AppInteractionStates.shakeAmplitude,
              end: -AppInteractionStates.shakeAmplitude,
            ),
            weight: 2,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: -AppInteractionStates.shakeAmplitude,
              end: AppInteractionStates.shakeAmplitude,
            ),
            weight: 2,
          ),
          TweenSequenceItem(
            tween: Tween(begin: AppInteractionStates.shakeAmplitude, end: 0.0),
            weight: 1,
          ),
        ]).animate(
          // Symmetric ease for natural shake oscillation
          CurvedAnimation(
            parent: _shakeController,
            curve: AppMotion.curveSymmetric,
          ),
        );
  }

  @override
  void dispose() {
    _shakeController.dispose();
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
      // Shake + haptic on validation failure
      AppInteractionStates.hapticHeavy();
      unawaited(_shakeController.forward(from: 0));
      AppLogger.d(
        'CreateOfferSheet: validation failed — title or price empty',
        tag: 'Chat',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and price')),
      );
      return;
    }

    // Validate that price is a positive integer — non-numeric input would
    // reach the ViewModel as an unparseable string and cause a runtime error.
    final parsedPrice = int.tryParse(price);
    if (parsedPrice == null || parsedPrice <= 0) {
      AppInteractionStates.hapticHeavy();
      unawaited(_shakeController.forward(from: 0));
      AppLogger.d(
        'CreateOfferSheet: validation failed — price is not a valid positive number',
        tag: 'Chat',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be a valid positive number')),
      );
      return;
    }

    // Validate delivery days only when the user has provided a value — it is
    // an optional field, but if filled it must be a positive integer.
    if (delivery.isNotEmpty) {
      final parsedDelivery = int.tryParse(delivery);
      if (parsedDelivery == null || parsedDelivery <= 0) {
        AppInteractionStates.hapticHeavy();
        unawaited(_shakeController.forward(from: 0));
        AppLogger.d(
          'CreateOfferSheet: validation failed — delivery days is not a valid positive number',
          tag: 'Chat',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery days must be a valid positive number'),
          ),
        );
        return;
      }
    }

    AppInteractionStates.hapticTap();
    AppLogger.i('CreateOfferSheet: offer submitted', tag: 'Chat');
    widget.onSubmit(title, description, price, delivery);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Semantics(
      label: 'Create custom offer form',
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            // Horizontal shake offset from animation
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: amberColors.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimens.r30),
            ),
            border: Border.all(color: amberColors.surfaceHighest),
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
                // Handle bar — consistent dimensions
                Center(
                  child: Container(
                    width: AppDimens.p48,
                    height: AppLayout.spacingTight,
                    decoration: BoxDecoration(
                      color: amberColors.surfaceHighest,
                      borderRadius: BorderRadius.circular(AppDimens.r4),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.p24),

                // Title
                Text(
                  'Create Custom Offer',
                  style: AppTypography.h4.copyWith(color: amberColors.text),
                ),
                const SizedBox(height: AppDimens.p20),

                // Title input
                _buildLabel('Title', amberColors),
                const SizedBox(height: AppDimens.p8),
                Semantics(
                  label: 'Offer title',
                  textField: true,
                  child: AppTextField(
                    controller: _titleController,
                    hintText: 'e.g., Performance Optimization Package',
                  ),
                ),
                const SizedBox(height: AppDimens.p16),

                // Description input
                _buildLabel('Description', amberColors),
                const SizedBox(height: AppDimens.p8),
                Semantics(
                  label: 'Offer description',
                  textField: true,
                  child: Container(
                    decoration: BoxDecoration(
                      color: amberColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppDimens.r14),
                      border: Border.all(color: amberColors.surfaceHighest),
                    ),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      cursorColor: amberColors.primary,
                      style: TextStyle(color: amberColors.text),
                      decoration: InputDecoration(
                        hintText: 'Describe what you will deliver...',
                        hintStyle: TextStyle(color: amberColors.muted),
                        filled: false,
                        fillColor: AmberDuskColors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.all(AppDimens.p12),
                      ),
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
                          _buildLabel('Amount (IQD)', amberColors),
                          const SizedBox(height: AppDimens.p8),
                          Semantics(
                            label: 'Offer amount in IQD',
                            textField: true,
                            child: AppTextField(
                              controller: _priceController,
                              hintText: '50000',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimens.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Delivery (Days)', amberColors),
                          const SizedBox(height: AppDimens.p8),
                          Semantics(
                            label: 'Delivery time in days',
                            textField: true,
                            child: AppTextField(
                              controller: _deliveryController,
                              hintText: '3',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.p24),

                // Submit button
                Semantics(
                  button: true,
                  label: 'Send offer',
                  child: AppButton(
                    text: 'Send Offer',
                    width: double.infinity,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, AmberDuskColorScheme amberColors) {
    return Text(
      text,
      style: AppTypography.captionBold.copyWith(color: amberColors.textSubtle),
    );
  }
}

/// Show the create offer sheet as a modal bottom sheet.
void showCreateOfferSheet(
  BuildContext context, {
  required Function(
    String title,
    String description,
    String price,
    String deliveryDays,
  )
  onSubmit,
}) {
  unawaited(
    showModalBottomSheet(
      context: context,
      backgroundColor: AmberDuskColors.transparent,
      isScrollControlled: true,
      builder: (context) => CreateOfferSheet(onSubmit: onSubmit),
    ),
  );
}
