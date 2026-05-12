import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/providers/theme_mode_provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/core/widgets/signed_image.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/favorites/view/favorites_screen.dart';
import 'package:sline_app/features/favorites/viewmodels/favorites_view_model.dart';
import 'package:sline_app/features/profile/view/edit_profile_screen.dart';
import 'package:sline_app/features/profile/view/my_services_screen.dart';
import 'package:sline_app/features/profile/view/public_profile_screen.dart';
import 'package:sline_app/features/profile/view/settings_screen.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';
import 'package:sline_app/features/saved/view/saved_tasks_screen.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/wallet/view/wallet_screen.dart';

/// Amber Dusk profile screen for account, services, portfolio, and settings.
///
/// The screen remains ViewModel-driven and keeps navigation to existing
/// profile, wallet, saved, favorites, and settings screens.
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
      AppLogger.d(
        'ProfileScreen: initial profile load started',
        tag: 'Profile',
      );
      profileVM.loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<ProfileViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoadingProfile) {
            return Center(
              child: CircularProgressIndicator(color: amber.primary),
            );
          }

          if (vm.profileError != null) {
            return _ProfileErrorState(
              message: vm.profileError!,
              onRetry: vm.loadUserData,
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AmberDuskSpacing.contentHorizontalPadding,
                    topPadding + AppDimens.p24,
                    AmberDuskSpacing.contentHorizontalPadding,
                    AppDimens.p12,
                  ),
                  child: _ProfileHeader(
                    onSettingsTap: () {
                      AppLogger.d(
                        'ProfileScreen: settings opened',
                        tag: 'Profile',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AmberDuskSpacing.contentHorizontalPadding,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ProfileHeroCard(vm: vm),
                    const SizedBox(height: AppDimens.p16),
                    _ProfileAvailabilityCard(vm: vm),
                    const SizedBox(height: AppDimens.p16),
                    _ProfileServicesCard(skills: vm.skills),
                    const SizedBox(height: AppDimens.p16),
                    _ProfilePortfolioStrip(items: vm.portfolioItems),
                    const SizedBox(height: AppDimens.p16),
                    const _ProfileSettingsGroup(),
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
}

/// Header matching the Open Design account screen hierarchy.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onSettingsTap});

  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const typography = AmberDuskTokens.typography;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACCOUNT',
                style: typography.chip.copyWith(
                  color: amber.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppDimens.p4),
              Text(
                'Profile',
                style: typography.screenTitle.copyWith(color: amber.text),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Profile settings',
          onPressed: onSettingsTap,
          icon: Icon(Icons.settings_outlined, color: amber.textSubtle),
        ),
      ],
    );
  }
}

