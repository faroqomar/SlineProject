# Auth Test Infrastructure (Phase 0)

## Selector Map (Keys)

To ensure stable tests, the following `Key` values MUST be used across all Auth screens:

| Screen    | Widget               | Key                                    |
| --------- | -------------------- | -------------------------------------- |
| Login     | Email Field          | `Key('login_email_field')`             |
| Login     | Password Field       | `Key('login_password_field')`          |
| Login     | Submit Button        | `Key('login_submit_button')`           |
| Login     | Forgot Password Link | `Key('login_forgot_password_link')`    |
| Login     | Sign Up Link         | `Key('login_sign_up_link')`            |
| SignUp    | Full Name Field      | `Key('signup_name_field')`             |
| SignUp    | Email Field          | `Key('signup_email_field')`            |
| SignUp    | Password Field       | `Key('signup_password_field')`         |
| SignUp    | Submit Button        | `Key('signup_submit_button')`          |
| ForgotPwd | Email Field          | `Key('forgot_password_email_field')`   |
| ForgotPwd | Submit Button        | `Key('forgot_password_submit_button')` |
| ResetPwd  | New Password Field   | `Key('reset_password_field')`          |
| ResetPwd  | Submit Button        | `Key('reset_password_submit_button')`  |

## Fixture Manifest & Env Contract

**Environment:**

- Unit/Widget tests use Mockito/Mocktail injected via standard constructors.
- Integration tests require a live or local Supabase instance specified in `supabase_config.dart` or via a `.env` override.

**Fixtures Required for Integration Tests:**

1. `test_user_valid@example.com` - Exists in `auth.users` AND `public.profiles`.
2. `test_user_missing_profile@example.com` - Exists in `auth.users` ONLY (to test self-heal/compatibility window).
3. `test_user_new@example.com` - Used for sign-up flow (should be deleted pre-flight or use dynamic suffix).

## Rerun Policy & Timeout Budgets

- **Unit/Widget tests:** Timeout 2 seconds per test. No retries.
- **Integration tests:** Timeout 30 seconds per test. 1 retry allowed on network/binding flakes.
- **Failure Artifacts:** Integration test failures should capture screenshot/logs via regular flutter driver logs.
