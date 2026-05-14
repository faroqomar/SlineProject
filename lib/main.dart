import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sline_app/app/main_navigation_screen.dart';
import 'package:sline_app/core/config/payment_runtime_config.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';
import 'package:sline_app/core/providers/system_config_view_model.dart';
import 'package:sline_app/core/providers/theme_mode_provider.dart';
import 'package:sline_app/core/services/account_guard_service.dart';
import 'package:sline_app/core/services/crash_reporting_service.dart';
import 'package:sline_app/core/services/dashboard_cache_service.dart';
import 'package:sline_app/core/services/deep_link_registry.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import 'package:sline_app/core/services/demo_payment_service.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_pending_store.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/core/services/qicard_payment_service.dart';
import 'package:sline_app/core/services/sentry_crash_reporting_service.dart';
import 'package:sline_app/core/services/supabase_config.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/utils/flutter_error_filters.dart';
import 'package:sline_app/core/utils/transitions/custom_route_transitions.dart';
import 'package:sline_app/core/webview_platform_init_stub.dart'
    if (dart.library.html) 'package:sline_app/core/webview_platform_init_web.dart'
    as webview_platform;
import 'package:sline_app/features/auth/view/account_restricted_screen.dart';
import 'package:sline_app/features/auth/view/login_screen.dart';
import 'package:sline_app/features/auth/view/maintenance_screen.dart';
import 'package:sline_app/features/auth/view/reset_password_update_screen.dart';
import 'package:sline_app/features/auth/view/signup_screen.dart';
import 'package:sline_app/features/auth/view/update_required_screen.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/booking/data/booking_repository.dart';
import 'package:sline_app/features/booking/models/payment_return_args.dart';
import 'package:sline_app/features/booking/services/booking_deep_link_handler.dart';
import 'package:sline_app/features/booking/view/payment_return_screen.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';
import 'package:sline_app/features/categories/data/categories_repository.dart';
import 'package:sline_app/features/categories/view/categories_screen.dart';
import 'package:sline_app/features/chat/data/chat_repository.dart';
import 'package:sline_app/features/chat/services/chat_deep_link_handler.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/dashboard/view/dashboard_screen.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/direct_offers/services/direct_offer_deep_link_handler.dart';
import 'package:sline_app/features/direct_offers/services/direct_offers_service.dart';
import 'package:sline_app/features/favorites/data/favorites_service.dart';
import 'package:sline_app/features/favorites/routes/favorites_routes.dart';
import 'package:sline_app/features/favorites/view/favorites_screen.dart';
import 'package:sline_app/features/favorites/viewmodels/favorites_view_model.dart';
import 'package:sline_app/features/home/view/home_screen.dart';
import 'package:sline_app/features/home/viewmodels/home_view_model.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';
import 'package:sline_app/features/profile/data/profile_repository.dart';
import 'package:sline_app/features/profile/services/profile_deep_link_handler.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';
import 'package:sline_app/features/proposals/data/proposal_award_repository.dart';
import 'package:sline_app/features/proposals/data/proposal_repository.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';
import 'package:sline_app/features/saved/data/saved_tasks_service.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/services/viewmodels/my_services_view_model.dart';
import 'package:sline_app/features/tasks/services/task_deep_link_handler.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/viewmodels/discovery_feed_view_model_contract.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';
import 'package:sline_app/features/work/services/work_deep_link_handler.dart';
import 'package:sline_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const bool kUseQiCardPayment = bool.fromEnvironment(
  'USE_QICARD_PAYMENT',
  defaultValue: true,
);

PaymentService createPaymentService() {
  if (kUseQiCardPayment) {
    AppLogger.i('Payment provider selected: QiCard', tag: 'Payment');
    return QiCardPaymentService();
  }

  AppLogger.i('Payment provider selected: Demo', tag: 'Payment');
  return DemoPaymentService();
}

/// Sentry DSN from compile-time --dart-define. Empty = Sentry disabled.
const String _sentryDsn = String.fromEnvironment('SENTRY_DSN');

/// Sentry environment from compile-time --dart-define. Defaults to development.
const String _sentryEnv = String.fromEnvironment(
  'SENTRY_ENV',
  defaultValue: 'development',
);

