import 'package:flutter/material.dart';
import 'package:sline_app/features/profile/view/manage_portfolio_screen.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/providers/theme_mode_provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/features/auth/viewmodels/auth_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.p24,
                topPadding + AppDimens.p24,
                AppDimens.p24,
                AppDimens.p16,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.arrow_back, color: colorScheme.text),
                    ),
                  ),
                  const SizedBox(width: AppDimens.p16),
                  Text(
                    'Settings',
                    style: AppTypography.h3.copyWith(color: colorScheme.text),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppDimens.p24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader(context, 'Preferences'),
                const SizedBox(height: AppDimens.p12),

                // Dark Mode
                Consumer<ThemeModeProvider>(
                  builder: (context, themeProvider, _) {
                    final isDark = themeProvider.themeMode == ThemeMode.dark;
                    return _buildSettingsTile(
                      context,
                      icon: isDark ? Icons.dark_mode : Icons.light_mode,
                      title: 'Dark Mode',
                      subtitle: isDark ? 'On' : 'Off',
                      trailing: Switch(
                        value: isDark,
                        activeThumbColor: AppColors.teal,
                        onChanged: (value) => themeProvider.toggleThemeMode(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppDimens.p24),
                _buildSectionHeader(context, 'Account'),
                const SizedBox(height: AppDimens.p12),

                _buildSettingsTile(
                  context,
                  icon: Icons.folder_special,
                  title: 'Manage Portfolio',
                  subtitle: 'Add or edit your work',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManagePortfolioScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimens.p12),

                _buildSettingsTile(
                  context,
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  subtitle: 'Manage alerts',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    // TODO: Implement notification settings
                  },
                ),
                const SizedBox(height: AppDimens.p12),
                _buildSettingsTile(
                  context,
                  icon: Icons.gpp_good_outlined,
                  title: 'Support & Safety',
                  subtitle: 'Reporting and account safety',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Support & Safety'),
                        content: const Text(
                          'You can report abusive content from task details, chat conversations, and public profiles. '
                          'For booking issues, open a booking and tap "Report Issue".',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimens.p12),
                _buildSettingsTile(
                  context,
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'English',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    // TODO: Implement language settings
                  },
                ),

                const SizedBox(height: AppDimens.p32),

                // Logout
                GestureDetector(
                  onTap: () async {
                    final authVM = context.read<AuthViewModel>();
                    final success = await authVM.logout();
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.p16),
                    decoration: BoxDecoration(
                      color: AppColors.lightRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimens.r16),
                      border: Border.all(
                        color: AppColors.lightRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: AppColors.lightRed),
                        const SizedBox(width: 8),
                        Text(
                          'Log Out',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.lightRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.captionBold.copyWith(
        color: context.colorScheme.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(AppDimens.p16),
        borderRadius: BorderRadius.circular(AppDimens.r16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.text, size: 20),
            ),
            const SizedBox(width: AppDimens.p16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.micro.copyWith(
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
