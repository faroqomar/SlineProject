---
name: flutter-add-integration-test
description: Configures and extends SLine Flutter integration tests using the integration_test package. Use when adding integration coverage, exploring UI flows, converting manual/MCP UI actions into permanent tests, or stabilizing end-to-end user flows.
metadata:
  last_modified: Thu, 14 May 2026 00:00:00 GMT
---

# Implementing SLine Flutter Integration Tests

## SLine Defaults

SLine already has `integration_test` and `flutter_test` in `pubspec.yaml`. Do not add those dependencies again unless the file proves they were removed.

Default to the existing `integration_test` + `WidgetTester` style. Do not add `flutter_driver`, `enableFlutterDriverExtension()`, or `test_driver/integration_test.dart` unless the task explicitly requires legacy `flutter drive` profiling.

Use the existing harness first:

- `test/integration_test/support/helpers.dart` for `ensureIntegrationBinding`, `launchAppForIntegration`, login helpers, provider access, and polling helpers.
- `integration_test/` for root-level device/integration tests that run with `flutter test integration_test/<file>`.
- `test/integration_test/` for SLine's grouped integration-style tests and support utilities.

## Project Setup Checklist

- Confirm current dependencies with `rg -n "integration_test|flutter_test" pubspec.yaml`.
- Reuse `SLineApp(prefs: prefs)` from `lib/main.dart` when launching app UI through tests.
- Add stable `ValueKey`s to critical widgets when a flow cannot be targeted reliably.
- Keep keys on View widgets only. Do not add Supabase calls, business logic, or data fetching to views for test convenience.
- Follow SLine comments policy: new public helpers/classes need `///` comments explaining what they do and why they exist.

## Interactive Exploration

When exploring a UI before writing a permanent test:

- Launch the app or relevant test target and inspect the widget tree.
- Prefer existing keys such as `LoginScreen.emailFieldKey`, `LoginScreen.passwordFieldKey`, `LoginScreen.signInButtonKey`, and `MainNavigationScreen.createTaskFabKey` when available.
- Use taps, text entry, scrolls, and waits to validate the path before encoding it.
- If a widget is lazily mounted in a list, scroll it into view before interacting.

## Authoring Guidelines

Use `WidgetTester` APIs:

- Start tests with `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` or the shared `ensureIntegrationBinding()`.
- Prefer `launchAppForIntegration(tester, tag: '<feature>')` for full app flows.
- Use `pumpUntilFound`, `pumpUntilAnyFound`, and short custom polling instead of blind long `pumpAndSettle()` calls when async Supabase/UI state is involved.
- Assert visible state with `find.byKey`, `find.text`, or provider state read through the helper layer.
- Keep fixtures explicit. If a flow requires seeded Supabase data, document the prerequisite in the test header.
- Use local/test Supabase fixtures only; never write tests that depend on a developer's personal production data.

## Execution

Run the smallest useful target first:

```bash
flutter test integration_test/<file>_test.dart
flutter test test/integration_test/<feature>_test.dart
flutter test integration_test/
```

Before handoff on a meaningful integration-test change, also run:

```bash
flutter analyze --no-fatal-infos
```

## Feedback Loop

- Widget not found: inspect keys and mounted tree, then add or reuse a stable key.
- Timeout: replace broad `pumpAndSettle()` with a bounded helper wait and a clear failure reason.
- Auth/session flakes: call `resetAuthSessionForIntegration(tag: ...)` before launching when the flow requires a clean login state.
- Fixture failure: make the seed/cleanup path explicit and verify RLS constraints instead of bypassing app architecture.

## Minimal SLine Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/app/main_navigation_screen.dart';
import 'package:sline_app/features/auth/view/login_screen.dart';

import 'support/helpers.dart';

void main() {
  ensureIntegrationBinding();

  group('Example integration flow', () {
    testWidgets('opens login or main shell', (tester) async {
      await launchAppForIntegration(tester, tag: 'example');

      await pumpUntilAnyFound(
        tester,
        [
          find.byKey(LoginScreen.emailFieldKey),
          find.byKey(MainNavigationScreen.createTaskFabKey),
        ],
        tag: 'example',
      );
    });
  });
}
```
