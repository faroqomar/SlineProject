import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/loading_utils.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/circle_icon_button.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/core/widgets/sliver_tab_bar_delegate.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/favorites/viewmodels/favorites_view_model.dart';
import 'package:sline_app/features/profile/view/widgets/public_profile/public_profile_header.dart';
import 'package:sline_app/features/profile/view/widgets/public_profile/public_profile_portfolio.dart';
import 'package:sline_app/features/profile/view/widgets/public_profile/public_profile_reviews.dart';
import 'package:sline_app/features/profile/view/widgets/public_profile/public_profile_stats.dart';
import 'package:sline_app/features/profile/viewmodels/public_profile_view_model.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';
import 'package:sline_app/features/tasks/view/widgets/task_card.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final int initialTabIndex;

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
        context.read<FavoritesViewModel>().ensureLoaded();
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
                NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      // 1. Visual Header (Gradient + Avatar) using existing component
                      // We wrap it in SliverToBoxAdapter because it wasn't designed as a FlexibleSpaceBar
                      PublicProfileHeader(profile: profile),

                      // 2. Profile Info (Name, Title, Location, Actions)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: AppDimens.p24,
                            right: AppDimens.p24,
                            bottom: AppDimens.p24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Push content down below the absolute positioned avatar/header
                              // PublicProfileHeader height is 120, plus avatar positioning...
                              // We need about 50-60px separation from top of this sliver
                              const SizedBox(height: 60),

                              // Name & Verification
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                          ),
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
                                      CircleIconButton(
                                        icon: Icons.share,
                                        onTap: () {
                                          // TODO: Implement share
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Consumer<FavoritesViewModel>(
                                        builder: (context, favoritesVm, _) {
                                          final isFavorited = favoritesVm.items
                                              .any(
                                                (f) =>
                                                    f.freelancerId ==
                                                    profile.id,
                                              );
                                          final icon = isFavorited
                                              ? Icons.favorite
                                              : Icons.favorite_border;
                                          final color = isFavorited
                                              ? AppColors.lightRed
                                              : colorScheme.textSecondary;

                                          return CircleIconButton(
                                            key: const Key(
                                              'public_profile_favorite_toggle',
                                            ),
                                            icon: icon,
                                            iconColor: color,
                                            onTap: () async {
                                              if (isFavorited) {
                                                await favoritesVm.remove(
                                                  profile.id,
                                                );
                                              } else {
                                                await favoritesVm.add(
                                                  profile.id,
                                                );
                                              }
                                            },
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      CircleIconButton(
                                        icon: Icons.flag_outlined,
                                        iconColor: AppColors.lightRed,
                                        onTap: () => _reportUserProfileAction(
                                          context,
                                          profile.id,
                                        ),
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
                            ],
                          ),
                        ),
                      ),

                      // 3. Pinned TabBar
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: SliverTabBarDelegate(
                          TabBar(
                            controller: _tabController,
                            labelColor: AppColors.teal,
                            unselectedLabelColor: colorScheme.textSecondary,
                            labelStyle: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            indicatorColor: AppColors.teal,
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
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppDimens.p24),
                            Text('Skills', style: AppTypography.h5),
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
                            // Add extra padding at bottom to avoid floating bar overlap
                            const SizedBox(height: 100),
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
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),

                      // --- History Tab ---
                      if (profile.history.isEmpty) Center(
                              child: Text(
                                'No completed work yet.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                            ) else ListView.separated(
                              controller: _historyScrollController,
                              padding: const EdgeInsets.fromLTRB(
                                AppDimens.p24,
                                AppDimens.p24,
                                AppDimens.p24,
                                100,
                              ),
                              itemCount: profile.history.length,
                              separatorBuilder: (_, __) =>
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
                          100,
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
                  child: GlassContainer(
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
    } on Exception catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting chat: $e')));
    } finally {
      loader.close();
    }
  }

  Future<void> _reportUserProfileAction(
    BuildContext context,
    String targetUserId,
  ) async {
    var draftReason = '';
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report User'),
        content: TextField(
          maxLines: 4,
          onChanged: (value) => draftReason = value,
          decoration: const InputDecoration(
            hintText: 'Describe the issue',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, draftReason.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
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
