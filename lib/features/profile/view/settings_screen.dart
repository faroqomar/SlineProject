import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/providers/theme_mode_provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
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
    final amberColors = context.amberColors;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: CustomScrollView(
        slivers: [
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
                  SizedBox.square(
                    dimension: AppDimens.touchTarget,
                    child: IconButton(
                      tooltip: 'Back',
                      style: IconButton.styleFrom(
                        backgroundColor: amberColors.surface,
                        foregroundColor: amberColors.text,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.r12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
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
                _SettingsGroup(
                  title: 'Preferences',
                  subtitle: 'App behavior',
                  children: [
                    Consumer<ThemeModeProvider>(
                      builder: (context, themeProvider, _) {
                        final isDark =
                            themeProvider.themeMode == ThemeMode.dark;
                        return _buildSettingsTile(
                          context,
                          icon: isDark ? Icons.dark_mode : Icons.light_mode,
                          title: 'Dark Mode',
                          subtitle: isDark ? 'On' : 'Off',
                          trailing: Switch(
                            value: isDark,
                            activeThumbColor: amberColors.primary,
                            onChanged: (value) {
                              AppLogger.d(
                                'Settings theme toggle changed',
                                tag: 'Settings',
                                json: {'dark': value},
                              );
                              themeProvider.toggleThemeMode();
                            },
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'English',
                      actionLabel: 'Open',
                      onTap: () {
                        AppLogger.d(
                          'Settings language row tapped',
                          tag: 'Settings',
                        );
                        _showComingSoonSnackBar(
                          context,
                          'Language settings coming soon',
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.p12),
                _SettingsGroup(
                  title: 'Public profile',
                  subtitle: 'Client-facing',
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.folder_special,
                      title: 'Manage Portfolio',
                      subtitle: 'Add or edit your work proof',
                      actionLabel: 'Manage',
                      onTap: () {
                        AppLogger.d(
                          'Settings manage portfolio opened',
                          tag: 'Settings',
                        );
                        unawaited(
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManagePortfolioScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      subtitle: 'Manage alerts',
                      actionLabel: 'Edit',
                      onTap: () {
                        AppLogger.d(
                          'Settings notifications row tapped',
                          tag: 'Settings',
                        );
                        _showComingSoonSnackBar(
                          context,
                          'Notification settings coming soon',
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.gpp_good_outlined,
                      title: 'Support & Safety',
                      subtitle: 'Reporting and account safety',
                      actionLabel: 'Open',
                      onTap: () {
                        AppLogger.d(
                          'Settings support dialog opened',
                          tag: 'Settings',
                        );
                        unawaited(
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
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.p12),
                _SettingsGroup(
                  title: 'Money and security',
                  subtitle: 'Private',
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.account_balance_wallet,
                      title: 'Request Withdrawal',
                      subtitle: 'Withdraw funds to your bank',
                      actionLabel: 'Open',
                      onTap: () {
                        AppLogger.d(
                          'Settings withdrawal row tapped',
                          tag: 'Settings',
                        );
                        _showComingSoonSnackBar(
                          context,
                          'Request withdrawal - coming soon',
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.p12),
                _SettingsGroup(
                  title: 'Account control',
                  subtitle: 'Requires confirmation',
                  danger: true,
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.logout,
                      title: 'Log Out',
                      subtitle: 'End this session on the device',
                      actionLabel: 'Log out',
                      danger: true,
                      onTap: () async {
                        AppLogger.i(
                          'Settings logout requested',
                          tag: 'Settings',
                        );
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => const LogoutConfirmationDialog(),
                        );
                        if (confirmed != true) {
                          AppLogger.d(
                            'Settings logout cancelled',
                            tag: 'Settings',
                          );
                          return;
                        }
                        if (!context.mounted) return;

                        final authVM = context.read<AuthSessionViewModel>();
                        await authVM.logout();
                        if (!context.mounted) return;

                        await Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.p32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    String? actionLabel,
    VoidCallback? onTap,
    bool danger = false,
  }) {
    final amberColors = context.amberColors;
    final iconColor = danger ? amberColors.danger : amberColors.primary;
    final iconBackground = danger
        ? amberColors.danger.withValues(alpha: 0.10)
        : amberColors.primary.withValues(alpha: 0.10);
    final actionForeground = danger ? amberColors.danger : amberColors.primary;
    final actionBackground = danger
        ? amberColors.danger.withValues(alpha: 0.08)
        : amberColors.primary.withValues(alpha: 0.11);

    return Semantics(
      button: onTap != null,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppDimens.p60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p14,
              vertical: AppDimens.p10,
            ),
            child: Row(
              children: [
                Container(
                  width: AppDimens.settingsRowIconWell,
                  height: AppDimens.settingsRowIconWell,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(AppDimens.r12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: AppDimens.iconSmall,
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: amberColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimens.p4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.micro.copyWith(
                          color: amberColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (actionLabel != null)
                  Container(
                    constraints: const BoxConstraints(minHeight: AppDimens.p32),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p12,
                    ),
                    decoration: BoxDecoration(
                      color: actionBackground,
                      borderRadius: BorderRadius.circular(
                        AmberDuskTokens.spacing.pillRadius,
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: AppTypography.captionBold.copyWith(
                        color: actionForeground,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoonSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

/// Confirmation dialog used before ending the current auth session.
///
/// The settings group labels logout as a confirmation-required action, so this
/// dialog preserves that destructive-action contract before calling the VM.
class LogoutConfirmationDialog extends StatelessWidget {
  /// Creates the logout confirmation prompt.
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;
    final colorScheme = context.colorScheme;

    return AlertDialog(
      backgroundColor: amberColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AmberDuskTokens.spacing.taskCardRadius,
        ),
      ),
      title: Text(
        'Log out?',
        style: AppTypography.h5.copyWith(color: colorScheme.text),
      ),
      content: Text(
        'You will need to sign in again to continue using SLine on this device.',
        style: AppTypography.bodyMedium.copyWith(
          color: colorScheme.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: amberColors.danger,
            foregroundColor: amberColors.textInverse,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Log out'),
        ),
      ],
    );
  }
}

/// Amber Dusk settings group with an Open Design-style header and rows.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.subtitle,
    required this.children,
    this.danger = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;

    return AppCardContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(
        AmberDuskTokens.spacing.taskCardRadius,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.p14,
              AppDimens.p12,
              AppDimens.p14,
              AppDimens.p8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: AppTypography.captionBold.copyWith(
                      color: danger ? amberColors.danger : amberColors.text,
                    ),
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.micro.copyWith(color: amberColors.muted),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
