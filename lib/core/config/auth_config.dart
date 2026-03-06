/// Central configuration for auth and profile provisioning behavior.
/// Used by AuthRepository retry logic; allows kill-switch without code deploy.
class AuthConfig {
  AuthConfig._();

  /// When true, profile fetch after signup/session uses retry loop.
  static const bool enableProfileFetchRetry = true;

  /// Max number of profile fetch attempts before giving up.
  static const int profileFetchMaxRetries = 3;

  /// Delay in milliseconds between retry attempts.
  static const int profileFetchRetryDelayMs = 500;

  /// Approximate total wait (retries * delay) in ms for observability.
  static const int profileFetchMaxTotalWaitMs =
      profileFetchMaxRetries * profileFetchRetryDelayMs;
}
