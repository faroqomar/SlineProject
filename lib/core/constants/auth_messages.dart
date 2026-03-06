/// User-facing auth and profile provisioning messages.
/// Centralized for consistency and future i18n.
class AuthMessages {
  AuthMessages._();

  static const String profileProvisioning = 'Setting up your account...';
  static const String profileRetryAttempt = 'Still working...';
  static const String profileProvisioningFailed =
      'Account creation failed. Please try again.';
  static const String accountBanned = 'Your account has been banned.';
  static const String accountSuspended =
      'Your account is temporarily suspended.';
  static const String sessionInvalid =
      'Your session is no longer valid. Please sign in again.';
}
