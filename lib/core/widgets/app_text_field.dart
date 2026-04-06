import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_theme.dart';

/// A customizable text input field with a style consistent with the application's design.
///
/// This widget leverages Flutter's [TextFormField] and applies a custom
/// [InputDecoration] to match the translucent background, border behavior,
/// and focus states seen in the React design.
class AppTextField extends StatelessWidget {
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
  final int maxLines; // Added

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
    this.maxLines = 1, // Default 1
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.appTextTheme;

    // The InputDecorationTheme is set in app_theme.dart, but we can override
    // or extend it here for specific AppTextField needs.
    // For this case, the InputDecorationTheme is already designed to match the inputs.
    return TextFormField(
      key: fieldKey,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      maxLines: maxLines, // Pass to TextFormField
      style: textTheme.bodyMedium?.copyWith(color: colorScheme.text),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.textSecondary,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        // The default styles for border, enabledBorder, focusedBorder, filled, fillColor
        // are already defined in `app_theme.dart` within `InputDecorationTheme`.
        // We only override what's necessary here.
        fillColor:
            colorScheme.inputBackground, // Ensure the background is consistent
      ),
      cursorColor:
          colorScheme.primary, // Cursor color matches primary focus color
    );
  }
}
