import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/profile/view/edit_profile_screen.dart';
import 'package:sline_app/features/profile/view/public_profile_screen.dart';
import 'package:sline_app/features/profile/view/settings_screen.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';

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
      unawaited(profileVM.loadUserData());
    });
  }

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const phoneLayout = AmberDuskTokens.phoneLayout;
    const spacing = AmberDuskTokens.spacing;
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;
    final bottomNavClearance =
        bottomSafePadding +
        phoneLayout.bottomNavBottom +
        phoneLayout.bottomNavHeight +
        spacing.lg;

    return Scaffold(
      backgroundColor: AmberDuskTokens.colors.transparent,
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

          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AmberDuskSpacing.contentHorizontalPadding,
                      AppDimens.p24,
                      AmberDuskSpacing.contentHorizontalPadding,
                      AppDimens.p12,
                    ),
                    child: _ProfileHeader(
                      onSettingsTap: () {
                        AppLogger.d(
                          'ProfileScreen: settings opened',
                          tag: 'Profile',
                        );
                        unawaited(
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
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
                      _ProfileMetricsGrid(vm: vm),
                      const SizedBox(height: AppDimens.p16),
                      _ProfileAvailabilityCard(vm: vm),
                      const SizedBox(height: AppDimens.p16),
                      _ProfileServicesCard(skills: vm.skills),
                      const SizedBox(height: AppDimens.p16),
                      _ProfilePortfolioStrip(items: vm.portfolioItems),
                      SizedBox(height: bottomNavClearance),
                    ]),
                  ),
                ),
              ],
            ),
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

/// High-emphasis identity card with profile actions.
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
                    unawaited(
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
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

/// Separate metric grid matching the Open Design profile module.
class _ProfileMetricsGrid extends StatelessWidget {
  const _ProfileMetricsGrid({required this.vm});

  final ProfileViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Projects',
            value: '${vm.portfolioItems.length}',
          ),
        ),
        const SizedBox(width: AppDimens.p10),
        Expanded(
          child: _MetricCard(label: 'Rating', value: vm.rating ?? 'New'),
        ),
        const SizedBox(width: AppDimens.p10),
        Expanded(
          child: _MetricCard(label: 'Skills', value: '${vm.skills.length}'),
        ),
      ],
    );
  }
}

/// Compact metric tile shown below the identity hero.
class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;

    return AppCardContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p12,
      ),
      borderRadius: BorderRadius.circular(AmberDuskSpacing.moduleRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AmberDuskTokens.typography.sectionTitle.copyWith(
              color: amber.text,
            ),
          ),
          const SizedBox(height: AppDimens.p2),
          Text(
            label,
            style: AmberDuskTokens.typography.chip.copyWith(color: amber.muted),
          ),
        ],
      ),
    );
  }
}

/// Availability summary matching the profile reference card.
class _ProfileAvailabilityCard extends StatelessWidget {
  const _ProfileAvailabilityCard({required this.vm});

  final ProfileViewModel vm;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    final subtitle = vm.loadedEmail?.trim().isEmpty ?? true
        ? 'Profile contact is connected'
        : vm.loadedEmail!.trim();

    return AppCardContainer(
      padding: const EdgeInsets.all(AppDimens.p16),
      borderRadius: BorderRadius.circular(AmberDuskSpacing.moduleRadius),
      child: Row(
        children: [
          Container(
            width: AppDimens.p40,
            height: AppDimens.p40,
            decoration: BoxDecoration(
              color: amber.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppDimens.r14),
            ),
            child: Icon(
              Icons.bolt_outlined,
              color: amber.success,
              size: AppDimens.iconSizeSmall,
            ),
          ),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready for new work',
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.p10),
          _StatusPill(label: 'Open', color: amber.success),
        ],
      ),
    );
  }
}

/// Small status badge used by profile rows and cards.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AmberDuskTokens.widgetTheme.statusPills.smallPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(
          AmberDuskTokens.widgetTheme.statusPills.radius,
        ),
      ),
      child: Text(
        label,
        style: AmberDuskTokens.widgetTheme.statusPills.smallTextStyle.copyWith(
          color: color,
        ),
      ),
    );
  }
}

/// Service rows derived from the profile skills collection.
class _ProfileServicesCard extends StatelessWidget {
  const _ProfileServicesCard({required this.skills});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    final visibleSkills = skills.take(3).toList(growable: false);

    if (visibleSkills.isEmpty) {
      return const _Panel(
        title: 'Services',
        child: _InfoRow(
          icon: Icons.design_services_outlined,
          title: 'No services listed yet',
          subtitle: 'Add services from profile editing.',
        ),
      );
    }

    return _Panel(
      title: 'Services',
      child: Column(
        children: [
          for (final skill in visibleSkills) ...[
            _ServiceRow(label: skill),
            if (skill != visibleSkills.last)
              const SizedBox(height: AppDimens.p10),
          ],
        ],
      ),
    );
  }
}

/// Portfolio preview strip using compact proof tiles from existing data.
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
      child: Row(
        children: [
          for (final item in items.take(2)) ...[
            Expanded(child: _PortfolioProofTile(item: item)),
            if (item != items.take(2).last)
              const SizedBox(width: AppDimens.p10),
          ],
        ],
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

/// Service-like row used to render real profile skills.
class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.label});

  final String label;

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
            Icons.design_services_outlined,
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
                label,
                style: AmberDuskTokens.typography.body.copyWith(
                  color: amber.text,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimens.p2),
              Text(
                'Listed skill',
                style: AmberDuskTokens.typography.bodySmall.copyWith(
                  color: amber.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.p10),
        _StatusPill(label: 'Visible', color: amber.primary),
      ],
    );
  }
}

/// Compact proof tile matching the profile portfolio strip reference.
class _PortfolioProofTile extends StatelessWidget {
  const _PortfolioProofTile({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    final title = item['title']?.toString() ?? 'Untitled';
    final description = item['description']?.toString().trim();
    final createdAt = DateTime.tryParse(item['created_at']?.toString() ?? '');
    final footer = createdAt == null ? 'Proof item' : '${createdAt.year} proof';

    return Container(
      constraints: const BoxConstraints(
        minHeight: AppDimens.p100 + AppDimens.p24,
      ),
      padding: const EdgeInsets.all(AppDimens.p12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [amber.primary.withValues(alpha: 0.18), amber.surfaceHighest],
        ),
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: amber.heroRim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusPill(label: 'Project', color: amber.primary),
          const SizedBox(height: AppDimens.p10),
          Text(
            title,
            style: AmberDuskTokens.typography.body.copyWith(
              color: amber.text,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: AppDimens.p4),
            Text(
              description,
              style: AmberDuskTokens.typography.chip.copyWith(
                color: amber.textSubtle,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppDimens.p12),
          Text(
            footer,
            style: AmberDuskTokens.typography.chip.copyWith(
              color: amber.textSubtle,
            ),
          ),
        ],
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
  unawaited(
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: userId,
          initialTabIndex: initialTabIndex,
        ),
      ),
    ),
  );
}
