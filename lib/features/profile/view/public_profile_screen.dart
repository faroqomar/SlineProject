import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/loading_utils.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/circle_icon_button.dart';
import 'package:sline_app/core/widgets/sliver_tab_bar_delegate.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/favorites/viewmodels/favorites_view_model.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';
import 'package:sline_app/features/profile/view/widgets/public_profile/public_profile_header.dart';
import 'package:sline_app/features/profile/view/widgets/public_profile/public_profile_portfolio.dart';
import 'package:sline_app/features/profile/view/widgets/public_profile/public_profile_reviews.dart';
import 'package:sline_app/features/profile/view/widgets/public_profile/public_profile_stats.dart';
import 'package:sline_app/features/profile/viewmodels/public_profile_view_model.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';
import 'package:sline_app/features/tasks/view/widgets/task_card.dart';

/// Displays another user's profile while preserving profile, favorite, chat,
/// and report behavior in their existing ViewModels.
class PublicProfileScreen extends StatefulWidget {
  /// Supabase profile id loaded by [PublicProfileViewModel].
  final String userId;

  /// Initial tab selected when opening the profile preview route.
  final int initialTabIndex;

  /// Creates a public profile surface for the provided [userId].
  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.initialTabIndex = 0,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Separate ScrollControllers for each tab to avoid "attached to multiple ScrollPosition" error
  final ScrollController _aboutScrollController = ScrollController();
  final ScrollController _portfolioScrollController = ScrollController();
  final ScrollController _historyScrollController = ScrollController();
  final ScrollController _reviewsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  bool _favoritesEnsureLoadedDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_favoritesEnsureLoadedDone) {
      _favoritesEnsureLoadedDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(context.read<FavoritesViewModel>().ensureLoaded());
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aboutScrollController.dispose();
    _portfolioScrollController.dispose();
    _historyScrollController.dispose();
    _reviewsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amberColors = context.amberColors;
    final tabTheme = AmberDuskTokens.widgetTheme.tabs;

    return ChangeNotifierProvider(
      create: (_) {
        final viewModel = PublicProfileViewModel();
        unawaited(viewModel.loadProfile(widget.userId));
        return viewModel;
      },
      child: Scaffold(
        backgroundColor: colorScheme.phoneBackground,
        body: Consumer<PublicProfileViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: amberColors.primary),
              );
            }

            final profile = vm.profile;
            if (profile == null) {
              return _PublicProfileErrorState(
                message: vm.error ?? 'User not found',
                onRetry: () => vm.loadProfile(widget.userId),
              );
            }

            return Stack(
              children: [
                NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      PublicProfileHeader(
                        profile: profile,
                        trailingActions: _buildHeroActions(context, profile),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppDimens.p24,
                            AppDimens.p0,
                            AppDimens.p24,
                            AppDimens.p16,
                          ),
                          child: PublicProfileStats(profile: profile),
                        ),
                      ),

                      // 3. Pinned TabBar
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: SliverTabBarDelegate(
                          TabBar(
                            controller: _tabController,
                            labelColor: tabTheme.activeLabelColor,
                            unselectedLabelColor: tabTheme.inactiveLabelColor,
                            labelStyle: tabTheme.labelStyle,
                            unselectedLabelStyle: tabTheme.inactiveLabelStyle,
                            indicatorColor: tabTheme.indicatorColor,
                            indicatorSize: TabBarIndicatorSize.label,
                            tabs: const [
                              Tab(text: 'About'),
                              Tab(text: 'Portfolio'),
                              Tab(text: 'History'),
                              Tab(text: 'Reviews'),
                            ],
                          ),
                          backgroundColor: colorScheme.phoneBackground,
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      // --- About Tab ---
                      SingleChildScrollView(
                        controller: _aboutScrollController,
                        padding: const EdgeInsets.all(AppDimens.p24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bio', style: AppTypography.h5),
                            const SizedBox(height: AppDimens.p8),
                            Text(
                              profile.bio,
                              style: AppTypography.bodySmall.copyWith(
                                color: colorScheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppDimens.p24),
                            Text('Skills', style: AppTypography.h5),
                            const SizedBox(height: AppDimens.p8),
                            Wrap(
                              spacing: AppDimens.p8,
                              runSpacing: AppDimens.p8,
                              children: profile.skills.map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimens.p12,
                                    vertical: AppDimens.p6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.cardBackground,
                                    borderRadius: BorderRadius.circular(
                                      AmberDuskTokens.spacing.pillRadius,
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
                            // Add extra padding at bottom to avoid floating bar overlap
                            const SizedBox(
                              height: AppDimens.publicProfileStickyBarClearance,
                            ),
                          ],
                        ),
                      ),

                      // --- Portfolio Tab ---
                      SingleChildScrollView(
                        controller: _portfolioScrollController,
                        padding: const EdgeInsets.all(AppDimens.p24),
                        child: Column(
                          children: [
                            PublicProfilePortfolio(
                              portfolio: profile.portfolio,
                            ),
                            const SizedBox(
                              height: AppDimens.publicProfileStickyBarClearance,
                            ),
                          ],
                        ),
                      ),

                      // --- History Tab ---
                      if (profile.history.isEmpty)
                        Center(
                          child: Text(
                            'No completed work yet.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colorScheme.textSecondary,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          controller: _historyScrollController,
                          padding: const EdgeInsets.fromLTRB(
                            AppDimens.p24,
                            AppDimens.p24,
                            AppDimens.p24,
                            AppDimens.publicProfileStickyBarClearance,
                          ),
                          itemCount: profile.history.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppDimens.p12),
                          itemBuilder: (context, index) {
                            return TaskCard(
                              task: profile.history[index],
                              onTap: () {
                                // Navigate to task details
                              },
                            );
                          },
                        ),

                      // --- Reviews Tab ---
                      SingleChildScrollView(
                        controller: _reviewsScrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AppDimens.p24,
                          AppDimens.p24,
                          AppDimens.p24,
                          AppDimens.publicProfileStickyBarClearance,
                        ),
                        child: PublicProfileReviews(reviews: profile.reviews),
                      ),
                    ],
                  ),
                ),

                // Sticky Bottom Bar (Hire / Message)
                Positioned(
                  bottom: AppDimens.p24,
                  left: AppDimens.p24,
                  right: AppDimens.p24,
                  child: AppCardContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p8,
                      vertical: AppDimens.p8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () =>
                                _handleMessageAction(context, profile.id),
                            icon: Icon(Icons.message, color: colorScheme.text),
                            label: Text(
                              'Message',
                              style: AppTypography.bodyLarge.copyWith(
                                color: colorScheme.text,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: AppDimens.publicProfileActionDividerWidth,
                          height: AppDimens.publicProfileActionDividerHeight,
                          color: amberColors.heroDivider,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.p8,
                            ),
                            child: AppButton(
                              text: 'Hire Now',
                              onPressed: () =>
                                  _handleHireAction(context, profile.id),
                              height: AppDimens.publicProfileActionButtonHeight,
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

  Widget _buildHeroActions(BuildContext context, FreelancerProfile profile) {
    final colorScheme = context.colorScheme;
    final amberColors = context.amberColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleIconButton(
          icon: Icons.share,
          tooltip: 'Share profile',
          onTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Share coming soon')));
          },
        ),
        const SizedBox(width: AppDimens.p4),
        Consumer<FavoritesViewModel>(
          builder: (context, favoritesVm, _) {
            final isFavorited = favoritesVm.items.any(
              (f) => f.freelancerId == profile.id,
            );
            final icon = isFavorited ? Icons.favorite : Icons.favorite_border;
            final color = isFavorited
                ? amberColors.danger
                : colorScheme.textSecondary;

            return CircleIconButton(
              key: const Key('public_profile_favorite_toggle'),
              icon: icon,
              iconColor: color,
              tooltip: isFavorited ? 'Remove favorite' : 'Add favorite',
              onTap: () async {
                if (isFavorited) {
                  await favoritesVm.remove(profile.id);
                } else {
                  await favoritesVm.add(profile.id);
                }
              },
            );
          },
        ),
        const SizedBox(width: AppDimens.p4),
        CircleIconButton(
          icon: Icons.flag_outlined,
          iconColor: amberColors.danger,
          tooltip: 'Report profile',
          onTap: () => _reportUserProfileAction(context, profile.id),
        ),
      ],
    );
  }

  void _handleHireAction(BuildContext context, String targetUserId) {
    AppLogger.i(
      'Public profile hire action requested',
      tag: 'PublicProfile',
      json: {'target_user_id': targetUserId},
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking from public profiles is coming soon.'),
      ),
    );
  }

  Future<void> _handleMessageAction(
    BuildContext context,
    String targetUserId,
  ) async {
    final chatVm = context.read<ChatViewModel>();
    final currentUserId = chatVm.currentUserId;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to message.')),
      );
      return;
    }

    if (currentUserId == targetUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself.')),
      );
      return;
    }

    final loader = LoadingUtils.show(
      context,
      debugLabel: 'public_profile_message',
    );
    try {
      final conversation = await chatVm.createOrGetConversation(
        user1Id: currentUserId,
        user2Id: targetUserId,
      );

      // Handle double-tap or error (conversation is null)
      if (conversation == null) {
        loader.close();
        return;
      }
      if (!context.mounted) return;

      unawaited(
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversation: conversation),
          ),
        ),
      );
    } on Exception catch (e, st) {
      AppLogger.e(
        'Public profile chat start failed',
        tag: 'PublicProfile',
        error: e,
        stackTrace: st,
      );
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start chat. Please try again.'),
        ),
      );
    } finally {
      loader.close();
    }
  }

  Future<void> _reportUserProfileAction(
    BuildContext context,
    String targetUserId,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const ReportUserDialog(),
    );
    if (!context.mounted || reason == null || reason.isEmpty) return;

    final vm = context.read<SafetyViewModel>();
    final ok = await vm.submitReport(
      entityType: 'user',
      entityId: targetUserId,
      reason: reason,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Report submitted.' : (vm.error ?? 'Report failed.'),
        ),
      ),
    );
  }
}

