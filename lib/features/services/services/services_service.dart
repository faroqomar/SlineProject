import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import '../models/service_model.dart';

class ServicesService {
  final SupabaseClient _client;

  ServicesService([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  Future<List<ServiceModel>> getMyServices(String userId) async {
    try {
      final response = await _client
          .from('services')
          .select()
          .eq('freelancer_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => ServiceModel.fromJson(e)).toList();
    } catch (e, st) {
      AppLogger.e('Failed to fetch services', error: e, stackTrace: st);
      return [];
    }
  }

  Future<ServiceModel?> createService(ServiceModel service) async {
    try {
      final response = await _client
          .from('services')
          .insert(service.toJson())
          .select()
          .single();

      return ServiceModel.fromJson(response);
    } catch (e, st) {
      AppLogger.e('Failed to create service', error: e, stackTrace: st);
      return null;
    }
  }

  Future<bool> updateStatus(String serviceId, String status) async {
    try {
      await _client
          .from('services')
          .update({'status': status})
          .eq('id', serviceId);
      return true;
    } catch (e) {
      AppLogger.e('Failed to update service status', error: e);
      return false;
    }
  }
}
