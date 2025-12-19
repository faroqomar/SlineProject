import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/features/profile/viewmodels/public_profile_view_model.dart';
import 'widgets/public_profile/public_profile_header.dart';
import 'widgets/public_profile/public_profile_stats.dart';
import 'widgets/public_profile/public_profile_portfolio.dart';
import 'widgets/public_profile/public_profile_reviews.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => PublicProfileViewModel()..loadProfile(widget.userId),
      child: Scaffold(
        backgroundColor: colorScheme.phoneBackground,
        body: Consumer<PublicProfileViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final profile = vm.profile;
            if (profile == null) {
              return const Center(child: Text('User not found'));
            }

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    PublicProfileHeader(profile: profile),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimens.p24,
                          50,
                          AppDimens.p24,
                          100,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name & Verification
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      profile.name,
                                      style: AppTypography.h3.copyWith(
                                        color: colorScheme.text,
                                      ),
                                    ),
                                    if (profile.verified)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: AppColors.lightTeal,
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    _buildIconButton(Icons.share, colorScheme),
                                    const SizedBox(width: 8),
                                    _buildIconButton(
                                      Icons.favorite_border,
                                      colorScheme,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              profile.title,
                              style: AppTypography.bodyMedium.copyWith(
                                color: colorScheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: colorScheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  profile.location,
                                  style: AppTypography.micro.copyWith(
                                    color: colorScheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimens.p24),

                            PublicProfileStats(profile: profile),
                            const SizedBox(height: AppDimens.p24),

                            // About
                            Text(
                              'About',
                              style: AppTypography.h5.copyWith(
                                color: colorScheme.text,
                              ),
                            ),
                            const SizedBox(height: AppDimens.p8),
                            Text(
                              profile.bio,
                              style: AppTypography.bodySmall.copyWith(
                                color: colorScheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppDimens.p24),

                            // Skills
                            Text(
                              'Skills',
                              style: AppTypography.h5.copyWith(
                                color: colorScheme.text,
                              ),
                            ),
                            const SizedBox(height: AppDimens.p8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.skills.map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.cardBackground,
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.r8,
                                    ),
                                    border: Border.all(
                                      color: colorScheme.cardBorder,
                                    ),
                                  ),
                                  child: Text(
                                    skill,
                                    style: AppTypography.captionBold.copyWith(
                                      color: colorScheme.text,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppDimens.p24),

                            PublicProfilePortfolio(
                              portfolio: profile.portfolio,
                            ),
                            const SizedBox(height: AppDimens.p24),

                            PublicProfileReviews(reviews: profile.reviews),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p8,
                      vertical: AppDimens.p8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.message, color: colorScheme.text),
                            label: Text(
                              'Message',
                              style: TextStyle(color: colorScheme.text),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
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
            );
          },
        ),
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
}
