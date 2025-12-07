import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/auth/viewmodels/auth_view_model.dart';

/// Signup screen (MVVM) with Glassmorphism design.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
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
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.p32, vertical: AppDimens.p24),
                child: Consumer<AuthViewModel>(
                  builder: (context, authVM, _) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // --- Header ---
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
                        
                        Text(
                          'Create Account',
                          style: AppTypography.h1.copyWith(
                            color: colorScheme.text,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimens.p8),
                        
                        Text(
                          'Join SLine today',
                          style: AppTypography.bodyMedium.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimens.p32),

                        // --- Form Fields ---
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Full Name',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimens.p8),
                        AppTextField(
                          controller: _nameController,
                          hintText: 'John Doe',
                        ),
                        const SizedBox(height: AppDimens.p16),

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
                        ),
                        const SizedBox(height: AppDimens.p16),

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
                          controller: _passwordController,
                          hintText: 'Create a password',
                          obscureText: true,
                        ),
                        const SizedBox(height: AppDimens.p16),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Confirm Password',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimens.p8),
                        AppTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm password',
                          obscureText: true,
                        ),
                        const SizedBox(height: AppDimens.p24),

                        // --- Actions ---
                        AppButton(
                          text: 'Create Account',
                          isLoading: authVM.isLoading,
                          width: double.infinity,
                          onPressed: () async {
                            final name = _nameController.text.trim();
                            final email = _emailController.text.trim();
                            final password = _passwordController.text.trim();
                            final confirm = _confirmPasswordController.text.trim();

                            if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All fields are required')),
                              );
                              return;
                            }
                            if (password != confirm) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Passwords do not match')),
                              );
                              return;
                            }
                            await authVM.register(
                              state: this,
                              email: email,
                              password: password,
                              fullName: name,
                            );
                          },
                        ),
                        const SizedBox(height: AppDimens.p24),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: colorScheme.divider)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppDimens.p8),
                              child: Text(
                                'OR',
                                style: AppTypography.captionBold.copyWith(
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: colorScheme.divider)),
                          ],
                        ),
                        const SizedBox(height: AppDimens.p24),

                        // Social Logins
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(context, '🔍'), // Google
                            const SizedBox(width: AppDimens.p12),
                            _buildSocialButton(context, '📘'), // Facebook
                            const SizedBox(width: AppDimens.p12),
                            _buildSocialButton(context, '🍎'), // Apple
                          ],
                        ),
                        const SizedBox(height: AppDimens.p24),

                        // Sign In Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: AppTypography.bodySmall.copyWith(
                                color: colorScheme.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Sign In',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(BuildContext context, String icon) {
    final AppColorScheme colorScheme = context.colorScheme;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: colorScheme.authInputBackground,
        borderRadius: BorderRadius.circular(AppDimens.r14),
        border: Border.all(color: colorScheme.authInputBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.r14),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppDimens.r14),
          child: Center(
            child: Text(
              icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }
}
