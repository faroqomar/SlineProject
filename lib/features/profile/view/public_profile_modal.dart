import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/glass_container.dart';

class PublicProfileModal extends StatelessWidget {
  const PublicProfileModal({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    // Mock Data
    final Map<String, dynamic> profile = {
      'initials': 'SM',
      'name': 'Sarah Miller',
      'verified': true,
      'online': true,
      'title': 'Full Stack Developer',
      'location': 'Toronto, Canada',
      'jobSuccess': '98%',
      'jobsCompleted': 142,
      'hourlyRate': '\$65/hr',
      'bio': 'Award-winning developer with 7+ years of experience crafting scalable web applications. I specialize in React, Node.js, and Flutter.',
      'skills': ['Flutter', 'React', 'Node.js', 'Firebase', 'UI/UX'],
      'portfolio': [
        {'title': 'E-commerce App', 'category': 'Mobile App', 'color': AppColors.teal},
        {'title': 'SaaS Dashboard', 'category': 'Web App', 'color': AppColors.gold},
        {'title': 'Finance Wallet', 'category': 'Fintech', 'color': AppColors.lightRed},
        {'title': 'Social Network', 'category': 'Mobile App', 'color': AppColors.lightTeal},
      ],
      'reviews': [
        {'client': 'Nexus Corp', 'rating': 5, 'comment': 'Sarah is incredibly talented! She delivered a stunning app.', 'date': '2 weeks ago'},
        {'client': 'TechFlow Inc', 'rating': 5, 'comment': 'Professional, fast, and high quality. Highly recommended.', 'date': '1 month ago'},
      ]
    };

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: Stack(
        children: [
          // Content
          CustomScrollView(
            slivers: [
              // Header Image
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.teal, AppColors.lightTeal],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                    // Back Button
                    Positioned(
                      top: 40,
                      left: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black26,
                        child: BackButton(color: Colors.white),
                      ),
                    ),
                    // Avatar
                    Positioned(
                      top: 80, // 120 - 40 (half avatar)
                      left: 20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(AppDimens.r20),
                          border: Border.all(color: colorScheme.phoneBackground, width: 4),
                        ),
                        child: Center(
                          child: Text(
                            profile['initials'],
                            style: AppTypography.h3.copyWith(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    // Online Badge
                    if (profile['online'])
                      Positioned(
                        top: 140,
                        left: 80,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.lightTeal,
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.phoneBackground, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Profile Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppDimens.p24, 50, AppDimens.p24, 100), // Top padding for avatar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                profile['name'],
                                style: AppTypography.h3.copyWith(color: colorScheme.text),
                              ),
                              if (profile['verified'])
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(Icons.check_circle, color: AppColors.lightTeal, size: 20),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildIconButton(Icons.share, colorScheme),
                              const SizedBox(width: 8),
                              _buildIconButton(Icons.favorite_border, colorScheme),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        profile['title'],
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: colorScheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            profile['location'],
                            style: AppTypography.micro.copyWith(color: colorScheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.p24),

                      // Stats Row
                      Container(
                        padding: const EdgeInsets.all(AppDimens.p12),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppDimens.r16),
                          border: Border.all(color: AppColors.teal.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            _buildStatItem('Job Success', profile['jobSuccess'], colorScheme),
                            _buildDivider(),
                            _buildStatItem('Total Jobs', profile['jobsCompleted'].toString(), colorScheme),
                            _buildDivider(),
                            _buildStatItem('Hourly', profile['hourlyRate'], colorScheme),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.p24),

                      // About
                      Text('About', style: AppTypography.h5.copyWith(color: colorScheme.text)),
                      const SizedBox(height: AppDimens.p8),
                      Text(
                        profile['bio'],
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppDimens.p24),

                      // Skills
                      Text('Skills', style: AppTypography.h5.copyWith(color: colorScheme.text)),
                      const SizedBox(height: AppDimens.p8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (profile['skills'] as List).map<Widget>((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.cardBackground,
                              borderRadius: BorderRadius.circular(AppDimens.r8),
                              border: Border.all(color: colorScheme.cardBorder),
                            ),
                            child: Text(
                              skill,
                              style: AppTypography.captionBold.copyWith(color: colorScheme.text),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppDimens.p24),

                      // Portfolio (Grid)
                      Text('Portfolio', style: AppTypography.h5.copyWith(color: colorScheme.text)),
                      const SizedBox(height: AppDimens.p12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: (profile['portfolio'] as List).length,
                        itemBuilder: (context, index) {
                          final item = profile['portfolio'][index];
                          return Container(
                            decoration: BoxDecoration(
                              color: item['color'],
                              borderRadius: BorderRadius.circular(AppDimens.r16),
                            ),
                            padding: const EdgeInsets.all(12),
                            alignment: Alignment.bottomLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  item['category'],
                                  style: AppTypography.micro.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom Bar
          Positioned(
            bottom: AppDimens.p24,
            left: AppDimens.p24,
            right: AppDimens.p24,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.p8, vertical: AppDimens.p8),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.message, color: colorScheme.text),
                      label: Text('Message', style: TextStyle(color: colorScheme.text)),
                    ),
                  ),
                  Container(width: 1, height: 24, color: Colors.grey.withValues(alpha: 0.3)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AppButton(
                        text: 'Hire Now',
                        onPressed: () {},
                        height: 46,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, AppColorScheme colorScheme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: Icon(icon, size: 20, color: colorScheme.textSecondary),
    );
  }

  Widget _buildStatItem(String label, String value, AppColorScheme colorScheme) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.h6.copyWith(
              color: label == 'Job Success' ? AppColors.teal : colorScheme.text,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: AppTypography.micro.copyWith(
              color: colorScheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.1));
  }
}
