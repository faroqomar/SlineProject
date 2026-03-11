# 8.1 App Start / Session Restore

# 8.2 Authentication Flow

## Purpose

Handles session restoration on cold boot, logging in, signing up, password recovery, and the AppGuard which checks for suspensions or bans.

## Entry Points

- `SplashScreen` (Cold boot)
- `LoginScreen`

## Sequences

### App Start & AppGuard Sequence

```mermaid
sequenceDiagram
    participant User
    participant Splash
    participant AuthVM
    participant AppGuard
    participant MainNav
    participant Restricted

    User->>Splash: Open App
    Splash->>AuthVM: Check Session

    alt No Session
        AuthVM-->>Splash: Invalid
        Splash->>LoginScreen: Navigation.replace
    else Active Session
        AuthVM->>AppGuard: Verify Profile Status

        alt Account Banned / Suspended
            AppGuard-->>Splash: Unauthorized
            Splash->>Restricted: Navigation.replace
        else Account Active
            AppGuard-->>Splash: Authorized
            Splash->>MainNav: Navigation.replace
        end
    end
```

### Login / Sign Up Sequence

```mermaid
sequenceDiagram
    participant User
    participant LoginUI
    participant AuthVM
    participant SupabaseAuth
    participant MainNav

    User->>LoginUI: Enter Credentials + Tap Login
    LoginUI->>AuthVM: login(email, password)
    AuthVM->>LoginUI: Show Loading State

    AuthVM->>SupabaseAuth: signInWithPassword

    alt Failure
        SupabaseAuth-->>AuthVM: AuthException
        AuthVM->>LoginUI: Update Error State
        LoginUI->>User: Show Snackbar (e.g., "Invalid credentials")
    else Success
        SupabaseAuth-->>AuthVM: Session Token
        AuthVM->>MainNav: Ensure Profile exists, Navigation.replace
    end
```

## Screen Details

- **Login / Signup View**: Uses standard `AppTextField` and `AppButton`. Errors mapped via `ErrorMapper`.
- **Restricted Screen**: Shows contact support UI if `profiles.force_logout_after` triggers a ban.

## Dependency on Backend

- Supabase Auth for sessions.
- `public.profiles` for `active_role` resolution upon successful login.
