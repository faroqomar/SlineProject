import 'package:flutter/foundation.dart';
import 'package:sline_app/core/models/public_system_config.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/system_config_service.dart';

class SystemConfigViewModel extends ChangeNotifier {
  SystemConfigViewModel({SystemConfigService? service})
    : _service = service ?? SystemConfigService();

  final SystemConfigService _service;

  PublicSystemConfig _config = PublicSystemConfig.defaults;
  bool _isLoading = false;

  PublicSystemConfig get config => _config;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      _config = await _service.fetchPublicConfig();
    } catch (e, st) {
      AppLogger.e(
        'System config load failed',
        tag: 'SystemConfigVM',
        error: e,
        stackTrace: st,
      );
      _config = PublicSystemConfig.defaults;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isUpdateRequired() {
    final current = const String.fromEnvironment(
      'APP_VERSION',
      defaultValue: '1.0.0',
    );
    final minimum = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => _config.minVersionIos,
      _ => _config.minVersionAndroid,
    };
    return !_service.isVersionAtLeast(current: current, minimum: minimum);
  }
}
