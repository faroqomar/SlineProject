import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';

class AccountRestrictedScreen extends StatefulWidget {
  const AccountRestrictedScreen({super.key, required this.status, this.reason});

  final String status;
  final String? reason;

  @override
  State<AccountRestrictedScreen> createState() =>
      _AccountRestrictedScreenState();
}

class _AccountRestrictedScreenState extends State<AccountRestrictedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    AppLogger.w('Account restricted screen displayed', tag: 'Auth');
    _fadeController = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: AppMotion.curveStandard),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final label = widget.status == 'banned'
        ? 'Account Banned'
        : 'Account Suspended';

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: Semantics(
        label: 'Account restricted',
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.p24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated shield icon with fade entrance
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: colorScheme.danger.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield,
                        size: 48,
                        color: colorScheme.danger,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.p24),
                  Text(
                    label,
                    style: AppTypography.h4.copyWith(color: colorScheme.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.p12),
                  Text(
                    widget.reason?.isNotEmpty ?? false
                        ? widget.reason!
                        : 'Your account is currently restricted. '
                              'Please contact support for details.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.p32),

                  // Contact Support button
                  AppButton(
                    text: 'Contact Support',
                    width: double.infinity,
                    onPressed: () {
                      AppLogger.i('Contact support tapped', tag: 'Auth');
                    },
                  ),
                  const SizedBox(height: AppDimens.p12),

                  // Log Out text button (muted styling)
                  Semantics(
                    button: true,
                    label: 'Log out',
                    child: TextButton(
                      onPressed: () async {
                        final authVm = context.read<AuthSessionViewModel>();
                        await authVm.logout();
                        if (!context.mounted) return;
                        unawaited(
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/login', (route) => false),
                        );
                      },
                      child: Text(
                        'Log Out',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    ),
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
