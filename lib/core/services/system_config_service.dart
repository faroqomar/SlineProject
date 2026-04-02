import 'package:sline_app/core/models/public_system_config.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SystemConfigService {
  SystemConfigService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<PublicSystemConfig> fetchPublicConfig() async {
    try {
      final rows = await _client.rpc('get_public_system_config');
      final map = <String, dynamic>{};
      for (final row in (rows as List<dynamic>)) {
        final json = row as Map<String, dynamic>;
        final key = json['key']?.toString();
        if (key == null) continue;
        map[key] = json['value'];
      }

      final maintenance = _asJson(map['maintenance_mode']);
      final signups = _asJson(map['disable_signups']);
      final minVersion = _asJson(map['min_app_version']);
      final banner = _asJson(map['app_banner']);

      return PublicSystemConfig(
        maintenanceEnabled: maintenance['enabled'] == true,
        maintenanceMessage: maintenance['message']?.toString() ?? '',
        disableSignups: signups['enabled'] == true,
        minVersionAndroid: minVersion['android']?.toString() ?? '1.0.0',
        minVersionIos: minVersion['ios']?.toString() ?? '1.0.0',
        bannerEnabled: banner['enabled'] == true,
        bannerText: banner['text']?.toString() ?? '',
        bannerType: banner['type']?.toString() ?? 'info',
      );
    } on Exception catch (e, st) {
      AppLogger.w(
        'Failed to fetch public system config, using defaults.',
        tag: 'SystemConfig',
        error: e,
      );
      AppLogger.d('Config fetch stack trace: $st', tag: 'SystemConfig');
      return PublicSystemConfig.defaults;
    }
  }

  bool isVersionAtLeast({required String current, required String minimum}) {
    final c = _parseVersion(current);
    final m = _parseVersion(minimum);
    for (var i = 0; i < 3; i++) {
      final cv = i < c.length ? c[i] : 0;
      final mv = i < m.length ? m[i] : 0;
      if (cv > mv) return true;
      if (cv < mv) return false;
    }
    return true;
  }

  List<int> _parseVersion(String value) {
    return value.split('.').take(3).map((e) => int.tryParse(e) ?? 0).toList();
  }

  Map<String, dynamic> _asJson(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }
}
