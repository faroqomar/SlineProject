import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/features/profile/models/profile_model.dart';
import 'dart:math';

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
    this.avatarUrl,
  });

  factory FreelancerProfile.fromModel({
    required ProfileModel profile,
    required List<PortfolioItem> portfolio,
    List<ReviewItem> reviews = const [],
  }) {
    // Extract initials
    String initials = '';
    if (profile.fullName != null && profile.fullName!.isNotEmpty) {
      final parts = profile.fullName!.split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    // Determine title based on role or skills (mock logic for now as title isn't in DB)
    String displayTitle = profile.activeRole == 'freelancer'
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
      online: false, // Placeholder
      title: displayTitle,
      location: 'Remote', // Placeholder
      jobSuccess: '100%', // Placeholder
      jobsCompleted: 0, // Placeholder
      hourlyRate: '-', // Placeholder
      bio: profile.bio ?? 'No bio available.',
      skills: profile.skills,
      portfolio: portfolio,
      reviews: reviews,
      avatarUrl: profile.avatarUrl,
    );
  }

  // Keeping mock for testing/previews if needed, but updated to use new structure if necessary
}

class PortfolioItem {
  final String id;
  final String title;
  final String category;
  final Color color;
  final String? imageUrl;
  final String? description;

  const PortfolioItem({
    required this.id,
    required this.title,
    required this.category,
    required this.color,
    this.imageUrl,
    this.description,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    // Assign a random color for UI variation
    final colors = [
      AppColors.teal,
      AppColors.gold,
      AppColors.lightRed,
      AppColors.lightTeal,
    ];
    final color = colors[Random().nextInt(colors.length)];

    return PortfolioItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: 'Project', // Placeholder as not in DB
      color: color,
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
    );
  }
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
