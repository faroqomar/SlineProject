import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/auth/viewmodels/auth_form_view_model.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const Key emailFieldKey = ValueKey<String>('forgot_email_field');
  static const Key sendResetLinkButtonKey = ValueKey<String>(
    'forgot_send_link_button',
  );

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _emailSent = false;
  String _sentToEmail = '';

  late final AnimationController _iconScaleController;
  late final Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();
    _iconScaleController = AnimationController(
      vsync: this,
      duration: AppMotion.emphasis,
    );
    _iconScaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _iconScaleController,
        curve: AppMotion.curveSpring,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _iconScaleController.dispose();
    super.dispose();
  }

  Future<void> _handleReset(AuthFormViewModel authVM) async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final success = await authVM.resetPassword(email);

    if (!mounted) return;

    if (success) {
      AppLogger.i('Password reset email sent', tag: 'Auth');
      setState(() {
        _emailSent = true;
        _sentToEmail = email;
      });
      unawaited(_iconScaleController.forward());
    } else {
      AppLogger.e('Password reset failed', tag: 'Auth', error: authVM.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => AuthFormViewModel(),
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
              child: AnimatedSwitcher(
                duration: AppMotion.standard,
                switchInCurve: AppMotion.curveStandard,
                switchOutCurve: AppMotion.curveAccel,
                child: _emailSent
                    ? _buildSuccessView(colorScheme)
                    : _buildFormView(colorScheme),
              ),
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
        const SizedBox(height: AppDimens.p80),
        // Animated mail icon
        ScaleTransition(
          scale: _iconScaleAnimation,
          child: Semantics(
            label: 'Email sent successfully',
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mail_outline_rounded,
                size: 48,
                color: colorScheme.success,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.p24),

        // Title
        Text(
          'Check your inbox',
          style: AppTypography.h4.copyWith(color: colorScheme.text),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.p12),

        // Body
        Text(
          'We sent a reset link to $_sentToEmail',
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.p40),

        // Back to Login button
        AppButton(
          text: 'Back to Login',
          width: double.infinity,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildFormView(AppColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey<String>('form_view'),
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
            key: ForgotPasswordScreen.emailFieldKey,
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
          const SizedBox(height: AppDimens.p16),

          // Inline error message
          Consumer<AuthFormViewModel>(
            builder: (context, authVM, child) {
              if (authVM.error == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.p16),
                child: Text(
                  authVM.error!,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.danger,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),

          // Action Button
          Consumer<AuthFormViewModel>(
            builder: (context, authVM, child) {
              return AppButton(
                key: ForgotPasswordScreen.sendResetLinkButtonKey,
                text: 'Send Reset Link',
                isLoading: authVM.isLoading,
                width: double.infinity,
                onPressed: () => _handleReset(authVM),
              );
            },
          ),
        ],
      ),
    );
  }
}