/// High-emphasis identity card with profile actions and compact metrics.
class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.vm});

  final ProfileViewModel vm;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const typography = AmberDuskTokens.typography;
    final name = _displayName(vm);
    final bio = (vm.loadedBio ?? '').trim().isEmpty
        ? 'Independent service provider'
        : vm.loadedBio!.trim();
    final badges = vm.badges.isEmpty ? const <String>['AVAILABLE'] : vm.badges;

    return Container(
      padding: const EdgeInsets.all(AppDimens.p18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AmberDuskTokens.surfaces.hero.gradientStops,
        ),
        borderRadius: BorderRadius.circular(AmberDuskSpacing.heroCardRadius),
        border: Border.all(color: amber.heroRim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SignedAvatar(
                storagePathOrUrl: vm.avatarUrl,
                size: AppDimens.p70,
                borderRadius: BorderRadius.circular(AppDimens.r20),
                borderColor: amber.heroText,
                borderWidth: 2,
                initials: _initials(name),
                showOnlineIndicator: true,
              ),
              const SizedBox(width: AppDimens.p14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: typography.bookingName.copyWith(
                        color: amber.heroText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimens.p4),
                    Text(
                      bio,
                      style: typography.bodySmall.copyWith(
                        color: amber.heroMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimens.p8),
                    Wrap(
                      spacing: AppDimens.p6,
                      runSpacing: AppDimens.p6,
                      children: badges
                          .map((badge) => _HeroBadge(label: badge))
                          .toList(growable: false),
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
                child: _HeroAction(
                  label: 'Edit profile',
                  foreground: AmberDuskColors.textDark,
                  background: amber.heroText,
                  onTap: () {
                    AppLogger.d(
                      'ProfileScreen: edit profile opened',
                      tag: 'Profile',
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppDimens.p10),
              Expanded(
                child: _HeroAction(
                  label: 'Public view',
                  foreground: amber.heroText,
                  background: amber.heroChip,
                  onTap: () => _openPublicProfile(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p16),
          Row(
            children: [
              _MetricPill(
                label: 'Projects',
                value: '${vm.portfolioItems.length}',
              ),
              const SizedBox(width: AppDimens.p8),
              _MetricPill(label: 'Rating', value: vm.rating ?? 'New'),
              const SizedBox(width: AppDimens.p8),
              _MetricPill(label: 'Skills', value: '${vm.skills.length}'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tiny badge used inside the profile hero.
class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    return Container(
      padding: AmberDuskTokens.widgetTheme.statusPills.smallPadding,
      decoration: BoxDecoration(
        color: amber.heroChip,
        borderRadius: BorderRadius.circular(
          AmberDuskTokens.widgetTheme.statusPills.radius,
        ),
      ),
      child: Text(
        label,
        style: AmberDuskTokens.widgetTheme.statusPills.smallTextStyle.copyWith(
          color: amber.heroText,
        ),
      ),
    );
  }
}

/// Hero action that preserves current navigation behavior.
class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.label,
    required this.foreground,
    required this.background,
    required this.onTap,
  });

  final String label;
  final Color foreground;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final buttons = AmberDuskTokens.widgetTheme.buttons;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: buttons.minHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(buttons.radius),
          ),
          child: Text(
            label,
            style: buttons.textStyle.copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}

/// Compact metric pill shown at the bottom of the identity card.
class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p10,
          vertical: AppDimens.p8,
        ),
        decoration: BoxDecoration(
          color: amber.heroChip,
          borderRadius: BorderRadius.circular(AppDimens.r14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AmberDuskTokens.typography.sectionTitle.copyWith(
                color: amber.heroText,
              ),
            ),
            Text(
              label,
              style: AmberDuskTokens.typography.chip.copyWith(
                color: amber.heroMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Availability summary matching the profile reference sections.
class _ProfileAvailabilityCard extends StatelessWidget {
  const _ProfileAvailabilityCard({required this.vm});

  final ProfileViewModel vm;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Availability',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.bolt_outlined,
            title: 'Ready for new work',
            subtitle: vm.loadedEmail ?? 'Profile contact is connected',
          ),
          const SizedBox(height: AppDimens.p10),
          const _InfoRow(
            icon: Icons.schedule_outlined,
            title: 'Typical response',
            subtitle: 'Within a few hours',
          ),
        ],
      ),
    );
  }
}

/// Service chips derived from the profile skills collection.
class _ProfileServicesCard extends StatelessWidget {
  const _ProfileServicesCard({required this.skills});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    final visibleSkills = skills.isEmpty
        ? const ['Profile setup', 'Service packages', 'Portfolio polish']
        : skills.take(6).toList(growable: false);

    return _Panel(
      title: 'Services',
      child: Wrap(
        spacing: AppDimens.p8,
        runSpacing: AppDimens.p8,
        children: visibleSkills
            .map((skill) => _SkillChip(label: skill))
            .toList(growable: false),
      ),
    );
  }
}

/// Portfolio preview strip using existing resolved portfolio image data.
class _ProfilePortfolioStrip extends StatelessWidget {
  const _ProfilePortfolioStrip({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _Panel(
        title: 'Portfolio',
        child: _InfoRow(
          icon: Icons.image_outlined,
          title: 'No portfolio yet',
          subtitle: 'Add work samples from profile editing.',
        ),
      );
    }

    return _Panel(
      title: 'Portfolio',
      child: SizedBox(
        height: 122,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.only(right: AppDimens.p10),
              child: _PortfolioTile(item: item),
            );
          },
        ),
      ),
    );
  }
}

/// Reusable panel matching Amber Dusk profile grouped modules.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;

    return AppCardContainer(
      padding: const EdgeInsets.all(AppDimens.p16),
      borderRadius: BorderRadius.circular(AmberDuskSpacing.moduleRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AmberDuskTokens.typography.chip.copyWith(
              color: amber.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppDimens.p12),
          child,
        ],
      ),
    );
  }
}

/// Icon, title, and subtitle row used in profile panels.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;

    return Row(
      children: [
        Container(
          width: AppDimens.p40,
          height: AppDimens.p40,
          decoration: BoxDecoration(
            color: amber.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimens.r14),
          ),
          child: Icon(
            icon,
            color: amber.primary,
            size: AppDimens.iconSizeSmall,
          ),
        ),
        const SizedBox(width: AppDimens.p12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AmberDuskTokens.typography.body.copyWith(
                  color: amber.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppDimens.p2),
              Text(
                subtitle,
                style: AmberDuskTokens.typography.bodySmall.copyWith(
                  color: amber.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Amber Dusk skill chip.
class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p8,
      ),
      decoration: BoxDecoration(
        color: amber.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AmberDuskSpacing.pillRadius),
      ),
      child: Text(
        label,
        style: AmberDuskTokens.typography.chip.copyWith(color: amber.primary),
      ),
    );
  }
}

