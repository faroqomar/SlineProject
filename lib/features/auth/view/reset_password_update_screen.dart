import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/auth/viewmodels/auth_form_view_model.dart';

/// Password update screen for users returning from a reset link.
class ResetPasswordUpdateScreen extends StatefulWidget {
  /// Creates the reset-password update route.
  const ResetPasswordUpdateScreen({super.key});

  static const Key passwordFieldKey = ValueKey<String>('reset_password_field');
  static const Key confirmPasswordFieldKey = ValueKey<String>(
    'reset_confirm_password_field',
  );
  static const Key updatePasswordButtonKey = ValueKey<String>(
    'reset_update_button',
  );

  @override
  State<ResetPasswordUpdateScreen> createState() =>
      _ResetPasswordUpdateScreenState();
}

class _ResetPasswordUpdateScreenState extends State<ResetPasswordUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordUpdated = false;
  int _countdown = 3;
  Timer? _countdownTimer;
  String? _inlineError;

  // Password requirement checks
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp('[A-Z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp('[0-9]'));
  bool get _hasSpecialChar =>
      _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController
      ..removeListener(_onPasswordChanged)
      ..dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        timer.cancel();
        if (!mounted) return;
        unawaited(
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          ),
        );
      }
    });
  }

  Future<void> _handleUpdate(AuthFormViewModel authVM) async {
    setState(() => _inlineError = null);

    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (password != confirm) {
      setState(() => _inlineError = 'Passwords do not match');
      return;
    }

    if (!_hasMinLength || !_hasUppercase || !_hasNumber || !_hasSpecialChar) {
      setState(() => _inlineError = 'Please meet all password requirements');
      return;
    }

    final success = await authVM.updatePassword(password);

    if (!mounted) return;

    if (success) {
      AppLogger.i('Password reset successful, redirecting...', tag: 'Auth');
      setState(() => _passwordUpdated = true);
      _startCountdown();
    } else {
      setState(
        () => _inlineError = authVM.error ?? 'Failed to update password',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return ChangeNotifierProvider(
      create: (_) => AuthFormViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Reset Password', style: AppTypography.h3),
          backgroundColor: AmberDuskColors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.p24),
            child: AnimatedSwitcher(
              duration: AppMotion.standard,
              switchInCurve: AppMotion.curveStandard,
              switchOutCurve: AppMotion.curveAccel,
              child: _passwordUpdated
                  ? _buildSuccessView(colorScheme)
                  : _buildFormView(colorScheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(AppColorScheme colorScheme) {
    return Column(
      key: const ValueKey<String>('success_view'),
      children: [
        const SizedBox(height: AppDimens.p48),
        Semantics(
          label: 'Password updated successfully',
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: colorScheme.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: AppLayout.iconFeature,
              color: colorScheme.success,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.p24),
        Text(
          'Password Updated!',
          style: AppTypography.h4.copyWith(color: colorScheme.text),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.p12),
        Text(
          'Redirecting in $_countdown...',
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormView(AppColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey<String>('form_view'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter your new password below.',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.p24),

          Text(
            'New Password',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.text,
            ),
          ),
          const SizedBox(height: AppDimens.p8),
          AppTextField(
            key: ResetPasswordUpdateScreen.passwordFieldKey,
            controller: _passwordController,
            hintText: 'Enter new password',
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimens.p12),

          // Password requirements checklist
          _PasswordRequirement(
            label: 'At least 8 characters',
            isMet: _hasMinLength,
          ),
          _PasswordRequirement(
            label: 'At least 1 uppercase letter',
            isMet: _hasUppercase,
          ),
          _PasswordRequirement(label: 'At least 1 number', isMet: _hasNumber),
          _PasswordRequirement(
            label: 'At least 1 special character',
            isMet: _hasSpecialChar,
          ),

          const SizedBox(height: AppDimens.p16),

          Text(
            'Confirm Password',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.text,
            ),
          ),
          const SizedBox(height: AppDimens.p8),
          AppTextField(
            key: ResetPasswordUpdateScreen.confirmPasswordFieldKey,
            controller: _confirmPasswordController,
            hintText: 'Confirm new password',
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimens.p16),

          // Inline error message
          if (_inlineError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.p16),
              child: Text(
                _inlineError!,
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.danger,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          Consumer<AuthFormViewModel>(
            builder: (context, authVM, child) {
              return AppButton(
                key: ResetPasswordUpdateScreen.updatePasswordButtonKey,
                text: 'Update Password',
                isLoading: authVM.isLoading,
                onPressed: () => _handleUpdate(authVM),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A single password requirement row with animated icon transition.
class _PasswordRequirement extends StatelessWidget {
  const _PasswordRequirement({required this.label, required this.isMet});

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.p4),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: AppMotion.fast,
            switchInCurve: AppMotion.curveStandard,
            switchOutCurve: AppMotion.curveAccel,
            child: isMet
                ? Icon(
                    Icons.check_circle,
                    key: const ValueKey<String>('check'),
                    size: AppDimens.p18,
                    color: colorScheme.success,
                  )
                : Icon(
                    Icons.circle_outlined,
                    key: const ValueKey<String>('circle'),
                    size: AppDimens.p18,
                    color: colorScheme.textSecondary,
                  ),
          ),
          const SizedBox(width: AppDimens.p8),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: AppMotion.fast,
              style: AppTypography.bodySmall.copyWith(
                color: isMet ? colorScheme.success : colorScheme.textSecondary,
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
