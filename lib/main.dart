import 'package:flutter/material.dart';
import 'package:sline_app/features/auth/view/signup_screen.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';
import 'package:sline_app/features/home/viewmodels/home_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';
import 'core/services/supabase_config.dart';
import 'core/services/logger_service.dart';
import 'features/auth/view/login_screen.dart';
import 'features/home/view/home_screen.dart';
import 'features/favorites/routes/favorites_routes.dart';
import 'features/favorites/view/favorites_screen.dart';
import 'features/categories/view/categories_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/main_navigation_screen.dart';
import 'core/providers/navigation_provider.dart';
import 'package:provider/provider.dart';
import 'features/booking/viewmodels/booking_view_model.dart';
import 'features/booking/view/availability_screen.dart';
import 'package:sline_app/core/theme/app_theme.dart'; // NEW
import 'package:sline_app/core/providers/theme_mode_provider.dart'; // NEW

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();

  // Set logger level (info = clean logs, debug = verbose logs)
  AppLogger.currentLevel = LogLevel.info;

  runApp(const SLineApp());
}

class SLineApp extends StatelessWidget {
  const SLineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()), // NEW
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => TaskFilterViewModel()),
        ChangeNotifierProvider(create: (_) => TaskViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => BookingViewModel()),
      ],
      child: Consumer<ThemeModeProvider>(
        builder: (context, themeModeProvider, child) {
          return MaterialApp(
            title: 'SLine App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(), // NEW
            darkTheme: AppTheme.dark(), // NEW
            themeMode: themeModeProvider.themeMode, // NEW
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
                final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>?;
                final providerId = (args?['providerId'] ?? args?['freelancerId']) as String?;
                final taskId = args?['taskId'] as String?;
                if (providerId == null || taskId == null) {
                  return const Scaffold(
                    body: Center(child: Text('Missing arguments for Availability')),
                  );
                }
                return AvailabilityScreen(
                  providerId: providerId,
                  taskId: taskId,
                );
              },
            },
          );
        },
      ),
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
