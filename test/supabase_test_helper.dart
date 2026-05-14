/// Helper for tests that need [Supabase.initialize] in VM (no platform plugins).
///
/// Use [ensureSupabaseTestEnvironment] before initializing Supabase, then pass
/// [supabaseTestLocalStorage] and [supabaseTestPkceStorage] to avoid
/// SharedPreferences/path_provider.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory implementation of [GotrueAsyncStorage] for VM tests.
class _InMemoryPkceStorage extends GotrueAsyncStorage {
  final Map<String, String> _map = {};

  @override
  Future<String?> getItem({required String key}) async => _map[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _map[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _map.remove(key);
  }
}

/// Call before [Supabase.initialize] in tests so that initialization does not
/// use platform channels (SharedPreferences, path_provider, app_links).
void ensureSupabaseTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.llfbandit.app_links/messages');
  const eventsChannel = MethodChannel('com.llfbandit.app_links/events');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => null);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(eventsChannel, (call) async => null);
}

/// Use as [Supabase.initialize]'s [localStorage] in VM tests (no persistence).
const LocalStorage supabaseTestLocalStorage = EmptyLocalStorage();

/// Use as [Supabase.initialize]'s [pkceAsyncStorage] in VM tests (no platform).
final GotrueAsyncStorage supabaseTestPkceStorage = _InMemoryPkceStorage();
