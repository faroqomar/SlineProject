import 'package:flutter/material.dart';
import 'package:sline_app/features/profile/controllers/profile_controller.dart';
import 'package:sline_app/features/auth/controllers/auth_controller.dart';
import 'package:sline_app/features/home/controllers/home_controller.dart';
import 'package:sline_app/features/chat/controllers/chat_controller.dart';
import 'package:sline_app/features/tasks/controllers/task_controller.dart';
import 'core/services/supabase_config.dart';
import 'features/auth/presentation/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/main_navigation_screen.dart';
import 'core/providers/navigation_provider.dart';
import 'package:provider/provider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
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
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => TaskController()),
      ],
      child: MaterialApp(
        title: 'SLine App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
        ),
        home: Supabase.instance.client.auth.currentUser != null
            ? const MainNavigationScreen()
            : const LoginScreen(),
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
        child: Text(
          'SLine is loading...',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}