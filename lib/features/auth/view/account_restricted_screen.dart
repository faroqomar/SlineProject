import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

/// Account status gate shown when the current user cannot continue in-app.
class AccountRestrictedScreen extends StatefulWidget {
  /// Creates the restricted-account route for the current account status.
  const AccountRestrictedScreen({super.key, required this.status, this.reason});

  final String status;
  final String? reason;

  @override
  State<AccountRestrictedScreen> createState() =>
      _AccountRestrictedScreenState();
}

class _AccountRestrictedScreenState extends State<AccountRestrictedScreen>
    with SingleTickerProviderStateMixin {
  static const String _supportEmail = 'support@sline.app';

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

  Future<void> _contactSupport() async {
    AppLogger.i('Contact support tapped', tag: 'Auth');

    final reason = widget.reason?.trim();
    final reasonLine = (reason?.isNotEmpty ?? false)
        ? 'Reason shown in app: $reason\n'
        : '';
    final mailtoUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: <String, String>{
        'subject': 'Account Restricted',
        'body':
            'Hello SLine Support,\n\n'
            'My account is marked as ${widget.status}.\n'
            '$reasonLine\n'
            'Please help me review this restriction.',
      },
    );

    try {
      final launched = await launchUrl(
        mailtoUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;

      AppLogger.w('Contact support mail client launch failed', tag: 'Auth');
    } on Exception catch (e, st) {
      AppLogger.e(
        'Contact support mail client launch failed',
        tag: 'Auth',
        error: e,
        stackTrace: st,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open email. Please contact $_supportEmail.'),
      ),
    );
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
              child: AppCardContainer(
                padding: const EdgeInsets.all(AppDimens.p24),
                borderRadius: BorderRadius.circular(AppDimens.r24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated shield icon with fade entrance
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: AppDimens.emptyStateIconContainer,
                        height: AppDimens.emptyStateIconContainer,
                        decoration: BoxDecoration(
                          color: colorScheme.danger.withAlpha(
                            (0.1 * 255).round(),
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shield,
                          size: AppDimens.emptyStateIconSize,
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
                      onPressed: _contactSupport,
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
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            ),
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
      ),
    );
  }
}