/// App entry point with global error handling and Sentry crash reporting.
///
/// Error boundary chain (outermost → innermost):
///   1. SentryFlutter.init — captures unhandled exceptions to Sentry
///   2. runZonedGuarded — catches async exceptions outside Flutter framework
///   3. FlutterError.onError — catches widget build/layout errors
///   4. PlatformDispatcher.onError — catches native/isolate errors
void main() async {
  // Sentry wraps the entire app. When DSN is empty, Sentry silently disables.
  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.environment = _sentryEnv;
      options.tracesSampleRate = 0.2;
      options.sendDefaultPii = false;
    },
    appRunner: () async {
      // Wire Sentry as the crash reporting implementation
      if (_sentryDsn.isNotEmpty) {
        CrashReportingService.instance = SentryCrashReportingService();
        AppLogger.i(
          'Sentry crash reporting enabled (env: $_sentryEnv)',
          tag: 'System',
        );
      }

      // Global Flutter framework error handler (widget build errors, etc.)
      FlutterError.onError = (details) {
        if (isIgnoredFlutterWebEngineDisposeError(details.exception) ||
            isIgnoredRealtimeEncodeError(details.exception) ||
            isIgnoredRealtimePayloadError(details.exception)) {
          return;
        }
        AppLogger.e(
          'Flutter Error: ${details.summary}',
          tag: 'System',
          error: details.exception,
          stackTrace: details.stack,
        );
        unawaited(
          CrashReportingService.instance.recordError(
            details.exception,
            details.stack,
            reason: details.summary.toString(),
            fatal: true,
          ),
        );
      };

      // Global platform error handler (native crashes, isolate errors)
      PlatformDispatcher.instance.onError = (error, stack) {
        if (isIgnoredFlutterWebEngineDisposeError(error) ||
            isIgnoredRealtimeEncodeError(error) ||
            isIgnoredRealtimePayloadError(error)) {
          return true;
        }
        AppLogger.e(
          'Platform Error',
          tag: 'System',
          error: error,
          stackTrace: stack,
        );
        unawaited(
          CrashReportingService.instance.recordError(error, stack, fatal: true),
        );
        return true; // Prevent app termination
      };

      await SupabaseConfig.init();

      // Web: register WebView platform so in-app payment WebView works
      webview_platform.initWebViewPlatform();

      // Set logger level (info = clean logs, debug = verbose logs)
      AppLogger.currentLevel = LogLevel.info;

      // Initialize SharedPreferences for caching
      final prefs = await SharedPreferences.getInstance();
      AppLogger.i('✅ Cache service ready');

      // runApp in the SAME zone as the binding (Sentry's appRunner zone).
      // Previously wrapped in runZonedGuarded which created a different zone,
      // causing "Zone mismatch" warning. Sentry already provides zone-based
      // error catching, so the extra runZonedGuarded is unnecessary.
      runApp(SLineApp(prefs: prefs));
    },
  );
}

class SLineApp extends StatelessWidget {
  final SharedPreferences prefs;

