import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sline_app/features/auth/view/signup_screen.dart';
import 'package:sline_app/features/auth/viewmodels/auth_view_model.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';
import 'package:sline_app/features/home/viewmodels/home_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';
import 'features/saved/viewmodels/saved_tasks_view_model.dart';
import 'features/saved/data/saved_tasks_service.dart';
import 'features/tasks/services/task_requests_service.dart';
import 'core/services/supabase_config.dart';
import 'core/services/logger_service.dart';
import 'features/auth/view/login_screen.dart';
import 'features/home/view/home_screen.dart';
import 'features/favorites/routes/favorites_routes.dart';
import 'features/favorites/view/favorites_screen.dart';
import 'features/favorites/viewmodels/favorites_view_model.dart';
import 'features/favorites/data/favorites_service.dart';
import 'features/categories/view/categories_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'app/main_navigation_screen.dart';
import 'core/providers/navigation_provider.dart';
import 'package:provider/provider.dart';
import 'features/booking/viewmodels/booking_view_model.dart';
import 'features/booking/view/availability_screen.dart';
import 'features/orders/viewmodels/orders_view_model.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/providers/theme_mode_provider.dart';
import 'features/notifications/viewmodels/notification_view_model.dart';
import 'features/wallet/viewmodels/wallet_view_model.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/dashboard_cache_service.dart';

/// App entry point with global error handling.
///
/// Why error boundary: Catches uncaught exceptions and logs them centrally,
/// preventing silent failures and enabling future crash reporting integration.
void main() async {
  // Wrap entire app in error zone to catch async exceptions
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Global Flutter framework error handler (widget build errors, etc.)
      FlutterError.onError = (FlutterErrorDetails details) {
        AppLogger.e(
          'Flutter Error: ${details.summary}',
          tag: 'System',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      // Global platform error handler (native crashes, isolate errors)
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.e(
          'Platform Error',
          tag: 'System',
          error: error,
          stackTrace: stack,
        );
        return true; // Prevent app termination
      };

      await SupabaseConfig.init();

      // Set logger level (info = clean logs, debug = verbose logs)
      AppLogger.currentLevel = LogLevel.info;

      // Initialize SharedPreferences for caching
      final prefs = await SharedPreferences.getInstance();
      AppLogger.i('✅ Cache service ready');

      runApp(SLineApp(prefs: prefs));
    },
    (error, stack) {
      // Catches any uncaught async exceptions outside the Flutter framework
      AppLogger.e(
        'Uncaught Zone Error',
        tag: 'System',
        error: error,
        stackTrace: stack,
      );
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
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        // Profile - user profile state
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        // Navigation - bottom nav state
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        // Theme - light/dark mode toggle
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
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
        ChangeNotifierProvider(create: (_) => BookingViewModel()),
        // Orders dashboard state
        ChangeNotifierProvider(create: (_) => OrdersViewModel()),
        // Notifications state
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        // Task Requests Service (Stateless)
        Provider(create: (_) => TaskRequestsService()),
        // Favorites state
        ChangeNotifierProvider(
          create: (_) => FavoritesViewModel(service: FavoritesService()),
        ),
        // Deep Link Service (Stateless)
        Provider(create: (_) => DeepLinkService()),
        // Dashboard Cache Service (Stateless)
        Provider(create: (_) => DashboardCacheService(prefs)),
        // Wallet state
        ChangeNotifierProvider(create: (_) => WalletViewModel()),
      ],
      child: const _AppWithAuthListener(),
    );
  }
}

/// Wrapper widget that sets up auth state listening.
///
/// Why separate widget: MaterialApp needs to be inside the Provider tree
/// so we can access AuthViewModel to set up session expiry callback.
class _AppWithAuthListener extends StatefulWidget {
  const _AppWithAuthListener();

  @override
  State<_AppWithAuthListener> createState() => _AppWithAuthListenerState();
}

class _AppWithAuthListenerState extends State<_AppWithAuthListener> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Set up session expiry callback after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVm = context.read<AuthViewModel>();
      authVm.onSessionExpired = _handleSessionExpired;
    });
  }

  void _handleSessionExpired() {
    AppLogger.w('Session expired - redirecting to login', tag: 'Auth');
    // Clear navigation stack and go to login
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
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
          home: Supabase.instance.client.auth.currentUser != null
              ? const MainNavigationScreen()
              : const LoginScreen(),
          routes: {
            '/login': (_) => const LoginScreen(),
            '/main': (_) => const MainNavigationScreen(),
            '/signup': (_) => const SignupScreen(),
            '/home': (_) => const HomeScreen(),
            '/categories': (_) => const CategoriesScreen(),
            FavoritesRoutes.routeName: (_) => const FavoritesScreen(),
            '/availability': (ctx) {
              final args =
                  ModalRoute.of(ctx)!.settings.arguments
                      as Map<String, dynamic>?;
              final providerId =
                  (args?['providerId'] ?? args?['freelancerId']) as String?;
              final taskId = args?['taskId'] as String?;
              if (providerId == null || taskId == null) {
                return const Scaffold(
                  body: Center(
                    child: Text('Missing arguments for Availability'),
                  ),
                );
              }
              return AvailabilityScreen(
                providerId: providerId,
                taskId: taskId,
                packageTier: args?['packageTier'] as String?,
                packagePrice: args?['packagePrice']?.toString(),
                packageData: args?['packageData'] as Map<String, dynamic>?,
              );
            },
          },
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('SLine is loading...', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
