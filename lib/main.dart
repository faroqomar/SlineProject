import 'package:flutter/material.dart';
import 'package:sline_app/features/auth/ui/signup_screen.dart';
import 'package:sline_app/features/chat/controllers/chat_controller.dart';
import 'package:sline_app/features/profile/controllers/profile_controller.dart';
import 'package:sline_app/features/auth/controllers/auth_controller.dart';
import 'package:sline_app/features/home/controllers/home_controller.dart';
import 'package:sline_app/features/tasks/controllers/task_controller.dart';
import 'package:sline_app/features/tasks/controllers/task_filter_controller.dart';
import 'core/services/supabase_config.dart';
import 'core/services/logger_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart'; // add at the top with other imports
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/main_navigation_screen.dart';
import 'core/providers/navigation_provider.dart';
import 'package:provider/provider.dart';
import 'features/booking/controllers/booking_controller.dart';
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
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => TaskFilterController()),
        ChangeNotifierProvider(create: (_) => TaskController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => BookingController()),
      ],
      child: MaterialApp(
        title: 'SLine App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
        home: Supabase.instance.client.auth.currentUser != null
            ? const MainNavigationScreen()
            : const LoginScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/main': (_) => const MainNavigationScreen(),
          '/signup': (_) => const SignupScreen(),
          '/home': (_) => const HomeScreen(), // added route
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
