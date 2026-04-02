import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/profile/data/profile_repository.dart';
import 'package:sline_app/features/profile/models/public_profile.dart';
import 'package:sline_app/features/portfolio/models/portfolio_item.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/services/message_service.dart';

class UserProfileViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepo;
  final MessageService _messageService;
  final String userId;

  bool _isLoading = true;
  String? _error;
  PublicProfile? _profile;
  List<PortfolioItem> _portfolio = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  PublicProfile? get profile => _profile;
  List<PortfolioItem> get portfolio => _portfolio;

  UserProfileViewModel({
    required this.userId,
    required ProfileRepository profileRepo,
    required MessageService messageService,
  }) : _profileRepo = profileRepo,
       _messageService = messageService;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Fetch Profile and map to Safe DTO
      final profileModel = await _profileRepo.fetchProfile(userId);
      _profile = PublicProfile.fromModel(profileModel);

      // 2. Fetch Portfolio (if any)
      // Note: Portfolio items RLS might restrict visibility.
      // We catch per-request errors to avoid breaking the whole screen.
      try {
        _portfolio = await _profileRepo.getPortfolioItems(userId);
      } on Exception catch (e) {
        AppLogger.w('Failed to load portfolio for user $userId: $e');
        // Non-critical: just show empty portfolio
        _portfolio = [];
      }
    } on Exception catch (e) {
      AppLogger.e('Failed to load user profile $userId: $e');
      _error = 'Failed to load profile. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns the current user ID, or null if not authenticated.
  String? get currentUserId => _profileRepo.currentUser?.id;

  /// Creates or retrieves an existing conversation with this user.
  ///
  /// Returns the [Conversation] on success, or null if the current user is not
  /// authenticated or is the same as the target user. Throws on service errors
  /// so the calling View can display appropriate feedback.
  Future<Conversation?> getOrCreateConversation() async {
    AppLogger.d(
      'Creating conversation for user profile $userId',
      tag: 'UserProfileVM',
    );

    final currentUser = _profileRepo.currentUser;
    if (currentUser == null || currentUser.id == userId) {
      return null;
    }

    final conversation = await _messageService.createOrGetConversation(
      user1Id: currentUser.id,
      user2Id: userId,
    );
    return conversation;
  }

  void retry() {
    load();
  }
}
