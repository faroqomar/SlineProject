# Auth State Machine (Phase 0)

## Auth Events & Routing

| Event                                          | ViewModel State                                | Navigation/Action Result                                        |
| ---------------------------------------------- | ---------------------------------------------- | --------------------------------------------------------------- |
| `AuthChangeEvent.signedOut`                    | `AuthStatus.unauthenticated`                   | Route to `LoginScreen`                                          |
| `AuthChangeEvent.passwordRecovery`             | `AuthStatus.recovery`                          | Route to `ResetPasswordScreen` (New)                            |
| `AuthChangeEvent.signedIn` (Profile = OK)      | `AuthStatus.authenticated`                     | Route to `DashboardScreen`                                      |
| `AuthChangeEvent.signedIn` (Profile = Missing) | `AuthStatus.authenticating` -> `authenticated` | Await `selfHealProfileRPC()` completion, then `DashboardScreen` |

## UI States

### Login / Signup Screens

- **Idle:** Form fields active, submit button enabled.
- **Loading:** Form fields disabled, submit button shows spinner.
- **Error:** Validation or Submission error displayed via `SnackBar` (using standard `_mapError` function), fields active.

### Reset Password Screen (Completion)

- **Idle:** New password field active.
- **Loading:** Field disabled, spinner.
- **Success:** Dialog/Snackbar + Route back to Login.
- **Error:** `SnackBar`, field active.
