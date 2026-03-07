import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/auth/viewmodels/auth_form_view_model.dart';

class ResetPasswordUpdateScreen extends StatefulWidget {
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

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate(AuthFormViewModel authVM) async {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (password != confirm) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    final success = await authVM.updatePassword(password);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVM.error ?? 'Failed to update password')),
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.p24),
            child: Form(
              key: _formKey,
              child: Column(
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
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
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
                  const SizedBox(height: AppDimens.p32),

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
            ),
          ),
        ),
      ),
    );
  }
}
