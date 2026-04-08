import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

/// A customizable text input field with password toggle, clear button,
/// character counter, and accessibility support.
///
/// ## Phase 1 Changes
/// - Converted from StatelessWidget to StatefulWidget (for toggle/clear state)
/// - Added [showPasswordToggle] — eye icon to toggle obscure text
/// - Added [showClearButton] — X icon that appears when field has value
/// - Added [maxLength] — live character counter below field
/// - Added [Semantics] wrapper for accessibility
/// - Suffix composition: when both toggle + clear are active, both show in a Row
/// - User-provided [suffixIcon] takes priority over toggle/clear
/// - All existing constructor params preserved (backward compatible)
class AppTextField extends StatefulWidget {
  final Key? fieldKey;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int maxLines;

  /// When true and [obscureText] is initially true, shows an eye icon toggle.
  final bool showPasswordToggle;

  /// When true, shows an animated X clear button when the field has value.
  final bool showClearButton;

  /// When set, shows a live character counter below the field.
  final int? maxLength;

  const AppTextField({
    super.key,
    this.fieldKey,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.showPasswordToggle = false,
    this.showClearButton = false,
    this.maxLength,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;
  TextEditingController? _internalController;
  bool _hasValue = false;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_internalController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    // Listen for value changes to show/hide clear button
    if (widget.showClearButton && widget.controller == null) {
      _internalController = TextEditingController();
    }
    _effectiveController.addListener(_onTextChanged);
    _hasValue = _effectiveController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onTextChanged);
    // Only dispose internally-created controllers
    _internalController?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final newHasValue = _effectiveController.text.isNotEmpty;
    if (newHasValue != _hasValue) {
      setState(() => _hasValue = newHasValue);
    }
  }

  void _toggleObscure() {
    setState(() => _obscureText = !_obscureText);
  }

  void _clearField() {
    _effectiveController.clear();
    widget.onChanged?.call('');
  }

  Widget? _buildSuffix() {
    // User-provided suffixIcon takes priority
    if (widget.suffixIcon != null) return widget.suffixIcon;

    final icons = <Widget>[];

    // Password toggle
    if (widget.showPasswordToggle && widget.obscureText) {
      icons.add(
        GestureDetector(
          onTap: _toggleObscure,
          child: Semantics(
            label: _obscureText ? 'Show password' : 'Hide password',
            child: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              size: 20,
            ),
          ),
        ),
      );
    }

    // Clear button (animated fade)
    if (widget.showClearButton && _hasValue) {
      icons.add(
        AnimatedOpacity(
          opacity: _hasValue ? 1.0 : 0.0,
          duration: AppMotion.micro,
          child: GestureDetector(
            onTap: _clearField,
            child: Semantics(
              label: 'Clear text',
              child: const Icon(Icons.close, size: 20),
            ),
          ),
        ),
      );
    }

    if (icons.isEmpty) return null;
    if (icons.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: icons.first,
      );
    }

    // Compose both icons in a Row when both are active
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < icons.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            icons[i],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.appTextTheme;

    final field = TextFormField(
      key: widget.fieldKey,
      controller: _effectiveController,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      validator: widget.validator,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      buildCounter: widget.maxLength != null
          ? (
              context, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) {
              return Text(
                '$currentLength/$maxLength',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.textTertiary,
                ),
              );
            }
          : null,
      style: textTheme.bodyMedium?.copyWith(color: colorScheme.text),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.textSecondary,
        ),
        prefixIcon: widget.prefixIcon,
        suffixIcon: _buildSuffix(),
        fillColor: colorScheme.inputBackground,
      ),
      cursorColor: colorScheme.primary,
    );

    return Semantics(
      textField: true,
      label: widget.hintText ?? '',
      child: field,
    );
  }
}
