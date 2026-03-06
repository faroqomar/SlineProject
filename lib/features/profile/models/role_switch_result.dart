/// Result of a role switch operation.
///
/// This model represents the JSON response from the `switch_active_role` RPC.
/// It includes success status, new role, and error information if applicable.
class RoleSwitchResult {
  final bool success;
  final String? newRole;
  final String? errorCode;
  final String? message;

  const RoleSwitchResult({
    required this.success,
    this.newRole,
    this.errorCode,
    this.message,
  });

  /// Create from JSON (RPC response)
  factory RoleSwitchResult.fromJson(Map<String, dynamic> json) {
    return RoleSwitchResult(
      success: json['success'] as bool? ?? false,
      newRole: json['new_role'] as String?,
      errorCode: json['error'] as String?,
      message: json['message'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'new_role': newRole,
      'error': errorCode,
      'message': message,
    };
  }

  /// True if role switch succeeded
  bool get isSuccess => success;

  /// True if there was an error
  bool get hasError => !success;

  /// Human-readable error message (fallback if server didn't provide one)
  String get displayError {
    if (message != null && message!.isNotEmpty) {
      return message!;
    }
    switch (errorCode) {
      case 'stale_state':
        return 'Role was already changed elsewhere. Please refresh.';
      case 'invalid_role':
        return 'Invalid role selected.';
      case 'db_error':
        return 'Database error. Please try again.';
      case 'session_error':
        return 'Session expired. Please log in again.';
      case 'rate_limit':
        return 'Too many role switches. Please wait a minute.';
      default:
        return 'Failed to switch role. Please try again.';
    }
  }

  @override
  String toString() {
    return 'RoleSwitchResult(success: $success, newRole: $newRole, errorCode: $errorCode)';
  }
}

/// Error codes returned by the role switch RPC.
class RoleSwitchError {
  static const String staleState = 'stale_state';
  static const String invalidRole = 'invalid_role';
  static const String dbError = 'db_error';
  static const String sessionError = 'session_error';
  static const String rateLimit = 'rate_limit';
  static const String teardownError = 'teardown_error';
}