  const SLineApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth - needed globally for logout from any screen
        ChangeNotifierProvider(create: (_) => AuthSessionViewModel()),
        // Profile - user profile state
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        // Navigation - bottom nav state
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        // Theme - light/dark mode toggle
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
        // Public runtime flags/config from system_config
        ChangeNotifierProvider(
          create: (_) {
            final viewModel = SystemConfigViewModel();
            unawaited(viewModel.load());
            return viewModel;
          },
        ),
        // Saved Tasks - global bookmark state
        ChangeNotifierProvider(
          create: (_) => SavedTasksViewModel(service: SavedTasksService()),
        ),
        // Home screen state
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        // Task filtering state (shared between screens)
        ChangeNotifierProvider(create: (_) => TaskFilterViewModel()),
        // Task CRUD operations
        ChangeNotifierProvider(create: (_) => TaskViewModel()),
        // Chat/messaging state
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        // Booking/scheduling state
        ChangeNotifierProvider(
          create: (_) => BookingViewModel(
            repo: BookingRepository(Supabase.instance.client),
            chatRepository: ChatRepository(Supabase.instance.client),
            paymentService: createPaymentService(),
          ),
        ),
        // Dashboard Cache (must be before DashboardViewModel so it can be injected)
        Provider(create: (_) => DashboardCacheService(prefs)),
        // Main unified dashboard state (hosted on the legacy NavView.orders slot)
        ChangeNotifierProvider(
          create: (ctx) => DashboardViewModel(
            cacheService: ctx.read<DashboardCacheService>(),
          ),
        ),
        // Notifications state
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        // Task Requests Service (Stateless)
        Provider(create: (_) => TaskRequestsService()),
        // Proposal repositories (RLS-safe list/award/payment; used by owner list and payment route)
        Provider(
          create: (ctx) => ProposalRepository(
            taskRequestsService: ctx.read<TaskRequestsService>(),
          ),
        ),
        Provider(create: (_) => ProposalAwardRepository()),
        // Task Service (for tender payment coordinator and dashboard)
        Provider(create: (_) => TaskService()),
        // Favorites state
        ChangeNotifierProvider(
          create: (_) => FavoritesViewModel(service: FavoritesService()),
        ),
        // Deep Link Registry + Service (Stateless)
        Provider(
          create: (_) {
            final registry = DeepLinkRegistry();
            registerTaskDeepLinks(registry);
            registerBookingDeepLinks(registry);
            registerChatDeepLinks(registry);
            registerDirectOfferDeepLinks(registry);
            registerWorkDeepLinks(registry);
            registerProfileDeepLinks(registry);
            return DeepLinkService(registry: registry);
          },
        ),
        Provider(create: (_) => AccountGuardService()),
        // Payment & direct offers (for details screen / QiCard direct-offer flow)
        Provider<PaymentService>(create: (_) => createPaymentService()),
        Provider<DirectOffersService>(
          create: (_) => DirectOffersService(Supabase.instance.client),
        ),
        Provider(create: (_) => PaymentPendingStore(prefs)),
        // Wallet state
        ChangeNotifierProvider(create: (_) => WalletViewModel()),
        // Safety flows (reports/disputes)
        ChangeNotifierProvider(create: (_) => SafetyViewModel()),
        // App-level data dependencies (views must not reference Supabase directly)
        Provider<SupabaseClient>(create: (_) => Supabase.instance.client),
        Provider<ProfileRepository>(
          create: (_) => ProfileRepository(Supabase.instance.client),
        ),
        Provider<CategoriesRepository>(
          create: (_) => CategoriesRepository(Supabase.instance.client),
        ),
        // My Services (profile) - no longer depends on dashboard
        ChangeNotifierProvider(create: (_) => MyServicesViewModel()),
      ],
      child: Builder(
        builder: (context) {
          return ListenableProvider<DiscoveryFeedViewModelContract>.value(
            value: context.read<HomeViewModel>(),
            child: const _AppWithAuthListener(),
          );
        },
      ),
    );
  }
}

/// Wrapper widget that sets up auth state listening.
///
/// Why separate widget: MaterialApp needs to be inside the Provider tree
/// so we can access AuthSessionViewModel to set up session expiry callback.
class _AppWithAuthListener extends StatefulWidget {
  const _AppWithAuthListener();

  @override
  State<_AppWithAuthListener> createState() => _AppWithAuthListenerState();
}

