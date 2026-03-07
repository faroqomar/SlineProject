/// Test fixtures barrel file
///
/// Export all test fixtures from this library for convenient importing.
///
/// Usage:
/// ```dart
/// import 'package:sline_app/test/fixtures/fixtures.dart';
///
/// // Or more specifically:
/// import '../fixtures/fixtures.dart';
/// ```
library;

// Profile fixtures for role switching and user data
export 'profiles.dart';

// Booking and fee locking fixtures
export 'booking_fixtures.dart';

// Tender task lifecycle fixtures
export 'tender_tasks.dart';

// Chat Creation Matrix fixtures (hide testClientId to avoid clash with profiles.dart)
export 'chat_fixtures.dart' hide testClientId;

// TaskRequest factory for bid/offer testing
export 'task_request_factory.dart';
