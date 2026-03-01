# Auth Feature Reference

## 1. Human Explanation

The auth feature is the gatekeeper for the app. It handles:
- email/password sign up
- email/password sign in
- password reset initiation
- session-aware logout
- loading the signed-in user's profile row after authentication

The current architecture is MVVM with repository-backed data access:
- views render forms and navigation
- `AuthViewModel` owns loading/error state and session listeners
- `AuthRepository` owns Supabase Auth and `profiles` reads/writes

`AuthViewModel` does not hold a `BuildContext`. It returns success/failure to the UI and exposes an `onSessionExpired` callback that is wired by `main.dart`.

## 2. Database and Supabase Mapping

| Resource | Purpose | Notes |
| --- | --- | --- |
| `auth.users` | primary Supabase identity | created by `supabase.auth.signUp()` |
| `public.profiles` | app-level user profile row | inserted after successful signup/session establishment |
| `auth.sessions` | active authenticated session | required for any RLS-protected follow-up query |

### `public.profiles` fields used by auth flows

| Column | Type | Purpose |
| --- | --- | --- |
| `id` | `uuid` | matches `auth.users.id` |
| `full_name` | `text` | captured at signup |
| `email` | `text` | cached for app reads |
| `avatar_url` | `text` | optional storage path, used elsewhere |
| `role` | `text` | current persona used by the UI |
| `created_at` | `timestamptz` | audit timestamp |

### RLS Summary

- `profiles` insert/update/select works only when `auth.uid() = id`.
- Auth APIs themselves are handled by Supabase Auth, but profile bootstrapping still depends on a live session.
- The repository therefore ensures a session exists before inserting the `profiles` row on signup.

## 3. File Inventory

| File | Layer | Description |
| --- | --- | --- |
| `lib/features/auth/data/auth_repository.dart` | repository | Owns signup, signin, signout, password reset, and current profile fetch. |
| `lib/features/auth/viewmodels/auth_view_model.dart` | viewmodel | Tracks loading/error state, maps auth errors, listens for auth-state changes, exposes `onSessionExpired`. |
| `lib/features/auth/view/login_screen.dart` | view | Login form and success/failure UI. |
| `lib/features/auth/view/signup_screen.dart` | view | Registration form and profile bootstrap entrypoint. |
| `lib/features/auth/view/forgot_password_screen.dart` | view | Password reset request UI. |

There is no live `lib/features/auth/services/auth_service.dart` file anymore. `AuthRepository` is the current single source of truth for auth data access.

## 4. Current Flow

### 4.1 Sign up

1. `SignupScreen` calls `AuthViewModel.register(...)`.
2. `AuthViewModel` delegates to `AuthRepository.signUp(...)`.
3. `AuthRepository` calls `supabase.auth.signUp(...)`.
4. If Supabase does not return a session immediately, the repository signs in with the same credentials.
5. Once `currentUser` exists, the repository inserts the matching `public.profiles` row.

### 4.2 Sign in

1. `LoginScreen` calls `AuthViewModel.login(...)`.
2. `AuthRepository.signIn(...)` performs `signInWithPassword(...)`.
3. On success, `AuthViewModel` loads the current profile and returns `true`.

### 4.3 Password reset

`AuthRepository.sendPasswordResetEmail(...)` calls Supabase with the current mobile redirect:
- `io.supabase.sline://login-callback`

### 4.4 Session expiry handling

- `AuthViewModel` subscribes to `Supabase.instance.client.auth.onAuthStateChange`.
- `main.dart` sets `authVm.onSessionExpired = _handleSessionExpired`.
- The app shell then clears the navigation stack back to `/login` when necessary.

## 5. Example Snippets

### Signup and profile bootstrap

```dart
await _client.auth.signUp(email: email, password: password);

if (_client.auth.currentUser == null) {
  await _client.auth.signInWithPassword(email: email, password: password);
}

await _client.from('profiles').insert({
  'id': _client.auth.currentUser!.id,
  'full_name': fullName,
  'email': email,
});
```

### ViewModel usage from UI

```dart
final success = await context.read<AuthViewModel>().login(
  email: email,
  password: password,
);

if (!mounted) return;
if (success) {
  Navigator.pushReplacementNamed(context, '/main');
}
```

## 6. Error Handling

`AuthViewModel` maps common raw auth failures to user-facing messages.

Examples:
- invalid credentials -> `Invalid email or password. Please try again.`
- unconfirmed email -> `Please verify your email before logging in.`
- duplicate account -> `An account with this email already exists.`
- network failure -> `Network error. Please check your connection.`

Repository logging masks email addresses before logging.

## 7. Testing Checklist

- Sign up a new user and confirm the `profiles` row is created.
- Sign in with a valid account and confirm `AuthViewModel.login()` returns `true`.
- Enter invalid credentials and confirm the mapped error is shown without clearing fields.
- Trigger password reset and verify the reset request succeeds.
- Sign out and confirm the app returns to `/login`.
- Simulate a session-expiry or sign-out event and verify `onSessionExpired` returns the app to the login route.