class _AppWithAuthListenerState extends State<_AppWithAuthListener>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _guardCheckRunning = false;
  bool _restrictedScreenShown = false;

  Widget _buildHome(SystemConfigViewModel configVm) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (kIsWeb) {
      final pendingPayment = context.read<PaymentPendingStore>().load();
      final paymentReturn = parsePaymentReturnArgs(Uri.base);
      final offerId = Uri.base.queryParameters['offer_id'];
      final requestId = Uri.base.queryParameters['request_id'];
      final paymentRequestId = Uri.base.queryParameters['payment_request_id'];

      // Direct offer return: payment_return=1&offer_id=... — handle in dashboard (recovery + clear URL).
      if (paymentReturn != null &&
          offerId != null &&
          offerId.isNotEmpty &&
          paymentRequestId != null &&
          paymentRequestId.isNotEmpty) {
        AppLogger.i(
          'Detected web direct-offer payment return; will recover from dashboard',
          tag: 'Payment',
          json: <String, dynamic>{
            'uri': Uri.base.toString(),
            'offer_id': offerId,
          },
        );
        return const MainNavigationScreen();
      }
      // Tender return: payment_return=1&request_id=...&payment_request_id=... — handle in dashboard.
      if (paymentReturn != null &&
          requestId != null &&
          requestId.isNotEmpty &&
          paymentRequestId != null &&
          paymentRequestId.isNotEmpty) {
        AppLogger.i(
          'Detected web tender payment return; will recover from dashboard',
          tag: 'Payment',
          json: <String, dynamic>{
            'uri': Uri.base.toString(),
            'request_id': requestId,
          },
        );
        return const MainNavigationScreen();
      }
      if (paymentReturn != null) {
        AppLogger.i(
          'Detected explicit web payment callback at app start',
          tag: 'Payment',
          json: <String, dynamic>{
            'uri': Uri.base.toString(),
            'booking_id': paymentReturn.bookingId,
            'correlation_id': paymentReturn.correlationId,
            'status': paymentReturn.normalizedStatus,
          },
        );
        return PaymentReturnScreen(initialArgs: paymentReturn);
      }

      if (currentUser != null &&
          pendingPayment != null &&
          shouldResumePendingWebPayment(
            currentUri: Uri.base,
            startedAt: pendingPayment.startedAt,
            callbackHosts: pendingPayment.callbackHosts,
            expectedReturnUrl: pendingPayment.returnUrl,
          )) {
        AppLogger.i(
          'Resuming pending web payment without explicit callback params',
          tag: 'Payment',
          json: <String, dynamic>{
            'uri': Uri.base.toString(),
            'booking_id': pendingPayment.bookingId,
            'correlation_id': pendingPayment.correlationId,
            'return_url': pendingPayment.returnUrl,
          },
        );
        return PaymentReturnScreen(
          initialArgs: PaymentReturnArgs(
            status: 'UNKNOWN',
            bookingId: pendingPayment.bookingId,
            correlationId: pendingPayment.correlationId,
            rawUri: Uri.base,
          ),
        );
      }
    }

    if (configVm.config.maintenanceEnabled) {
      return MaintenanceScreen(message: configVm.config.maintenanceMessage);
    }

    if (configVm.isUpdateRequired()) {
      final minVersion = defaultTargetPlatform == TargetPlatform.iOS
          ? configVm.config.minVersionIos
          : configVm.config.minVersionAndroid;
      return UpdateRequiredScreen(minimumVersion: minVersion);
    }

    return currentUser != null
        ? const MainNavigationScreen()
        : const LoginScreen();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set up session expiry callback after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVm = context.read<AuthSessionViewModel>();
      authVm.onSessionExpired = _handleSessionExpired;
      authVm.onPasswordRecovery = _handlePasswordRecovery;
      unawaited(context.read<SystemConfigViewModel>().load());
      unawaited(_runAccountGuards());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<SystemConfigViewModel>().load());
      unawaited(_runAccountGuards());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleSessionExpired() {
    AppLogger.w('Session expired - redirecting to login', tag: 'Auth');
    // Clear navigation stack and go to login
    unawaited(
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      ),
    );
  }

  void _handlePasswordRecovery() {
    AppLogger.i('Handling password recovery callback', tag: 'Auth');
    unawaited(_navigatorKey.currentState?.pushNamed('/reset-password'));
  }

  Future<void> _runAccountGuards() async {
    if (_guardCheckRunning || !mounted) return;
    if (Supabase.instance.client.auth.currentUser == null) return;

    _guardCheckRunning = true;
    try {
      final guard = await context
          .read<AccountGuardService>()
          .evaluateCurrentUser();
      if (!mounted) return;

      if (guard.isRevoked) {
        AppLogger.w(
          'Session revoked by force_logout_after. Signing out.',
          tag: 'Auth',
          json: <String, dynamic>{
            'force_logout_after': guard.forceLogoutAfterUtc?.toIso8601String(),
            'session_iat': guard.sessionIssuedAtUtc?.toIso8601String(),
          },
        );
        await context.read<AuthSessionViewModel>().logout();
        if (!mounted) return;
        _restrictedScreenShown = false;
        unawaited(
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          ),
        );
        return;
      }

      if (guard.isRestricted) {
        if (_restrictedScreenShown) return;
        _restrictedScreenShown = true;
        unawaited(
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => AccountRestrictedScreen(
                status: guard.accountStatus,
                reason: guard.moderationReason,
              ),
            ),
            (route) => false,
          ),
        );
        return;
      }

      _restrictedScreenShown = false;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Account guard evaluation failed',
        tag: 'Auth',
        error: e,
        stackTrace: st,
      );
    } finally {
      _guardCheckRunning = false;
    }
  }

  Route<dynamic>? _resolveRoute(RouteSettings settings) {
    AppLogger.d('Resolving route: ${settings.name}', tag: 'Navigation');

    final routes = <String, Widget>{
      '/login': const LoginScreen(),
      '/main': const MainNavigationScreen(),
      '/signup': const SignupScreen(),
      '/reset-password': const ResetPasswordUpdateScreen(),
      '/home': const HomeScreen(),
      '/dashboard': const DashboardScreen(),
      '/categories': const CategoriesScreen(),
      FavoritesRoutes.routeName: const FavoritesScreen(),
    };

    final screen = routes[settings.name];
    if (screen != null) {
      return SlinePageRoute.forwardPush(child: screen, settings: settings);
    }

    AppLogger.w('Unknown route: ${settings.name}', tag: 'Navigation');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModeProvider>(
      builder: (context, themeModeProvider, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'SLine App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeModeProvider.themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: _buildHome(context.watch<SystemConfigViewModel>()),
          onGenerateRoute: _resolveRoute,
        );
      },
    );
  }
}
