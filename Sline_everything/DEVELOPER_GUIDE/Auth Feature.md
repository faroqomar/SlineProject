# Auth Feature Reference

## 1. Human Explanation
The authentication module gates the entire SLine marketplace. It lets prospective clients or freelancers sign up, seeds their `profiles` row, signs them into Supabase Auth, and exposes the active session to downstream features like tasks, chat, bookings, and profile management. Unauthenticated users are redirected to `LoginScreen`/`SignupScreen`; once `AuthViewModel` confirms credentials, navigation jumps to `MainNavigationScreen` and the rest of the app becomes accessible under RLS.

## 2. Database & Supabase Mapping
| Column | Type | Purpose / Usage | Notes |
| --- | --- | --- | --- |
| `auth.users.id` | `uuid` | Primary Supabase identity | Immutable; referenced by every feature table |
| `auth.users.email` | `text` | Login credential | Unique; Supabase handles verification/reset |
| `auth.users.created_at` | `timestamptz` | Account creation timestamp | Stored in UTC |
| `profiles.id` | `uuid` | FK → `auth.users.id`; local profile key | Inserted during signup to unlock features |
| `profiles.full_name` | `text` | Display name across UI | Captured at signup; editable later |
| `profiles.email` | `text` | Cached email for quick reads | Should mirror `auth.users.email` |
| `profiles.avatar_url` | `text` | Storage path for avatar | Signed URLs generated via `AvatarService` |
| `profiles.role` | `text` | Current persona (client/freelancer) | Can be changed in profile settings |
| `profiles.created_at` | `timestamptz` | Profile row creation | Default `now()` in UTC |
| `auth.sessions` | Built-in | Active session in SDK | Required for any RLS-protected query |

**RLS summary**
- `profiles` **SELECT/UPDATE/DELETE**: allowed only when `auth.uid() = id`.
- `profiles` **INSERT**: new row must satisfy `id = auth.uid()`.
- Supabase Auth APIs bypass RLS but depend on configured email templates, reset links, and security policies.

## 3. File Inventory
| File | Layer | Description |
| --- | --- | --- |
| `lib/features/auth/view/login_screen.dart` | View | Material 3 login form with validation, `ChangeNotifierProvider`, and call to `AuthViewModel.login()`.
| `lib/features/auth/view/signup_screen.dart` | View | Signup experience with password confirmation and call to `AuthViewModel.register()`.
| `lib/features/auth/viewmodels/auth_view_model.dart` | ViewModel | `ChangeNotifier` that toggles `isLoading`, invokes `AuthService`, emits snackbars, and routes to `MainNavigationScreen` or `/login`.
| `lib/features/auth/services/auth_service.dart` | Service | Central Supabase layer for signup/signin/signout, session verification, and `profiles` access with logging via `AppLogger`.
| `lib/features/auth/data/auth_repository.dart` | Repository | Optional abstraction mirroring service calls for future error mapping or caching; currently unused by the ViewModel.

## 4. ERD Diagram
```mermaid
erDiagram
    AUTH_USERS ||--|| PROFILES : "id = id"
    PROFILES ||--o{ USER_ROLES : "user_id"
    ROLES ||--o{ USER_ROLES : "role_id"
    PROFILES ||--o{ TASKS : "user_id"

    AUTH_USERS {
        uuid id PK
        text email
        timestamptz created_at
    }

    PROFILES {
        uuid id PK/FK
        text full_name
        text email
        text avatar_url
        text role
        timestamptz created_at
    }

    USER_ROLES {
        uuid user_id FK
        uuid role_id FK
    }

    ROLES {
        uuid id PK
        text name
    }

    TASKS {
        uuid id PK
        uuid user_id FK
        text title
        numeric budget
        text status
    }
```

```text
auth.users (id PK, email, created_at)
   │
   └── profiles (id PK/FK → auth.users.id, full_name, email, avatar_url, role, created_at)
          │
          ├──< user_roles (user_id FK → profiles.id, role_id FK → roles.id)
          │        └── roles (id PK, name)
          └──< tasks (user_id FK → profiles.id, title, budget, status, ...)
```