/// Dialog that collects a non-empty reason before submitting a user report.
///
/// The dialog owns only temporary form state. [SafetyViewModel] submission stays
/// in the parent screen so report authority remains outside the form widget.
class ReportUserDialog extends StatefulWidget {
  /// Creates the report-user reason prompt.
  const ReportUserDialog({super.key});

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  var _draftReason = '';

  @override
  Widget build(BuildContext context) {
    final dialogColors = context.colorScheme;
    final dialogAmber = context.amberColors;
    final trimmedReason = _draftReason.trim();

    return AlertDialog(
      backgroundColor: dialogAmber.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AmberDuskTokens.spacing.taskCardRadius,
        ),
      ),
      title: Text(
        'Report User',
        style: AppTypography.h5.copyWith(color: dialogColors.text),
      ),
      content: TextField(
        maxLines: 4,
        onChanged: (value) => setState(() => _draftReason = value),
        style: AppTypography.bodyMedium.copyWith(color: dialogColors.text),
        decoration: InputDecoration(
          hintText: 'Describe the issue',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: dialogColors.textSecondary,
          ),
          filled: true,
          fillColor: dialogAmber.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AmberDuskTokens.widgetTheme.fields.radius,
            ),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: trimmedReason.isEmpty
              ? null
              : () => Navigator.pop(context, trimmedReason),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

/// Error state for public-profile load failures.
///
/// It distinguishes repository/network failures from a genuine missing profile
/// while preserving the existing retry path through [PublicProfileViewModel].
class _PublicProfileErrorState extends StatelessWidget {
  const _PublicProfileErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amberColors = context.amberColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: AppCardContainer(
          padding: const EdgeInsets.all(AppDimens.p20),
          borderRadius: BorderRadius.circular(AmberDuskTokens.spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_outlined,
                color: amberColors.danger,
                size: AppDimens.emptyStateIconSize,
              ),
              const SizedBox(height: AppDimens.p12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.text,
                ),
              ),
              const SizedBox(height: AppDimens.p16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: amberColors.primary,
                  foregroundColor: amberColors.textInverse,
                ),
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
