import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';

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
  });

  // Factory for mock data
  factory FreelancerProfile.mock() {
    return FreelancerProfile(
      id: 'mock-1',
      initials: 'SM',
      name: 'Sarah Miller',
      verified: true,
      online: true,
      title: 'Full Stack Developer',
      location: 'Toronto, Canada',
      jobSuccess: '98%',
      jobsCompleted: 142,
      hourlyRate: '\$65/hr',
      bio:
          'Award-winning developer with 7+ years of experience crafting scalable web applications. I specialize in React, Node.js, and Flutter.',
      skills: ['Flutter', 'React', 'Node.js', 'Firebase', 'UI/UX'],
      portfolio: [
        PortfolioItem(
          title: 'E-commerce App',
          category: 'Mobile App',
          color: AppColors.teal,
        ),
        PortfolioItem(
          title: 'SaaS Dashboard',
          category: 'Web App',
          color: AppColors.gold,
        ),
        PortfolioItem(
          title: 'Finance Wallet',
          category: 'Fintech',
          color: AppColors.lightRed,
        ),
        PortfolioItem(
          title: 'Social Network',
          category: 'Mobile App',
          color: AppColors.lightTeal,
        ),
      ],
      reviews: [
        ReviewItem(
          client: 'Nexus Corp',
          rating: 5,
          comment:
              'Sarah is incredibly talented! She delivered a stunning app.',
          date: '2 weeks ago',
        ),
        ReviewItem(
          client: 'TechFlow Inc',
          rating: 5,
          comment: 'Professional, fast, and high quality. Highly recommended.',
          date: '1 month ago',
        ),
      ],
    );
  }
}

class PortfolioItem {
  final String title;
  final String category;
  final Color color;

  const PortfolioItem({
    required this.title,
    required this.category,
    required this.color,
  });
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
