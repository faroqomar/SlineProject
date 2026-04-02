import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/app/main_navigation_screen.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/core/providers/system_config_view_model.dart';
import 'package:sline_app/features/auth/viewmodels/auth_form_view_model.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/auth/view/forgot_password_screen.dart';

/// Login screen for user authentication (MVVM) with Glassmorphism design.
///
/// Architecture: Uses a local AuthFormViewModel provider for scoped state.
/// The View handles navigation and SnackBar display based on ViewModel state,
/// keeping the ViewModel framework-agnostic.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.authViewModelFactory,
    this.mainNavigationBuilder,
  });

  final AuthFormViewModel Function()? authViewModelFactory;
  final WidgetBuilder? mainNavigationBuilder;

  static const Key emailFieldKey = ValueKey<String>('login_email_field');
  static const Key passwordFieldKey = ValueKey<String>('login_password_field');
  static const Key signInButtonKey = ValueKey<String>('login_sign_in_button');

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final sessionVm = context.read<AuthSessionViewModel>();
        final sessionError = sessionVm.error;
        if (sessionError != null && sessionError.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(sessionError)));
          sessionVm.clearError();
        }
      } on Exception catch (_) {
        // AuthSessionViewModel not provided (e.g. in tests)
      } on Error catch (_) {
        // ProviderNotFoundException extends Error
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle login action - calls ViewModel and manages navigation/feedback.
  Future<void> _handleLogin(AuthFormViewModel authVM) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await authVM.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful')));
      unawaited(
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                widget.mainNavigationBuilder ??
                (_) => const MainNavigationScreen(),
          ),
        ),
      );
    } else {
      // Show error from ViewModel
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authVM.error ?? 'Login failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    final signupsDisabled =
        context.watch<SystemConfigViewModel?>()?.config.disableSignups ?? false;

    return ChangeNotifierProvider(
      create: (_) => widget.authViewModelFactory?.call() ?? AuthFormViewModel(),
      child: Scaffold(
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.p32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- Header ---
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(AppDimens.r20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'S',
                            style: AppTypography.h1.copyWith(
                              fontSize: 36,
                              color: AppColors.offWhite,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.p24),

                      // Title
                      Text(
                        'Welcome Back',
                        style: AppTypography.h1.copyWith(
                          color: colorScheme.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimens.p8),

                      // Subtitle
                      Text(
                        'Sign in to continue to SLine',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (signupsDisabled) ...[
                        const SizedBox(height: AppDimens.p8),
                        Text(
                          'New account registration is currently disabled.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.lightRed,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: AppDimens.p32),

                      // --- Form Fields ---
                      // Email
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
                        fieldKey: LoginScreen.emailFieldKey,
                        controller: _emailController,
                        hintText: 'your@email.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimens.p16),

                      // Password
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Password',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.p8),
                      AppTextField(
                        fieldKey: LoginScreen.passwordFieldKey,
                        controller: _passwordController,
                        hintText: 'Enter your password',
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.p24),

                      // --- Actions ---
                      // Login Button
                      Consumer<AuthFormViewModel>(
                        builder: (context, authVM, child) {
                          return AppButton(
                            tapTargetKey: LoginScreen.signInButtonKey,
                            text: 'Sign In',
                            isLoading: authVM.isLoading,
                            width: double.infinity,
                            onPressed: () => _handleLogin(authVM),
                          );
                        },
                      ),
                      const SizedBox(height: AppDimens.p24),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                            child: Text(
                              'Sign Up',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