## 5. Supabase Snippets
```sql
-- Seed profile after a successful signup
insert into public.profiles (id, full_name, email)
values ('<auth_user_id>', '<Full Name>', '<email@example.com>');
-- RLS enforces auth.uid() = id.

-- Retrieve full profile for dashboard
select id, full_name, email, avatar_url, role
from public.profiles
where id = '<auth_user_id>';

-- Update display name
update public.profiles
set full_name = 'New Name'
where id = '<auth_user_id>';

-- Delete profile (rare client-side)
delete from public.profiles
where id = '<auth_user_id>';
```

```dart
final supabase = Supabase.instance.client;

/// Register a user and create the matching profile row.
Future<void> registerUser({
  required String email,
  required String password,
  required String fullName,
}) async {
  final response = await supabase.auth.signUp(email: email, password: password);

  // Ensure we hold a session so RLS checks pass on profile insert.
  final session = response.session ?? await supabase.auth.signInWithPassword(
    email: email,
    password: password,
  );

  if (session == null || supabase.auth.currentUser == null) {
    throw const AuthException('Sign-up succeeded but no session was created.');
  }

  await supabase.from('profiles').insert({
    'id': supabase.auth.currentUser!.id,
    'full_name': fullName,
    'email': email,
  });
}

/// Login with friendly error handling.
Future<void> loginUser(String email, String password) async {
  try {
    await supabase.auth.signInWithPassword(email: email, password: password);
  } on AuthException catch (error) {
    if (error.message.contains('Invalid login credentials')) {
      throw const FormatException('Email or password is incorrect.');
    }
    rethrow;
  }
}

/// Update profile name while respecting RLS.
Future<void> updateFullName(String fullName) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) throw const AuthException('Not signed in');

  await supabase.from('profiles').update({
    'full_name': fullName,
  }).eq('id', userId);
}

/// Sign out the current user.
Future<void> logoutUser() async {
  await supabase.auth.signOut();
}
```

## 6. Error Handling
| Origin | System Error | User-Facing Message | Mitigation |
| --- | --- | --- | --- |
| `supabase.auth.signUp` | `AuthException` (duplicate email / rate limit) | “An account with that email already exists. Try logging in.” | Prompt password reset |
| `supabase.auth.signInWithPassword` | `AuthException: Invalid login credentials` | “Email or password is incorrect.” | Keep fields intact for retry |
| `public.profiles` insert/update | `PostgrestException code=42501` (RLS) | “Session expired. Please log in again.” | Force re-authentication |
| `public.profiles` insert` | `PostgrestException code=23505` (duplicate PK)` | “Profile already initialized. Please log in.” | Skip insert, continue login |
| Network failure | `SocketException` / timeout | “Cannot reach the server. Check your connection and retry.” | Offer retry action |
| `supabase.auth.signOut` | `AuthException: Session not found` | Silent success | Navigation still returns to `/login` |

**Mapping tips**
- `23505` → Duplicate record; surface “already exists”.
- `42501` → Permission denied; prompt re-login.
- `AuthException` → Map library message to curated copy before showing to the user.

## 7. Extra Notes & Testing Checklist
- **Session-first logic**: Always verify `supabase.auth.currentUser` before inserting into `profiles`; RLS rejects anonymous inserts.
- **UTC timestamps**: Convert `auth.users.created_at` and `profiles.created_at` with `toLocal()` for presentation.
- **Logging**: `AuthService` uses `AppLogger`; avoid logging PII such as passwords or tokens.
- **Repository is optional**: `AuthRepository` mirrors `AuthService` and can be injected later for caching or analytics without refactoring UI.
- **Storage integration**: Avatar uploads are delegated to `AvatarService`; auth feature only stores the resulting path.

**Testing checklist**
- **Signup happy path**: Register user, confirm `profiles` row exists, navigate to `MainNavigationScreen`.
- **Duplicate signup**: Expect friendly duplicate email message and prompt to log in.
- **Login failure**: Buttons re-enable after error, snackbar shows mapped copy.
- **Logout flow**: Session cleared and navigation returns to `/login`.
- **Profile fetch post-login**: `AuthService.getCurrentUserProfile()` succeeds with current JWT and returns latest data.