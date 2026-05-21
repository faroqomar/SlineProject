import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/profile/view/public_profile_screen.dart';

/// Deprecated: No call sites. Use RequestsListScreen + RequestTile for offer
/// details. See DEPRECATION_Proposals_2026-03-04.md.
@Deprecated('Use proposals list and tile; see DEPRECATION_Proposals_2026-03-04')
class ProposalDetailsModal extends StatelessWidget {
  final Map<String, dynamic>? proposal; // Pass mock proposal or real one later

  @Deprecated(
    'Use proposals list and tile; see DEPRECATION_Proposals_2026-03-04',
  )
  const ProposalDetailsModal({super.key, this.proposal});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    // Mock Data if null
    final data =
        proposal ??
        {
          'freelancer': {
            'id': 'mock-1',
            'initials': 'DC',
            'name': 'David Chen',
            'location': 'Toronto, Canada',
            'rating': '4.9',
            'verified': true,
            'online': true,
          },
          'bidAmount': r'$700',
          'deliveryTime': '4 Days',
          'coverLetter':
              "Hi, I have 5 years of experience in logo design and branding for tech startups. I utilize Adobe Illustrator and can provide vector files. I've worked with AI companies before and understand the aesthetic you're looking for.",
          'attachments': ['portfolio_v1.pdf', 'concept_sketch.jpg'],
        };

    final freelancer = data['freelancer'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimens.p24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: colorScheme.cardBackground,
                      child: BackButton(color: colorScheme.text),
                    ),
                  ),
                  Text(
                    'Proposal Details',
                    style: AppTypography.h4.copyWith(color: colorScheme.text),
                  ),
                  const SizedBox(width: AppDimens.p40), // Balance
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.p24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Freelancer Card
                    GestureDetector(
                      onTap: () {
                        unawaited(
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PublicProfileScreen(
                                userId: freelancer['id'] as String? ?? 'mock-1',
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppDimens.p16),
                        decoration: BoxDecoration(
                          color: colorScheme.cardBackground,
                          borderRadius: BorderRadius.circular(AppDimens.r20),
                          border: Border.all(color: colorScheme.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.r16,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      freelancer['initials'].toString(),
                                      style: AppTypography.h4.copyWith(
                                        color: AppColors.almostBlack,
                                      ),
                                    ),
                                  ),
                                ),
                                if (freelancer['online'] == true)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.lightTeal,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colorScheme.cardBackground,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: AppDimens.p16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    freelancer['name'].toString(),
                                    style: AppTypography.h5.copyWith(
                                      color: colorScheme.text,
                                    ),
                                  ),
                                  const SizedBox(height: AppDimens.p4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: AppDimens.p14,
                                        color: AppColors.gold,
                                      ),
                                      Text(
                                        ' ${freelancer['rating']}',
                                        style: AppTypography.captionBold
                                            .copyWith(color: AppColors.gold),
                                      ),
                                      const SizedBox(width: AppDimens.p8),
                                      Icon(
                                        Icons.location_on,
                                        size: AppDimens.p14,
                                        color: colorScheme.textSecondary,
                                      ),
                                      Text(
                                        ' ${freelancer['location']}',
                                        style: AppTypography.micro.copyWith(
                                          color: colorScheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: colorScheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.p24),

                    // Bid Info
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Bid Amount',
                            data['bidAmount'].toString(),
                            AppColors.teal,
                            colorScheme,
                          ),
                        ),
                        const SizedBox(width: AppDimens.p16),
                        Expanded(
                          child: _buildInfoCard(
                            'Delivery',
                            data['deliveryTime'].toString(),
                            colorScheme.text,
                            colorScheme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.p24),

                    // Cover Letter
                    Text(
                      'Cover Letter',
                      style: AppTypography.h5.copyWith(color: colorScheme.text),
                    ),
                    const SizedBox(height: AppDimens.p12),
                    Container(
                      padding: const EdgeInsets.all(AppDimens.p16),
                      decoration: BoxDecoration(
                        color: colorScheme.inputBackground,
                        borderRadius: BorderRadius.circular(AppDimens.r16),
                        border: Border.all(color: colorScheme.inputBorder),
                      ),
                      child: Text(
                        data['coverLetter'].toString(),
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.p24),

                    // Attachments
                    Text(
                      'Attachments',
                      style: AppTypography.h5.copyWith(color: colorScheme.text),
                    ),
                    const SizedBox(height: AppDimens.p12),
                    if (data['attachments'] != null)
                      ...(data['attachments'] as List).map(
                        (file) => Container(
                          margin: const EdgeInsets.only(bottom: AppDimens.p8),
                          padding: const EdgeInsets.all(AppDimens.p12),
                          decoration: BoxDecoration(
                            color: colorScheme.cardBackground,
                            borderRadius: BorderRadius.circular(AppDimens.r12),
                            border: Border.all(color: colorScheme.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppDimens.p8),
                                decoration: BoxDecoration(
                                  color: AppColors.lightRed.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.r8,
                                  ),
                                ),
                                child: Icon(
                                  Icons.attach_file,
                                  size: AppDimens.p18,
                                  color: AppColors.lightRed,
                                ),
                              ),
                              const SizedBox(width: AppDimens.p12),
                              Text(
                                file.toString(),
                                style: AppTypography.bodySmall.copyWith(
                                  color: colorScheme.text,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.download,
                                size: AppDimens.p18,
                                color: colorScheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Bar
            AppCardContainer(
              padding: const EdgeInsets.all(AppDimens.p24),
              borderRadius: BorderRadius.zero,
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(text: 'Accept Offer', onPressed: () {}),
                  ),
                  const SizedBox(width: AppDimens.p16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.cardBorder),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimens.p16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.r16),
                        ),
                      ),
                      child: Text(
                        'Decline',
                        style: TextStyle(
                          color: colorScheme.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    Color valueColor,
    AppColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: label == 'Bid Amount'
            ? AppColors.teal.withValues(alpha: 0.1)
            : colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(
          color: label == 'Bid Amount'
              ? AppColors.teal.withValues(alpha: 0.2)
              : colorScheme.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.captionBold.copyWith(
              color: colorScheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.p4),
          Text(
            value,
            style: AppTypography.h5.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
