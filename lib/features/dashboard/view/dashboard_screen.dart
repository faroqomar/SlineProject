import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/web_url_utils_stub.dart'
    if (dart.library.html) 'package:sline_app/core/utils/web_url_utils_web.dart'
    as web_url_utils;
import 'package:sline_app/features/dashboard/view/tabs/bookings_tab.dart';
import 'package:sline_app/features/dashboard/view/tabs/inbox_tab.dart';
import 'package:sline_app/features/dashboard/view/tabs/overview_tab.dart';
import 'package:sline_app/features/dashboard/view/tabs/wallet_tab.dart';
import 'package:sline_app/features/dashboard/view/tabs/work_tab.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/direct_offers/services/direct_offers_service.dart';

/// Single source of dashboard tab labels for both TabBar and header copy.
const List<String> _dashboardTabLabels = [
  'Overview',
  'Bookings',
  'Work',
  'Wallet',
  'Inbox',
];

/// Phone dashboard shell for overview, bookings, work, wallet, and inbox.
///
/// The shell owns only tab presentation and recovery wiring; data loading and
/// role state remain in [DashboardViewModel] so lazy loading stays centralized.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.tabViews});

  static const Key settingsButtonKey = ValueKey<String>(
    'dashboard_settings_button',
  );
  static const Key freelancerRoleButtonKey = ValueKey<String>(
    'dashboard_role_freelancer',
  );
  static const Key clientRoleButtonKey = ValueKey<String>(
    'dashboard_role_client',
  );

  final List<Widget>? tabViews;

  @override
  Widget build(BuildContext context) {
    return _DashboardContent(tabViews: tabViews);
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({this.tabViews});

  final List<Widget>? tabViews;

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _webPaymentReturnHandled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    if (kIsWeb && !_webPaymentReturnHandled) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleWebPaymentReturnIfPresent(),
      );
    }
  }

  /// Web: when user returns from QiCard with payment_return=1 and either
  /// offer_id+payment_request_id (direct offer) or request_id+payment_request_id (tender),
  /// run recovery and clear the URL.
  Future<void> _handleWebPaymentReturnIfPresent() async {
    if (!mounted || !kIsWeb) return;
    final uri = Uri.base;
    if (uri.queryParameters['payment_return'] != '1') return;

    final offerId = uri.queryParameters['offer_id'];
    final requestId = uri.queryParameters['request_id'];
    final paymentRequestId = uri.queryParameters['payment_request_id'];

    final isDirectOffer =
        offerId != null &&
        offerId.isNotEmpty &&
        paymentRequestId != null &&
        paymentRequestId.isNotEmpty;
    final isTender =
        requestId != null &&
        requestId.isNotEmpty &&
        paymentRequestId != null &&
        paymentRequestId.isNotEmpty;

    if (!isDirectOffer && !isTender) return;

    _webPaymentReturnHandled = true;
    final vm = context.read<DashboardViewModel>();

    if (isDirectOffer) {
      final directOffers = context.read<DirectOffersService>();
      try {
        await directOffers.recoverPaymentAfterCallback(
          offerId,
          paymentRequestId,
        );
        AppLogger.i(
          'Web direct-offer recovery succeeded',
          tag: 'Dashboard',
          json: <String, dynamic>{'offer_id': offerId},
        );
      } on Exception catch (e) {
        AppLogger.e(
          'Web direct-offer recovery failed offer_id=$offerId',
          tag: 'Dashboard',
          error: e,
        );
      }
    } else if (isTender) {
      final paymentService = context.read<PaymentService>();
      try {
        final result = await paymentService.recoverTenderPaymentAfterCallback(
          requestId: requestId,
          paymentRequestId: paymentRequestId,
        );
        if (result.isSuccess) {
          AppLogger.i(
            'Web tender recovery succeeded',
            tag: 'Dashboard',
            json: <String, dynamic>{'request_id': requestId},
          );
        } else {
          AppLogger.w(
            'Web tender recovery returned not ok',
            tag: 'Dashboard',
            json: <String, dynamic>{
              'request_id': requestId,
              'error': result.error,
            },
          );
        }
      } on Exception catch (e) {
        AppLogger.e(
          'Web tender recovery failed request_id=$requestId',
          tag: 'Dashboard',
          error: e,
        );
      }
    }

    web_url_utils.clearPaymentReturnParamsFromUrl();
    if (mounted) unawaited(vm.refresh());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Opens a bottom sheet with dashboard settings (role switcher).
  ///
  /// The sheet uses the Amber Dusk scoped-sheet recipe so dashboard settings
  /// feel like the rest of the phone shell instead of the legacy app theme.
  void _showSettings(BuildContext context, DashboardViewModel vm) {
    const amber = AmberDuskTokens.colors;
    final sheetRecipe = AmberDuskTokens.surfaces.sheet;
    final colorScheme = context.colorScheme;

    AppLogger.d('DashboardScreen: opening settings sheet', tag: 'Dashboard');

    unawaited(
      showModalBottomSheet(
        context: context,
        showDragHandle: false,
        backgroundColor: AmberDuskColors.transparent,
        barrierColor: amber.scrim,
        builder: (sheetContext) {
          final bottomSafePadding = MediaQuery.viewPaddingOf(
            sheetContext,
          ).bottom;
          return SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: sheetRecipe.fill,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(sheetRecipe.radius),
                ),
                boxShadow: AppDecorations.elevation(
                  sheetRecipe.elevationLevel,
                  isDark: colorScheme.isDark,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AmberDuskSpacing.contentHorizontalPadding,
                  AppDimens.p12,
                  AmberDuskSpacing.contentHorizontalPadding,
                  AppDimens.p20 + bottomSafePadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Single Amber Dusk handle; showModalBottomSheet's
                    // built-in handle stays disabled to avoid duplicate layers.
                    Container(
                      width: AppDimens.p40,
                      height: AppDimens.p4,
                      decoration: BoxDecoration(
                        color: amber.surfaceHighest,
                        borderRadius: BorderRadius.circular(AppDimens.r4),
                      ),
                    ),
                    const SizedBox(height: AppDimens.p18),
                    Text(
                      'Dashboard Settings',
                      style: AmberDuskTokens.typography.sectionTitle.copyWith(
                        color: amber.text,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'User Role',
                        style: AmberDuskTokens.typography.chip.copyWith(
                          color: amber.textSubtle,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.p12),
                    ChangeNotifierProvider.value(
                      value: vm,
                      child: const _RoleSwitch(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    const amber = AmberDuskTokens.colors;
    const spacing = AmberDuskTokens.spacing;
    const typography = AmberDuskTokens.typography;
    final bottomClearance = _dashboardBottomClearance(context);

    // Sync controller with VM state
    if (_tabController.index != vm.currentTab.index) {
      _tabController.animateTo(vm.currentTab.index);
    }

    return Scaffold(
      backgroundColor: amber.page,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.contentHorizontalPadding,
                spacing.md,
                spacing.contentHorizontalPadding,
                spacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dashboardTabLabel(vm.currentTab).toUpperCase(),
                            style: typography.chip.copyWith(
                              color: amber.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppDimens.p4),
                          Text(
                            'Dashboard',
                            style: typography.screenTitle.copyWith(
                              color: amber.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dashboard settings',
                    icon: Icon(
                      key: DashboardScreen.settingsButtonKey,
                      Icons.settings_outlined,
                      color: amber.textSubtle,
                    ),
                    onPressed: () => _showSettings(context, vm),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.contentHorizontalPadding,
              ),
              child: Semantics(
                label: 'Dashboard tabs',
                child: _DashboardTabStrip(
                  currentIndex: vm.currentTab.index,
                  onSelected: vm.setTab,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.p8),
            Expanded(
              child: Padding(
                // Padding avoids overlap with the app-level bottom nav.
                padding: EdgeInsets.only(bottom: bottomClearance),
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children:
                      widget.tabViews ??
                      const [
                        OverviewTab(),
                        BookingsTab(),
                        WorkTab(),
                        WalletTab(),
                        InboxTab(),
                      ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the visible section label for the active dashboard tab.
  String _dashboardTabLabel(DashboardTab tab) => _dashboardTabLabels[tab.index];

  double _dashboardBottomClearance(BuildContext context) {
    const phoneLayout = AmberDuskTokens.phoneLayout;
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;
    // Dashboard tabs sit behind the app-level floating nav, so the shell owns
    // the shared clearance before each inner tab adds any local list padding.
    return bottomSafePadding +
        phoneLayout.bottomNavBottom +
        phoneLayout.bottomNavHeight +
        AppDimens.p16;
  }
}

/// Centered dashboard tab strip with exactly one visual active state.
///
/// A custom strip avoids Material TabBar pressed/focus overlays that can make a
/// second tab look selected while keeping horizontal scrolling for localization.
class _DashboardTabStrip extends StatelessWidget {
  const _DashboardTabStrip({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const spacing = AmberDuskTokens.spacing;
    final tabTheme = AmberDuskTokens.widgetTheme.tabs;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_dashboardTabLabels.length, (index) {
                final isActive = index == currentIndex;
                final label = _dashboardTabLabels[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _dashboardTabLabels.length - 1
                        ? 0
                        : spacing.xs,
                  ),
                  child: Semantics(
                    button: true,
                    selected: isActive,
                    label: '$label dashboard tab',
                    child: GestureDetector(
                      key: ValueKey<String>('dashboard_tab_$label'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        AppInteractionStates.hapticTap();
                        onSelected(index);
                      },
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        curve: AppMotion.curveStandard,
                        constraints: const BoxConstraints(
                          minHeight: AppDimens.p48,
                        ),
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: spacing.md),
                        decoration: BoxDecoration(
                          color: isActive
                              ? amber.activeGlow
                              : AmberDuskColors.transparent,
                          borderRadius: BorderRadius.circular(
                            spacing.compactControlRadius,
                          ),
                        ),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              (isActive
                                      ? tabTheme.labelStyle
                                      : tabTheme.inactiveLabelStyle)
                                  .copyWith(
                                    color: isActive
                                        ? tabTheme.activeLabelColor
                                        : tabTheme.inactiveLabelColor,
                                  ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class _RoleSwitch extends StatelessWidget {
  const _RoleSwitch();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    const amber = AmberDuskTokens.colors;
    final isFreelancer = vm.currentRole == UserRole.freelancer;

    return Container(
      padding: const EdgeInsets.all(AppDimens.p4),
      decoration: BoxDecoration(
        color: AmberDuskWidgetTheme.fieldSurface,
        borderRadius: BorderRadius.circular(AppDimens.r20),
        border: Border.all(color: amber.dark.overlay),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoleButton(
            label: 'Freelancer',
            isActive: isFreelancer,
            buttonKey: DashboardScreen.freelancerRoleButtonKey,
            onTap: () => vm.setRole(UserRole.freelancer),
          ),
          _RoleButton(
            label: 'Client',
            isActive: !isFreelancer,
            buttonKey: DashboardScreen.clientRoleButtonKey,
            onTap: () => vm.setRole(UserRole.client),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Key? buttonKey;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.isActive,
    this.buttonKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;

    return Semantics(
      button: true,
      // selected communicates active state to screen readers without embedding it
      // in the label string, enabling proper VoiceOver/TalkBack announcements.
      selected: isActive,
      label: '$label role',
      child: GestureDetector(
        onTap: () {
          AppInteractionStates.hapticTap();
          if (isActive) return;
          onTap();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Role changed to $label.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
        },
        child: AnimatedContainer(
          key: buttonKey,
          duration: AppMotion.fast,
          // curveStandard for smooth deceleration on role toggle
          curve: AppMotion.curveStandard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p16,
            vertical: AppDimens.p6,
          ),
          decoration: BoxDecoration(
            color: isActive ? amber.primary : AmberDuskColors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.r16),
          ),
          child: Text(
            label,
            style: AmberDuskTokens.typography.control.copyWith(
              color: isActive ? amber.textInverse : amber.textSubtle,
            ),
          ),
        ),
      ),
    );
  }
}
