import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';

/// System gate shown when SLine is temporarily unavailable for maintenance.
class MaintenanceScreen extends StatefulWidget {
  /// Creates the maintenance gate with optional server-provided copy.
  const MaintenanceScreen({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    AppLogger.d('Maintenance screen displayed', tag: 'Auth');
    _rotationController = AnimationController(
      vsync: this,
      // Slow looping motion keeps the gate alive without implying urgency.
      duration: AppMotion.dramatic,
    );
    unawaited(_rotationController.repeat());
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    widget.onRetry?.call();
    // Allow a brief loading indication before resetting
    await Future<void>.delayed(AppMotion.emphasis);
    if (!mounted) return;
    setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: Semantics(
        label: 'App under maintenance',
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
                    RotationTransition(
                      turns: _rotationController,
                      child: Container(
                        width: AppDimens.emptyStateIconContainer,
                        height: AppDimens.emptyStateIconContainer,
                        decoration: BoxDecoration(
                          color: colorScheme.warning.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.build,
                          size: AppDimens.emptyStateIconSize,
                          color: colorScheme.warning,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.p24),
                    Text(
                      "We'll be back soon",
                      style: AppTypography.h4.copyWith(color: colorScheme.text),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.p12),
                    Text(
                      widget.message?.isNotEmpty ?? false
                          ? widget.message!
                          : 'We are improving SLine right now. '
                                'Please try again shortly.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.p32),
                    AppButton(
                      text: 'Try Again',
                      isLoading: _isRetrying,
                      width: double.infinity,
                      onPressed: _handleRetry,
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
