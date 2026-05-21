import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/navigation/main_nav_destinations.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';
import 'package:sline_app/core/providers/system_config_view_model.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/app_animations.dart';
import 'package:sline_app/core/utils/transitions/custom_route_transitions.dart';
import 'package:sline_app/core/widgets/custom_bottom_nav_bar.dart';
import 'package:sline_app/features/chat/view/messages_screen.dart';
import 'package:sline_app/features/dashboard/view/dashboard_screen.dart';
import 'package:sline_app/features/home/view/home_screen.dart';
import 'package:sline_app/features/profile/view/profile_screen.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';
import 'package:sline_app/features/tasks/view/create_task_screen.dart';
import 'package:sline_app/features/tasks/viewmodels/discovery_feed_view_model_contract.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

/// Main navigation screen that manages bottom navigation and screen switching.
///
/// Phase 2 redesign: directional tab transitions, FAB spring entrance with
/// scroll-aware visibility, Home-owned create action, and Amber Dusk shell
/// materials that do not activate the global app theme.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    this.screens,
    this.createTaskScreenBuilder,
  });

  static const Key createTaskFabKey = ValueKey<String>('main_nav_create_task');

  final List<Widget>? screens;
  final WidgetBuilder? createTaskScreenBuilder;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fabController;
  late final Animation<double> _fabScale;
  late final AnimationController _bannerController;
  late final Animation<Offset> _bannerSlide;

  int _previousTabIndex = 0;
  bool _fabVisible = true;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();

    // FAB spring entrance
    _fabController = AnimationController(
      duration: AppMotion.emphasis,
      vsync: this,
    );
    _fabScale = CurvedAnimation(
      parent: _fabController,
      curve: AppMotion.curveSpring,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.d('FAB entrance animation started', tag: 'Navigation');
      unawaited(_fabController.forward());
    });

    // Banner slide-in
    _bannerController = AnimationController(
      duration: AppMotion.standard,
      vsync: this,
    );
    _bannerSlide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _bannerController,
            curve: AppMotion.curveDecel,
          ),
        );
  }

  @override
  void dispose() {
    _fabController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  bool _onScrollNotification(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.reverse && _fabVisible) {
      // Scrolling down — hide FAB
      _fabVisible = false;
      unawaited(
        _fabController.animateTo(
          0,
          duration: AppMotion.fast,
          curve: AppMotion.curveAccel,
        ),
      );
    } else if (notification.direction == ScrollDirection.forward &&
        !_fabVisible) {
      // Scrolling up — show FAB
      _fabVisible = true;
      unawaited(
        _fabController.animateTo(
          1,
          duration: AppMotion.fast,
          curve: AppMotion.curveSpring,
        ),
      );
    }
    return false;
  }

  void _dismissBanner() {
    AppLogger.d('Runtime banner dismissed', tag: 'Navigation');
    unawaited(
      _bannerController.reverse().then((_) {
        if (mounted) setState(() => _bannerDismissed = true);
      }),
    );
  }

  Future<void> _openCreateTask(
    BuildContext context,
    WidgetBuilder createTaskBuilder,
  ) async {
    AppLogger.i('Opening create task screen from Home FAB', tag: 'Navigation');
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await navigator.push<CreateTaskResult>(
      SlinePageRoute.modalSheet(child: createTaskBuilder(context)),
    );

    if (!mounted || !context.mounted) return;
    if (result == null) {
      AppLogger.d(
        'Create task sheet dismissed without changes',
        tag: 'Navigation',
      );
      return;
    }

    AppLogger.i(
      'Create task sheet completed',
      tag: 'Navigation',
      json: <String, dynamic>{
        'operation': result.operation.name,
        'task_type': result.taskType.name,
        if (result.taskId != null) 'task_id': result.taskId,
      },
    );

    await _refreshAfterCreateTask();
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.successMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _refreshAfterCreateTask() async {
    final navigationProvider = context.read<NavigationProvider?>();
    final feedViewModel = context.read<DiscoveryFeedViewModelContract?>();
    final filterViewModel = context.read<TaskFilterViewModel?>();
    final profileViewModel = context.read<ProfileViewModel?>();

    navigationProvider?.setCurrentIndex(MainNavDestinations.home);

    final refreshes = <Future<void>>[];
    if (feedViewModel != null && filterViewModel != null) {
      refreshes.add(
        feedViewModel.refresh(
          filterController: filterViewModel,
          surface: 'home_post_create',
        ),
      );
    }
    if (profileViewModel != null) {
      refreshes.add(profileViewModel.loadHeaderProfile());
    }

    if (refreshes.isEmpty) {
      AppLogger.w(
        'Create task completed without available refresh providers',
        tag: 'Navigation',
      );
      return;
    }

    try {
      await Future.wait(refreshes);
      AppLogger.i('Create task completion refresh finished', tag: 'Navigation');
    } on Exception catch (error, stackTrace) {
      AppLogger.e(
        'Create task completion refresh failed',
        tag: 'Navigation',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    const amberColors = AmberDuskTokens.colors;
    const phoneLayout = AmberDuskTokens.phoneLayout;
    final createTaskBuilder =
        widget.createTaskScreenBuilder ?? ((_) => const CreateTaskScreen());

    final screens =
        widget.screens ??
        const [
          HomeScreen(),
          DashboardScreen(),
          MessagesScreen(),
          ProfileScreen(),
        ];

    if (screens.length != MainNavDestinations.visibleCount) {
      AppLogger.w(
        'MainNavigationScreen received ${screens.length} screens, expected ${MainNavDestinations.visibleCount}',
        tag: 'Navigation',
      );
    }

    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        final rawIndex = navigationProvider.currentIndex;
        final currentIndex =
            MainNavDestinations.isVisibleIndex(rawIndex) &&
                rawIndex < screens.length
            ? rawIndex
            : MainNavDestinations.home;
        if (rawIndex != currentIndex) {
          AppLogger.w(
            'Normalizing stale main navigation index $rawIndex to ${MainNavDestinations.home}',
            tag: 'Navigation',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                navigationProvider.currentIndex == rawIndex &&
                rawIndex != currentIndex) {
              navigationProvider.setCurrentIndex(MainNavDestinations.home);
            }
          });
        }
        final runtimeConfig = context.watch<SystemConfigViewModel?>()?.config;
        final hasBanner =
            runtimeConfig != null &&
            runtimeConfig.bannerEnabled &&
            runtimeConfig.bannerText.trim().isNotEmpty;
        final showBanner = !_bannerDismissed && hasBanner;
        final showCreateFab = currentIndex == MainNavDestinations.home;
        final fabBottomOffset =
            phoneLayout.bottomNavBottom +
            phoneLayout.bottomNavHeight +
            AmberDuskTokens.spacing.sm;
        final bottomFadeHeight =
            MediaQuery.viewPaddingOf(context).bottom +
            phoneLayout.bottomNavBottom +
            phoneLayout.bottomNavHeight +
            AmberDuskTokens.spacing.xxl;

        // Start banner animation if banner should be visible
        if (showBanner &&
            !_bannerController.isAnimating &&
            _bannerController.status == AnimationStatus.dismissed) {
          unawaited(_bannerController.forward());
        }

        // Determine slide direction based on tab index change
        final goingForward = currentIndex >= _previousTabIndex;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _previousTabIndex = currentIndex;
        });

        return Scaffold(
          extendBody: true,
          body: NotificationListener<UserScrollNotification>(
            onNotification: _onScrollNotification,
            child: Stack(
              children: [
                // 1. Amber Dusk shell background. The solid base keeps the app
                // calm while the two tiny radial fades separate the phone shell
                // from safe areas without becoming decoration.
                const Positioned.fill(
                  child: ColoredBox(color: AmberDuskColors.background),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: AmberDuskMaterial.atmosphericAmberDecoration,
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: AmberDuskMaterial.atmosphericForestDecoration,
                  ),
                ),

                // 2. Active Screen with directional slide+fade transition
                AnimatedSwitcher(
                  duration: AppMotion.standard,
                  switchInCurve: AppMotion.curveStandard,
                  switchOutCurve: AppMotion.curveStandard,
                  transitionBuilder: (child, animation) {
                    if (MediaQuery.of(context).disableAnimations) {
                      return child;
                    }
                    final slideOffset = Tween<Offset>(
                      begin: Offset(goingForward ? 0.05 : -0.05, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: slideOffset,
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(currentIndex),
                    child: screens[currentIndex],
                  ),
                ),

                // 4. Runtime Banner with slide-in animation
                if (showBanner)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + AppDimens.p8,
                    left: AppDimens.p16,
                    right: AppDimens.p16,
                    child: SlideTransition(
                      position: _bannerSlide,
                      child: GestureDetector(
                        onVerticalDragEnd: (details) {
                          if ((details.primaryVelocity ?? 0) < -100) {
                            _dismissBanner();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.p12,
                            vertical: AppDimens.p10,
                          ),
                          decoration: BoxDecoration(
                            color: _bannerColor(
                              runtimeConfig.bannerType,
                            ).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(AppDimens.r12),
                          ),
                          child: Text(
                            runtimeConfig.bannerText,
                            style: AppTypography.captionBold.copyWith(
                              color: amberColors.text,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 5. Bottom navigation safe-area fade. It only sits behind the
                // fixed nav so scrolled content disappears naturally at the edge.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: bottomFadeHeight,
                  child: const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AmberDuskMaterial.bottomNavFadeGradient,
                      ),
                    ),
                  ),
                ),

                // 6. Amber Dusk solid bottom navigation bar
                const CustomBottomNavBar(),

                // 7. Home-owned FAB with spring entrance + scroll-aware motion
                if (showCreateFab)
                  Positioned(
                    // The nav bar uses Amber Dusk frame-edge positioning, so
                    // the FAB mirrors that coordinate system and stays exactly
                    // one spacing token above the shell.
                    bottom: fabBottomOffset,
                    right: AppDimens.p24,
                    child: ScaleTransition(
                      scale: _fabScale,
                      child: Semantics(
                        label: 'Create a post',
                        button: true,
                        child: Tooltip(
                          message: 'Create a post',
                          child: AnimatedRotationButton(
                            rotationAngle: 0.125,
                            onTap: () {
                              unawaited(
                                _openCreateTask(context, createTaskBuilder),
                              );
                            },
                            child: Container(
                              key: MainNavigationScreen.createTaskFabKey,
                              width: phoneLayout.fabSize,
                              height: phoneLayout.fabSize,
                              decoration: BoxDecoration(
                                color: amberColors.primary,
                                borderRadius: BorderRadius.circular(
                                  phoneLayout.fabRadius,
                                ),
                                boxShadow: AppDecorations.elevation(
                                  AmberDuskTokens.surfaces.cta.elevationLevel,
                                  isDark: colorScheme.isDark,
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                color: amberColors.page,
                                size: AppDimens.iconSizeLarge,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _bannerColor(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return AmberDuskTokens.colors.star;
      case 'error':
      case 'danger':
        return AmberDuskTokens.colors.rust;
      default:
        return AmberDuskTokens.colors.primary;
    }
  }
}
