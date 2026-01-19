import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/profile/data/profile_repository.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';

class PublicProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;

  FreelancerProfile? _profile;
  bool _isLoading = false;
  String? _error;

  PublicProfileViewModel(this._repository);

  FreelancerProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _repository.getPublicProfile(userId);
    } catch (e, stackTrace) {
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
