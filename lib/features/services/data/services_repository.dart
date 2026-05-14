import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/services/models/service_model.dart';
import 'package:sline_app/features/services/models/service_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized data-access layer for `public.services`.
///
/// Ownership is enforced server-side via RLS —
/// `freelancer_id` is never set from the client.
class ServicesRepository {
  static const _kTag = 'ServicesRepo';
  static const _table = 'services';

  final SupabaseClient _client;

  ServicesRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  // ── Helpers ──────────────────────────────────────────────

  String? get _currentUserId => _client.auth.currentUser?.id;

  // ── Reads ────────────────────────────────────────────────

  /// Fetches services owned by the current user.
  /// Throws if not authenticated or on DB error.
  Future<List<ServiceModel>> fetchMyServices() async {
    final uid = _currentUserId;
    if (uid == null) {
      AppLogger.w('fetchMyServices called without auth', tag: _kTag);
      throw StateError('Not signed in');
    }

    AppLogger.d('Fetching services for user=$uid', tag: _kTag);
    final response = await _client
        .from(_table)
        .select()
        .eq('freelancer_id', uid)
        .order('created_at', ascending: false);

    final services = (response as List)
        .map((e) => ServiceModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    AppLogger.i('Fetched ${services.length} services', tag: _kTag);
    return services;
  }

  // ── Writes ───────────────────────────────────────────────

  /// Creates a new service. `freelancer_id` is set by RLS (auth.uid()).
  /// Returns the created [ServiceModel].
  Future<ServiceModel> createService({
    required String title,
    String? description,
    double? price,
    int? deliveryDays,
    ServiceStatus status = ServiceStatus.draft,
    List<String> imageUrls = const [],
  }) async {
    AppLogger.i('Creating service: title="$title"', tag: _kTag);
    final response = await _client
        .from(_table)
        .insert({
          'title': title,
          'description': description,
          'price': price,
          'delivery_days': deliveryDays,
          'status': status.name,
          'image_urls': imageUrls,
        })
        .select()
        .single();

    final service = ServiceModel.fromJson(response);
    AppLogger.i('Created service id=${service.id}', tag: _kTag);
    return service;
  }

  /// Updates a service's status (e.g. activate, pause, draft).
  /// RLS ensures only the owner can update.
  Future<void> updateServiceStatus(
    String serviceId,
    ServiceStatus status,
  ) async {
    AppLogger.i(
      'Updating status: service=$serviceId → ${status.name}',
      tag: _kTag,
    );
    await _client
        .from(_table)
        .update({'status': status.name})
        .eq('id', serviceId);
    AppLogger.i('Status updated: service=$serviceId', tag: _kTag);
  }

  /// Updates editable fields of a service.
  /// RLS ensures only the owner can update.
  Future<ServiceModel> updateService(
    String serviceId, {
    String? title,
    String? description,
    double? price,
    int? deliveryDays,
    List<String>? imageUrls,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (price != null) updates['price'] = price;
    if (deliveryDays != null) updates['delivery_days'] = deliveryDays;
    if (imageUrls != null) updates['image_urls'] = imageUrls;

    if (updates.isEmpty) {
      AppLogger.w('updateService called with no changes', tag: _kTag);
      throw ArgumentError('No fields to update');
    }

    AppLogger.i(
      'Updating service=$serviceId fields=${updates.keys.join(', ')}',
      tag: _kTag,
    );
    final response = await _client
        .from(_table)
        .update(updates)
        .eq('id', serviceId)
        .select()
        .single();

    final service = ServiceModel.fromJson(response);
    AppLogger.i('Updated service id=${service.id}', tag: _kTag);
    return service;
  }
}
