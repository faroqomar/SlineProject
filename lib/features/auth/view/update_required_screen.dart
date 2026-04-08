import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';

class UpdateRequiredScreen extends StatefulWidget {
  const UpdateRequiredScreen({super.key, required this.minimumVersion});

  final String minimumVersion;

  @override
  State<UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends State<UpdateRequiredScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    AppLogger.d('Update required screen displayed', tag: 'Auth');
    _slideController = AnimationController(
      vsync: this,
      duration: AppMotion.emphasis,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: AppMotion.curveSpring,
          ),
        );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: Semantics(
        label: 'App update required',
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.p24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated slide-bounce download icon
                  SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.system_update,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.p24),
                  Text(
                    'Update Required',
                    style: AppTypography.h4.copyWith(color: colorScheme.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.p12),
                  Text(
                    'Please update the app to continue. '
                    'Minimum supported version: ${widget.minimumVersion}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.p32),
                  AppButton(
                    text: 'Update Now',
                    width: double.infinity,
                    onPressed: () {
                      // Platform-specific store link would go here
                      AppLogger.i(
                        'Update Now tapped for v${widget.minimumVersion}',
                        tag: 'Auth',
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
