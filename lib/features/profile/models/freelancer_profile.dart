import 'dart:math';

import 'package:flutter/material.dart';
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

    // Determine title based on role or skills (mock logic for now as title isn't in DB)
    var displayTitle = profile.activeRole == 'freelancer'
        ? 'Freelancer'
        : 'Client';
    if (profile.skills.isNotEmpty) {
      displayTitle = profile.skills.first;
    }

    return FreelancerProfile(
      id: profile.id,
      initials: initials,
      name: profile.fullName ?? 'Unknown User',
      verified: profile.email != null, // Simple proxy for verification
      title: displayTitle,
      location: 'Remote', // Placeholder
      jobSuccess: '100%', // Placeholder
      jobsCompleted: 0, // Placeholder
      hourlyRate: '-', // Placeholder
      bio: profile.bio ?? 'No bio available.',
      skills: profile.skills,
      portfolio: portfolio,
      reviews: reviews,
      history: history,
      avatarUrl: profile.avatarUrl,
    );
  }

  // Keeping mock for testing/previews if needed, but updated to use new structure if necessary
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
