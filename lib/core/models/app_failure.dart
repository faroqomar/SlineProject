/// Typed error hierarchy for ViewModel state management.
///
/// Replaces `String? error` fields with structured failure types
/// that views can pattern-match on to show contextual error UI.
sealed class AppFailure {
  const AppFailure(this.userMessage, {this.debugMessage});

  final String userMessage;
  final String? debugMessage;
}

/// Network timeout, no connection, or DNS failure.
class NetworkFailure extends AppFailure {
  const NetworkFailure(
    super.userMessage, {
    super.debugMessage,
    this.isTimeout = false,
  });

  final bool isTimeout;
}

/// Authentication session expired or unauthorized access.
class AuthFailure extends AppFailure {
  const AuthFailure(
    super.userMessage, {
    super.debugMessage,
    this.sessionExpired = false,
  });

  final bool sessionExpired;
}

/// Input validation errors with per-field detail.
class ValidationFailure extends AppFailure {
  const ValidationFailure(
    super.userMessage, {
    super.debugMessage,
    this.fieldErrors = const {},
  });

  final Map<String, String> fieldErrors;
}

/// Domain-specific business rule violation (e.g. BOOKING_ALREADY_EXISTS).
class BusinessFailure extends AppFailure {
  const BusinessFailure(
    super.userMessage, {
    super.debugMessage,
    required this.code,
  });

  final String code;
}
