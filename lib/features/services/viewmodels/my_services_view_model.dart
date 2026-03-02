import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/services/models/service_model.dart';
import 'package:sline_app/features/services/services/services_service.dart';

/// Owns "My Services" list for the profile/settings flow.
/// Replaces dependency on DashboardViewModel for this screen.
class MyServicesViewModel extends ChangeNotifier {
  MyServicesViewModel({ServicesService? servicesService})
      : _servicesService = servicesService ?? ServicesService();

  final ServicesService _servicesService;
  static const _kTag = 'MyServices';

  List<ServiceModel> _services = [];
  List<ServiceModel> get services => _services;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Loads services for the current user (freelancer).
  Future<void> load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      _services = [];
      _error = 'Not signed in';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _services = await _servicesService.getMyServices(uid);
      AppLogger.d('Loaded ${_services.length} services', tag: _kTag);
    } catch (e) {
      AppLogger.e('Failed to load services', error: e, tag: _kTag);
      _error = e.toString();
      _services = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
