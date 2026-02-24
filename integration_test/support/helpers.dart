import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

import 'package:sline_app/app/main_navigation_screen.dart';
import 'package:sline_app/core/services/supabase_config.dart';
import 'package:sline_app/features/auth/view/login_screen.dart';
import 'package:sline_app/features/home/viewmodels/home_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';
import 'package:sline_app/main.dart' as app;

import 'preflight.dart';

bool _supabaseInitialized = false;

IntegrationTestWidgetsFlutterBinding ensureIntegrationBinding() {
  return IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}

Future<void> _ensureSupabaseInitialized(String tag) async {
  if (_supabaseInitialized) return;
  T61T70Preflight.log(tag, 'Initializing Supabase SDK for integration harness');
  try {
    await SupabaseConfig.init();
    _supabaseInitialized = true;
  } catch (e) {
    final msg = e.toString().toLowerCase();
    final alreadyInitialized =
        msg.contains('already') && msg.contains('initializ');
    if (!alreadyInitialized) rethrow;
    _supabaseInitialized = true;
  }
}

Future<void> resetAuthSessionForIntegration({required String tag}) async {
  await _ensureSupabaseInitialized(tag);
  try {
    await Supabase.instance.client.auth.signOut();
    T61T70Preflight.log(tag, 'Signed out existing session for clean launch');
  } catch (e) {
    T61T70Preflight.log(tag, 'Sign-out reset skipped: $e');
  }
}

Future<void> launchAppForIntegration(
  WidgetTester tester, {
  required String tag,
  bool resetAuth = false,
}) async {
  await _ensureSupabaseInitialized(tag);
  if (resetAuth) {
    await resetAuthSessionForIntegration(tag: tag);
  }

  final prefs = await SharedPreferences.getInstance();
  T61T70Preflight.log(tag, 'Pumping SLineApp test harness');
  await tester.pumpWidget(app.SLineApp(prefs: prefs));
  await tester.pump();

  await pumpUntilAnyFound(
    tester,
    [
      find.byKey(LoginScreen.emailFieldKey),
      find.byKey(MainNavigationScreen.createTaskFabKey),
    ],
    tag: tag,
    timeout: const Duration(seconds: 15),
    reason:
        'Timed out waiting for login or main navigation shell after app launch.',
  );
}

bool exists(Finder finder) => finder.evaluate().isNotEmpty;

Future<void> pumpUntil(
  WidgetTester tester, {
  required bool Function() condition,
  required String tag,
  Duration timeout = const Duration(seconds: 12),
  Duration step = const Duration(milliseconds: 200),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await tester.pump(step);
  }
  if (condition()) return;
  throw TestFailure(
    reason ??
        '[$tag] Timed out after ${timeout.inSeconds}s waiting for condition.',
  );
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  required String tag,
  Duration timeout = const Duration(seconds: 12),
  String? reason,
}) {
  return pumpUntil(
    tester,
    condition: () => exists(finder),
    tag: tag,
    timeout: timeout,
    reason: reason,
  );
}

Future<void> pumpUntilAnyFound(
  WidgetTester tester,
  List<Finder> finders, {
  required String tag,
  Duration timeout = const Duration(seconds: 12),
  String? reason,
}) {
  return pumpUntil(
    tester,
    condition: () => finders.any(exists),
    tag: tag,
    timeout: timeout,
    reason: reason,
  );
}

Future<void> pumpFor(
  WidgetTester tester, {
  Duration duration = const Duration(seconds: 1),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
  }
}

BuildContext appContext(WidgetTester tester) {
  final materialApp = find.byType(MaterialApp);
  if (!exists(materialApp)) {
    throw TestFailure('MaterialApp not found; app not launched yet.');
  }
  return tester.element(materialApp);
}

T readProvider<T>(WidgetTester tester) {
  return Provider.of<T>(appContext(tester), listen: false);
}

Future<void> loginViaUi(
  WidgetTester tester, {
  required String tag,
  required String email,
  required String password,
}) async {
  if (exists(find.byKey(MainNavigationScreen.createTaskFabKey))) {
    T61T70Preflight.log(tag, 'Already authenticated; login step skipped');
    return;
  }

  await pumpUntilFound(
    tester,
    find.byKey(LoginScreen.emailFieldKey),
    tag: tag,
    timeout: const Duration(seconds: 15),
    reason: 'Login screen did not appear before login attempt.',
  );

  await tester.enterText(find.byKey(LoginScreen.emailFieldKey), email);
  await tester.pump();
  await tester.enterText(find.byKey(LoginScreen.passwordFieldKey), password);
  await tester.pump();
  await tester.tap(find.byKey(LoginScreen.signInButtonKey));
  await tester.pump();

  await pumpUntilAnyFound(
    tester,
    [
      find.byKey(MainNavigationScreen.createTaskFabKey),
      find.textContaining('Login failed'),
      find.textContaining('invalid'),
      find.textContaining('Invalid'),
    ],
    tag: tag,
    timeout: const Duration(seconds: 25),
    reason: 'Timed out waiting for login result (success or error).',
  );

  if (exists(find.byKey(MainNavigationScreen.createTaskFabKey))) {
    return;
  }

  final errorTexts = ['Login failed', 'invalid', 'Invalid'];
  final firstVisibleError = errorTexts.firstWhere(
    (text) => exists(find.textContaining(text)),
    orElse: () => 'Unknown login error',
  );
  throw TestFailure(
    '[$tag] Login did not reach main navigation: $firstVisibleError',
  );
}

Future<void> refreshHomeFeedViaProviders(
  WidgetTester tester, {
  required String tag,
}) async {
  final homeVm = readProvider<HomeViewModel>(tester);
  final filterVm = readProvider<TaskFilterViewModel>(tester);
  T61T70Preflight.log(tag, 'Refreshing HomeViewModel/TaskFilterViewModel');
  await homeVm.refresh(filterController: filterVm);
  await tester.pump();
  await pumpFor(tester, duration: const Duration(seconds: 1));
}

Future<void> tapByKey(
  WidgetTester tester,
  Key key, {
  required String tag,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final finder = find.byKey(key);
  await pumpUntilFound(
    tester,
    finder,
    tag: tag,
    timeout: timeout,
    reason: 'Could not find widget with key $key',
  );
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await tester.pump();
}

String uniqueMarker(String tag, String prefix) {
  final ts = DateTime.now().millisecondsSinceEpoch;
  return '${prefix}_${tag.toLowerCase()}_$ts';
}
