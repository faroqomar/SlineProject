/// Integration environment contract for dashboard remediation tests.
///
/// Values are read from `--dart-define` so tests fail fast (skip) when
/// staging or fixture data is not provided.
class DashboardEnv {
  static const bool stagingConfirmed = bool.fromEnvironment(
    'IT_STAGING_CONFIRMED',
  );

  static const String loginEmail = String.fromEnvironment(
    'IT_LOGIN_EMAIL',
  );
  static const String loginPassword = String.fromEnvironment(
    'IT_LOGIN_PASSWORD',
  );

  /// Optional: minimum wallet balance (IQD) for payment happy-path tests.
  static const String walletMinBalance = String.fromEnvironment(
    'IT_DASHBOARD_WALLET_MIN_BALANCE',
  );

  /// Optional: task ID for award/pay or work-tab integration scenarios.
  static const String taskId = String.fromEnvironment(
    'IT_DASHBOARD_TASK_ID',
  );

  /// Optional: task_request ID for tender payment scenarios.
  static const String taskRequestId = String.fromEnvironment(
    'IT_DASHBOARD_TASK_REQUEST_ID',
  );

  /// Optional: booking ID for booking accept/decline/cancel scenarios.
  static const String bookingId = String.fromEnvironment(
    'IT_DASHBOARD_BOOKING_ID',
  );
}
