import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/profile/data/profile_repository.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';

class PublicProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;

  FreelancerProfile? _profile;
  bool _isLoading = false;
  String? _error;

  PublicProfileViewModel({
    ProfileRepository? repository,
    SupabaseClient? client,
  }) : _repository =
           repository ?? ProfileRepository(client ?? Supabase.instance.client) {
    AppLogger.d(
      'PublicProfileViewModel created'
      '${repository == null ? " (self-constructed ProfileRepository)" : ""}',
      tag: 'PublicProfileViewModel',
    );
  }

  FreelancerProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _repository.getPublicProfile(userId);
    } on Exception catch (e, stackTrace) {
      _error = 'Failed to load profile';
      AppLogger.e(
        'Error loading public profile',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
