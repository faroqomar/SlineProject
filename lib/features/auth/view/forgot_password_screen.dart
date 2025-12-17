import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/auth/viewmodels/auth_view_model.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset(AuthViewModel authVM) async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final success = await authVM.resetPassword(email);

    if (!mounted) return;

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent! Check your email.'),
          backgroundColor: AppColors.teal,
        ),
      );
      Navigator.pop(context); // Return to login
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVM.error ?? 'Failed to send reset link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.text),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.authGradientStart,
                colorScheme.authGradientEnd,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.p32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: AppDimens.p48),
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        size: 40,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p24),

                    // Title
                    Text(
                      'Forgot Password?',
                      style: AppTypography.h1.copyWith(color: colorScheme.text),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.p8),

                    // Subtitle
                    Text(
                      'Enter your email address to receive a password reset link.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.p40),

                    // Email Field
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.p8),
                    AppTextField(
                      controller: _emailController,
                      hintText: 'your@email.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.p32),

                    // Action Button
                    Consumer<AuthViewModel>(
                      builder: (context, authVM, child) {
                        return AppButton(
                          text: 'Send Reset Link',
                          isLoading: authVM.isLoading,
                          width: double.infinity,
                          onPressed: () => _handleReset(authVM),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
