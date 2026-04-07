import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/providers/theme_mode_provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/core/widgets/signed_image.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/profile/view/edit_profile_screen.dart';
import 'package:sline_app/features/profile/view/my_services_screen.dart';
import 'package:sline_app/features/profile/view/public_profile_screen.dart'; // Added
import 'package:sline_app/features/profile/view/settings_screen.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';
import 'package:sline_app/features/saved/view/saved_tasks_screen.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/wallet/view/wallet_screen.dart';

/// Profile screen - user profile management and settings with Glassmorphism design.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileVM = context.read<ProfileViewModel>();
      profileVM.loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<ProfileViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoadingProfile) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.profileError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    vm.profileError!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.lightRed,
                    ),
                  ),
                  const SizedBox(height: AppDimens.p16),
                  ElevatedButton(
                    onPressed: () => vm.loadUserData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // --- Header Title ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.p24,
                    topPadding + AppDimens.p24,
                    AppDimens.p24,
                    AppDimens.p16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile',
                            style: AppTypography.h3.copyWith(
                              color: colorScheme.text,
                            ),
                          ),
                          Text(
                            'Manage your account',
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            borderRadius: BorderRadius.circular(AppDimens.r12),
                          ),
                          child: Text(
                            'Edit',
                            style: AppTypography.captionBold.copyWith(
                              color: AppColors.offWhite,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Profile Card ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p24,
                  ),
                  child: AppCardContainer(
                    padding: const EdgeInsets.all(AppDimens.p16),
                    borderRadius: BorderRadius.circular(AppDimens.r20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SignedAvatar(
                              storagePathOrUrl: vm.avatarUrl,
                              size: 70,
                              borderRadius: BorderRadius.circular(
                                AppDimens.r16,
                              ),
                              borderColor: AppColors.gold,
                              borderWidth: 3,
                            ),
                            const SizedBox(width: AppDimens.p16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          vm.fullName ?? 'Guest User',
                                          style: AppTypography.h5.copyWith(
                                            color: colorScheme.text,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: AppColors.lightTeal,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    (vm.loadedBio ?? '').isNotEmpty
                                        ? vm.loadedBio!
                                        : 'No bio yet',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: colorScheme.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _buildBadge(
                                        context,
                                        '⭐ Top Rated',
                                        AppColors.lightTeal,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildBadge(
                                        context,
                                        'Rising',
                                        AppColors.gold,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.p16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                context,
                                'Projects',
                                '47',
                                AppColors.teal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatItem(
                                context,
                                'Rating',
                                '4.9',
                                AppColors.gold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatItem(
                                context,
                                'Earned',
                                r'$12.5k',
                                AppColors.lightTeal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppDimens.p24)),

              // --- Skills Section ---
              if (vm.skills.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skills',
                          style: AppTypography.h5.copyWith(
                            color: colorScheme.text,
                          ),
                        ),
                        const SizedBox(height: AppDimens.p12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: vm.skills
                              .map(
                                (skill) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.teal.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    skill,
                                    style: AppTypography.micro.copyWith(
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppDimens.p24),
                ),
              ],

              // --- Portfolio Section ---
              if (vm.portfolioItems.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p24,
                    ),
                    child: Text(
                      'Portfolio',
                      style: AppTypography.h5.copyWith(color: colorScheme.text),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppDimens.p12),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 140,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.p24,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: vm.portfolioItems.length,
                      itemBuilder: (context, index) {
                        final item = vm.portfolioItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 200,
                              color: colorScheme.cardBackground,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (item['image_url'] != null)
                                    SignedImage(
                                      storagePathOrUrl: item['image_url'],
                                      width: 120,
                                      height: 120,
                                      bucket: 'portfolio',
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        item['title'] ?? 'Untitled',
                                        style: AppTypography.captionBold
                                            .copyWith(color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppDimens.p24),
                ),
              ],

              // --- Menu Items ---
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.p24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildMenuItem(
                      context,
                      'Edit Profile',
                      Icons.person,
                      AppColors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppDimens.p8),
                    _buildMenuItem(
                      context,
                      'My Services',
                      Icons.design_services_outlined,
                      AppColors.gold,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyServicesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppDimens.p8),
                    Selector<SavedTasksViewModel, int>(
                      selector: (_, vm) => vm.savedTasks.length,
                      builder: (context, count, _) {
                        return _buildMenuItem(
                          context,
                          'Saved Projects',
                          Icons.favorite,
                          AppColors.lightRed,
                          badge: count > 0 ? '$count' : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SavedTasksScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppDimens.p8),
                    _buildMenuItem(
                      context,
                      'Work History',
                      Icons.history,
                      AppColors.lightTeal,
                      onTap: () {
                        final userId = context
                            .read<AuthSessionViewModel>()
                            .currentUserId;
                        if (userId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PublicProfileScreen(
                                userId: userId,
                                initialTabIndex: 2, // History Tab
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: AppDimens.p8),
                    _buildMenuItem(
                      context,
                      'Wallet',
                      Icons.account_balance_wallet,
                      AppColors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WalletScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppDimens.p8),
                    _buildMenuItem(
                      context,
                      'Request Withdrawal',
                      Icons.send_outlined,
                      AppColors.teal,
                      badge: 'Coming soon',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Request withdrawal — coming soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppDimens.p8),
                    _buildMenuItem(
                      context,
                      'Settings',
                      Icons.settings,
                      AppColors.mediumGreyBlue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppDimens.p8),

                    // Dark Mode Toggle
                    _buildDarkModeToggle(context),
                    const SizedBox(height: AppDimens.p24),

                    // Logout button
                    GestureDetector(
                      onTap: () async {
                        final authVM = context.read<AuthSessionViewModel>();
                        await authVM.logout();
                        if (!context.mounted) return;

                        unawaited(
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          ),
                        );
                      },
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.lightRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimens.r16),
                          border: Border.all(
                            color: AppColors.lightRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Logout',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.lightRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.p100),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.micro.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final isDark = context.colorScheme.isDark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : AppColors.offWhite.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimens.r14),
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.h4.copyWith(color: color)),
          Text(
            label,
            style: AppTypography.micro.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String label,
    IconData icon,
    Color color, {
    String? badge,
    VoidCallback? onTap,
  }) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AppCardContainer(
        padding: const EdgeInsets.all(AppDimens.p16),
        borderRadius: BorderRadius.circular(AppDimens.r16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppDimens.r12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.text,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: AppTypography.micro.copyWith(
                    color: AppColors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: colorScheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(BuildContext context) {
    final colorScheme = context.colorScheme;
    final themeProvider = context.watch<ThemeModeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return GestureDetector(
      onTap: themeProvider.toggleThemeMode,
      child: AppCardContainer(
        padding: const EdgeInsets.all(AppDimens.p16),
        borderRadius: BorderRadius.circular(AppDimens.r16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppDimens.r12),
              ),
              child: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: colorScheme.text,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dark Mode',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.text,
                    ),
                  ),
                  Text(
                    'Switch between themes',
                    style: AppTypography.micro.copyWith(
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isDark,
              activeThumbColor: AppColors.teal,
              onChanged: (value) => themeProvider.toggleThemeMode(),
            ),
          ],
        ),
      ),
    );
  }
}
