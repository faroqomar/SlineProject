import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
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
  /// Phase 7 redesign: migrated from AlertDialog to BottomSheet for a more
  /// native mobile feel. The sheet uses solid surface (cardBackground),
  /// drag handle, and safe-area-aware bottom padding.
  void _showSettings(BuildContext context, DashboardViewModel vm) {
    final colorScheme = context.colorScheme;

    AppLogger.d('DashboardScreen: opening settings sheet', tag: 'Dashboard');

    showModalBottomSheet(
      context: context,
      // Rounded top corners for premium sheet appearance
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.r24),
        ),
      ),
      backgroundColor: colorScheme.cardBackground,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.screenHorizontalMargin,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppLayout.spacingStandard),
              // Drag handle — visual affordance for dismissibility
              Container(
                width: AppDimens.p40,
                height: AppDimens.p4,
                decoration: BoxDecoration(
                  color: colorScheme.textTertiary,
                  borderRadius: BorderRadius.circular(AppDimens.r4),
                ),
              ),
              const SizedBox(height: AppLayout.spacingSection),
              Text(
                'Dashboard Settings',
                style: AppTypography.h5.copyWith(color: colorScheme.text),
              ),
              const SizedBox(height: AppLayout.spacingScreen),
              // Section label for role switcher
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'User Role',
                  style: AppTypography.captionBold.copyWith(
                    color: colorScheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppLayout.spacingStandard),
              // Role switcher — shared via Provider so it reads VM state
              ChangeNotifierProvider.value(
                value: vm,
                child: const _RoleSwitch(),
              ),
              const SizedBox(height: AppLayout.spacingScreen),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final colorScheme = context.colorScheme;

    // Sync controller with VM state
    if (_tabController.index != vm.currentTab.index) {
      _tabController.animateTo(vm.currentTab.index);
    }

    // Minimal top bar — clean text tabs, no containers, no pills,
    // no decoration noise. Just typography and a thin underline.
    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: AppTypography.h4.copyWith(color: colorScheme.text),
        ),
        backgroundColor: colorScheme.background,
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Dashboard settings',
            icon: Icon(
              key: DashboardScreen.settingsButtonKey,
              Icons.settings_outlined,
              color: colorScheme.textSecondary,
            ),
            onPressed: () => _showSettings(context, vm),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(AppDimens.p40),
          child: Semantics(
            label: 'Dashboard tabs',
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              // Thin 2px underline — minimal, not a pill or box
              indicatorWeight: 2,
              indicatorColor: colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              // Active: primary colored text, bold
              labelColor: colorScheme.primary,
              labelStyle: AppTypography.captionBold,
              // Inactive: muted text
              unselectedLabelColor: colorScheme.textTertiary,
              unselectedLabelStyle: AppTypography.caption,
              dividerColor: colorScheme.divider,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p8,
              ),
              onTap: vm.setTab,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Bookings'),
                Tab(text: 'Work'),
                Tab(text: 'Wallet'),
                Tab(text: 'Inbox'),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        // Padding to avoid overlap with Main Bottom Nav Bar
        padding: const EdgeInsets.only(
          bottom: AppLayout.bottomNavHeight + AppLayout.spacingStandard,
        ),
        child: TabBarView(
          controller: _tabController,
          physics:
              const NeverScrollableScrollPhysics(), // Disable swipe to avoid conflict with internal tabs
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
    );
    return scaffold;
  }
}

class _RoleSwitch extends StatelessWidget {
  const _RoleSwitch();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final colorScheme = context.colorScheme;
    final isFreelancer = vm.currentRole == UserRole.freelancer;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.inputBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.inputBorder),
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
    final colorScheme = context.colorScheme;

    return Semantics(
      button: true,
      // selected communicates active state to screen readers without embedding it
      // in the label string, enabling proper VoiceOver/TalkBack announcements.
      selected: isActive,
      label: '$label role',
      child: GestureDetector(
        onTap: () {
          AppInteractionStates.hapticTap();
          onTap();
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
            color: isActive ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.r16),
          ),
          child: Text(
            label,
            style: AppTypography.captionBold.copyWith(
              // onPrimary (Material ColorScheme) ensures legible contrast against the primary-colored active background
              color: isActive
                  ? Theme.of(context).colorScheme.onPrimary
                  : colorScheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