/// Portfolio thumbnail tile for profile previews.
class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    final title = item['title']?.toString() ?? 'Untitled';
    final imageUrl = item['image_url']?.toString();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.r16),
      child: Container(
        width: 164,
        color: amber.surfaceHighest,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              SignedImage(
                storagePathOrUrl: imageUrl,
                width: 164,
                height: 122,
                bucket: 'portfolio',
              ),
            Positioned(
              left: AppDimens.p10,
              right: AppDimens.p10,
              bottom: AppDimens.p10,
              child: Text(
                title,
                style: AmberDuskTokens.typography.chip.copyWith(
                  color: amber.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Account actions grouped in the Amber Dusk settings module.
class _ProfileSettingsGroup extends StatelessWidget {
  const _ProfileSettingsGroup();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Settings',
      child: Column(
        children: [
          _ActionRow(
            label: 'Edit Profile',
            icon: Icons.person_outline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          _ActionRow(
            label: 'My Services',
            icon: Icons.design_services_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyServicesScreen()),
            ),
          ),
          Selector<SavedTasksViewModel, int>(
            selector: (_, vm) => vm.savedTasks.length,
            builder: (context, count, _) => _ActionRow(
              label: 'Saved Projects',
              icon: Icons.bookmark_border,
              badge: count > 0 ? '$count' : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedTasksScreen()),
              ),
            ),
          ),
          Selector<FavoritesViewModel, int>(
            selector: (_, vm) => vm.itemsWithProfile.length,
            builder: (context, count, _) => _ActionRow(
              label: 'Favorites',
              icon: Icons.star_outline,
              badge: count > 0 ? '$count' : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ),
            ),
          ),
          _ActionRow(
            label: 'Wallet',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ),
          ),
          _ActionRow(
            label: 'Work History',
            icon: Icons.history,
            onTap: () => _openPublicProfile(context, initialTabIndex: 2),
          ),
          const _DarkModeRow(),
          const SizedBox(height: AppDimens.p8),
          const _LogoutButton(),
        ],
      ),
    );
  }
}

/// Tappable row with optional badge for account actions.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppLogger.d(
            'ProfileScreen: action tapped',
            tag: 'Profile',
            json: {'action': label},
          );
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.p8),
          child: Row(
            children: [
              Container(
                width: AppDimens.p40,
                height: AppDimens.p40,
                decoration: BoxDecoration(
                  color: amber.surfaceHighest,
                  borderRadius: BorderRadius.circular(AppDimens.r14),
                ),
                child: Icon(
                  icon,
                  color: amber.primary,
                  size: AppDimens.iconSizeSmall,
                ),
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Text(
                  label,
                  style: AmberDuskTokens.typography.body.copyWith(
                    color: amber.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: AmberDuskTokens.widgetTheme.statusPills.smallPadding,
                  decoration: BoxDecoration(
                    color: amber.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      AmberDuskTokens.widgetTheme.statusPills.radius,
                    ),
                  ),
                  child: Text(
                    badge!,
                    style: AmberDuskTokens
                        .widgetTheme
                        .statusPills
                        .smallTextStyle
                        .copyWith(color: amber.primary),
                  ),
                ),
              const SizedBox(width: AppDimens.p8),
              Icon(
                Icons.chevron_right,
                color: amber.muted,
                size: AppDimens.iconSizeSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme mode toggle row kept in the profile settings group.
class _DarkModeRow extends StatelessWidget {
  const _DarkModeRow();

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    final themeProvider = context.watch<ThemeModeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p8),
      child: Row(
        children: [
          Container(
            width: AppDimens.p40,
            height: AppDimens.p40,
            decoration: BoxDecoration(
              color: amber.surfaceHighest,
              borderRadius: BorderRadius.circular(AppDimens.r14),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: amber.primary,
              size: AppDimens.iconSizeSmall,
            ),
          ),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Text(
              'Dark Mode',
              style: AmberDuskTokens.typography.body.copyWith(
                color: amber.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(
            value: isDark,
            activeThumbColor: amber.primary,
            onChanged: (_) => themeProvider.toggleThemeMode(),
          ),
        ],
      ),
    );
  }
}

/// Logout control with the existing auth-session navigation behavior.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        AppLogger.i('ProfileScreen: logout requested', tag: 'Profile');
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
        height: AppDimens.p48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: amber.dangerMuted,
          borderRadius: BorderRadius.circular(AppDimens.r16),
        ),
        child: Text(
          'Logout',
          style: AmberDuskTokens.typography.control.copyWith(
            color: amber.danger,
          ),
        ),
      ),
    );
  }
}

/// Profile error panel with retry action.
class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AmberDuskTokens.typography.body.copyWith(
                color: amber.danger,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.p16),
            _HeroAction(
              label: 'Retry',
              foreground: amber.text,
              background: amber.primary,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

String _displayName(ProfileViewModel vm) {
  final name = vm.fullName?.trim();
  return name == null || name.isEmpty ? 'Guest User' : name;
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
      .toUpperCase();
}

void _openPublicProfile(BuildContext context, {int initialTabIndex = 0}) {
  final userId = context.read<AuthSessionViewModel>().currentUserId;
  if (userId == null) {
    AppLogger.w(
      'ProfileScreen: public profile blocked without current user',
      tag: 'Profile',
      json: {'initial_tab': initialTabIndex},
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in to view your public profile.')),
    );
    return;
  }

  AppLogger.d(
    'ProfileScreen: public profile opened',
    tag: 'Profile',
    json: {'initial_tab': initialTabIndex},
  );
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          PublicProfileScreen(userId: userId, initialTabIndex: initialTabIndex),
    ),
  );
}
