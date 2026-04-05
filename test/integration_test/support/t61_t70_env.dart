
/// Integration environment contract for T61-T70 staging-backed tests.
///
/// These values are intentionally read from `--dart-define` so the tests fail
/// fast (via `skip`) when staging credentials/seed IDs are not provided.
class T61T70Env {
  static const bool stagingConfirmed = bool.fromEnvironment(
    'IT_STAGING_CONFIRMED',
    defaultValue: false,
  );

  static const String androidDeviceId = String.fromEnvironment(
    'IT_ANDROID_DEVICE_ID',
    defaultValue: '',
  );
  static const bool useQiCardPayment = bool.fromEnvironment(
    'USE_QICARD_PAYMENT',
    defaultValue: true,
  );

  static const String loginEmail = String.fromEnvironment(
    'IT_LOGIN_EMAIL',
    defaultValue: '',
  );
  static const String loginPassword = String.fromEnvironment(
    'IT_LOGIN_PASSWORD',
    defaultValue: '',
  );

  static const String t66Surface1 = String.fromEnvironment(
    'IT_T66_SURFACE1',
    defaultValue: '',
  );
  static const String t66Surface2 = String.fromEnvironment(
    'IT_T66_SURFACE2',
    defaultValue: '',
  );

  static const String t67ConversationId = String.fromEnvironment(
    'IT_T67_CONVERSATION_ID',
    defaultValue: '',
  );
  static const String t67ConversationCue = String.fromEnvironment(
    'IT_T67_CONVERSATION_CUE',
    defaultValue: '',
  );

  static const String t68ProviderId = String.fromEnvironment(
    'IT_T68_PROVIDER_ID',
    defaultValue: '',
  );
  static const String t68TaskId = String.fromEnvironment(
    'IT_T68_TASK_ID',
    defaultValue: '',
  );
  static const String t68SlotId = String.fromEnvironment(
    'IT_T68_SLOT_ID',
    defaultValue: '',
  );
  static const String t68ExpectedStatus = String.fromEnvironment(
    'IT_T68_EXPECTED_STATUS',
    defaultValue: '',
  );

  static const String t69EntityType = String.fromEnvironment(
    'IT_T69_ENTITY_TYPE',
    defaultValue: '',
  );
  static const String t69NotificationId = String.fromEnvironment(
    'IT_T69_NOTIFICATION_ID',
    defaultValue: '',
  );
  static const String t69TargetEntityId = String.fromEnvironment(
    'IT_T69_TARGET_ENTITY_ID',
    defaultValue: '',
  );

  static const String t70RoleCueFreelancer = String.fromEnvironment(
    'IT_T70_ROLE_CUE_FREELANCER',
    defaultValue: '',
  );
  static const String t70RoleCueClient = String.fromEnvironment(
    'IT_T70_ROLE_CUE_CLIENT',
    defaultValue: '',
  );
}
