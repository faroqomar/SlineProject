import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/services/data/services_repository.dart';
import 'package:sline_app/features/services/models/service_model.dart';
import 'package:sline_app/features/services/models/service_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Owns "My Services" list state for the profile/settings flow.
/// Single source of truth for service data — replaces any global
/// dashboard-level service state.
class MyServicesViewModel extends ChangeNotifier {
  MyServicesViewModel({ServicesRepository? repository})
    : _repository = repository ?? ServicesRepository();

  final ServicesRepository _repository;
  static const _kTag = 'MyServices';

  List<ServiceModel> _services = [];
  List<ServiceModel> get services => List.unmodifiable(_services);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Load ──────────────────────────────────────────────────

  /// Loads services for the current user (freelancer).
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _services = await _repository.fetchMyServices();
      AppLogger.i('Loaded ${_services.length} services', tag: _kTag);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to load services',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      _error = _mapError(e);
      _services = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Create ────────────────────────────────────────────────

  /// Creates a new service and prepends it to the list.
  Future<void> createService({
    required String title,
    String? description,
    double? price,
    int? deliveryDays,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final service = await _repository.createService(
        title: title,
        description: description,
        price: price,
        deliveryDays: deliveryDays,
      );
      _services = [service, ..._services];
      AppLogger.i('Service created: ${service.id}', tag: _kTag);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to create service',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      _error = _mapError(e);
    }
    notifyListeners();
  }

  // ── Update Status ─────────────────────────────────────────

  /// Toggles a service between active/paused (or draft → active).
  Future<void> updateStatus(String serviceId, ServiceStatus status) async {
    _error = null;
    notifyListeners();

    try {
      await _repository.updateServiceStatus(serviceId, status);
      // Optimistic update
      _services = _services.map((s) {
        if (s.id == serviceId) return s.copyWith(status: status);
        return s;
      }).toList();
      AppLogger.i(
        'Status updated: service=$serviceId → ${status.name}',
        tag: _kTag,
      );
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to update status',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      _error = _mapError(e);
    }
    notifyListeners();
  }

  // ── Update Fields ─────────────────────────────────────────

  /// Updates editable fields on a service.
  Future<void> updateService(
    String serviceId, {
    String? title,
    String? description,
    double? price,
    int? deliveryDays,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.updateService(
        serviceId,
        title: title,
        description: description,
        price: price,
        deliveryDays: deliveryDays,
      );
      _services = _services.map((s) {
        if (s.id == serviceId) return updated;
        return s;
      }).toList();
      AppLogger.i('Service updated: $serviceId', tag: _kTag);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to update service',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      _error = _mapError(e);
    }
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _mapError(Object e) {
    if (e is PostgrestException) {
      switch (e.code) {
        case '42501':
          return 'Session expired. Please log in again.';
        case '23505':
          return 'A service with this title already exists.';
        case '23503':
          return 'Related item does not exist.';
        default:
          return 'Database error occurred. Please try again.';
      }
    }
    if (e is StateError) {
      return 'An error occurred. Please try again.';
    }
    return 'An error occurred. Please try again.';
  }
}
