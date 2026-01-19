import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';

class PublicProfileHeader extends StatelessWidget {
  final FreelancerProfile profile;

  const PublicProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    return SliverToBoxAdapter(
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
                border: Border.all(
                  color: colorScheme.phoneBackground,
                  width: 4,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.r20 - 4),
                child: SignedAvatar(
                  storagePathOrUrl: profile.avatarUrl,
                  size: 80,
                  borderRadius: BorderRadius.circular(AppDimens.r20 - 4),
                  placeholder: Container(
                    color: AppColors.gold,
                    child: Center(
                      child: Text(
                        profile.initials,
                        style: AppTypography.h3.copyWith(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Online Badge
          if (profile.online)
            Positioned(
              top: 140,
              left: 80,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.lightTeal,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.phoneBackground,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
