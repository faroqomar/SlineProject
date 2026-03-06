/// RLS (Row Level Security) Test Suite Barrel File
///
/// Export all RLS test utilities for convenient importing.
/// Test files with main() are NOT exported - run them individually.
///
/// Usage:
/// ```dart
/// import 'package:sline_app/test/rls/rls_test.dart';
///
/// // Then run individual test files:
/// // flutter test test/rls/critical_blockers_test.dart
/// ```
library;

// Test helper for RLS policy assertions
export 'rls_test_helper.dart';

// Test fixtures for RLS testing
export 'fixtures/rls_test_users.dart';

// NOTE: Test files with main() are NOT exported from this barrel.
// Run them individually:
// - critical_blockers_test.dart
// - view_security_test.dart
// - role_switch_jwt_test.dart
