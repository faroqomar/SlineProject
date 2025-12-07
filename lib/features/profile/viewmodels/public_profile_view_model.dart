import 'package:flutter/foundation.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';

class PublicProfileViewModel extends ChangeNotifier {
  FreelancerProfile? _profile;
  bool _isLoading = false;

  FreelancerProfile? get profile => _profile;
  bool get isLoading => _isLoading;

  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // For now, return mock data regardless of userId
    // In the future, fetch from repository
    _profile = FreelancerProfile.mock();

    _isLoading = false;
    notifyListeners();
  }
}
