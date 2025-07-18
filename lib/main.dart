import 'package:flutter/material.dart';
import 'package:sline_app/features/profile/ui/controller/profile_controller.dart';
import 'core/services/supabase_config.dart';
import 'features/auth/ui/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/home/ui/home_screen.dart';
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
      ],
      child: MaterialApp(
        title: 'SLine App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
        ),
        home: Supabase.instance.client.auth.currentUser != null
            ? const HomeScreen()
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