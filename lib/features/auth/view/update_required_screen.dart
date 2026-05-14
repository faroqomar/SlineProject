import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:url_launcher/url_launcher.dart';

/// System gate shown when the installed app version can no longer continue.
class UpdateRequiredScreen extends StatefulWidget {
  /// Creates the update gate for the required minimum version.
  const UpdateRequiredScreen({super.key, required this.minimumVersion});

  final String minimumVersion;

  @override
  State<UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends State<UpdateRequiredScreen>
    with SingleTickerProviderStateMixin {
  static const String _androidPackageId = String.fromEnvironment(
    'SLINE_ANDROID_PACKAGE_ID',
    defaultValue: 'com.example.sline_app',
  );
  static const String _iosBundleId = String.fromEnvironment(
    'SLINE_IOS_BUNDLE_ID',
    defaultValue: 'com.example.slineApp',
  );
  static const String _iosAppId = String.fromEnvironment('SLINE_IOS_APP_ID');
  static final Uri _androidMarketUri = Uri.parse(
    'market://details?id=$_androidPackageId',
  );
  static final Uri _androidWebStoreUri = Uri.https(
    'play.google.com',
    '/store/apps/details',
    <String, String>{'id': _androidPackageId},
  );
  static final Uri? _iosAppStoreUri = _iosAppId.isEmpty
      ? null
      : Uri.parse('itms-apps://itunes.apple.com/app/id$_iosAppId');
  static final Uri? _iosWebStoreUri = _iosAppId.isEmpty
      ? null
      : Uri.https('apps.apple.com', '/app/id$_iosAppId');
  static final Uri _webDownloadUri = Uri.https('sline.app', '/download');

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

  List<Uri> _storeUris() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => <Uri>[_androidMarketUri, _androidWebStoreUri],
      TargetPlatform.iOS => <Uri>[
        if (_iosAppStoreUri != null) _iosAppStoreUri!,
        if (_iosWebStoreUri != null) _iosWebStoreUri!,
        _webDownloadUri,
      ],
      _ => <Uri>[_webDownloadUri],
    };
  }

  Future<void> _openStore() async {
    AppLogger.i(
      'Update Now tapped',
      tag: 'Auth',
      json: <String, dynamic>{
        'has_minimum_version': widget.minimumVersion.isNotEmpty,
        'minimum_version': widget.minimumVersion,
      },
    );

    final storeUris = _storeUris();
    try {
      for (final uri in storeUris) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      }

      AppLogger.w(
        'App store launch failed',
        tag: 'Auth',
        json: <String, dynamic>{
          'platform': defaultTargetPlatform.name,
          'ios_bundle_id': _iosBundleId,
          'ios_app_id_configured': _iosAppId.isNotEmpty,
        },
      );
    } on Exception catch (e, st) {
      AppLogger.e(
        'App store launch failed',
        tag: 'Auth',
        error: e,
        stackTrace: st,
      );
    }

    final fallback = storeUris.last.toString();
    var clipboardSuccess = false;
    try {
      await Clipboard.setData(ClipboardData(text: fallback));
      clipboardSuccess = true;
    } on Object catch (e, st) {
      AppLogger.w(
        'Update link clipboard copy failed',
        tag: 'Auth',
        error: e,
        json: <String, dynamic>{
          'stack_trace': st.toString(),
          'fallback': fallback,
        },
      );
    }
    if (!mounted) return;
    final message = clipboardSuccess
        ? 'Could not open the store. Update link copied to clipboard. Please paste it in your browser.'
        : 'Could not open the store. Please visit $fallback to update.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
              child: AppCardContainer(
                padding: const EdgeInsets.all(AppDimens.p24),
                borderRadius: BorderRadius.circular(AppDimens.r24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: AppDimens.updateRequiredIconContainer,
                        height: AppDimens.updateRequiredIconContainer,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.system_update,
                          size: AppDimens.updateRequiredIconSize,
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
                      onPressed: _openStore,
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
