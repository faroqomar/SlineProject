import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/profile/data/profile_repository.dart';
import 'package:sline_app/features/profile/models/public_profile.dart';
import 'package:sline_app/features/chat/services/message_service.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';

class UserProfileViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepo;
  final MessageService _messageService;
  final String userId;

  bool _isLoading = true;
  String? _error;
  PublicProfile? _profile;
  List<Map<String, dynamic>> _portfolio = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  PublicProfile? get profile => _profile;
  List<Map<String, dynamic>> get portfolio => _portfolio;

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
      } catch (e) {
        AppLogger.w('Failed to load portfolio for user $userId: $e');
        // Non-critical: just show empty portfolio
        _portfolio = [];
      }
    } catch (e) {
      AppLogger.e('Failed to load user profile $userId: $e');
      _error = 'Failed to load profile. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Starts a direct conversation with this user
  Future<void> startChat(BuildContext context) async {
    final currentUser = _profileRepo.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to send messages.'),
        ),
      );
      return;
    }

    if (currentUser.id == userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself.')),
      );
      return;
    }

    try {
      // Create or get existing conversation
      final conversation = await _messageService.createOrGetConversation(
        user1Id: currentUser.id,
        user2Id: userId,
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversation: conversation),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Failed to start chat with $userId: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start chat. Please try again.'),
          ),
        );
      }
    }
  }

  void retry() {
    load();
  }
}
