/// Encapsulates Supabase client bootstrapping and configuration values.
///
/// Why this exists: Initializes the SDK once at app start so repositories
/// and services can access `Supabase.instance.client` throughout the app.
///
/// Security Note: The anon key is safe to be in client code because:
/// 1. It's designed to be public (like a Firebase API key)
/// 2. All data access is protected by Row Level Security (RLS) policies
/// 3. The key only allows operations that RLS permits for the authenticated user
/// 4. Service role keys (which bypass RLS) are NEVER stored here
library;

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Supabase project URL - identifies which project to connect to
  static const String supabaseUrl = 'https://isddrknbjsgaantjojhm.supabase.co';

  // Anon (public) key - safe to expose, all operations are RLS-protected
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzZGRya25ianNnYWFudGpvamhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2NzEzNTAsImV4cCI6MjA2ODI0NzM1MH0.nszrlk0ZUmn94ur0mUQPr_ObIRy-wGe8Z-uOCyZuftc';

  /// Initialize Supabase SDK - must be called before runApp()
  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}
