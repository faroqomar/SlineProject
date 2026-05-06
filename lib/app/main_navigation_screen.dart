import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/navigation/main_nav_destinations.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';
import 'package:sline_app/core/providers/system_config_view_model.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/utils/app_animations.dart';
import 'package:sline_app/core/utils/transitions/custom_route_transitions.dart';
import 'package:sline_app/core/widgets/custom_bottom_nav_bar.dart';
import 'package:sline_app/features/chat/view/messages_screen.dart';
import 'package:sline_app/features/dashboard/view/dashboard_screen.dart';
import 'package:sline_app/features/home/view/home_screen.dart';
import 'package:sline_app/features/profile/view/profile_screen.dart';
import 'package:sline_app/features/tasks/view/create_task_screen.dart';

/// Main navigation screen that manages bottom navigation and screen switching.
///
/// Phase 2 redesign: directional tab transitions, FAB spring entrance with
/// scroll-aware visibility, animated runtime banner.
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
      _fabController.forward();
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
      _fabController.animateTo(
        0,
        duration: AppMotion.fast,
        curve: AppMotion.curveAccel,
      );
    } else if (notification.direction == ScrollDirection.forward &&
        !_fabVisible) {
      // Scrolling up — show FAB
      _fabVisible = true;
      _fabController.animateTo(
        1,
        duration: AppMotion.fast,
        curve: AppMotion.curveSpring,
      );
    }
    return false;
  }

  void _dismissBanner() {
    AppLogger.d('Runtime banner dismissed', tag: 'Navigation');
    _bannerController.reverse().then((_) {
      if (mounted) setState(() => _bannerDismissed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
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
        final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

        // Start banner animation if banner should be visible
        if (showBanner &&
            !_bannerController.isAnimating &&
            _bannerController.status == AnimationStatus.dismissed) {
          _bannerController.forward();
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
                // 1. Global Background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.teal,
                        AppColors.lightTeal,
                        AppColors.gold.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),

                // 2. Phone Background
                Container(color: colorScheme.phoneBackground),

                // 3. Active Screen with directional slide+fade transition
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 5. iOS 26 Liquid Glass Bottom Navigation Bar
                const CustomBottomNavBar(),

                // 6. FAB (Create Task) with spring entrance + scroll-aware
                Positioned(
                  bottom: AppLayout.fabBottomOffset + bottomSafePadding,
                  right: AppDimens.p24,
                  child: ScaleTransition(
                    scale: _fabScale,
                    child: AnimatedRotationButton(
                      rotationAngle: 0.125,
                      onTap: () {
                        AppLogger.i(
                          'Opening create task screen from main navigation FAB',
                          tag: 'Navigation',
                        );
                        Navigator.of(context).push(
                          SlinePageRoute.modalSheet(
                            child: createTaskBuilder(context),
                          ),
                        );
                      },
                      child: Container(
                        key: MainNavigationScreen.createTaskFabKey,
                        width: AppLayout.fabSize,
                        height: AppLayout.fabSize,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(AppDimens.r18),
                          // FAB uses custom teal-tinted shadow for brand emphasis,
                          // not the generic AppDecorations.elevation() scale.
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppColors.white,
                          // 30px — FAB-specific icon size, between iconMedium (24)
                          // and iconLarge (32). Intentionally unique for visual weight.
                          size: 30,
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
        return AppColors.gold;
      case 'error':
      case 'danger':
        return AppColors.lightRed;
      default:
        return AppColors.teal;
    }
  }
}
