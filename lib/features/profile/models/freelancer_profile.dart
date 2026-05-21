import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_colors.dart';
// Canonical PortfolioItem from portfolio feature
import 'package:sline_app/features/portfolio/models/portfolio_item.dart'
    show PortfolioItem;
import 'package:sline_app/features/profile/models/profile_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';

/// FreelancerProfile model for public profile display.
/// Uses canonical PortfolioItem from portfolio feature.
class FreelancerProfile {
  final String id;
  final String initials;
  final String name;
  final bool verified;
  final bool online;

  /// Active public role. Supported values are `freelancer` and `client`.
  final String role;
  final String title;
  final String location;
  final String jobSuccess;
  final int jobsCompleted;
  final String hourlyRate;
  final String bio;
  final List<String> skills;
  final List<PortfolioItem> portfolio;
  final List<ReviewItem> reviews;
  final List<Task> history;
  final String? avatarUrl;

  const FreelancerProfile({
    required this.id,
    required this.initials,
    required this.name,
    this.verified = false,
    this.online = false,
    required this.role,
    required this.title,
    required this.location,
    required this.jobSuccess,
    required this.jobsCompleted,
    required this.hourlyRate,
    required this.bio,
    required this.skills,
    required this.portfolio,
    required this.reviews,
    this.history = const [],
    this.avatarUrl,
  });

  factory FreelancerProfile.fromModel({
    required ProfileModel profile,
    required List<PortfolioItem> portfolio,
    List<ReviewItem> reviews = const [],
    List<Task> history = const [], // Added
  }) {
    // Extract initials
    var initials = '';
    if (profile.fullName != null && profile.fullName!.isNotEmpty) {
      final parts = profile.fullName!.split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    final trimmedRole = profile.activeRole.trim();
    final activeRole = trimmedRole.isEmpty
        ? 'client'
        : trimmedRole.toLowerCase();
    // Freelancers can use their first skill as a short professional title.
    // Client profiles should stay role-labeled so the public CTA cannot imply
    // that a client is a bookable service provider.
    var displayTitle = activeRole == 'freelancer' ? 'Freelancer' : 'Client';
    if (activeRole == 'freelancer' && profile.skills.isNotEmpty) {
      displayTitle = profile.skills.first;
    }
    final completedHistory = history
        .where((task) => task.status == TaskStatus.completed)
        .toList(growable: false);
    final completedJobs = completedHistory.length;

    return FreelancerProfile(
      id: profile.id,
      initials: initials,
      name: profile.fullName ?? 'Unknown User',
      verified: profile.email != null, // Simple proxy for verification
      role: activeRole,
      title: displayTitle,
      location: 'Remote', // Placeholder
      jobSuccess: completedJobs == 0
          ? '-'
          : '100%', // Placeholder until ratings exist
      jobsCompleted: completedJobs,
      hourlyRate: '-', // Placeholder
      bio: profile.bio?.trim() ?? '',
      skills: profile.skills,
      portfolio: portfolio,
      reviews: reviews,
      history: history,
      avatarUrl: profile.avatarUrl,
    );
  }

  // Keeping mock for testing/previews if needed, but updated to use new structure if necessary

  /// True when this profile is allowed to present freelancer booking actions.
  bool get isFreelancer => role == 'freelancer';
}

/// Extension to provide UI-specific properties for PortfolioItem display.
/// This keeps the canonical PortfolioItem clean while adding view-specific
/// properties needed for the public profile UI.
extension PortfolioItemUIProps on PortfolioItem {
  /// Returns a random color for UI variation (for public profile display).
  Color get displayColor {
    final colors = [
      AppColors.teal,
      AppColors.gold,
      AppColors.lightRed,
      AppColors.lightTeal,
    ];
    return colors[Random().nextInt(colors.length)];
  }

  /// Returns a placeholder category for UI display.
  String get displayCategory => 'Project';
}

class ReviewItem {
  final String client;
  final double rating;
  final String comment;
  final String date;

  const ReviewItem({
    required this.client,
    required this.rating,
    required this.comment,
    required this.date,
  });
}
