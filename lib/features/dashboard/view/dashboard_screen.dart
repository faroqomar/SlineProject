import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/core/utils/web_url_utils_stub.dart'
    if (dart.library.html) 'package:sline_app/core/utils/web_url_utils_web.dart'
    as web_url_utils;
import 'package:sline_app/features/direct_offers/services/direct_offers_service.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/app_enums.dart';
import '../viewmodels/dashboard_view_model.dart';
import 'tabs/overview_tab.dart';
// import 'tabs/manage_tab.dart'; // Removed
import 'tabs/bookings_tab.dart';
import 'tabs/work_tab.dart';
import 'tabs/wallet_tab.dart';
import 'tabs/inbox_tab.dart';

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
      } catch (e) {
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
      } catch (e) {
        AppLogger.e(
          'Web tender recovery failed request_id=$requestId',
          tag: 'Dashboard',
          error: e,
        );
      }
    }

    web_url_utils.clearPaymentReturnParamsFromUrl();
    if (mounted) vm.refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSettings(BuildContext context, DashboardViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dashboard Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User Role'),
            const SizedBox(height: 12),
            // Reusing the Role Switcher here
            ChangeNotifierProvider.value(value: vm, child: const _RoleSwitch()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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

    var scaffold = Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: AppTypography.h4.copyWith(color: colorScheme.text),
        ),
        backgroundColor: colorScheme.background,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              key: DashboardScreen.settingsButtonKey,
              Icons.settings_outlined,
              color: colorScheme.textSecondary,
            ),
            onPressed: () => _showSettings(context, vm),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.textSecondary,
            indicatorColor: colorScheme.primary,
            onTap: (index) => vm.setTab(index),
            tabs: const [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
              Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Bookings'),
              Tab(icon: Icon(Icons.work_history_outlined), text: 'Work'),
              Tab(
                icon: Icon(Icons.account_balance_wallet_outlined),
                text: 'Wallet',
              ),
              Tab(icon: Icon(Icons.inbox_outlined), text: 'Inbox'),
            ],
          ),
        ),
      ),
      body: Padding(
        // Add padding to avoid overlap with Main Bottom Nav Bar
        padding: const EdgeInsets.only(bottom: 80),
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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        key: buttonKey,
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppTypography.captionBold.copyWith(
            color: isActive ? AppColors.white : colorScheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
