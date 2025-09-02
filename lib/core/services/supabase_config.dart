/// What: Encapsulates Supabase client bootstrapping and configuration values.
/// Why: Initializes the SDK once at app start so repositories/services can use it.
library;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://isddrknbjsgaantjojhm.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzZGRya25ianNnYWFudGpvamhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2NzEzNTAsImV4cCI6MjA2ODI0NzM1MH0.nszrlk0ZUmn94ur0mUQPr_ObIRy-wGe8Z-uOCyZuftc';

  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}
