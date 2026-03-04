class PublicSystemConfig {
  const PublicSystemConfig({
    required this.maintenanceEnabled,
    required this.maintenanceMessage,
    required this.disableSignups,
    required this.minVersionAndroid,
    required this.minVersionIos,
    required this.bannerEnabled,
    required this.bannerText,
    required this.bannerType,
  });

  final bool maintenanceEnabled;
  final String maintenanceMessage;
  final bool disableSignups;
  final String minVersionAndroid;
  final String minVersionIos;
  final bool bannerEnabled;
  final String bannerText;
  final String bannerType;

  static const PublicSystemConfig defaults = PublicSystemConfig(
    maintenanceEnabled: false,
    maintenanceMessage: '',
    disableSignups: false,
    minVersionAndroid: '1.0.0',
    minVersionIos: '1.0.0',
    bannerEnabled: false,
    bannerText: '',
    bannerType: 'info',
  );
}
