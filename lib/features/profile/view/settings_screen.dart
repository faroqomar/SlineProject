import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/providers/theme_mode_provider.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/profile/view/manage_portfolio_screen.dart';

/// Account settings screen using grouped Amber Dusk row treatment.
class SettingsScreen extends StatelessWidget {
  /// Creates the settings route.
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
                        activeThumbColor: colorScheme.primary,
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
                    _showComingSoonSnackBar(
                      context,
                      'Notification settings coming soon',
                    );
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
                    _showComingSoonSnackBar(
                      context,
                      'Language settings coming soon',
                    );
                  },
                ),

                const SizedBox(height: AppDimens.p24),
                _buildSectionHeader(context, 'Wallet'),
                const SizedBox(height: AppDimens.p12),

                _buildComingSoonTile(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'Request Withdrawal',
                  subtitle: 'Withdraw funds to your bank',
                ),

                const SizedBox(height: AppDimens.p32),

                // Logout
                GestureDetector(
                  onTap: () async {
                    final authVM = context.read<AuthSessionViewModel>();
                    await authVM.logout();
                    if (!context.mounted) return;

                    await Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.p16),
                    decoration: BoxDecoration(
                      color: colorScheme.dangerMuted,
                      borderRadius: BorderRadius.circular(AppDimens.r16),
                      border: Border.all(
                        color: colorScheme.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: colorScheme.danger),
                        const SizedBox(width: 8),
                        Text(
                          'Log Out',
                          style: AppTypography.bodyMedium.copyWith(
                            color: colorScheme.danger,
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
      child: AppCardContainer(
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

  void _showComingSoonSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// Wallet/withdrawal tile styled as a future feature (coming soon).
  Widget _buildComingSoonTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request withdrawal — coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: AppCardContainer(
        padding: const EdgeInsets.all(AppDimens.p16),
        borderRadius: BorderRadius.circular(AppDimens.r16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
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
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p10,
                vertical: AppDimens.p4,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'Coming soon',
                style: AppTypography.micro.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
