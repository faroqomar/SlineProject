/// Integration environment contract for T61-T70 staging-backed tests.
///
/// These values are intentionally read from `--dart-define` so the tests fail
/// fast (via `skip`) when staging credentials/seed IDs are not provided.
class T61T70Env {
  static const bool stagingConfirmed = bool.fromEnvironment(
    'IT_STAGING_CONFIRMED',
  );

  static const String androidDeviceId = String.fromEnvironment(
    'IT_ANDROID_DEVICE_ID',
  );
  static const bool useQiCardPayment = bool.fromEnvironment(
    'USE_QICARD_PAYMENT',
    defaultValue: true,
  );

  static const String loginEmail = String.fromEnvironment(
    'IT_LOGIN_EMAIL',
  );
  static const String loginPassword = String.fromEnvironment(
    'IT_LOGIN_PASSWORD',
  );

  static const String t66Surface1 = String.fromEnvironment(
    'IT_T66_SURFACE1',
  );
  static const String t66Surface2 = String.fromEnvironment(
    'IT_T66_SURFACE2',
  );

  static const String t67ConversationId = String.fromEnvironment(
    'IT_T67_CONVERSATION_ID',
  );
  static const String t67ConversationCue = String.fromEnvironment(
    'IT_T67_CONVERSATION_CUE',
  );

  static const String t68ProviderId = String.fromEnvironment(
    'IT_T68_PROVIDER_ID',
  );
  static const String t68TaskId = String.fromEnvironment(
    'IT_T68_TASK_ID',
  );
  static const String t68SlotId = String.fromEnvironment(
    'IT_T68_SLOT_ID',
  );
  static const String t68ExpectedStatus = String.fromEnvironment(
    'IT_T68_EXPECTED_STATUS',
  );

  static const String t69EntityType = String.fromEnvironment(
    'IT_T69_ENTITY_TYPE',
  );
  static const String t69NotificationId = String.fromEnvironment(
    'IT_T69_NOTIFICATION_ID',
  );
  static const String t69TargetEntityId = String.fromEnvironment(
    'IT_T69_TARGET_ENTITY_ID',
  );

  static const String t70RoleCueFreelancer = String.fromEnvironment(
    'IT_T70_ROLE_CUE_FREELANCER',
  );
  static const String t70RoleCueClient = String.fromEnvironment(
    'IT_T70_ROLE_CUE_CLIENT',
  );
}
