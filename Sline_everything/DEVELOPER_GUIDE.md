# 🗺️ SLine Developer Guide (Complete Reference)

**Version**: 2.20.2 (replace_task_request update-in-place; get_public_system_config; ledger/app fixes)
**Last Updated**: 2026-03-22

This comprehensive guide consolidates all feature-specific documentation into a single reference. It includes the system map, architecture overview, and deep-dives for every feature module.

---

## 📑 Table of Contents

- [Profile Feature Reference](#profile-feature-reference)
  - [Role Switching (v2.18)](#8-role-switching-v218)
- [Portfolio Feature Reference](#portfolio-feature-reference)
- [Favorites Feature Reference](#favorites-feature-reference)
- [Saved Feature Reference](#saved-feature-reference)
- [Categories Feature Reference](#categories-feature-reference)
- [Home Feature Reference](#home-feature-reference)
- [Core Module Reference](#core-module-reference)
- [Auth Feature Reference](#auth-feature-reference)
- [Legacy Orders Dashboard (Decommissioned)](#legacy-orders-dashboard-decommissioned)
- [Chat Feature Reference](#chat-feature-reference)
- [Direct Chat Offers (Direct Offers Feature)](DEVELOPER_GUIDE/Direct_Offers_Feature.md)
- [Booking Feature Reference](#booking-feature-reference)
- [Order Management Feature Reference](DEVELOPER_GUIDE/Order_Management_Feature.md)
- [Proposals Feature Reference](DEVELOPER_GUIDE/Proposals_Feature.md)
- [Wallet Feature Reference](DEVELOPER_GUIDE/Wallet_Feature.md)
- [Work Management (Unified Flow)](#work-management-unified-flow)
- [Hardened Payment Gateway (v2.20)](#hardened-payment-gateway-v220)
- [Finance & Payment Ledger Reference](#finance--payment-ledger-reference)
- [Tender Task Lifecycle](#tender-task-lifecycle)
- [Task Request (Bid) Flow](#task-request-bid-flow)

---

---

# PART I: SYSTEM OVERVIEW

# 🗺️ SLine System Map (Executive Summary)

This section gives any new contributor a complete map of the SLine app: how it’s built, how data flows through Supabase, and how to safely extend it. Use this as your birds‑eye guide; each feature also has its own deep‑dive document under `Sline_everything/DEVELOPER_GUIDE/`.

## 1. Project Overview

- **Framework**: Flutter (Material 3)
- **Backend**: Supabase (Auth, Postgres, Storage, Realtime, RPC)
- **State Mgmt**: Provider + ChangeNotifier (MVVM per feature)
- **Structure**: `lib/features/<feature>/{view,viewmodels,services,models,data}`
- **Security**: Row Level Security (RLS) on all app tables; UI interacts through repositories/services only.

## 2. Runbook (Local Dev)

- **Prereqs**: Flutter SDK, Dart, Supabase project (URL + anon key)
- **Bootstrap Supabase**: ensure DDL/policies in `Sline_everything/SUPABASE_SETUP.md` are applied
- **Configure client**: initialize Supabase once (see `lib/core/services/supabase_config.dart`)
- **Run**: `flutter run -d <device>`

## 3. Architecture (MVVM, per feature)

- **View (`view/`)**: Widgets/screens, local state only (forms), Material 3. **No direct backend calls** — views must not reference `Supabase.instance` or call `.from()`/`.rpc()`; obtain data via ViewModels and inject repositories/clients via `context.read<>()` (e.g. `SupabaseClient`, `ProfileRepository`, `CategoriesRepository` provided in `main.dart`).
- **ViewModel (`viewmodels/`)**: ChangeNotifier with business logic and UI state. Calls repository/service.
- **Repository/Service (`data/`, `services/`)**: Encapsulate Supabase queries, error mapping, and Storage ops.
- **Models (`models/`)**: Immutable data models mirroring DB rows (UTC timestamps).
- **Notifications**: All notification rows are created server-side (triggers, RPCs). The client only reads and updates (e.g. mark as read) via `NotificationService`; no client inserts into `public.notifications`. On connect, the ViewModel fetches unread first (foreground sync) then streams the latest 50. Push: device tokens are stored in `user_devices` via `PushDeviceService` (register on login/resume/token refresh when FCM is available); push delivery is server-only (trigger or cron → Edge Function → FCM). Plan: `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`.

**App-level providers** (in `lib/main.dart`): `Provider<SupabaseClient>`, `Provider<ProfileRepository>`, `Provider<CategoriesRepository>` so that views that need to construct ViewModels with a client or repository get them via `context.read<>()` instead of referencing Supabase directly.

Conventions

- **English code/comments** only. **Mounted** checks after async in widgets.
- Store **Storage paths** in DB, not signed URLs; generate signed URLs at render time (if bucket private).
- Use **time-based cursors** for paging (ISO timestamps); convert UTC → local for display.

## 4. Data Model (Key Tables)

| Area       | Tables (FKs)                                                                             | Notes                                                                                                                |
| ---------- | ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Identity   | `auth.users` → `public.profiles(id)`                                                     | App identity row per user; RLS owner-only update.                                                                    |
| Tasks      | `tasks(owner_id, user_id, client_id → profiles.id)`                                      | `owner_id` is the generated canonical owner key; app code keeps compatibility reads on legacy `user_id`/`client_id`. |
| Requests   | `task_requests(task_id, bidder_id → profiles.id)`                                        | Tender only; unique pending per (task,bidder); guarded triggers.                                                     |
| Booking    | `availability_slots(provider_id)` → `bookings(task_id, provider_id, client_id, slot_id)` | RLS enforces roles; status guard trigger.                                                                            |
| Categories | `categories` → `tasks(category_id)`                                                      | DB‑first with unique lower(name).                                                                                    |
| Chat       | `conversations(user1_id,user2_id,task_id,initiated_by)` → `messages(conversation_id)`    | RLS: participants only; DM requires favorite.                                                                        |
| Favorites  | `favorites(client_id, freelancer_id)`                                                    | Unique per pair; used to allow DM creation.                                                                          |
| Portfolio  | `portfolio_items(owner_id)`                                                              | Public bucket by default; can switch to private + signed URLs.                                                       |

### Mini ERD

```mermaid
erDiagram
  AUTH_USERS ||--|| PROFILES : "id=id"
  PROFILES ||--o{ TASKS : "user_id"
  CATEGORIES ||--o{ TASKS : "category_id"
  TASKS ||--o{ TASK_REQUESTS : "task_id"
  PROFILES ||--o{ TASK_REQUESTS : "bidder_id"
  PROFILES ||--o{ AVAILABILITY_SLOTS : "provider_id"
  AVAILABILITY_SLOTS ||--o{ BOOKINGS : "slot_id"
  PROFILES ||--o{ BOOKINGS : "provider_id/client_id"
  TASKS ||--o{ BOOKINGS : "task_id"
  PROFILES ||--o{ FAVORITES : "client_id/freelancer_id"
  PROFILES ||--o{ PORTFOLIO_ITEMS : "owner_id"
  PROFILES ||--o{ CONVERSATIONS : "user1_id/user2_id"
  TASKS ||--o{ CONVERSATIONS : "task_id (optional)"
  CONVERSATIONS ||--o{ MESSAGES : "conversation_id"
```

## 5. Feature Map (Where to look)

- **Core**: `lib/core/` – Supabase bootstrap, logging, theme, utils, shared widgets (signed avatar/image)
- **Auth**: `lib/features/auth/` – signup/login, session. Profile fetch after signup/session restore uses retry (see `AuthConfig` in `lib/core/config/auth_config.dart`). `AccountGuardService` is invoked on login and on cold start (session restore) in `main.dart` to block banned/suspended users.
- **Profile**: `lib/features/profile/` – profile edit, avatar upload, role switch, my tasks
- **Tasks**: `lib/features/tasks/` – create/list/details, images, requests (offers)
- **Proposals**: `lib/features/proposals/` – proposal models, repositories, payment route; list/submit/award/pay entry points (UI re-exports from tasks)
- **Booking**: `lib/features/booking/` – direct booking checkout, payment recovery, client/provider booking histories
- **Chat**: `lib/features/chat/` – conversations/messages, attachments, realtime
- **Favorites**: `lib/features/favorites/` – client’s saved freelancers, enables DMs
- **Saved**: `lib/features/saved/` – saved (bookmarked) tasks per user
- **Portfolio**: `lib/features/portfolio/` – public gallery of freelancer work
- **Categories**: `lib/features/categories/` – read‑mostly, DB‑first

Each feature has a dedicated deep‑dive under `Sline_everything/DEVELOPER_GUIDE/<Feature>.md` with DB mapping, ERD, snippets, and testing.

## 6. RLS/Policies (Golden Rules)

- Always run under a valid **session**; otherwise every RLS‑protected query fails (42501).
- Insert/update checks use `auth.uid()`: set owner fields server‑side where possible (e.g., `provider_id`, `client_id`, `user_id`).
- Follow setup SQL in `SUPABASE_SETUP.md`: DDL, indexes, policies, and triggers (offers tender‑only, booking guard, slot overlap, DM guard via favorites).

## 7. Storage (Buckets)

| Bucket             | Visibility       | Used by             | Access Pattern                                        |
| ------------------ | ---------------- | ------------------- | ----------------------------------------------------- |
| `avatars`          | Private          | Profile avatars     | Store path; create signed URL at render               |
| `task-images`      | Private          | Task images         | Store path; signed URL per image                      |
| `chat-attachments` | Private          | Message attachments | Store path; short‑lived signed URLs                   |
| `portfolio`        | Public (current) | Portfolio items     | Store public URL (or switch to private + signed URLs) |

## 8. Error Mapping (Common)

**Centralized Utility**: Use `lib/core/utils/error_mapper.dart` for consistent error handling:

```dart
import 'package:sline_app/core/utils/error_mapper.dart';

try {
  await supabaseOperation();
} on PostgrestException catch (e, st) {
  AppLogger.e('Operation failed', tag: 'Service', error: e, stackTrace: st);
  throw Exception(ErrorMapper.map(e));  // Returns user-friendly message
}
```

| Area    | Error                                      | Map to                                             |
| ------- | ------------------------------------------ | -------------------------------------------------- |
| Auth    | `AuthException(Invalid login credentials)` | "Email or password is incorrect."                  |
| RLS     | `Postgrest 42501`                          | "Session expired / Not allowed. Please sign in."   |
| Unique  | `23505` (duplicate)                        | "Already exists." (favorites, offers)              |
| FK      | `23503`                                    | "Related item does not exist."                     |
| Storage | 404                                        | "File not available."                              |
| Storage | 413                                        | "File is too large. Please choose a smaller file." |
| Network | `SocketException`                          | "Cannot reach the server. Check your connection."  |
| Chat    | Trigger payload checks                     | "Offer requires price and days."                   |

- **Generic user-facing messages**: The mapper returns user-friendly text only; technical phrases (e.g. "apply migrations") are not shown. Wrapped exceptions are handled via internal heuristics (e.g. `_looksLikeTechnicalMessage`) so technical leaks are avoided.
- **Replace offer**: `no_pending_offer_to_replace` and RPC/function ambiguity messages are mapped to user-friendly strings in `TaskRequestsService._mapReplaceOfferError` (`lib/features/tasks/services/task_requests_service.dart`).

**Reference**: See `.cursor/rules/error-handling.mdc` for complete error mapping conventions.

## 9. How to Add a New Feature (Playbook)

- **Schema**: add tables/columns in `SUPABASE_SETUP.md` (DDL, RLS, indexes, triggers). Apply to Supabase.
- **Module skeleton**: `lib/features/new_feature/{view,viewmodels,services,models,data}`.
- **Models**: mirror DB names; timestamps in UTC.
- **Service/Repo**: put all Supabase calls here; never from UI.
- **ViewModel**: ChangeNotifier with loading/error state; expose typed methods for UI.
- **UI**: Material 3, local form state, mounted checks after awaits.
- **Docs**: create `Sline_everything/DEVELOPER_GUIDE/New Feature.md` using the existing template (overview → DB mapping → inventory → ERD → snippets → errors → tests).

## 10. Testing & Quality

**Current state (Phase C, 2026-04-02):** 706 tests pass, 30 skipped, 0 failures. 14 of 26 ViewModels tested (54%). 14 model test files.

- **Unit**: services (mock Supabase), viewmodels state transitions, model DTO parsing.
- **Widget**: screen interactions (form validation, loading states, snackbars).
- **Integration**: happy‑paths against staging Supabase (auth, RLS, flows).
- **RLS**: 8 security test files validating policy enforcement.
- **Checklists**: each feature doc ends with a testing checklist; follow it before merging.

### 10.0 ViewModel Test Pattern (Constructor DI)

All ViewModels use optional constructor parameters for dependency injection:

```dart
// Production: uses defaults
WalletViewModel()

// Test: inject mocks
WalletViewModel(repo: mockRepo, accountGuardService: mockGuard)
```

Shared mock classes live in `test/helpers/mock_services.dart` (8 classes). Import via `test/helpers/helpers.dart` barrel.

**Key patterns:**
- Use `registerFallbackValue()` in `setUpAll` for types passed to `any(named:)`
- Pre-configure ALL stubs BEFORE constructing VMs that auto-load in constructor (e.g., DashboardVM)
- Add `RoleSwitchCoordinator().clearForTesting()` in `tearDown` for VMs that register with the singleton (ChatVM, DashboardVM)
- Use `thenAnswer((_) async => throw Exception(...))` for async error mocking with `Future.wait`, NOT `thenThrow()`

### 10.1 CI/CD Pipeline

GitHub Actions (`.github/workflows/ci.yml`) runs on every push/PR to `main`:

| Job | What It Does | Blocks Merge? |
|-----|-------------|---------------|
| **Lint & Analyze** | `dart format --set-exit-if-changed .` + `flutter analyze --no-fatal-infos` | Yes (warnings/errors fail) |
| **Architecture Guard** | 6 grep-based MVVM boundary checks (Supabase in views, controllers in VMs, Navigator in VMs, repo imports in views, view imports in VMs, Supabase in VMs) | Yes (hard failure since Phase B, 2026-04-01) |
| **Unit & Widget Tests** | `flutter test --coverage` with coverage % reported to PR summary | Yes |
| **Build** | APK (debug) + Web (release) compilation | Yes |

Flutter version pinned: **3.38.9** across all jobs.

### 10.2 Pre-commit Hook

`.githooks/pre-commit` runs `dart format` + `flutter analyze` locally before every commit.

**First-time setup:** `git config core.hooksPath .githooks`

### 10.3 Lint Rules

`analysis_options.yaml` enforces 34 rules in 3 categories:

- **Core (18):** type safety, const correctness, naming, async safety (`unawaited_futures`, `use_build_context_synchronously`)
- **Safety (7):** resource cleanup (`cancel_subscriptions`, `close_sinks`), dead-code prevention (`throw_in_finally`, `unnecessary_statements`)
- **Code Quality (9):** immutability (`prefer_final_locals`), null safety (`prefer_null_aware_operators`), dependency hygiene (`depend_on_referenced_packages`)

Strong mode: `implicit-casts: false`, `implicit-dynamic: false`.

### 10.4 Error vs Exception Handling (Dart-Specific)

In Dart, `Error` and `Exception` are separate hierarchies under `Object`:
- `Exception` = recoverable runtime errors (network, auth, validation, Supabase queries)
- `Error` = programming bugs or environment failures (TypeError, AssertionError, StackOverflowError)

Rules:
1. ViewModel and service catch blocks use `on Exception catch (e)` by default.
2. Code that accesses `Supabase.instance` in a "try or fallback to null" pattern MUST also catch `Error` (throws `AssertionError` when not initialized).
3. Code that accesses `context.read<T>()` outside a guaranteed Provider scope MUST catch `Error` (throws `ProviderNotFoundException`).
4. JSON parsing of external data (realtime, webhooks) should catch `FormatException` and `TypeError` explicitly.
5. Global error boundaries (`runZonedGuarded`, `FlutterError.onError`) are the only places that should catch everything.

### 10.5 ViewModel notifyListeners() Timing

- NEVER call `notifyListeners()` synchronously inside a method invoked during `build()`, `initState()`, or `didChangeDependencies()`.
- If a ViewModel method needs to set loading state at the start, either skip the initial `notifyListeners()` (view manages its own loading via `setState`) or defer via `addPostFrameCallback`.
- The `finally` block after an `await` is always safe.
- Views calling ViewModel methods during initialization should use `addPostFrameCallback`.

### 10.6 Supabase Query Builder Pattern

Supabase's Dart client uses a builder pattern where `.eq()`, `.lt()`, `.gt()`, `.order()` return a `PostgrestFilterBuilder` that implements `Future`. These are NOT fire-and-forget futures — they are builder chain methods.

- NEVER wrap query builder methods in `unawaited()`.
- Use `query = query.lt(...)` (reassignment) when conditionally applying filters.
- The `unawaited_futures` lint is a false positive for these methods.

## 11. Observability (Crash & Error Tracking)

- **Crash Reporting**: `CrashReportingService` (lib/core/services/crash_reporting_service.dart) abstracts the backend (Sentry/Firebase).
- **Zoned Errors**: `main.dart` uses `runZonedGuarded` to catch concurrent async errors.
- **Flutter Errors**: `FlutterError.onError` is hooked to report UI crashes.
- **Logging**:
  - Use `AppLogger.e(message, error, stackTrace)` for handled exceptions.
  - Use `AppLogger.i/d/w` for standard logs.
  - **Avoid `print()`**: CI/CodeGuard will flag direct print usage.

## 11. Quick Links (Deep Dives)

- Core: `DEVELOPER_GUIDE/Core Module.md`
- Auth: `DEVELOPER_GUIDE/Auth Feature.md`
- Profile: `DEVELOPER_GUIDE/Profile Feature.md`
- Tasks: `DEVELOPER_GUIDE/Task Feature.md`
- Booking: `DEVELOPER_GUIDE/Booking Feature.md`
- Chat: `DEVELOPER_GUIDE/Chat Feature.md`
- Favorites: `DEVELOPER_GUIDE/Favorites Feature.md`
- Saved: `DEVELOPER_GUIDE/Saved Feature.md`
- Portfolio: `DEVELOPER_GUIDE/Portfolio Feature.md`
- Categories: `DEVELOPER_GUIDE/Categories Feature.md`
- Inventory: `DEVELOPER_GUIDE/Inventory Feature.md` (Planned)
- Order Management: `DEVELOPER_GUIDE/Order_Management_Feature.md`
- Proposals: `DEVELOPER_GUIDE/Proposals_Feature.md`

## 12. Gotchas & Tips

- **Offer flow**: only for `task_type='tender'`; unique pending per (task,bidder).
- **DMs**: client‑only; requires freelancer in **favorites**; enforced by triggers.
- **Signed URLs**: keep TTL short; regenerate on demand; never persist signed URLs in DB.
- **Cursors**: prefer time‑based (`created_at`, `starts_at`), not offset paging.
- **Localization**: profile `language` can power a global locale provider.

With this map and the linked deep‑dives, a new engineer can navigate, extend, and debug SLine safely and productively.

---

# PART II: FEATURE DEEP-DIVES

Each section below provides complete documentation for a specific feature module, including database mapping, ERD diagrams, code snippets, error handling, and testing checklists.

---

# Profile Feature Reference

## 1. Human Explanation

The Profile feature manages a user’s app identity beyond `auth.users`. It loads and edits the current user’s `profiles` row, generates signed avatar URLs from the private `avatars` bucket, exposes a lightweight header-only load path for Home, and shows the user’s own tasks. MVVM flow:

- UI in `lib/features/profile/view/` renders the form and actions.
- `ProfileViewModel` orchestrates full profile loads for Profile screens and `loadHeaderProfile()` for Home/dashboard header usage.
- `ProfileRepository` performs self-only `profiles` reads/writes, delegates avatar upload to `AvatarService`, and delegates cross-user summary lookups to `ProfileSummaryService`.

## 2. Database & Supabase Mapping

### 2.1 `public.profiles`

| Column         | Type                              | Purpose / Usage                                    | Notes                                                  |
| -------------- | --------------------------------- | -------------------------------------------------- | ------------------------------------------------------ |
| `id`           | `uuid` (PK, FK → `auth.users.id`) | Identity link to Supabase Auth                     | Primary join key across modules                        |
| `full_name`    | `text`                            | Display name                                       | Editable in Profile screen                             |
| `email`        | `text`                            | Cached email for self-service settings             | Updated alongside Auth when changed                    |
| `bio`          | `text`                            | Short description                                  | Editable in Profile screen                             |
| `active_role`  | `text`                            | `client` or `freelancer`                           | Drives Home/Tasks UX                                   |
| `seller_level` | `seller_level_enum`               | `new_seller` / `level_1` / `level_2` / `top_rated` | Used by Home discovery filters and secure author cards |
| `avatar_url`   | `text`                            | Private storage path in `avatars` bucket           | Use signed URLs for display                            |
| `skills`       | `text[]`                          | Skill tags                                         | Included in summary RPC payload                        |
| `created_at`   | `timestamptz`                     | Creation time (UTC)                                | Default `now()`                                        |

RLS (summary): direct `public.profiles` reads are self-only (`auth.uid() = id`). Cross-user reads must use the authenticated server-side summary RPC `public.rpc_get_profile_summaries(uuid[])`.

### 2.2 Storage buckets (private)

| Bucket    | Purpose        | Used by                            | Notes                                            |
| --------- | -------------- | ---------------------------------- | ------------------------------------------------ |
| `avatars` | Profile images | `AvatarService` and `SignedAvatar` | Store path only; generate signed URL for display |

## 3. File Inventory

| File                                                           | Layer      | Description                                                                                                                                    |
| -------------------------------------------------------------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/features/profile/data/profile_repository.dart`            | Repository | Wraps self-only `profiles` reads/writes, email updates, role change, password reset, avatar upload, and my-tasks helpers.                      |
| `lib/features/profile/services/avatar_service.dart`            | Service    | Uploads avatar to `avatars` bucket and creates short-lived signed URLs. Stores only the storage path in DB.                                    |
| `lib/features/profile/services/profile_summary_service.dart`   | Service    | Calls `rpc_get_profile_summaries` and `search_profiles`; only safe summary fields are exposed cross-user.                                      |
| `lib/features/profile/view/widgets/profile_preview_modal.dart` | Widget     | Helper `showProfilePreview(context, userId)` to launch public profile in a modal sheet.                                                        |
| `lib/features/profile/viewmodels/profile_view_model.dart`      | ViewModel  | `ChangeNotifier` that binds form controllers, updates profile, uploads avatar, handles logout/role change, and exposes full/header load paths. |
| `lib/features/profile/view/profile_screen.dart`                | View       | Material 3 profile UI with form fields, avatar, role toggle, password reset, and sign out.                                                     |
| `lib/features/profile/view/widgets/profile_avatar_widget.dart` | Widget     | Renders a profile avatar via a signed URL for a private storage path.                                                                          |

## 4. ERD Diagram (Context)

```mermaid
erDiagram
  AUTH_USERS ||--|| PROFILES : "id = id"
  PROFILES ||--o{ TASKS : "user_id"
  PROFILES ||--o{ STORAGE_AVATARS : "avatar_url (path)"

  AUTH_USERS { uuid id PK, text email }
  PROFILES { uuid id PK/FK, text full_name, text email, text bio, text active_role, seller_level_enum seller_level, text avatar_url, timestamptz created_at }
  TASKS { uuid id PK, uuid user_id FK, text title }
  STORAGE_AVATARS { text path PK }
```

```text
auth.users (id, email)
   └── profiles (id=auth.users.id, full_name, email, bio, active_role, seller_level, avatar_url)
            └──(path) avatars bucket (private, signed URLs)
   └── tasks (user_id → profiles.id)
```

## 5. Supabase Snippets

### 5.1 SQL (core operations)

```sql
-- Load my profile
select id, full_name, email, bio, active_role, seller_level, avatar_url
from public.profiles
where id = auth.uid();

-- Update profile fields (RLS enforces id = auth.uid())
update public.profiles
set full_name = 'New Name', bio = 'About me', active_role = 'freelancer'
where id = auth.uid();

-- Change avatar path after upload
update public.profiles
set avatar_url = concat('avatars/', auth.uid(), '/', extract(epoch from now())::bigint, '.jpg')
where id = auth.uid();
```

### 5.2 Dart (supabase_flutter)

```dart
final supabase = Supabase.instance.client;

// Fetch full self profile (ProfileRepository.fetchProfile)
final me = supabase.auth.currentUser!.id;
final row = await supabase
  .from('profiles')
  .select('id, full_name, email, avatar_url, bio, active_role, skills, created_at, seller_level')
  .eq('id', me)
  .single();

// Update profile fields (ProfileRepository.updateProfileFields)
await supabase.from('profiles').update({
  'full_name': fullName,
  'bio': bio,
}).eq('id', me);

// Change auth email (ProfileRepository.updateUserEmail)
await supabase.auth.updateUser(UserAttributes(email: newEmail));

// Upload avatar via AvatarService and save path
final path = await AvatarService(supabase).uploadAvatar(
  userId: me,
  bytes: imageBytes,
  contentType: 'image/jpeg',
  fileExt: 'jpg',
);
await supabase.from('profiles').update({'avatar_url': path}).eq('id', me);

// Create signed URL for display
final signed = await AvatarService(supabase).createSignedUrl(path);

// Fetch safe summaries for task authors / public cards
final summaries = await supabase.rpc('rpc_get_profile_summaries', params: {
  'p_ids': [authorId, anotherAuthorId],
});
```

## 6. Error Handling

| Origin            | Error                | User-Facing Message                     | Mitigation                                         |
| ----------------- | -------------------- | --------------------------------------- | -------------------------------------------------- |
| Profiles update   | `42501` RLS denied   | "Session expired. Please log in again." | Re-authenticate and retry.                         |
| Auth email change | `AuthException`      | "Unable to change email right now."     | Prompt to retry; ensure email is valid and unique. |
| Avatar upload     | `StorageException`   | "Upload failed. Please try again."      | Validate file type/size; retry.                    |
| Signed URL        | Expired URL          | "Image link expired. Refreshing…"       | Regenerate signed URL lazily.                      |
| IDs               | `22P02` invalid UUID | "Invalid identifier."                   | Validate IDs before requests.                      |

## 7. Extra Notes & Testing Checklist

- **Store paths, not signed URLs** in `profiles.avatar_url`; generate signed URLs at render time.
- **UTC**: All timestamps are UTC; convert with `toLocal()` where needed.
- **Session required**: All RLS-protected queries require an active session.
- **Cross-user reads**: Do not query another user from base `profiles`; use `ProfileSummaryService` / `rpc_get_profile_summaries`.
- **Home/Tasks impact**: Updating `active_role` or `seller_level` affects Home/Tasks UX and discovery filters on next load.

Testing checklist:

- Load profile → fields populate in `ProfileViewModel` controllers.
- Update name/bio → persisted in `public.profiles` and reflected in UI.
- Upload avatar → path saved, signed URL generated, and image renders.
- Change email → Auth email updated; cached profile email optional sync.
- Change role → Home reflects the role after reload.
- Fetch my tasks → user's tasks load and render; delete/update works.

## 8. Role Switching (v2.18)

### 8.1 Overview

The Role Switching feature allows a single user account to toggle between **Client** and **Freelancer** personas. The v2.18 implementation provides atomic, race-condition-protected role switching with comprehensive teardown to prevent data leakage between personas.

### 8.2 Architecture

**Flow:**

1. **Rate Limit Check** — Max 3 switches per minute per user
2. **Atomic RPC** — `switch_active_role()` with `expected_old_role` guard
3. **Session Refresh** — Gets new JWT token with updated role claim
4. **JWT Verification** — Confirms token contains expected role
5. **Teardown Contract** — All ViewModels clear cached data
6. **Profile Reload** — Fetches fresh data for new role

**Key Components:**

| Component               | Purpose                                      | File                                                    |
| ----------------------- | -------------------------------------------- | ------------------------------------------------------- |
| `RoleSwitchRepository`  | RPC calls, session refresh, JWT verification | `lib/features/profile/data/role_switch_repository.dart` |
| `RoleSwitchCoordinator` | Cross-ViewModel teardown coordination        | `lib/core/services/role_switch_coordinator.dart`        |
| `RoleSwitchAware`       | Mixin interface for ViewModels               | `lib/core/mixins/role_switch_aware.dart`                |
| `RoleSwitchResult`      | Type-safe RPC response model                 | `lib/features/profile/models/role_switch_result.dart`   |

### 8.3 Database Layer

**RPC Function:**

```sql
-- Atomic role switching with race protection
switch_active_role(
  p_expected_old_role TEXT,  -- Guard: must match current DB state
  p_new_role TEXT            -- Target: 'client' or 'freelancer'
) RETURNS JSONB
```

**Trigger:**

```sql
-- Syncs profiles.active_role to auth.users.app_metadata
-- Enables JWT-based RLS (faster than table joins)
trigger trg_sync_role_to_jwt ON profiles
```

**RLS Policies (JWT-based):**

- `task_requests_insert_freelancer_jwt` — Only freelancers can submit proposals
- `availability_slots_insert/update_freelancer_jwt` — Only freelancers manage slots
- `tasks_insert_client_jwt` — Only clients create tasks

### 8.4 ViewModel Teardown Contract

All ViewModels with cached data implement `RoleSwitchAware`:

| ViewModel            | Teardown Action                                                              |
| -------------------- | ---------------------------------------------------------------------------- |
| `ChatViewModel`      | Cancel subscriptions, remove Supabase channels, clear conversations/messages |
| `DashboardViewModel` | Clear work items, bookings, inbox, counters, reset lazy-load flags           |
| `TaskViewModel`      | Clear task lists, picked images                                              |
| `HomeViewModel`      | Clear featured tasks, reset pagination cursors                               |

### 8.5 Error Handling

| Error Code      | When                           | User Message                                    |
| --------------- | ------------------------------ | ----------------------------------------------- |
| `stale_state`   | Role changed on another device | "Role was already changed. Please refresh."     |
| `rate_limit`    | >3 switches in 1 minute        | "Too many role switches. Please wait a minute." |
| `session_error` | Session refresh failed         | "Session expired. Please log in again."         |
| `db_error`      | Database error                 | "Failed to switch role. Please try again."      |

### 8.6 Usage

```dart
// In ProfileViewModel
Future<bool> changeRole(String newRole) async {
  // Full atomic flow with teardown
  final success = await changeRole(newRole);
  if (success) {
    // Navigate to Dashboard with new role data
  } else {
    // Show error from _profileError
  }
}
```

### 8.7 Testing Checklist

- Switch to Freelancer → Dashboard shows freelancer work items
- Switch back to Client → Dashboard shows client tasks
- Double-tap switch button → Second attempt blocked with stale_state
- Rate limit → 4th rapid switch shows rate_limit error
- Multi-device → Switch on device A, device B shows stale_state on next attempt
- Chat cleanup → Old conversations not visible after switch

### 8.8 References

- Plan: `.TODO/PLAN_RoleSwitchingFlow_CRITIC_2026-03-06.md`
- Migration: `supabase/migrations/20260306_role_switch_foundation.sql`
- Execution Log: `.TODO/EXECUTION_LOG_RoleSwitchingFlow_CRITIC_2026-03-06.md`

---

## 8.1 RLS Testing Guide

The `test/rls/` directory contains automated tests for Supabase RLS policies.

### Running RLS Tests

```bash
# Run all RLS tests
flutter test test/rls/

# Run specific test file
flutter test test/rls/critical_blockers_test.dart

# Run with verbose output
flutter test test/rls/ -v
```

### Test Categories

| File                          | Tests | Purpose                                                                |
| ----------------------------- | ----- | ---------------------------------------------------------------------- |
| `critical_blockers_test.dart` | 12    | 4 critical security vulnerabilities (cross-user access, log injection) |
| `view_security_test.dart`     | 7     | PII exposure prevention, `security_invoker` validation                 |
| `role_switch_jwt_test.dart`   | 7     | JWT-based role enforcement (client vs freelancer operations)           |

### Writing RLS Tests

Use `RlsTestHelper` assertion methods:

```dart
import 'rls_test_helper.dart';
import 'fixtures/rls_test_users.dart';

void main() {
  late RlsTestHelper helper;

  setUp(() {
    helper = RlsTestHelper();
  });

  test('user can read own data', () async {
    await helper.assertCanSelect(
      'messages',
      {'conversation_id': 'conv-123'},
      asUserId: TestUsers.clientUser.id,
    );
  });

  test('user cannot read others data', () async {
    await helper.assertCannotSelect(
      'messages',
      {'conversation_id': 'others-conv'},
      asUserId: TestUsers.otherClientUser.id,
    );
  });
}
```

### Available Assertions

- `assertCanSelect()` / `assertCannotSelect()`
- `assertCanInsert()` / `assertCannotInsert()`
- `assertCanUpdate()` / `assertCannotUpdate()`
- `assertCanDelete()` / `assertCannotDelete()`
- `assertViewDoesNotExist()`

### Test Users

| User              | Role       | Purpose                      |
| ----------------- | ---------- | ---------------------------- |
| `clientUser`      | client     | Primary client persona       |
| `freelancerUser`  | freelancer | Primary freelancer persona   |
| `otherClientUser` | client     | Cross-user isolation testing |
| `adminUser`       | admin      | Admin privilege testing      |
| `serviceRole`     | service    | Service role operations      |

### References

- Test README: `test/rls/README.md`
- Plan: `.TODO/PLAN_RLS_Authorization_Map_CRITIC_2026-03-06.md`
- Execution Log: `.TODO/EXECUTION_LOG_RLS_Authorization_Map_CRITIC_2026-03-06.md`

---

# Portfolio Feature Reference

## 1. Human Explanation

The Portfolio feature lets freelancers showcase their work via items containing title, description, and an image. Items are owned by the profile (`owner_id`) and images are stored under the `portfolio` bucket.

**v2.4 Update (2025-12-16)**: Portfolio management is now also integrated into the Profile module:

- **UI**: `lib/features/profile/view/manage_portfolio_screen.dart` (accessible from Settings)
- **ViewModel**: `ProfileViewModel` handles portfolio CRUD via `fetchPortfolio()`, `addPortfolioItem()`, `updatePortfolioItem()`, `deletePortfolioItem()`
- **Repository**: `ProfileRepository` includes portfolio methods + `uploadPortfolioImage()`
- **Image Picker**: Uses `FilePicker` instead of `ImagePicker` for iOS stability, with `FlutterImageCompress` for optimization
- **Dialog Workaround**: After upload, dialog shows checkmark (not image preview) to avoid iOS native crash

Legacy MVVM flow (if using standalone module):

- UI in `lib/features/portfolio/view/` (screen + sheets + widgets).
- `PortfolioViewModel` orchestrates listing, add, edit, and delete.
- `PortfolioRepository` wraps `PortfolioService` (Storage + PostgREST) and exposes a stable API.

## 2. Database & Supabase Mapping

### 2.1 `public.portfolio_items`

| Column        | Type                        | Purpose / Usage          | Notes                                                                                  |
| ------------- | --------------------------- | ------------------------ | -------------------------------------------------------------------------------------- |
| `id`          | `uuid` (PK)                 | Portfolio item id        | Default `gen_random_uuid()`                                                            |
| `owner_id`    | `uuid` (FK → `profiles.id`) | Owner profile id         | `ON DELETE CASCADE`                                                                    |
| `title`       | `text`                      | Work title               | Required                                                                               |
| `description` | `text`                      | Details                  | Optional                                                                               |
| `image_path`  | `text`                      | Storage path (canonical) | **Canonical**: Store path like `ownerId/filename.jpg`, resolve to signed URL at render |
| `image_url`   | `text`                      | Legacy public URL        | **Deprecated**: Legacy public URL (backwards compatibility only)                       |
| `created_at`  | `timestamptz`               | When created (UTC)       | Default `now()`                                                                        |

Indexes

- `idx_portfolio_owner_created (owner_id, created_at DESC)` for fast listing.

RLS Policies (Summary)

| Table             | Action | Policy                             | Rule                                  |
| ----------------- | ------ | ---------------------------------- | ------------------------------------- |
| `portfolio_items` | SELECT | `portfolio_select_owner_or_public` | `USING (true)` (public-readable)      |
| `portfolio_items` | ALL    | `portfolio_crud_owner`             | `USING/CHECK (auth.uid() = owner_id)` |

### 2.2 Storage bucket

| Bucket      | Visibility | Purpose               | Notes                                                                                               |
| ----------- | ---------- | --------------------- | --------------------------------------------------------------------------------------------------- |
| `portfolio` | Public     | Host portfolio images | Service stores a public URL via `getPublicUrl()`; if switching to private, use signed URLs instead. |

## 3. File Inventory

| File                                                              | Layer      | Description                                                                                                |
| ----------------------------------------------------------------- | ---------- | ---------------------------------------------------------------------------------------------------------- |
| `lib/features/portfolio/data/portfolio_repository.dart`           | Repository | Wraps `PortfolioService` and exposes list/add/delete/update methods; surfaces `currentUser`.               |
| `lib/features/portfolio/services/portfolio_service.dart`          | Service    | Uploads bytes to `portfolio` bucket, produces public URL, inserts/reads/deletes rows in `portfolio_items`. |
| `lib/features/portfolio/models/portfolio_item.dart`               | Model      | Immutable item with `id`, `owner_id`, `title`, `description`, `image_url`, `created_at`.                   |
| `lib/features/portfolio/viewmodels/portfolio_view_model.dart`     | ViewModel  | `ChangeNotifier` that manages paging cursor, adds/edits/deletes and updates the list.                      |
| `lib/features/portfolio/view/portfolio_screen.dart`               | View       | Grid/List of items with pull-to-refresh and load-more.                                                     |
| `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart`     | View       | Form to pick image + enter title/description; calls ViewModel add.                                         |
| `lib/features/portfolio/view/sheets/edit_portfolio_sheet.dart`    | View       | Form to edit title/description; calls ViewModel update.                                                    |
| `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart` | View       | Full-screen preview with details.                                                                          |
| `lib/features/portfolio/view/widgets/portfolio_tile.dart`         | Widget     | Card per item (image + title).                                                                             |

## 4. ERD Diagram

```mermaid
erDiagram
  PROFILES ||--o{ PORTFOLIO_ITEMS : "owner_id"

  PROFILES {
    uuid id PK
    text full_name
  }
  PORTFOLIO_ITEMS {
    uuid id PK
    uuid owner_id FK
    text title
    text description
    text image_url
    timestamptz created_at
  }
```

```text
profiles (id) ──< portfolio_items (owner_id)
```

## 5. Supabase Snippets

### 5.1 SQL

```sql
-- Insert a portfolio item (owner-only by RLS)
insert into public.portfolio_items (owner_id, title, description, image_url)
values (auth.uid(), 'Landing Page', 'A marketing website', '<public-url-or-path>')
returning *;

-- List items for a user
select id, title, description, image_url, created_at
from public.portfolio_items
where owner_id = '<profile_id>'
order by created_at desc
limit 30;

-- Update title/description (owner-only)
update public.portfolio_items
set title = 'New Title', description = null
where id = '<item_id>' and owner_id = auth.uid();

-- Delete an item (owner-only)
delete from public.portfolio_items
where id = '<item_id>' and owner_id = auth.uid();
```

### 5.2 Dart (supabase_flutter)

```dart
final supabase = Supabase.instance.client;

// Add item with uploaded image
Future<void> addPortfolioItem({
  required String title,
  String? description,
  required Uint8List imageBytes,
  required String filename,
}) async {
  final ownerId = supabase.auth.currentUser!.id;
  // Upload to Storage
  final path = '$ownerId/${DateTime.now().millisecondsSinceEpoch}_$filename';
  await supabase.storage.from('portfolio').uploadBinary(path, imageBytes,
      fileOptions: const FileOptions(upsert: false));
  final publicUrl = supabase.storage.from('portfolio').getPublicUrl(path);
  // Insert row
  await supabase.from('portfolio_items').insert({
    'owner_id': ownerId,
    'title': title,
    'description': description,
    'image_url': publicUrl,
  });
}

// List items with simple paging cursor
Future<List<Map<String, dynamic>>> listPortfolio({required String ownerId, String? cursorIso, int limit = 30}) async {
  final rows = await supabase
      .from('portfolio_items')
      .select()
      .eq('owner_id', ownerId)
      .order('created_at', ascending: false)
      .limit(limit);
  return (rows as List).cast<Map<String, dynamic>>();
}

// Delete item and optionally remove storage object
Future<void> deletePortfolioItem(String id, {String? publicUrl}) async {
  await supabase.from('portfolio_items').delete().eq('id', id);
  if (publicUrl != null) {
    final marker = '/object/public/portfolio/';
    final idx = publicUrl.indexOf(marker);
    if (idx != -1) {
      final storagePath = publicUrl.substring(idx + marker.length);
      await supabase.storage.from('portfolio').remove([storagePath]);
    }
  }
}
```

## 6. Error Handling

| Origin               | Error                | User-Facing Message                       | Mitigation                             |
| -------------------- | -------------------- | ----------------------------------------- | -------------------------------------- |
| Upload               | `StorageException`   | "Upload failed. Please try again."        | Validate file size/type; retry safely. |
| Insert/Update/Delete | `42501` RLS denied   | "You can only manage your own portfolio." | Ensure session; check ownership.       |
| Delete image         | Storage 404          | "Image already removed."                  | Ignore silently to keep UX smooth.     |
| IDs                  | `22P02` invalid UUID | "Invalid identifier."                     | Validate IDs before requests.          |

## 7. Extra Notes & Testing Checklist

- **Public vs Private**: Current implementation stores a public URL; if privacy is required, store the path and generate signed URLs instead.
- **Paging**: Consider time-based cursors (`created_at`) on the server once SDK supports it.
- **UTC**: All timestamps are UTC; convert to local for display.

Testing checklist:

- Add item (upload + insert) → appears in grid and opens in details.
- Edit title/description → changes persist and reflect in list.
- Delete item → row removed; image cleanup attempted.
- Attempt to edit/delete other user’s item → denied by RLS.

# Favorites Feature Reference

## 1. Human Explanation

The Favorites feature lets a Client bookmark a Freelancer for quick access. It streamlines repeat collaborations and enables a shortcut to start a direct chat (DM) without creating a task first. The implementation follows MVVM:

- UI in `lib/features/favorites/view/` (screen + widgets) stays declarative.
- `FavoritesViewModel` handles list state, add/remove actions, and error surface.
- `FavoritesService` executes Supabase queries under RLS.

## 2. Database & Supabase Mapping

### 2.1 `public.favorites`

| Column          | Type                        | Purpose / Usage                     | Notes                             |
| --------------- | --------------------------- | ----------------------------------- | --------------------------------- |
| `id`            | `uuid` (PK)                 | Favorite record id                  | Default `gen_random_uuid()`       |
| `client_id`     | `uuid` (FK → `profiles.id`) | Who favorites                       | Must equal `auth.uid()` under RLS |
| `freelancer_id` | `uuid` (FK → `profiles.id`) | Who is favorited                    | Used to gate DM creation          |
| `created_at`    | `timestamptz`               | When the favorite was created (UTC) | Default `now()`                   |

Indexes & Constraints

- Unique `(client_id, freelancer_id)` to prevent duplicates.
- Indexes on `client_id` and `freelancer_id` for lookups (see `SUPABASE_SETUP.md`).

RLS Policies (Summary)

| Table       | Action | Policy                 | Rule                     |
| ----------- | ------ | ---------------------- | ------------------------ |
| `favorites` | SELECT | `favorites_select_own` | `client_id = auth.uid()` |
| `favorites` | INSERT | `favorites_insert_own` | `client_id = auth.uid()` |
| `favorites` | DELETE | `favorites_delete_own` | `client_id = auth.uid()` |

Related Policies

- Chat DM creation references `favorites` via `trg_conversations_guard`: only a client can start a non-task conversation with someone in their favorites.

## 3. File Inventory

| File                                                          | Layer     | Description                                                                     |
| ------------------------------------------------------------- | --------- | ------------------------------------------------------------------------------- |
| `lib/features/favorites/data/favorites_service.dart`          | Service   | CRUD for `favorites` with RLS-safe patterns; joins profiles for display.        |
| `lib/features/favorites/models/favorite_model.dart`           | Model     | `FavoriteModel` and `FavoriteWithProfile` (joined row with freelancer profile). |
| `lib/features/favorites/viewmodels/favorites_view_model.dart` | ViewModel | `ChangeNotifier` holding list, loading state, and calling service methods.      |
| `lib/features/favorites/view/favorites_screen.dart`           | View      | List of favorited freelancers with add/remove actions.                          |
| `lib/features/favorites/view/widgets/`                        | Widgets   | Cards/widgets for rendering favorites (if present).                             |
| `lib/features/favorites/routes/favorites_routes.dart`         | Routes    | Navigation entry-points to favorites UI.                                        |

## 4. ERD Diagram

```mermaid
erDiagram
  PROFILES ||--o{ FAVORITES : "client_id"
  PROFILES ||--o{ FAVORITES : "freelancer_id"

  PROFILES {
    uuid id PK
    text full_name
    text avatar_url
  }
  FAVORITES {
    uuid id PK
    uuid client_id FK
    uuid freelancer_id FK
    timestamptz created_at
  }
```

```text
profiles (id) ──< favorites (client_id)
profiles (id) ──< favorites (freelancer_id)
```

## 5. Supabase Snippets

### 5.1 SQL

```sql
-- Add a favorite (RLS ensures client_id = auth.uid())
insert into public.favorites (client_id, freelancer_id)
values (auth.uid(), '<freelancer_id>');

-- List my favorites with freelancer profile
select f.created_at, p.id, p.full_name, p.avatar_url
from public.favorites f
join public.profiles p on p.id = f.freelancer_id
where f.client_id = auth.uid()
order by f.created_at desc;

-- Remove a favorite I own
delete from public.favorites
where client_id = auth.uid() and freelancer_id = '<freelancer_id>';
```

### 5.2 Dart (supabase_flutter)

```dart
final supabase = Supabase.instance.client;

// Add
Future<void> addFavorite(String freelancerId) async {
  await supabase.from('favorites').insert({
    'client_id': supabase.auth.currentUser!.id,
    'freelancer_id': freelancerId,
  });
}

// List (simple)
Future<List<Map<String, dynamic>>> listFavorites() async {
  final rows = await supabase
      .from('favorites')
      .select()
      .eq('client_id', supabase.auth.currentUser!.id)
      .order('created_at', ascending: false);
  return (rows as List).cast<Map<String, dynamic>>();
}

// List with profile fields
Future<List<Map<String, dynamic>>> listFavoritesWithProfile() async {
  final rows = await supabase
      .from('favorites')
      .select('created_at, freelancer:freelancer_id (id, full_name, avatar_url)')
      .eq('client_id', supabase.auth.currentUser!.id)
      .order('created_at', ascending: false);
  return (rows as List).cast<Map<String, dynamic>>();
}

// Remove
Future<void> removeFavorite(String freelancerId) async {
  await supabase.from('favorites')
      .delete()
      .eq('client_id', supabase.auth.currentUser!.id)
      .eq('freelancer_id', freelancerId);
}

// Friendly error mapping
Future<void> safeAddFavorite(String freelancerId) async {
  try {
    await addFavorite(freelancerId);
  } on PostgrestException catch (e) {
    if (e.code == '23505') {
      throw const FormatException('This freelancer is already in your favorites.');
    }
    if (e.code == '42501') {
      throw const FormatException('You can only manage your own favorites.');
    }
    rethrow;
  }
}
```

## 6. Error Handling

| Origin       | Error                    | User-Facing Message                             | Mitigation                                               |
| ------------ | ------------------------ | ----------------------------------------------- | -------------------------------------------------------- |
| Add favorite | `23505` unique violation | "This freelancer is already in your favorites." | Disable button or show success state if already present. |
| Any CRUD     | `42501` RLS denied       | "You can only manage your own favorites."       | Ensure session and use current `auth.uid()`.             |
| Fetch join   | Missing profile row      | "Profile unavailable."                          | Render placeholder name/avatar.                          |

## 7. Extra Notes & Testing Checklist

- **DM integration**: Starting a non-task conversation requires the freelancer to be in the client’s favorites; enforced by triggers/policies in conversations.
- **UTC**: `created_at` is UTC; format with `formatUtcToLocal()` for display.
- **Performance**: Use the simple list for most screens; join with profiles only when fields are needed.

Testing checklist:

- Add → list shows the freelancer at top.
- Add same freelancer again → unique violation mapped to friendly copy.
- Remove → disappears from list and server.
- Attempt cross-user delete → denied by RLS.
- Start DM from a favorite → allowed by conversations guard.

# Saved Feature Reference

## 1. Human Explanation

The Saved feature lets an authenticated user bookmark tasks for quick access. It is private per-user and shows a list with navigation to task details. Architecture:

- UI in `lib/features/saved/view/` renders saved tasks and toggles.
- `SavedTasksViewModel` manages state (ids + full tasks), loading, and friendly errors.
- `SavedTasksService` performs PostgREST calls to `saved_tasks` and joins `tasks` when needed.

## 2. Database & Supabase Mapping

### 2.1 `public.saved_tasks`

| Column       | Type                        | Purpose / Usage       | Notes                         |
| ------------ | --------------------------- | --------------------- | ----------------------------- |
| `id`         | `uuid` (PK)                 | Saved entry id        | Default `gen_random_uuid()`   |
| `user_id`    | `uuid` (FK → `profiles.id`) | Owner of the bookmark | Must equal `auth.uid()` (RLS) |
| `task_id`    | `uuid` (FK → `tasks.id`)    | Bookmarked task       | Unique with `user_id`         |
| `created_at` | `timestamptz`               | When saved (UTC)      | Default `now()`               |

Indexes & Constraints

- Unique `(user_id, task_id)` prevents duplicates.
- (Typical) index on `user_id` for listing performance.

RLS Policies (Summary)

| Table         | Action | Policy     | Rule                   |
| ------------- | ------ | ---------- | ---------------------- |
| `saved_tasks` | SELECT | owner-only | `user_id = auth.uid()` |
| `saved_tasks` | INSERT | owner-only | `user_id = auth.uid()` |
| `saved_tasks` | DELETE | owner-only | `user_id = auth.uid()` |

## 3. File Inventory

| File                                                        | Layer     | Description                                                                      |
| ----------------------------------------------------------- | --------- | -------------------------------------------------------------------------------- |
| `lib/features/saved/data/saved_tasks_service.dart`          | Service   | CRUD: listMine, isSaved, add, remove, toggle, listMineWithDetails (join tasks).  |
| `lib/features/saved/models/saved_task_model.dart`           | Model     | Maps `saved_tasks` rows; typed fields `id`, `user_id`, `task_id`, `created_at`.  |
| `lib/features/saved/viewmodels/saved_tasks_view_model.dart` | ViewModel | Holds saved ids and full tasks; load/refresh/toggle with friendly error mapping. |
| `lib/features/saved/view/saved_tasks_screen.dart`           | View      | List UI with remove/open actions; uses ViewModel.                                |
| `lib/features/saved/view/widgets/saved_task_tile.dart`      | Widget    | Renders one saved task card/tile.                                                |
| `lib/features/saved/routes/saved_routes.dart`               | Routes    | Navigation to Saved screen.                                                      |

## 4. ERD Diagram

```mermaid
erDiagram
  PROFILES ||--o{ SAVED_TASKS : "user_id"
  TASKS    ||--o{ SAVED_TASKS : "task_id"

  PROFILES { uuid id PK }
  TASKS { uuid id PK, text title }
  SAVED_TASKS { uuid id PK, uuid user_id FK, uuid task_id FK, timestamptz created_at }
```

```text
profiles (id) ──< saved_tasks (user_id)
tasks (id)    ──< saved_tasks (task_id)
```

## 5. Supabase Snippets

### 5.1 SQL

```sql
-- Save a task (owner-only by RLS)
insert into public.saved_tasks (user_id, task_id)
values (auth.uid(), '<task_id>');

-- Fetch my saved tasks
select * from public.saved_tasks
where user_id = auth.uid()
order by created_at desc;

-- Remove a saved task
// List Mine with Manual Join (RLS-safe summary enrichment)
// We fetch tasks first, then fetch safe profile summaries, and merge manually.
Future<List<Task>> listMineWithDetails() async {
  // 1. Fetch saved tasks with basic task details
  final res = await _client
      .from('saved_tasks')
      .select('task:tasks(*)')
      .eq('user_id', uid)
      .order('created_at', ascending: false);

  // 2. Extract user IDs
  final userIds = res.map((r) => r['task']['user_id']).toSet().toList();

  // 3. Fetch safe profile summaries through the RPC boundary
  final summaries = await ProfileSummaryService(_client).fetchByIds(
    userIds.whereType<String>(),
  );

  // 4. Merge
  return res.map((row) {
    final taskJson = row['task'];
    final profile = summaries[taskJson['user_id']];
    var task = Task.fromJson(taskJson);
    if (profile != null) {
      task = task.copyWith(
        userName: profile.fullName,
        userAvatar: profile.avatarUrl,
        authorSellerLevel: profile.sellerLevel,
      );
    }
    return task;
  }).toList();
}
```

### 5.3 Workarounds

- **PGRST200 on Join**: The direct join `.select('task:tasks(*, profiles!tasks_user_id_fkey(*))')` is not relied on. Saved-task enrichment uses a **manual 2-step fetch** plus `rpc_get_profile_summaries` so cross-user reads stay compatible with self-only `profiles` RLS.

### 5.2 Dart (supabase_flutter)

```dart
final supabase = Supabase.instance.client;

class SavedTasksService {
  Future<List<Map<String, dynamic>>> listMine() async {
    final rows = await supabase
        .from('saved_tasks')
        .select()
        .eq('user_id', supabase.auth.currentUser!.id)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<bool> isSaved(String taskId) async {
    final row = await supabase
        .from('saved_tasks')
        .select('id')
        .eq('user_id', supabase.auth.currentUser!.id)
        .eq('task_id', taskId)
        .maybeSingle();
    return row != null;
  }

  Future<void> add(String taskId) async {
    await supabase.from('saved_tasks').insert({
      'user_id': supabase.auth.currentUser!.id,
      'task_id': taskId,
    });
  }

  Future<void> remove(String taskId) async {
    await supabase
        .from('saved_tasks')
        .delete()
        .eq('user_id', supabase.auth.currentUser!.id)
        .eq('task_id', taskId);
  }

  Future<bool> toggle(String taskId) async {
    final already = await isSaved(taskId);
    if (already) { await remove(taskId); return false; }
    try {
      await add(taskId); return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') return true; // unique violation → already saved
      rethrow;
    }
  }
}
```

## 6. Error Handling

| Origin        | Error                    | User-Facing Message                        | Mitigation                            |
| ------------- | ------------------------ | ------------------------------------------ | ------------------------------------- |
| Add duplicate | `23505` unique violation | "This task is already in your saved list." | Treat as success (already saved).     |
| Any CRUD      | `42501` RLS denied       | "Please sign in to manage saved tasks."    | Ensure session; map to friendly copy. |
| Join details  | Missing task row         | "This task is no longer available."        | Hide card; allow cleanup removal.     |

## 7. Extra Notes & Testing Checklist

- **Privacy**: Saved entries are per-user; never expose other users’ saved tasks.
- **UX**: Toggle should optimistically update the icon, with background refresh of full list.
- **UTC**: Use `formatUtcToLocal()` when displaying `created_at`.

Testing checklist:

- Save → appears in list; icon toggles immediately.
- Save the same task twice → duplicate is handled gracefully.
- Remove → disappears; toggle syncs across Home/Saved screens.
- Access when signed out → friendly prompt and no data leakage.
  ⸻

  ✅ That’s the full documentation for Categories.

⸻

# Categories Feature Reference

## 1. Human Explanation

The categories module provides a read-mostly catalog of service categories (e.g., "Design", "Development"). It powers dropdowns and filters in `tasks` creation and browsing. Admins seed and manage categories; regular users only read them. The feature is implemented with MVVM: `CategoriesViewModel` coordinates reads via `CategoriesRepository` → `CategoriesService`, and UI in `categories_screen.dart` remains declarative.

## 2. Database & Supabase Mapping

### 2.1 `public.categories`

| Column       | Type          | Purpose / Usage        | Notes                                                |
| ------------ | ------------- | ---------------------- | ---------------------------------------------------- |
| `id`         | `uuid` (PK)   | Category identifier    | Default `gen_random_uuid()`                          |
| `name`       | `text`        | Human-readable name    | Unique (case-insensitive) via index on `lower(name)` |
| `icon_url`   | `text`        | Optional icon path/URL | Nullable                                             |
| `created_at` | `timestamptz` | Created timestamp      | Default `now()` (UTC)                                |

### 2.2 `public.tasks` (relevant FK)

| Column        | Type                          | Purpose / Usage          | Notes                              |
| ------------- | ----------------------------- | ------------------------ | ---------------------------------- |
| `category_id` | `uuid` (FK → `categories.id`) | Tasks link to a category | Indexed as `idx_tasks_category_id` |

### 2.3 Indexes & Constraints

- `uq_categories_name`: `UNIQUE (lower(name))` prevents duplicates with different cases.
- `idx_categories_name_lower`: index on `lower(name)` accelerates search/sort.
- `idx_tasks_category_id`: speeds up task filtering by category.

### 2.4 RLS Policies (Summary)

| Table               | Action               | Who                | Rule / Notes                                 |
| ------------------- | -------------------- | ------------------ | -------------------------------------------- |
| `public.categories` | SELECT               | Authenticated      | Read-only for app users                      |
| `public.categories` | INSERT/UPDATE/DELETE | Admin/Service role | Managed via seeds/Dashboard (not by clients) |
| `public.tasks`      | SELECT               | Authenticated      | Standard app-wide policy                     |

## 3. File Inventory

| File                                                            | Layer      | Description                                                                                                          |
| --------------------------------------------------------------- | ---------- | -------------------------------------------------------------------------------------------------------------------- |
| `lib/features/categories/services/categories_service.dart`      | Service    | Executes PostgREST reads from `public.categories`, provides simple in-memory cache, and client-side search fallback. |
| `lib/features/categories/data/categories_repository.dart`       | Repository | Wraps the service, exposes `getAll`, `getById`, `getCachedOrFetch`, and surfaces `currentUser`.                      |
| `lib/features/categories/viewmodels/categories_view_model.dart` | ViewModel  | `ChangeNotifier` handling loading state, errors, search query, and list data.                                        |
| `lib/features/categories/view/categories_screen.dart`           | View       | Material 3 UI for listing/searching categories using the ViewModel.                                                  |
| `lib/features/categories/models/category_model.dart`            | Model      | Immutable model mapping DB columns (`id`, `name`, `icon_url`, `created_at`) with UTC handling.                       |

## 4. ERD Diagram

```mermaid
erDiagram
  CATEGORIES ||--o{ TASKS : "category_id"

  CATEGORIES {
    uuid id PK
    text name
    text icon_url
  }

  TASKS {
    uuid id PK
    uuid category_id FK
  }
```

```text
categories (id, name, icon_url)
     │
     └──< tasks (category_id)
```

## 5. Supabase Snippets

### 5.1 SQL

```sql
-- Read categories (app users)
select id, name, icon_url from public.categories order by name asc;

-- Insert a category (admin/service role only)
insert into public.categories (name, icon_url) values ('Design', 'icons/design.png');

-- Update a category name (admin only)
update public.categories set name = 'UI/UX Design' where id = '...';

-- Delete a category (admin only)
delete from public.categories where id = '...';

-- Tasks by category name
select t.*
from public.tasks t
join public.categories c on c.id = t.category_id
where lower(c.name) = lower('Design');
```

### 5.2 Dart (supabase_flutter)

```dart
final supabase = Supabase.instance.client;

// Fetch all categories ordered by name (matches CategoriesService.getAll)
Future<List<CategoryModel>> fetchCategories({int limit = 200}) async {
  final rows = await supabase
      .from('categories')
      .select()
      .order('name', ascending: true)
      .limit(limit);

  return (rows as List<dynamic>)
      .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

// Get a single category by id (may return null)
Future<CategoryModel?> getCategoryById(String id) async {
  final row = await supabase
      .from('categories')
      .select()
      .eq('id', id)
      .maybeSingle();
  return row == null ? null : CategoryModel.fromJson(row as Map<String, dynamic>);
}

// Friendly error mapping example for a write (admin-only path)
Future<void> adminRenameCategory(String id, String newName) async {
  try {
    await supabase
        .from('categories')
        .update({'name': newName})
        .eq('id', id);
  } on PostgrestException catch (e) {
    if (e.code == '23505') {
      throw const FormatException('A category with that name already exists.');
    }
    if (e.code == '42501') {
      throw const FormatException('You do not have permission to modify categories.');
    }
    rethrow;
  }
}
```

## 6. Error Handling

| Origin          | Error                         | User Message                                         | Mitigation                           |
| --------------- | ----------------------------- | ---------------------------------------------------- | ------------------------------------ |
| Read categories | Network/timeout               | "Unable to fetch categories. Check your connection." | Retry with cached data if available. |
| Admin writes    | 23505 (unique violation)      | "A category with that name already exists."          | Suggest a different name.            |
| Admin writes    | 42501 (RLS/permission denied) | "You do not have permission to modify categories."   | Use service role/admin tools.        |
| Any             | 22P02 (invalid input syntax)  | "Invalid identifier provided."                       | Validate IDs before sending.         |

## 7. Extra Notes & Testing Checklist

- **Caching**: `CategoriesService` maintains a simple in-memory cache; call `clearCache()` to refresh.
- **UTC**: `created_at` is UTC; no conversion needed for display beyond human formatting.
- **Search**: Service performs client-side search when SDK lacks `.ilike`; consider server-side search later.
- **Seeding**: See `SUPABASE_SETUP.md` for seed values and indexes (`uq_categories_name`, `idx_categories_name_lower`).

Testing checklist:

- **List**: Fetch categories and verify alphabetical ordering.
- **Search**: Apply a search query and confirm client-side filter works.
- **Cache**: Verify `getCachedOrFetch()` returns cached data after a first load.
- **Tasks join**: Query tasks by `category_id` and ensure correct filtering.
- **Permission**: Attempt a write with a user token and confirm RLS denial.

# Home Feature Reference

## 1. Human Explanation

The Home feature is the authenticated discovery surface. It shows a searchable, filterable feed of open tasks, applies client-side discovery filters over the loaded window, and shares its list behavior with the Tender and Booking discovery screens. It follows MVVM:

- UI in `lib/features/home/view/` renders search/filter controls and task list.
- `HomeViewModel` loads the feed with a composite pagination cursor (`created_at`, `id`), implements the shared `DiscoveryFeedViewModelContract`, and updates `TaskFilterViewModel`.
- `TaskService` provides the Supabase reads for tasks and enriches author display data through `rpc_get_profile_summaries`.
- `TaskFilterViewModel` applies search, category, price, delivery-time, and seller-level filters to the loaded discovery window and emits privacy-safe filter telemetry.

## 2. Database & Supabase Mapping

Home does not own tables; it reads from feature tables to populate the dashboard.

### 2.1 `public.tasks` (consumed)

| Column        | Type                        | Purpose / Usage             | Notes                                                   |
| ------------- | --------------------------- | --------------------------- | ------------------------------------------------------- |
| `id`          | `uuid`                      | Task id                     | Used for navigation/details and composite pagination    |
| `title`       | `text`                      | Headline                    | Shown in list cards                                     |
| `description` | `text`                      | Summary                     | Displayed in `TaskCard`                                 |
| `budget`      | `numeric`/`bigint`          | Price field                 | Formatted via `format_price.dart`                       |
| `user_id`     | `uuid` (FK → `profiles.id`) | Author                      | Enriched with safe summary data via RPC                 |
| `status`      | `text`/enum                 | Feed visibility             | Home fetch uses `status = 'open'`                       |
| `task_type`   | enum                        | Tender vs booking behavior  | Seller-level filters exclude tenders                    |
| `category_id` | `uuid` (FK)                 | Category filter             | Joined to `categories(name)`                            |
| `created_at`  | `timestamptz`               | Primary sort / cursor value | Ordered `DESC`; tied rows use `id DESC` as tiebreaker   |
| `deadline`    | `timestamptz`               | Delivery estimate fallback  | Used when booking packages do not provide delivery days |
| `packages`    | `jsonb`                     | Booking delivery estimates  | Min `delivery` value drives delivery-time filters       |
| `image_paths` | `text[]`                    | Thumbnails                  | Shown by `TaskCard` via signed images                   |

Related tables/contracts: `public.categories` for labels and `public.rpc_get_profile_summaries(uuid[])` for author name/avatar/seller level.

RLS: Home reads depend on authenticated-only `public.tasks` access. Direct `public.profiles` reads are self-only and are not part of Home feed rendering.

## 3. File Inventory

| File                                                                    | Layer              | Description                                                                                             |
| ----------------------------------------------------------------------- | ------------------ | ------------------------------------------------------------------------------------------------------- |
| `lib/features/home/view/home_screen.dart`                               | View               | Discovery UI with search, filters, refresh, and navigation to details/create/saved tasks.               |
| `lib/features/home/view/widgets/filters_modal.dart`                     | Widget             | Bottom sheet for sort, category, price, delivery-time, and seller-level filters.                        |
| `lib/features/home/viewmodels/home_view_model.dart`                     | ViewModel          | `ChangeNotifier` that loads/refreshes featured tasks, tracks composite pagination, and updates filters. |
| `lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart` | ViewModel contract | Shared discovery-feed API consumed by Home, Tenders, and Bookings without a Home-specific dependency.   |
| `lib/features/tasks/view/widgets/discovery_task_sliver.dart`            | Widget             | Shared list/empty/load-more sliver used by Home, Tenders, and Bookings discovery surfaces.              |
| `lib/features/tasks/viewmodels/task_filter_view_model.dart`             | ViewModel          | Holds filtered list, search text, category, price, delivery-time, seller-level, and sort state.         |

## 4. ERD Diagram (Context)

```mermaid
erDiagram
  CATEGORIES ||--o{ TASKS : "category_id"

  CATEGORIES { uuid id PK, text name }
  TASKS { uuid id PK, uuid user_id FK, uuid category_id FK, text title, text description, timestamptz created_at }
```

```text
categories (id) ──< tasks (category_id)
```

## 5. Supabase Snippets

### 5.1 Dart (reads used by Home)

```dart
final supabase = Supabase.instance.client;

// Fetch open tasks for Home with composite cursor (as in TaskService)
final rows = await supabase
  .from('tasks')
  .select('id, title, description, budget, user_id, status, task_type, category_id, category, created_at, deadline, skills, image_paths, categories(name)')
  .eq('status', 'open')
  .order('created_at', ascending: false)
  .order('id', ascending: false);

// Then enrich unique author ids via rpc_get_profile_summaries(p_ids)
final authorSummaries = await supabase.rpc('rpc_get_profile_summaries', params: {
  'p_ids': rows.map((row) => row['user_id']).toSet().toList(),
});
```

### 5.2 Filter logic (ViewModel collaboration)

```dart
// HomeViewModel.loadFeaturedTasks(...) populates TaskFilterViewModel
await homeViewModel.loadFeaturedTasks(filterController: context.read<TaskFilterViewModel>());

// Delivery and seller-level filters are applied client-side over the loaded feed window.
context.read<TaskFilterViewModel>().toggleDeliveryTime('Up to 3 days');
context.read<TaskFilterViewModel>().toggleSellerLevel('Level 2');
```

## 6. Error Handling

| Origin       | Error             | User Message                    | Mitigation                                       |
| ------------ | ----------------- | ------------------------------- | ------------------------------------------------ |
| Task fetch   | Network/PostgREST | "Unable to load tasks."         | Retry with pull-to-refresh; log via `AppLogger`. |
| Profile join | Missing profile   | "Author profile unavailable."   | Render placeholder name/avatar.                  |
| RLS          | Permission denied | "Please sign in to view tasks." | Ensure valid session.                            |

## 7. Extra Notes & Testing Checklist

- **Performance**: Avoid N+1 joins in UI; TaskService already batches and hydrates author names/avatars.
- **UTC**: Times are UTC; convert with `formatUtcToLocal()` for display.
- **Saved tasks**: Home integrates with `SavedTasksViewModel` to sync bookmark icons after refresh.

Testing checklist:

- Home loads with featured open tasks on first display.
- Search and category filter update the list immediately.
- Pull-to-refresh reloads tasks and syncs saved-state icons.
- Navigate to task details and back; state is preserved.
- Create a new task → returning to Home refreshes and shows it if `open`.

# Core Module Reference

## 1. Human Explanation

The core module (`lib/core/`) contains runtime infrastructure shared across the whole app:

- Supabase bootstrap and shared service contracts
- payment orchestration helpers used by booking flows
- logging, crash reporting, and error filtering
- theme tokens, shared widgets, and formatting utilities
- small shared models used across multiple features

It is the place for cross-feature code. Feature-specific business rules stay in `lib/features/<feature>/`.

## 2. Platform and Supabase Mapping

Core does not own product tables, but it provides the app-wide runtime used to read them safely.

### 2.1 Shared Supabase resources consumed by core

| Resource                  | Purpose                       | Used by                                 | Notes                                                             |
| ------------------------- | ----------------------------- | --------------------------------------- | ----------------------------------------------------------------- |
| `public.profiles`         | shared user identity metadata | `UserProfile`, `SignedAvatar` consumers | avatar path is stored in DB; signed URL is created at render time |
| `avatars` bucket          | private avatar storage        | `SignedAvatar`, profile flows           | signed URL required for display                                   |
| `task-images` bucket      | private task image storage    | `SignedImage`, task flows               | signed URL required for display                                   |
| `chat-attachments` bucket | private chat file storage     | chat feature widgets/services           | same signed-URL pattern                                           |

### 2.2 Shared payment runtime contracts

Core owns the app-side payment runtime interfaces used by the booking and tender features:

- `PaymentService`: abstract contract for payment providers (booking, direct offer, tender).
- `QiCardPaymentService`: server-backed QiCard create/recover for booking, direct offer, and tender. Tender flow: create (edge `qicard_payment_create_tender`) → WebView → recovery (edge `qicard_payment_recovery_tender`) → ledger gateway_escrow + task assignment.
- `DemoPaymentService`: fallback/demo provider
- `PaymentPendingStore`: persists pending browser payment state on web
- `payment_runtime_config.dart`: callback host validation and callback parsing (supports `request_id`/`payment_request_id` for tender return URLs).

### 2.3 Web safety helpers

Core also owns two browser-specific stability helpers:

- `LoadingUtils.show(...) -> LoadingHandle`: overlay-based loading UI with no navigator mutation
- `flutter_error_filters.dart`: filters the known disposed `EngineFlutterView` assertion on web before crash-reporting/log spam

## 3. File Inventory

| File                                             | Layer     | Description                                                                             |
| ------------------------------------------------ | --------- | --------------------------------------------------------------------------------------- |
| `lib/core/services/supabase_config.dart`         | bootstrap | Initializes Supabase once and exposes the shared client.                                |
| `lib/core/services/logger_service.dart`          | service   | `AppLogger` for structured debug/error logging.                                         |
| `lib/core/services/crash_reporting_service.dart` | service   | Crash-reporting abstraction with a quiet no-op implementation by default.               |
| `lib/core/services/payment_service.dart`         | contract  | Shared payment DTOs and the `PaymentService` interface.                                 |
| `lib/core/services/demo_payment_service.dart`    | service   | Local/demo payment implementation and legacy fallback path.                             |
| `lib/core/services/qicard_payment_service.dart`  | service   | Server-backed QiCard create/recover/refund orchestration.                               |
| `lib/core/services/payment_pending_store.dart`   | service   | Persists pending payment context across same-tab web redirects.                         |
| `lib/core/services/deep_link_service.dart`       | service   | Shared deep-link plumbing used by app navigation flows.                                 |
| `lib/core/config/payment_runtime_config.dart`    | config    | Compile-time finish URL, callback host rules, payment callback parsing.                 |
| `lib/core/utils/loading_utils.dart`              | utility   | Root overlay loading helper that returns an idempotent `LoadingHandle`.                 |
| `lib/core/utils/flutter_error_filters.dart`      | utility   | Filters the known web engine disposal assertion.                                        |
| `lib/core/utils/error_mapper.dart`               | utility   | Shared PostgREST/Auth/network error mapping.                                            |
| `lib/core/utils/format_date.dart`                | utility   | UTC-to-local date/time formatting helpers.                                              |
| `lib/core/utils/format_price.dart`               | utility   | Shared price formatting helpers.                                                        |
| `lib/core/utils/signed_url_cache.dart`           | utility   | Short-lived cache for generated signed URLs.                                            |
| `lib/core/utils/ledger_forensics.dart`           | utility   | Ledger p_meta forensics (session_id, request_id); single source for LedgerService (09). |
| `lib/core/providers/navigation_provider.dart`    | provider  | Global navigation tab state.                                                            |
| `lib/core/providers/theme_mode_provider.dart`    | provider  | Light/dark theme mode state.                                                            |
| `lib/core/models/user_profile.dart`              | model     | Shared typed profile model.                                                             |
| `lib/core/models/payment_return_args.dart`       | model     | Shared typed browser payment callback payload.                                          |
| `lib/core/theme/app_colors.dart`                 | theme     | Central palette definitions.                                                            |
| `lib/core/theme/app_dimens.dart`                 | theme     | Spacing, radius, sizing tokens.                                                         |
| `lib/core/theme/app_typography.dart`             | theme     | Shared typography and fallback font configuration.                                      |
| `lib/core/theme/app_theme.dart`                  | theme     | Builds the app `ThemeData` and `AppThemeExtension`.                                     |
| `lib/core/widgets/custom_bottom_nav_bar.dart`    | widget    | Shared app shell bottom nav.                                                            |
| `lib/core/widgets/signed_avatar.dart`            | widget    | Renders private avatar paths through signed URLs.                                       |
| `lib/core/widgets/signed_image.dart`             | widget    | Renders private image paths through signed URLs.                                        |

## 4. Runtime Patterns

### 4.1 App bootstrap

- `main.dart` initializes Supabase through `SupabaseConfig.init()`.
- Shared providers are registered at app root, including `SupabaseClient`, `ProfileRepository`, `CategoriesRepository`, and `PaymentPendingStore`.
- `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and `runZonedGuarded` are wired through the core logging/crash-reporting path.

### 4.2 Loading overlays

The current pattern is overlay-based, not dialog-based.

```dart
final loader = LoadingUtils.show(context, debugLabel: 'open_chat');
try {
  await doSomethingAsync();
} finally {
  loader.close();
}
```

Do not use `Navigator.pop()` to dismiss loading UI. The old `LoadingUtils.hide(context)` pattern is obsolete.

### 4.3 Web payment callback parsing

```dart
final paymentReturn = parsePaymentReturnArgs(Uri.base);
if (paymentReturn != null) {
  return PaymentReturnScreen(initialArgs: paymentReturn);
}
```

The callback parser validates host + path shape against `kQiCardFinishUrl` and `buildQiCardCallbackHosts()`.

### 4.4 Typography and fallback fonts

`AppTypography` now centralizes fallback font families for missing glyphs:

- `Noto Sans`
- `Noto Sans Arabic`
- `Roboto`
- `Arial`
- `sans-serif`

This allows user-generated Arabic text to render without forcing feature code to manage font fallback.

## 5. Error Handling Notes

| Origin                   | Error                                    | Handling                                                          |
| ------------------------ | ---------------------------------------- | ----------------------------------------------------------------- |
| Supabase bootstrap       | bad URL/key/session setup                | fail fast during app startup; log through `AppLogger`             |
| Signed URL creation      | missing object / expired URL             | return placeholder and regenerate URL when needed                 |
| Web engine assertion     | disposed `EngineFlutterView`             | filtered by `isIgnoredFlutterWebEngineDisposeError(...)`          |
| Payment callback parsing | invalid host / invalid booking reference | handled in `PaymentReturnScreen` with explicit terminal messaging |

## 6. Testing Checklist

- Boot the app and confirm `SupabaseConfig.init()` succeeds before rendering feature screens.
- Render `SignedAvatar` and `SignedImage` using valid private paths.
- Verify `LoadingHandle.close()` is safe even when a route closes during async work.
- On web, confirm a payment callback loads `PaymentReturnScreen` instead of falling back to the main shell immediately.
- Confirm the known disposed `EngineFlutterView` assertion is filtered and not duplicated in debug logs.
- Confirm Arabic user-generated text renders with the theme fallback stack.

# Auth Feature Reference

## 1. Human Explanation

The auth feature is the gatekeeper for the app. It handles:

- email/password sign up
- email/password sign in
- password reset initiation
- password update (recovery)
- session-aware logout
- loading the signed-in user's profile row after authentication

The current architecture is MVVM with repository-backed data access:

- views render forms and navigation
- `AuthSessionViewModel` owns session state, profile loading, session listeners, and logout
- `AuthFormViewModel` owns transient form state (loading, errors) for login, signup, and reset flows
- `AuthRepository` owns Supabase Auth and `profiles` reads/writes

Neither ViewModel holds a `BuildContext`. They return success/failure to the UI and expose auth state that is wired by `main.dart` or consumed by widgets.

## 2. Database and Supabase Mapping

| Resource          | Purpose                      | Notes                                                 |
| ----------------- | ---------------------------- | ----------------------------------------------------- |
| `auth.users`      | primary Supabase identity    | created by `supabase.auth.signUp()`                   |
| `public.profiles` | app-level user profile row   | generated via Postgres trigger on `auth.users` insert |
| `auth.sessions`   | active authenticated session | required for any RLS-protected follow-up query        |

### `public.profiles` fields used by auth flows

| Column       | Type          | Purpose                                |
| ------------ | ------------- | -------------------------------------- |
| `id`         | `uuid`        | matches `auth.users.id`                |
| `full_name`  | `text`        | captured at signup/updated via trigger |
| `email`      | `text`        | cached for app reads                   |
| `avatar_url` | `text`        | optional storage path, used elsewhere  |
| `role`       | `text`        | current persona used by the UI         |
| `created_at` | `timestamptz` | audit timestamp                        |

### RLS Summary

- `profiles` insert/update/select works only when `auth.uid() = id`.
- Auth APIs themselves are handled by Supabase Auth, but profile bootstrapping is handled seamlessly by backend triggers.
- The repository relies on the database trigger `trg_on_auth_user_created` to automatically create the profile row from user metadata.

## 3. File Inventory

| File                                                        | Layer      | Description                                                                   |
| ----------------------------------------------------------- | ---------- | ----------------------------------------------------------------------------- |
| `lib/features/auth/data/auth_repository.dart`               | repository | Owns signup, signin, signout, password reset, and current profile fetch.      |
| `lib/features/auth/viewmodels/auth_session_view_model.dart` | viewmodel  | Tracks current profile, listens for auth-state changes, and handles logout.   |
| `lib/features/auth/viewmodels/auth_form_view_model.dart`    | viewmodel  | Tracks loading/error state for login, signup, and password reset forms.       |
| `lib/features/auth/view/login_screen.dart`                  | view       | Login form and success/failure UI using `AuthFormViewModel`.                  |
| `lib/features/auth/view/signup_screen.dart`                 | view       | Registration form and profile bootstrap entrypoint using `AuthFormViewModel`. |
| `lib/features/auth/view/forgot_password_screen.dart`        | view       | Password reset request UI.                                                    |
| `lib/features/auth/view/update_password_screen.dart`        | view       | Password recovery completion UI.                                              |

There is no live `lib/features/auth/services/auth_service.dart` file anymore. `AuthRepository` is the current single source of truth for auth data access.

## 4. Current Flow

### 4.1 Sign up

1. `SignupScreen` calls `AuthFormViewModel.register(...)`.
2. `AuthFormViewModel` delegates to `AuthRepository.signUp(...)`.
3. `AuthRepository` calls `supabase.auth.signUp(...)`, passing `full_name` in `data`.
4. Supabase DB trigger `trg_on_auth_user_created` creates the `public.profiles` row natively.
5. If auto-sign-in occurs or upon explicit sign-in, `AuthSessionViewModel` detects the session and loads the new profile.

### 4.2 Sign in

1. `LoginScreen` calls `AuthFormViewModel.login(...)`.
2. `AuthRepository.signIn(...)` performs `signInWithPassword(...)`.
3. On success, `AuthFormViewModel` returns `true`.
4. `AuthSessionViewModel` detects the auth state change and loads the profile.

### 4.3 Profile provisioning retry

After signup or when restoring a session, the app fetches the current user's `profiles` row. Because the profile row is created by a Postgres trigger, it can be briefly delayed. The app uses a short retry loop (see `AuthConfig` in `lib/core/config/auth_config.dart`: `profileFetchMaxAttempts`, `profileFetchRetryDelayMs`, and `enableProfileFetchRetry`). `AuthRepository.getCurrentUserProfileWithRetry()` performs the fetch; on success the session continues; if the profile is still missing after all attempts, the user is signed out and shown a configured message (e.g. "Profile creation failed. Please try again."). This avoids showing a broken session when the trigger is slow.

### 4.4 Password reset

`AuthRepository.sendPasswordResetEmail(...)` calls Supabase with the current mobile redirect:

- `io.supabase.sline://login-callback`

### 4.5 Session expiry / Logout

- `AuthSessionViewModel` subscribes to `Supabase.instance.client.auth.onAuthStateChange`.
- `main.dart` listens to `AuthSessionViewModel` and redirects to `/login` if `currentProfile` becomes null or session expires.
- `AuthSessionViewModel.logout()` calls `AuthRepository.signOut()`.

## 5. Example Snippets

### Signup with App Metadata

```dart
final response = await _client.auth.signUp(
  email: email,
  password: password,
  data: {'full_name': fullName},
);
```

### ViewModel usage from UI

```dart
final success = await context.read<AuthFormViewModel>().login(
  email: email,
  password: password,
);

if (!mounted) return;
if (success) {
  Navigator.pushReplacementNamed(context, '/main');
}
```

## 6. Error Handling

`AuthFormViewModel` maps common raw auth failures to user-facing messages.

Examples:

- invalid credentials -> `Invalid email or password. Please try again.`
- unconfirmed email -> `Please verify your email before logging in.`
- duplicate account -> `An account with this email already exists.`
- network failure -> `Network error. Please check your connection.`

Repository logging uses `AppLogger` and masks email addresses.

## 7. Testing Checklist

- Sign up a new user and confirm the backend trigger creates the `profiles` row.
- Sign in with a valid account and confirm `AuthFormViewModel.login()` returns `true`.
- Enter invalid credentials and confirm the mapped error is shown without clearing fields.
- Trigger password reset and verify the reset request succeeds.
- Call `AuthSessionViewModel.logout()` and confirm the app returns to `/login`.
- Simulate a session-expiry or sign-out event and verify `AuthSessionViewModel` clears data and forces navigation.

## Legacy Orders Dashboard (Decommissioned)

## 1. Human Explanation

The standalone `orders` dashboard module was removed on 2026-03-01.

- The live bottom-nav dashboard entry is `lib/features/dashboard/view/dashboard_screen.dart`.
- `lib/app/main_navigation_screen.dart` still uses the legacy enum slot name `NavView.orders` for compatibility, but that slot no longer maps to `lib/features/orders/`.
- The old `orders` module is intentionally not part of the runtime anymore; only `lib/features/orders/README.md` remains as a tombstone note.

## 2. Replacement Contract

- **Navigation entry**: `lib/app/main_navigation_screen.dart`
- **Bottom-nav shell**: `lib/core/widgets/custom_bottom_nav_bar.dart`
- **Dashboard UI**: `lib/features/dashboard/view/dashboard_screen.dart`
- **Dashboard state**: `lib/features/dashboard/viewmodels/dashboard_view_model.dart`
- **Legacy placeholder**: `lib/features/orders/README.md`

### 2.1 Current dashboard behavior (2026-03)

- **Cache**: `DashboardCacheService` is provided in `main.dart` and injected into `DashboardViewModel`; overview data can be served from cache when appropriate.
- **Lazy-load by tab**: Overview data loads first; Bookings and Inbox data load on first visit to those tabs. Full refresh still loads all datasets.
- **Wallet snapshot**: On first entry to the dashboard, `OverviewTab` triggers `WalletViewModel.loadWallet()` so the balance snapshot is visible without a separate wallet visit. After withdrawal, the ViewModel refreshes both balance and activities. `ensureLoaded()` uses a shared `_loadingFuture` so concurrent callers await the same load.
- **My Services**: `MyServicesScreen` (profile) uses `MyServicesViewModel` and `ServicesRepository.fetchMyServices()`; it no longer depends on dashboard state.
- **Tender payment**: All payment entry points (Inbox, Work, Next Actions, Work Details, Requests list after award) use `openProposalPayment(context, summary)` from `lib/features/proposals/routes/proposal_payment_route.dart`; see [Proposals Feature](DEVELOPER_GUIDE/Proposals_Feature.md). That route builds `TenderPaymentScreen` with `TenderPaymentCoordinator` and `TenderPaymentViewModel`; the screen uses only the ViewModel (no direct service calls in the widget). Awarding an offer moves the task to the Work tab as "Waiting payment"; the client can Pay or Cancel from there (Cancel reverts the award so the task reappears in Inbox). `TaskService` is provided in `main.dart`. **QiCard (March 2026):** When the app uses `QiCardPaymentService`, the Pay button is enabled: the coordinator calls the edge function `qicard_payment_create_tender` to get a `form_url`, the screen opens `PaymentWebViewScreen` for the user to pay; on return the app calls `recoverTenderPaymentAfterCallback` (edge function `qicard_payment_recovery_tender`), which runs `process_payment_event_ledger(gateway_escrow, task_request)` and assigns the task (freelancer, in_progress). **Demo:** When using `DemoPaymentService`, the Pay button is disabled (fail-closed); tender state never advances.
- **Offer submission:** Task offer submit no longer mutates `profiles.active_role`. RLS does not require the user to be in the freelancer role. If insert is denied (e.g., trying to bid on your own task or a closed task), the app shows: "You cannot submit an offer. The task might be closed or you are the task owner."
- **Dashboard cards**: Booking card lives in `lib/features/booking/view/widgets/dashboard_booking_card.dart` (callbacks for actions); offer card in `lib/features/tasks/view/widgets/dashboard_offer_card.dart`; wallet snapshot in `lib/features/wallet/view/widgets/wallet_snapshot_card.dart`. Shared status color/label helpers: `lib/core/utils/status_presenter.dart`.
- **Pull-to-refresh on every tab**: All four dashboard tabs support pull-to-refresh and call `DashboardViewModel.refresh()` (full reload). Implemented in: `lib/features/dashboard/view/tabs/overview_tab.dart` (ListView wrapped in `RefreshIndicator`), `lib/features/dashboard/view/tabs/bookings_tab.dart` (empty state and list both wrapped; empty uses `SingleChildScrollView` + `AlwaysScrollableScrollPhysics`), `lib/features/dashboard/view/tabs/inbox_tab.dart` (empty state wrapped; list already had `RefreshIndicator`), `lib/features/dashboard/view/tabs/work_tab.dart` (Active, Done, Cancelled sub-tabs each have `RefreshIndicator` for both empty and filled lists).

## 3. Why It Was Removed

- The main app had already consolidated the dashboard tab onto `DashboardScreen`.
- `OrdersViewModel` remained app-root scoped in `lib/main.dart` even though no live route instantiated the standalone orders dashboard.
- Keeping both `dashboard` and `orders` modules created two competing dashboard surfaces and stale documentation.

## 4. Verification Checklist

- Confirm `lib/main.dart` no longer imports or provides `OrdersViewModel`.
- Confirm `lib/app/main_navigation_screen.dart` still renders `DashboardScreen()` in the legacy `NavView.orders` slot.
- Confirm repo search for `OrdersDashboardScreen`, `OrdersViewModel`, and `OrdersService` returns no live Dart references outside historical `.TODO/` artifacts.

---

# Chat Feature Reference

## 1. Human Explanation

The chat module provides one-to-one messaging between a client and a freelancer. Conversations may be tied to a `task` (job discussion) or be a client-initiated direct message (DM) to a favorite freelancer. The feature follows MVVM:

- UI in `lib/features/chat/view/` stays declarative.
- `ChatViewModel` orchestrates state, subscriptions, and actions.

- `ChatRepository` wraps `MessageService`, which performs Supabase queries, RPC calls, and Realtime streaming.

**New in v2.8.2**:

- `ChatContextWidget`: Glassmorphism banner linking chat to its task. Tapping navigates to Task Details.
- `LoadingUtils`: Used to show blocking loaders during navigation or heavy actions.

**Direct Chat Offers (v2.17)**: Freelancer creates an offer from any 1:1 chat (no task required). Client accepts in chat only; payment is from Dashboard (QiCard). Full flow, DB mapping, and file inventory: [Direct Chat Offers (Direct Offers Feature)](DEVELOPER_GUIDE/Direct_Offers_Feature.md).

## 2. Database & Supabase Mapping

### 2.1 `public.conversations`

| Column         | Type                               | Purpose / Usage              | Notes                          |
| -------------- | ---------------------------------- | ---------------------------- | ------------------------------ |
| `id`           | `uuid` (PK)                        | Conversation id              | Generated on insert            |
| `task_id`      | `uuid` (FK → `tasks.id`, nullable) | Optional task context        | Enables task-linked chats      |
| `user1_id`     | `uuid` (FK → `profiles.id`)        | First participant            | Used by RLS checks             |
| `user2_id`     | `uuid` (FK → `profiles.id`)        | Second participant           | Used by RLS checks             |
| `initiated_by` | `uuid` (FK → `profiles.id`)        | Who started the conversation | Used by guard trigger/policies |
| `created_at`   | `timestamptz`                      | Creation timestamp (UTC)     | Default `now()`                |

Indexes/Constraints

- `uq_conversations_pair_task` on `(least(user1_id,user2_id), greatest(user1_id,user2_id), coalesce(task_id, '00000000-0000-0000-0000-000000000000'))` prevents duplicates for the same pair/task.
- `idx_conversations_task`, `idx_conversations_user1`, `idx_conversations_user2` for fast lookups.

### 2.2 `public.message_type_enum`

Values: `text`, `offer`, `offer_update`, `offer_accepted`, `offer_rejected`, `delivery_submitted`, `end_early_request`, `dispute_report`.

### 2.3 `public.messages`

| Column            | Type                                  | Purpose / Usage                            | Notes                                   |
| ----------------- | ------------------------------------- | ------------------------------------------ | --------------------------------------- |
| `id`              | `uuid` (PK)                           | Message id                                 | Generated on insert                     |
| `conversation_id` | `uuid` (FK → `conversations.id`)      | Parent conversation                        | Indexed                                 |
| `sender_id`       | `uuid` (FK → `profiles.id`)           | Sender                                     | Must equal `auth.uid()` on insert (RLS) |
| `receiver_id`     | `uuid` (FK → `profiles.id`, nullable) | Receiver                                   | Optional for some flows                 |
| `content`         | `text`                                | Text body                                  | May be empty for attachment-only        |
| `attachment_url`  | `text`                                | Storage path in private bucket             | Generate signed URLs for reads          |
| `attachment_type` | `text`                                | 'image' or 'file'                          | Optional                                |
| `attachment_name` | `text`                                | Original filename                          | Optional                                |
| `attachment_size` | `int`                                 | Size in bytes                              | Optional                                |
| `message_type`    | `message_type_enum`                   | Message semantics                          | Default `text`                          |
| `payload`         | `jsonb`                               | Extra fields (e.g., `{price, days, note}`) | Default `{}`                            |
| `created_at`      | `timestamptz`                         | Creation timestamp (UTC)                   | Default `now()`                         |

Index

- `idx_messages_convo_created` on `(conversation_id, created_at)`.

### 2.4 Storage (private)

- Bucket: `chat-attachments` (private). Store object path; create signed URLs on demand.

### 2.5 RLS Policies (Summary)

| Table           | Action | Policy Summary             | Notes                                                                                                          |
| --------------- | ------ | -------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `conversations` | SELECT | Only participants can read | `auth.uid() = user1_id OR auth.uid() = user2_id`                                                               |
| `conversations` | INSERT | Client-only creation       | Must be initiator and participant; task-linked requires task owner; DM requires freelancer in client favorites |
| `messages`      | SELECT | Only participants can read | Checked via parent conversation                                                                                |
| `messages`      | INSERT | Only participants can send | `sender_id = auth.uid()`, plus guard for `offer_accepted/offer_rejected` (task owner or initiator)             |

Triggers/Functions

- `trg_conversations_before_insert_guard` / `conversations_before_insert_guard()`: Only clients can start non-task DMs with favorites; task-linked normally requires non-owner to initiate. Exception: the task owner may create a task-linked conversation when rejecting an offer via `reject_task_request` (RPC sets `app.allow_owner_task_conversation`; see SUPABASE_SETUP.md §8.3 and migration `20260305071000_conversations_guard_allow_owner_reject.sql`).
- `trg_messages_before_insert_validate` / `messages_before_insert_validate`: Offer messages require `price` and `days` in `payload`.

### 2.6 Direct Chat Offers (v2.17)

- **Table:** `direct_offers`. Lifecycle: sent → accepted (unpaid) → pay from Dashboard → active → delivered → completed. See `Sline_everything/SUPABASE_SETUP.md` §5.14.
- **App:** `lib/features/direct_offers/` (model, service, viewmodel, view). Chat shows **Accept** only; payment from Dashboard via QiCard; detail screen `DirectOfferDetailsScreen`.
- **Full reference:** [Direct Chat Offers (Direct Offers Feature)](DEVELOPER_GUIDE/Direct_Offers_Feature.md) — flow, DB, ledger, edge functions, file inventory, integration points.
- `trg_messages_offer_accepted`: Task-linked offers only; pure direct_offers do not touch `tasks`. **Archive:** RPC `archive_conversation_v1` — see `SUPABASE_SETUP.md`.

## 3. File Inventory

| File                                                      | Layer      | Description                                                                                                                                              |
| --------------------------------------------------------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/features/chat/data/chat_repository.dart`             | Repository | Wraps `MessageService`; exposes conversation/message APIs, receipts, and Realtime streams.                                                               |
| `lib/features/chat/services/message_service.dart`         | Service    | PostgREST + Realtime for messages (active chat + Inbox), RPCs for receipts, task chats, and archive. Inbox uses `subscribeToInboxMessages(userId)`; conversations table is not in realtime publication. See diagram 18. |
| `lib/features/chat/services/attachment_service.dart`      | Service    | Storage upload/delete/signed URL helpers for attachments.                                                                                                |
| `lib/features/chat/services/chat_realtime_merger.dart`    | Service    | Merges realtime message snapshots (dedupe, sort).                                                                                                        |
| `lib/features/chat/viewmodels/chat_view_model.dart`       | ViewModel  | `ChangeNotifier` managing conversation list, active conversation, message list, subscriptions, and receipts.                                             |
| `lib/features/chat/view/messages_screen.dart`             | View       | Conversations list with previews via joined selects.                                                                                                     |
| `lib/features/chat/view/chat_screen.dart`                 | View       | Single conversation UI (messages + composer).                                                                                                            |
| `lib/features/chat/view/widgets/chat_context_widget.dart` | Widget     | Glassmorphic banner showing task context + navigation.                                                                                                   |
| `lib/features/chat/models/conversation_model.dart`        | Model      | Conversation with display fields (other user name/avatar, last message).                                                                                 |
| `lib/features/chat/models/message_model.dart`             | Model      | Message with attachments, type, payload (wire: snake_case); includes `MessageType.system`.                                                               |
| `lib/features/chat/models/chat_offer_payload.dart`        | Model      | Canonical offer payload: `days` on write; legacy `delivery` read.                                                                                        |
| `lib/features/chat/attachments/`                          | Submodule  | Upload/compress/pick utils and widgets for attachment UX.                                                                                                |
| `lib/features/direct_offers/`                             | Feature    | Direct Chat Offers: model, service (`acceptOfferWithoutPayment`, `payNow`, `recoverPaymentAfterCallback`), viewmodel, view (`DirectOfferDetailsScreen`). |

## 4. ERD Diagram

```mermaid
erDiagram
  PROFILES ||--o{ CONVERSATIONS : "user1_id/user2_id"
  TASKS ||--o{ CONVERSATIONS : "task_id (optional)"
  CONVERSATIONS ||--o{ MESSAGES : "conversation_id"
  PROFILES ||--o{ MESSAGES : "sender_id/receiver_id"

  PROFILES {
    uuid id PK
    text full_name
    text avatar_url
  }
  TASKS {
    uuid id PK
    text title
  }
  CONVERSATIONS {
    uuid id PK
    uuid task_id FK
    uuid user1_id FK
    uuid user2_id FK
    uuid initiated_by FK
    timestamptz created_at
  }
  MESSAGES {
    uuid id PK
    uuid conversation_id FK
    uuid sender_id FK
    uuid receiver_id FK
    text content
    text attachment_url
    text attachment_type
    text attachment_name
    int attachment_size
    message_type_enum message_type
    jsonb payload
    timestamptz created_at
  }
```

```text
profiles (id)
  ├─< conversations (user1_id, user2_id, initiated_by)
  │       └─< messages (conversation_id, sender_id, receiver_id)
tasks (id) ──< conversations (task_id, optional)
```

## 5. Supabase Snippets

### 5.1 SQL

```sql
-- Create or fetch a DM conversation (server enforces initiator/participants via policies/triggers)
insert into public.conversations (user1_id, user2_id, initiated_by)
values (auth.uid(), '<other_user_id>', auth.uid())
on conflict do nothing
returning *;

-- Insert a message (participants only)
insert into public.messages (conversation_id, sender_id, receiver_id, content)
values ('<conv_id>', auth.uid(), '<other_user_id>', 'Hello');

-- Query messages ordered by time
select * from public.messages
where conversation_id = '<conv_id>'
order by created_at asc;
```

### 5.2 Dart (supabase_flutter)

```dart
final supabase = Supabase.instance.client;

// Send a message
Future<void> sendText({required String convId, required String receiverId, required String text}) async {
  await supabase.from('messages').insert({
    'conversation_id': convId,
    'sender_id': supabase.auth.currentUser!.id,
    'receiver_id': receiverId,
    'content': text,
  });
}

// Subscribe to messages in a conversation
Stream<Map<String, dynamic>?> streamMessages(String convId) {
  return supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', convId)
      .order('created_at')
      .map((rows) => rows.isEmpty ? null : rows.last as Map<String, dynamic>);
}

// Upload attachment and send (store path; generate signed URL on read)
Future<void> sendImage({required String convId, required String receiverId, required List<int> bytes, required String mime}) async {
  final userId = supabase.auth.currentUser!.id;
  final path = 'convos/$convId/${DateTime.now().toUtc().toIso8601String()}';
  await supabase.storage.from('chat-attachments').uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
  await supabase.from('messages').insert({
    'conversation_id': convId,
    'sender_id': userId,
    'receiver_id': receiverId,
    'attachment_url': path,
    'attachment_type': 'image',
    'attachment_name': 'image.jpg',
  });
}
```

## 6. Error Handling

| Origin              | Error                                         | User-Facing Message                                    | Mitigation                                                          |
| ------------------- | --------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------- |
| Start conversation  | `23505` (unique `uq_conversations_pair_task`) | "Conversation already exists."                         | Fetch and open the existing conversation.                           |
| Insert conversation | RLS (client-only) / trigger guard             | "You are not allowed to start this conversation."      | Ensure initiator is the client and favorite/task owner checks pass. |
| Send message        | `42501` (permission denied)                   | "You are not a participant in this conversation."      | Verify membership and session.                                      |
| Offer messages      | Trigger validation                            | "Offer requires price and days."                       | Validate payload before sending.                                    |
| Attachment          | Storage error or expired signed URL           | "Attachment unavailable. Please re-upload or refresh." | Recreate signed URL or re-upload.                                   |
| IDs                 | `22P02` invalid UUID                          | "Invalid chat identifier."                             | Validate IDs before calling APIs.                                   |

## 7. Extra Notes & Testing Checklist

- **Realtime**: Subscribe to `messages` stream only: active chat via `.eq('conversation_id')`, Inbox via `.eq('receiver_id', userId)`. The `conversations` table is not in the realtime publication. See `Sline_everything/AppDigram/All_Diagrams/18_realtime-subscription-topology.md`.
- **Signed URLs**: Keep attachments private; generate signed URLs on demand and cache short-term.
- **Time zones**: `created_at` stored in UTC; format locally in UI.
- **Receipts**: RPCs `mark_conversation_delivered` and `mark_conversation_seen` update delivery/read states.
- **DM vs Task**: DM requires the freelancer to be in client's `favorites`; task chat requires task owner.

---

## Chat Creation Matrix (v2.19)

**Purpose**: Secure, atomic conversation creation with role-based and favorites-based access control.

### Overview

The Chat Creation Matrix replaces the legacy non-atomic `SELECT-then-INSERT` pattern with an atomic RPC that enforces business rules at the database level:

1. **Role Enforcement**: Only clients can initiate direct DMs
2. **Favorites Enforcement**: Clients can only DM freelancers in their favorites list
3. **Rate Limiting**: Maximum 20 conversation creations per hour per user
4. **Idempotency**: Duplicate calls return the same conversation (no duplicates)
5. **Audit Trail**: All conversation creation logged to `admin_logs`

### Key Components

| Component                           | Type      | Location | Purpose                                                 |
| ----------------------------------- | --------- | -------- | ------------------------------------------------------- |
| `start_direct_conversation_v1()`    | RPC       | Supabase | Atomic DM creation with all validations                 |
| `is_client()`                       | Function  | Supabase | Check if user has `active_role = 'client'`              |
| `check_conversation_rate_limit()`   | Function  | Supabase | Verify user is within 20/hour limit                     |
| `conversations_before_insert_guard` | Trigger   | Supabase | Validates ALL conversation inserts                      |
| `app_config`                        | Table     | Supabase | Feature flag storage (`enable_direct_conversation_rpc`) |
| `MessageService`                    | Service   | Flutter  | Routes to RPC or legacy path based on flag              |
| `ChatViewModel`                     | ViewModel | Flutter  | Loading states, error handling, double-tap prevention   |

### Business Rules

| Rule                         | Enforcement         | Error Message                                                 |
| ---------------------------- | ------------------- | ------------------------------------------------------------- |
| Only clients initiate DMs    | Guard trigger + RPC | "Only clients can start conversations with freelancers"       |
| Favorites required           | Guard trigger + RPC | "Add this freelancer to your favorites first"                 |
| Rate limit 20/hour           | Guard trigger + RPC | "You've reached the conversation limit. Try again in an hour" |
| Identity integrity           | Guard trigger       | "initiated_by must equal current user"                        |
| Self-conversation prevention | RPC                 | "You can't start a conversation with yourself"                |

### Usage

**Automatic via MessageService**:

```dart
try {
  final conversation = await messageService.createOrGetConversation(
    user1Id: clientId,
    user2Id: freelancerId,
  );
  // Navigate to chat
} catch (e) {
  final message = ErrorMapper.map(e);
  // Show user-friendly error
}
```

**Direct RPC (advanced)**:

```dart
final response = await supabase.rpc(
  'start_direct_conversation_v1',
  params: {'p_target_id': freelancerId},
);
```

### Error Handling

All errors are mapped to user-friendly messages via `ErrorMapper`:

| SQL Error                                                 | User Message                                                          |
| --------------------------------------------------------- | --------------------------------------------------------------------- |
| `Freelancers cannot start direct conversations`           | "Only clients can start conversations with freelancers"               |
| `You can only message freelancers in your favorites list` | "Add this freelancer to your favorites first to start a conversation" |
| `Rate limit exceeded: maximum 20 conversations per hour`  | "You've reached the conversation limit. Try again in an hour"         |
| `Target user not found`                                   | "User not found. They may have deleted their account"                 |
| `Cannot create conversation with yourself`                | "You can't start a conversation with yourself"                        |

### Feature Flag

Controlled via `app_config` table:

```sql
-- Check current value
SELECT value FROM app_config WHERE key = 'enable_direct_conversation_rpc';
-- Returns: 'false' (default) or 'true'

-- Enable (gradual rollout)
SELECT admin_set_config('enable_direct_conversation_rpc', 'true');

-- Disable (instant rollback)
SELECT admin_set_config('enable_direct_conversation_rpc', 'false');
```

**Behavior**:

- `false` (default): Uses legacy direct INSERT path (backward compatible)
- `true`: Uses new atomic RPC path with full validation

### Migration & Rollback

**Zero-downtime migration**: Feature flag defaults to `false`; app continues working during deployment.

**Rollback options**:

1. **Fast** (instant): `UPDATE app_config SET value = 'false'` - App falls back to legacy path
2. **Emergency**: Bypass guard trigger if critical issues found
3. **Full**: Drop new functions if needed

### Testing

```bash
# Unit tests
flutter test test/services/message_service_test.dart

# Security tests
flutter test test/rls/chat_creation_security_test.dart

# Integration tests
flutter test integration_test/chat_creation_test.dart
```

### Files

| File                                                          | Description                             |
| ------------------------------------------------------------- | --------------------------------------- |
| `supabase/migrations/20260306000000_chat_creation_matrix.sql` | Database migration                      |
| `lib/features/chat/services/message_service.dart`             | Service layer with feature flag routing |
| `lib/features/chat/viewmodels/chat_view_model.dart`           | Loading states and error handling       |
| `lib/core/utils/error_mapper.dart`                            | Error message mapping                   |
| `test/fixtures/chat_fixtures.dart`                            | Test data                               |
| `test/services/message_service_test.dart`                     | Unit tests                              |
| `integration_test/chat_creation_test.dart`                    | E2E tests                               |

---

Testing checklist

- Create/fetch conversation (DM and task-linked) as allowed roles.
- Send/receive text; stream updates in UI.
- Upload attachment; confirm access via signed URLs when reading.
- Attempt non-participant send → denied by RLS.
- Send offer without required payload → trigger error; validate client-side.

# Direct Chat Offers

**Full reference:** [Direct Chat Offers (Direct Offers Feature)](DEVELOPER_GUIDE/Direct_Offers_Feature.md)

Chat-to-work: freelancer creates an offer from a 1:1 chat; client accepts in chat (no payment there); offer appears as **Pending Payment** in Dashboard; client pays from Dashboard (QiCard); then deliver/complete like a booking. Covers flow, `direct_offers` table, ledger, edge functions `qicard_payment_create_direct_offer` / `qicard_payment_recovery_direct_offer`, and all app files in `lib/features/direct_offers/` plus Chat/Dashboard/Payment integration.

---

# Booking Feature Reference

## 1. Human-Readable Overview

The booking feature currently supports direct service bookings with server-backed payment initiation and recovery.

Primary user flows:

- clients can purchase a booking package from a booking task
- providers can review booking requests, accept or decline them, and mark work as delivered
- clients can review details and approve release after delivery
- both sides can inspect booking history and the embedded management timeline

Important current behavior:

- slotless direct bookings are allowed multiple times for the same client/task pair
- slot-based rows still exist in the schema and UI as legacy/historical support
- QiCard is the default payment provider, but payment initiation and reconciliation are server-backed through Supabase edge functions

## 2. Supabase Mapping

### 2.1 Core tables

#### `public.bookings`

| Column           | Type                  | Purpose / Usage                  | Notes                                                                                                                        |
| ---------------- | --------------------- | -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `id`             | `uuid`                | booking identifier               | primary key                                                                                                                  |
| `task_id`        | `uuid`                | linked booking task              | nullable in model but expected for current flow                                                                              |
| `provider_id`    | `uuid`                | service provider                 | used for provider-side lists and RLS                                                                                         |
| `client_id`      | `uuid`                | booking client                   | used for client-side lists and RLS                                                                                           |
| `slot_id`        | `uuid`                | optional legacy slot link        | nullable for direct slotless bookings                                                                                        |
| `status`         | `booking_status_enum` | booking lifecycle                | app maps `paid_request_pending`, `active`, `delivered`, `completed`, `canceled`, `refunded`, `expired_unanswered`, `no_show`, `disputed` |
| `payment_status` | `payment_status_enum` | payment lifecycle                | `unpaid`, `held`, `released`, `refunded`                                                                                     |
| `price`          | `numeric`             | canonical amount                 | server-derived for booking drafts                                                                                            |
| `package_id`     | `text`                | selected package tier            | optional                                                                                                                     |
| `requirements`   | `jsonb`               | selected package/request payload | optional                                                                                                                     |
| `note`           | `text`                | client note                      | optional                                                                                                                     |
| `delivery_days`  | `integer`             | delivery estimate                | used in checkout/details timeline                                                                                            |
| `due_at`         | `timestamptz`         | due date                         | shown in booking details timeline                                                                                            |
| `completed_at`   | `timestamptz`         | completion timestamp             | set when work is completed/released                                                                                          |
| `created_at`     | `timestamptz`         | audit timestamp                  | UTC                                                                                                                          |

#### `public.availability_slots`

This table still exists and is still documented in `SUPABASE_SETUP.md`, but the current Flutter booking flow no longer exposes slot-creation screens. Existing rows are treated as historical/legacy support, and `BookingModel` still reads slot timing when `slot_id` is present.

### 2.2 Payment and workflow backend objects

Current server-backed booking/payment flow depends on:

- `rpc_create_booking_draft_validated(...)`
- `qicard_payment_create`
- `qicard_payment_recovery`
- `booking_decline_refund`
- `rpc_submit_delivery`
- `rpc_approve_delivery`
- `process_payment_event_ledger(...)`
- **Booking lifecycle (2026-03-08):** Client cannot cancel after delivery (use "Report Issue" → disputed). `fn_booking_guard` blocks delivered→canceled by client; allows delivered→disputed (client). `rpc_finalize_auto_approval` booking branch calls ledger when review window expires. `admin_resolve_booking_dispute` (admin-only) resolves disputed→completed or refunded.

### 2.3 RLS summary

- clients can see and mutate only their own bookings where allowed by policy
- providers can see and mutate their own incoming bookings where allowed by policy
- payment/ledger side effects are enforced server-side via RPCs and edge functions; the client is not authoritative for privileged transitions

## 3. File Inventory

| File                                                       | Layer      | Description                                                                                         |
| ---------------------------------------------------------- | ---------- | --------------------------------------------------------------------------------------------------- |
| `lib/features/booking/models/booking_model.dart`           | model      | Typed booking row with UTC timestamps, payment status, due date, and legacy slot fallback parsing.  |
| `lib/features/booking/models/payment_return_args.dart`     | model      | Feature re-export for the shared payment callback DTO.                                              |
| `lib/features/booking/services/booking_service.dart`       | service    | Reads bookings, updates status, submits ledger-backed booking actions, fetches single booking rows. |
| `lib/features/booking/data/booking_repository.dart`        | repository | Thin abstraction over `BookingService` plus current-user access.                                    |
| `lib/features/booking/viewmodels/booking_view_model.dart`  | viewmodel  | Orchestrates booking lists, payment creation/recovery, delivery/release actions, and chat handoff.  |
| `lib/features/booking/view/bookings_discovery_screen.dart` | view       | Booking-task discovery surface powered by the home/task feed.                                       |
| `lib/features/booking/view/payment_checkout_screen.dart`   | view       | Direct booking checkout screen; creates draft booking and launches payment flow.                    |
| `lib/features/booking/view/payment_webview_screen.dart`    | view       | Mobile webview payment container for trusted callback flows.                                        |
| `lib/features/booking/view/payment_return_screen.dart`     | view       | Web callback landing screen that validates callback state and triggers recovery.                    |
| `lib/features/booking/view/payment_method_screen.dart`     | view       | Demo/manual payment form used by non-QiCard paths.                                                  |
| `lib/features/booking/view/bookings_list_screen.dart`      | view       | Client/provider booking history list with filtering and pagination.                                 |
| `lib/features/booking/view/booking_details_screen.dart`    | view       | Detailed booking view with CTA resolution, management timeline, and message handoff.                |
| `lib/features/booking/view/widgets/booking_card.dart`      | widget     | Shared summary card for booking rows.                                                               |

## 4. Current Flutter Flow

### 4.1 Checkout

1. A client opens a booking task and starts checkout.
2. `PaymentCheckoutScreen` calls `BookingViewModel.createPaymentForBooking(...)`.
3. `QiCardPaymentService` invokes `qicard_payment_create`.
4. The server validates the task/package/request payload, creates a canonical booking draft, and returns `booking_id`, `form_url`, and correlation identifiers.

### 4.2 Gateway handoff

- **Mobile**: `PaymentWebViewScreen` opens the payment URL and only accepts trusted callback hosts/booking identifiers.
- **Web**: checkout persists `PendingPaymentContext` through `PaymentPendingStore` and redirects the browser in the same tab.

### 4.3 Recovery

- When the gateway returns, the app uses `PaymentReturnArgs` plus stored pending context.
- `PaymentReturnScreen` or `PaymentCheckoutScreen` calls `recoverBookingPaymentWithRetries(...)`.
- Recovery succeeds only when the booking reaches `payment_status = held`.

### 4.4 Post-payment actions

Provider-side actions:

- accept booking
- decline/refund booking
- mark delivered

Client-side actions:

- release booking payment with fee handling
- message provider
- review timeline/history

`BookingDetailsScreen` also embeds `OrderManagementSection` with `WorkLogScope(entityId: booking.id, entityType: 'booking')`.

## 5. Example Snippets

### Create payment-backed booking draft

```dart
final result = await bookingViewModel.createPaymentForBooking(
  taskId: taskId,
  note: note,
  packageId: packageId,
  requirements: packageData,
);
```

### Recover payment after trusted callback

```dart
final recovery = await bookingViewModel.recoverBookingPaymentWithRetries(
  bookingId: bookingId,
);
```

### Load paged history

```dart
await bookingViewModel.loadBookingsAsClient();
await bookingViewModel.loadMoreBookingsAsProvider();
```

## 6. Error Handling and Notes

Current mapped booking/payment messages include:

- task not bookable
- self-booking forbidden
- invalid package
- slot unavailable
- booking create/recovery failure

Additional notes:

- the client can create repeat slotless direct bookings for the same service task
- slot exclusivity still applies to slot-based bookings through database constraints/policies
- `BookingModel.dueAtUtc` falls back to `availability_slots.starts_at` for historical slot-based rows
- `PaymentMethodScreen` remains in the repo for demo/manual payment paths, but QiCard is the default provider in `main.dart`

## 7. Testing Checklist

- create a booking draft for a booking task and verify checkout opens correctly
- on web, confirm same-tab redirect returns to `PaymentReturnScreen`
- on mobile, confirm `PaymentWebViewScreen` accepts only trusted callback URLs
- verify successful recovery reaches `payment_status = held`
- verify repeat slotless direct bookings for the same client/task pair are allowed
- verify provider can accept/decline/deliver and client can release after delivery
- verify booking details show due date, delivery days, and management timeline correctly
- verify legacy slot-based bookings still render safely when `slot_id` is present

**Added in v2.13** — 2026-02-16

## Purpose

Provides freelancers with a **single view** to manage all active work — both tender-based tasks and booking-based jobs — using a normalized model. The module introduces versioned work contracts for accountability and change/extension request workflows.

## Architecture

```
lib/features/work/
├── models/
│   ├── unified_work_item_model.dart     # Maps vw_unified_work_items view
│   ├── work_contract_model.dart         # Versioned scope snapshot
│   ├── change_request_model.dart        # Scope/price/days change proposal
│   └── extension_request_model.dart     # Deadline extension proposal
├── services/
│   └── work_management_service.dart     # Supabase queries for work items; delegates booking logic to BookingService
├── viewmodels/
│   └── work_item_details_view_model.dart  # Screen-scoped ChangeNotifier
└── view/
    ├── work_item_details_screen.dart     # 3-tab interface (Overview, Extensions, Contract)
    └── widgets/
        ├── submit_delivery_modal.dart    # Bottom sheet for delivery submission
        ├── request_extension_modal.dart  # Bottom sheet for extension requests
        └── review_delivery_modal.dart    # Client approval / revision request modal
```

## Data Flow

```
UI (WorkItemDetailsScreen)
  └── Consumer<WorkItemDetailsViewModel>
        └── WorkItemDetailsViewModel (ChangeNotifier)
              └── WorkManagementService
                    └── Supabase (vw_unified_work_items, work_contracts, RPCs)
```

**Key:** The ViewModel is registered at **screen scope** via `ChangeNotifierProvider` inside the screen's `build()` method. It is NOT a global provider.

## Database Objects

| Object                       | Type    | Purpose                                                                                                                                                                                                                                                                                       |
| ---------------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `vw_unified_work_items`      | View    | UNION ALL of tasks (in progress + awarded pending), bookings, and direct_offers; dispute override; security_invoker; see SUPABASE_SETUP.md §6.4.                                                                                                                                            |
| `work_contracts`             | Table   | Versioned scope snapshots (price, days, description)                                                                                                                                                                                                                                          |
| `change_requests`            | Table   | Scope/price/days change proposals                                                                                                                                                                                                                                                             |
| `extension_requests`         | Table   | Deadline extension proposals                                                                                                                                                                                                                                                                  |
| `rpc_submit_delivery`        | RPC     | Atomic delivery: status + timestamp; for bookings, `confirmed`/`paid_request_pending` → `active` then `delivered`                                                                                                                                                                             |
| `rpc_request_revision`       | RPC     | Client revision with limit check (status=delivered, revisions_used < revisions_total). Revision errors (no revisions remaining, not delivered) are mapped via ErrorMapper and shown in the Review Delivery modal.                                                                                                                                                                                                                                                              |
| `rpc_accept_change_request`  | RPC     | Accept change, create new contract version                                                                                                                                                                                                                                                    |
| `rpc_approve_delivery`       | RPC     | Client approves delivered work for `entity_type` task, booking, or direct_offer; when `payment_status=held`, calls ledger `release_with_fee` (stable idempotency key + FOR UPDATE) then sets `completed`. See SUPABASE_SETUP §9.5 and [Wallet Feature](DEVELOPER_GUIDE/Wallet_Feature.md) §4. |
| `rpc_finalize_auto_approval` | RPC     | Auto-approve after review window                                                                                                                                                                                                                                                              |
| `trg_activate_contract`      | Trigger | Auto-create contract on booking confirmation                                                                                                                                                                                                                                                  |
| `trg_freeze_contract_fields` | Trigger | Block direct scope changes on active work                                                                                                                                                                                                                                                     |

## Enums (app_enums.dart)

- `WorkItemType` — `task`, `booking`
- `UnifiedWorkStatus` — `pending`, `pendingPayment`, `requestPending`, `active`, `delivered`, `completed`, `canceled`, `disputed`, `unknown`

## Key Patterns

1. **Parallel Data Fetching**: `loadData()` uses `Future.wait` with 5 concurrent queries
2. **Single source of truth**: Dashboard and work detail read only from `vw_unified_work_items`. No fallback mappers; when the view returns no row for an id/type, the app shows "Work item not found".
3. **Review Ownership Contract**:
   - `vw_unified_work_items.needs_review` is a raw delivered-state flag, not an authorization result.
   - Client-facing review UI must combine that flag with role-derived permissions before showing review sections or CTAs.
   - Dashboard/work screens use `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/models/work_item.dart` helpers:
     - `actionableNeedsReview` → current role can review now
     - `awaitingCounterpartyReview` → delivered work is waiting on the other side
   - Provider/freelancer users should see `Awaiting Client Review` in dashboard cards and `Waiting for Client Review` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/view/work_item_details_screen.dart`.
4. **Booking chat**: From work detail, booking work opens chat via plain DM (no `taskId`); task work uses task-linked RPC. See `.TODO/Archive/WorkExectuion/DECISION_work_chat_contract_2026-03-04.md`.
5. **Status Mapping**:
   - `declineBooking` maps to DB `refunded` status (per `fn_booking_guard` transitions).
   - `paid_request_pending` maps to `UnifiedWorkStatus.requestPending` to expose actions (Accept/Decline).
6. **Observability**:
   - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/viewmodels/work_item_details_view_model.dart` logs role/status context on detail load so CTA mismatches can be traced from AppLogger output.
7. **Error Handling**:
   - Work detail actions set screen-safe user-facing errors in the ViewModel and log full traces through `AppLogger`; review action routing is role-gated before any modal is opened.

## Verification

- **Unified Work View (4-branch, direct offers, no fallbacks):** Plan: `.TODO/PLAN_UnifiedWorkView_2026-03-08_CRITIC.md`; Execution: `.TODO/EXECUTION_LOG_PLAN_UnifiedWorkView_2026-03-08_CRITIC.md`; Master report: `.TODO/MASTER_REPORT_2026-03-08_UnifiedWorkView.md`; Contract: `.TODO/contract_vw_unified_work_items.md`.
- Plan: `.TODO/PLAN_Freelancer_Unified_Flow_2026-02-16.md`
- Architect Patch: `.TODO/ARCHITECT_PATCH_2026-02-16_Unified_Flow.md`
- CodeGuard Review: `.TODO/CODEGUARD_REVIEW_2026-02-16_Freelancer_Unified_Flow.md`
- Regression tests:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/dashboard/work_tab_test.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/work_item_model_test.dart`

---

# Hardened Payment Gateway (v2.20)

## 1. Overview

The Hardened Payment Gateway is a security-first payment orchestration layer that centralizes payment authorization in Supabase Edge Functions. It uses `payment_intents`, `payment_events`, and `orphan_payments` to ensure idempotency, audit every gateway event, and prevent unauthorized fund movements.

### Key Principles

- **Server-Side Authorization**: Only Edge Functions create or update payment intents (via `service_role`).
- **Intent path**: When the gateway sends `additionalInfo.intent_id`, the webhook (`qicard_webhook_handler`) looks up the intent, inserts into `payment_events`, validates amount/currency, then calls the ledger with `payment_intent_id` in `p_meta`; `journal_entries.meta` stores it for forensics.
- **Append-only audit**: `payment_events` is INSERT-only for `service_role`; a trigger blocks UPDATE/DELETE.
- **Orphan handling**: Events with no matching intent or amount mismatch are written to `orphan_payments` and never trigger the ledger.

**Contracts and logging:** `.TODO/improvement_the_system/ImplementReady/24_hardened_paymentLinking_system/CONTRACT_HardenedPaymentLinking.md`, `LOGGING_AND_SECRETS.md`.

## 2. Database Mapping

See **SUPABASE_SETUP.md** §5.23–5.25 for full column lists.

- **`payment_intents`**: State and metadata (entity_type, entity_id, payer_id, receiver_id, gross_amount, currency, status, signature, paid_at, gateway_intent_id). RLS: SELECT for payer; INSERT/UPDATE only `service_role`.
- **`payment_events`**: One row per webhook hit when intent is known; `gateway_event_id` UNIQUE, `intent_id` FK to payment_intents. RLS: INSERT `service_role` only; trigger enforces append-only.
- **`orphan_payments`**: Gateway events not linked to a valid intent (reason: intent_not_found, amount_mismatch); optional `investigated` for admin queue.

## 3. Webhook Intent Path (QiCard → Edge)

Canonical webhook: **`qicard_webhook_handler`**. When payload has `additionalInfo.intent_id` (valid UUID):

1. Look up `payment_intents` by `id` or `gateway_intent_id` (= paymentId).
2. If not found → INSERT `orphan_payments` (reason: intent_not_found), return 200.
3. INSERT `payment_events` (gateway_event_id, intent_id, event_type, payload); on duplicate gateway_event_id, treat as idempotent.
4. If intent.status already `succeeded` → return 200 (idempotency).
5. Validate amount and currency against intent; on mismatch → INSERT `orphan_payments` (amount_mismatch), return 200.
6. Call `submitGatewayEscrowHold` or `submitDirectOfferGatewayEscrow` with `paymentIntentId`; RPCs merge it into `journal_entries.meta`.
7. UPDATE `payment_intents` SET status = 'succeeded', paid_at = now().

Internal HMAC verification (create edge writes signature, webhook verifies) is planned; see LOGGING_AND_SECRETS.md.

## 4. Implementation Flow (Flutter)

1. **Create draft / accept offer**: Booking draft or direct offer accepted, unpaid.
2. **Create payment**: App calls `qicard_payment_create` (booking) or `qicard_payment_create_direct_offer` (direct offer). Edge returns `intent_id` and `form_url` when it inserts a row into `payment_intents`.
3. **Realtime (when intent_id present)**: UI subscribes to `payment_intents(id)` via `PaymentService.streamPaymentIntentStatus(intentId)`. Booking: `PaymentCheckoutScreen`; direct offer: `PaymentWebViewScreen` (receives `paymentIntentStatusStream`).
4. **Webview**: User completes payment at `form_url`. On success, webhook updates intent and ledger; Realtime delivers status → UI pops with success. If Realtime is not used (no intent_id), app relies on callback URL and recovery.

## 5. Security & Idempotency

- **RLS**: Clients can only SELECT their own `payment_intents`. Only `service_role` can INSERT/UPDATE payment_intents and INSERT payment_events.
- **Append-only**: Trigger `trg_payment_events_append_only` rejects UPDATE/DELETE on `payment_events`.
- **Ledger audit**: `process_payment_event_ledger` (gateway_escrow) and `process_gateway_escrow_direct_offer` persist `payment_intent_id` from `p_meta` into `journal_entries.meta` for forensics.

---

# Finance & Payment Ledger Reference

**Added in v2.16** — 2026-02-24

**Ledger event flow (09):** Diagram, risk register, contract, smoke checklist and withdrawal runbook: `.TODO/improvement_the_system/Done/09_ledger-event-flow/` — see `06_DIAGRAM_FINAL.md`, `03_RISK_REGISTER.md`, `CONTRACT_ledger_event_flow.md`, `SMOKE_CHECKLIST_AND_RUNBOOK.md`. Forensics: `p_meta` includes `session_id` and `request_id` per contract; the app builds them via `lib/core/utils/ledger_forensics.dart` and `LedgerService` merges them into every RPC call. `admin_adjustment` is scoped out for this release.

## 1. Human-Readable Overview

The Finance module implements a **Double-Entry Ledger System** to replace the legacy simple log. It ensures that every transaction is balanced (Debits = Credits) and provides a secure, auditable history of all user funds and system fees.

Key features:

- **Escrow Enforcement**: Payments for bookings/tasks are held in a platform account until completion.
- **Legacy Protection**: The old `wallet_transactions` table is frozen (read-only) to preserve history without risk of drift.
- **Idempotency**: Prevents duplicate charges by using unique keys from the payment gateway.
- **Approve delivery (escrow release):** Idempotent under retry; the server uses a stable key and `FOR UPDATE` so duplicate approval calls do not double-release funds (see diagram 16 and `rpc_approve_delivery` in SUPABASE_SETUP).
- **Real-time Balances**: User available/escrow balances are aggregated live from ledger lines.

## 2. Supabase Integration

### 2.1 Ledger Tables

| Table             | Purpose                                                     | Notes                                     |
| ----------------- | ----------------------------------------------------------- | ----------------------------------------- |
| `accounts`        | Chart of accounts (User wallets, Platform escrow, Revenue). | Linked to `profiles.id` where applicable. |
| `journal_entries` | The "Event" record (Header).                                | Links to `booking` or `task` via ID.      |
| `ledger_lines`    | The atomic Debit/Credit entries.                            | Direction: `DEBIT` or `CREDIT`.           |

### 2.2 Orchestration (RPC)

**`process_payment_event_ledger(event_type, related_entity_type, related_entity_id)`**

- **Flow**: App → Payment Gateway (QiCard/Demo) → Successful Result → Call this RPC.
- **Safety**: Wrapped in a DB transaction; if Debits != Credits, the whole batch fails.

### 2.3 Balance View

**`vw_wallet_balances_user`** (canonical user-scoped view; app uses this only)

- Security invoker: user sees only own row. Dynamically aggregates balance by summing ledger lines for that user's accounts.
- **Available**: Sum of credits to `user_available:uuid`.
- **Escrow (Held)**: Sum of credits to `platform_escrow` where linked to the user's jobs.
- Activity: `vw_wallet_activity_user`. See [Wallet Feature](DEVELOPER_GUIDE/Wallet_Feature.md).

## 3. Flutter Integration

### 3.1 Payment Flow

**QiCard (default)**: `PaymentCheckoutScreen` creates a server-validated booking draft through `qicard_payment_create`, launches the gateway form, then relies on webhook/recovery to move the booking to `payment_status=held`. Web uses same-tab redirect plus `PaymentReturnScreen`; mobile uses `PaymentWebViewScreen`.

**Demo**: `processPayment()` is still available through `DemoPaymentService`, but the live booking purchase path is the server-backed QiCard flow.

```dart
final draft = await bookingViewModel.createPaymentForBooking(
  taskId: taskId,
  packageId: packageId,
  requirements: packageData,
);

if (draft.formUrl != null) {
  // Open payment flow, then recover until payment_status == held.
  final recovery = await bookingViewModel.recoverBookingPaymentWithRetries(
    bookingId: draft.bookingId!,
  );
}
```

### 3.2 Error Handling

- **`insufficient_funds`**: (Future withdrawal flow) Friendly message to user.
- **`frozen_legacy`**: Thrown if attempting to use old `wallet_transactions` API.

## 4. Testing Checklist

- [x] New account creation: Auto-created when a user receives funds.
- [x] Escrow hold: Check `platform_escrow` balance increases on booking.
- [x] Release: Check `user_available` increases and `platform_escrow` decreases on completion.
- [x] Fee calculation: Verification of `system_revenue` account credits.
- [x] Idempotency: Retrying the same transaction ID results in `already_processed` check.

## 5. Dashboard-App Link Runtime Guards (March 2026)

This release adds app-side enforcement and trust/safety UI so dashboard actions are visible in Flutter immediately.

### 5.1 App Guard and Moderation

- `lib/core/services/account_guard_service.dart` evaluates `profiles.account_status` and `profiles.force_logout_after`.
- `lib/main.dart` runs guard checks on startup/resume and routes to:
  - `lib/features/auth/view/account_restricted_screen.dart` for suspended/banned users.
  - login flow for revoked sessions (`force_logout_after > session_iat`).
- Sensitive actions now check guard state before execution in:
  - `lib/features/chat/viewmodels/chat_view_model.dart`
  - `lib/features/wallet/viewmodels/wallet_view_model.dart`
  - `lib/features/tasks/view/task_details_screen.dart`

### 5.2 Public System Config Wiring

- `lib/core/services/system_config_service.dart` reads public config via RPC `get_public_system_config`.
- `lib/core/providers/system_config_view_model.dart` exposes runtime flags to UI:
  - maintenance mode
  - minimum app version
  - disable signups
  - app banner
- App shell/auth integration:
  - `lib/features/auth/view/maintenance_screen.dart`
  - `lib/features/auth/view/update_required_screen.dart`
  - signup/login UX in `lib/features/auth/view/signup_screen.dart` and `lib/features/auth/view/login_screen.dart`
  - global banner in `lib/app/main_navigation_screen.dart`

### 5.3 Reports and Disputes UX

- New safety MVVM layer:
  - `lib/features/safety/services/report_service.dart`
  - `lib/features/safety/services/dispute_service.dart`
  - `lib/features/safety/viewmodels/safety_view_model.dart`
- UI entry points:
  - Task reporting in `lib/features/tasks/view/task_details_screen.dart`
  - Chat/user reporting in `lib/features/chat/view/chat_screen.dart`
  - Booking dispute submission in `lib/features/booking/view/booking_details_screen.dart`
  - Public profile reporting in `lib/features/profile/view/public_profile_screen.dart`
  - Support/safety shortcut in `lib/features/profile/view/settings_screen.dart`
- **Dispute guard on Approve:** `SafetyViewModel.hasOpenDisputeForTask`, `hasOpenDisputeForBooking`, `hasOpenDisputeForDirectOffer` gate the Approve/Review button on booking details, work item details, and direct offer details. When an open dispute exists, the button is disabled (fail-closed on check error).

#### Dispute entry points (Plan 14a)

- **Booking:** "Report Issue" on booking details when booking is delivered and no open/active dispute; submits via `SafetyViewModel.submitDispute(taskId: booking.taskId, ...)`.
- **Task:** "Report Issue" on work item details when source is task, status is in progress or delivered, and no open/active dispute; submits via `SafetyViewModel.submitDispute(taskId: entityId, ...)`.
- **Direct offer:** "Report Issue" on direct offer details when offer is active or delivered and no open/active dispute; submits via `SafetyViewModel.submitDispute(directOfferId: offerId, ...)`. DisputeService uses `rpc_submit_dispute` for both task and direct_offer (eligibility and single-open/active enforced in DB).

#### Frozen behaviour (Plan 14a)

When a dispute is **open** or **active**, the entity is treated as Frozen for lifecycle actions:

- **rpc_submit_delivery** and **rpc_request_revision** raise `Cannot submit delivery: dispute in progress` / `Cannot request revision: dispute in progress` and do not change state.
- **rpc_approve_delivery** and **rpc_finalize_auto_approval** already block release when an open/active dispute exists.

ErrorMapper maps these RPC messages to user-friendly text; WorkManagementService / SafetyViewModel surface them in the UI.

#### Dispute lifecycle (escrow guard, single source, UI)

1. **Escrow guard:** RPCs `rpc_approve_delivery` and `rpc_finalize_auto_approval` block release when an open/active dispute exists for the task (or booking’s task, or direct_offer). No funds are released while a dispute is open or active.
2. **Single source for “has dispute”:**
   - **Dashboard / CTA:** Disputed state for list and primary action (e.g. Submit Evidence) comes from `vw_unified_work_items.unified_status = 'disputed'` (dashboard repository, permission service).
   - **Approve/Review button:** Detail screens use **SafetyViewModel** → **DisputeService** for the live check (`hasOpenDisputeForTask`, `hasOpenDisputeForBooking`, `hasOpenDisputeForDirectOffer`) to enable or disable the button.
3. **UI:** Booking details `_ApproveWithDisputeGuard` and `_BookingDisputeBanner`; work item details `_ReviewWithDisputeGuard`, `_ReportIssueGuard` (task, direct_offer, and **booking** when work item is a booking), and `_DisputeBannerContent`; direct offer details `_ApproveWithDisputeGuard`, `_DirectOfferDisputeBanner`, and `_ReportIssueGuardDirectOffer`. Plan: `.TODO/PLAN_DisputeLifecycle_2026-03-08.md`, `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`.
4. **Banner copy:** When a dispute exists, screens show status-specific text: **open** → "Dispute under review. Approve and release disabled."; **active** → "Work frozen — in dispute." (from `SafetyViewModel.getDisputeStatusForTask` / `getDisputeStatusForBooking` / `getDisputeStatusForDirectOffer`).
5. **Unified view:** `vw_unified_work_items` shows `unified_status = 'disputed'` only when a linked dispute has `status IN ('open', 'active')` (migration `20260308190000_vw_unified_work_items_dispute_open_active_only.sql`). Resolved or canceled disputes do not mark the item as disputed.

---

---

# Tender Task Lifecycle

## 1. Human Explanation

The tender task lifecycle manages the complete flow of a task posted as a "tender" (bidding) type from creation through completion. It includes:

1. **Task Creation**: Client posts a task with requirements
2. **Offer Submission**: Freelancers submit offers with price and timeline
3. **Offer Award**: Client selects a freelancer (award step)
4. **Payment Window**: Client has 48 hours to complete payment
5. **Work Execution**: Freelancer works on the task
6. **Delivery & Review**: Freelancer submits, client reviews
7. **Completion**: Funds released to freelancer

### Guardrails (March 2026)

To prevent race conditions and ensure fairness:

1. **Optimistic Concurrency Control**: When awarding, the client sends the price they saw. If the freelancer updated their offer in the meantime, the award fails with a PRICE_MISMATCH error.

2. **Idempotency**: Double-clicking the Award button won't create duplicate awards - the second call returns 'already_accepted'.

3. **Auto-Expiry**: Offers that aren't paid within 48 hours automatically revert to 'open' status via a cron job.

4. **Audit Logging**: All price mismatch attempts and award actions are logged to `admin_logs` for security monitoring.

## 2. Technical Overview

### State Machine

```
open → assigned (award) → in_progress (payment) → delivered (submit) → closed (approve)
                    ↓
              [auto-expire after 48h if unpaid]
                    ↓
                  open (revert)
```

### Database Schema

**task_requests table**:

- `status`: pending → accepted → rejected/expired
- `payment_status`: unpaid → held → released/refunded
- `awarded_at`: Timestamp when accepted
- `payment_deadline`: 48 hours from award
- `fee_rate_applied_bps`: Locked platform fee at award time
- `fee_amount`, `net_amount`: Pre-calculated for transparency

**Key Indexes**:

- `idx_task_requests_awarded_unpaid`: Optimizes cron expiry queries
- `idx_one_accepted_per_task`: Enforces only one accepted offer per task

### RPC Functions

**award_task_offer(p_request_id, p_client_id, p_expected_price_cents)** (3 params; 2-param overload removed in 20260308180100):

- Validates ownership (task owner only)
- Checks for existing accepted offers (idempotency)
- Validates price if expected_price_cents provided
- **Does not assign freelancer:** sets task status to `assigned` and `task_requests.payment_status = 'unpaid'`; freelancer is set only in `pay_awarded_offer` (migration 20260308180000).
- Creates notifications to both parties
- Logs to admin_logs

**Inbox Pay Now:** `TaskService.getOffersReceived` includes both pending and accepted+unpaid offers (filter: `status.eq.pending` or `status.eq.accepted` and `payment_status.eq.unpaid`) so the client sees awarded offers in the Inbox with a Pay Now button. See `lib/features/tasks/services/task_service.dart`.

**cleanup_expired_awards()**:

- Runs every 10 minutes via pg_cron
- Finds offers with status='accepted', payment_status='unpaid', payment_deadline < now - 1h
- Reverts task to 'open'
- Notifies both parties
- Logs to admin_logs

### Flutter Implementation

**TaskRequestsService** (`lib/features/tasks/services/task_requests_service.dart`):

- `awardOffer(offerId, expectedPriceCents)`: Calls RPC, throws PriceMismatchException
- `PriceMismatchException`: Custom exception with expected/actual prices
- `OfferAlreadyAcceptedException`: Idempotency hit

**TaskRequestsViewModel** (`lib/features/tasks/viewmodels/task_requests_view_model.dart`):

- `award(requestId, expectedPriceCents)`: Business logic, error mapping
- `acceptOffer(request, expectedPriceCents)`: UI-friendly method

**DashboardViewModel** (`lib/features/dashboard/viewmodels/dashboard_view_model.dart`):

- `awardOffer(offer)`: Passes `expectedPriceCents: (offer.price * 100).round()` to `TaskService.awardOffer()` for Inbox tab awards (optimistic price lock)

**AwardExpirationMonitor** (`lib/features/tasks/viewmodels/award_expiration_monitor.dart`):

- Live countdown timer
- Urgency levels (relaxed/urgent/critical/expired)
- Proper disposal to prevent memory leaks

**UI Components**:

- `DashboardOfferCard`: Shows countdown badge for accepted unpaid offers
- `RequestsListScreen`: Handles price mismatch dialog, refresh on mismatch

## 3. Error Handling

### Price Mismatch Flow

1. Client clicks Award (price captured at click time)
2. Freelancer updated offer milliseconds before
3. RPC returns PRICE_MISMATCH error
4. Service throws PriceMismatchException
5. ViewModel catches and re-throws
6. UI shows price mismatch dialog with old vs new price
7. User can cancel or refresh to see updated offer

### UI Implementation

```dart
try {
  await viewModel.award(request.id, expectedPriceCents: priceCents);
} on PriceMismatchException catch (e) {
  showPriceMismatchDialog(e); // Shows old vs new price
}
```

## 4. Configuration

**system_config keys**:

- `tender_payment_timeout_hours`: Default 48 hours (configurable)
- `platform_fee_bps`: Default 1000 (10%, locked at award time)

## 5. Testing

### Unit Tests

- `test/unit/tender/award_expiration_monitor_test.dart`: Timer, urgency levels
- `test/unit/tender/task_requests_service_test.dart`: Price parsing, exceptions
- `test/unit/tender/task_requests_view_model_test.dart`: Flow logic

### Fixtures

- `test/fixtures/tender_tasks.dart`: Complete set of task/request fixtures

### Smoke Test

- `.TODO/SMOKE_TEST_TENDER.md`: 5-minute manual verification

## 6. Monitoring

### Rollback Triggers

- Query: `SELECT COUNT(*) FROM task_requests WHERE status='accepted' AND payment_status='unpaid' AND awarded_at < NOW() - INTERVAL '72 hours'`
- Alert if > 5% of assigned tasks are stuck > 72 hours

### Admin Logs

- `PRICE_MISMATCH_ATTEMPT`: Security signal for bidding attacks
- `OFFER_AWARDED`: Successful awards
- `AWARD_AUTO_EXPIRED`: Cron job expirations

## 7. Contract

See `.TODO/CONTRACT_accept_task_request_v2.md` for complete RPC contract.

---

# Storage Configuration & Caching Reference (v2)

## Overview

This section documents the centralized storage configuration and signed URL caching system implemented for secure, efficient storage access.

## SharedStorageConfig

**Location**: `lib/core/config/storage_config.dart`

Centralized TTL values for consistent signed URL expiry across all storage buckets:

| Bucket             | TTL             | Purpose                       |
| ------------------ | --------------- | ----------------------------- |
| `chat-attachments` | 3600s (1 hour)  | Sensitive chat files          |
| `avatars`          | 7200s (2 hours) | Profile images (discoverable) |
| `task-images`      | 7200s (2 hours) | Task images (discoverable)    |

### TTL Alignment Reference

| Data Type        | Bucket           | TTL         | Cache Duration | Refresh Window      |
| ---------------- | ---------------- | ----------- | -------------- | ------------------- |
| Chat Attachments | chat-attachments | 3600s (1hr) | 90min          | 30min before expiry |
| Avatars          | avatars          | 7200s (2hr) | 90min          | 30min before expiry |
| Task Images      | task-images      | 7200s (2hr) | 90min          | 30min before expiry |

**Note**: Cache duration (90min) is intentionally less than minimum TTL (3600s) to ensure URLs are refreshed before they expire.

**Usage**:

```dart
// Get TTL for any bucket
final ttl = SharedStorageConfig.ttlForBucket('chat-attachments');

// Use in service
final url = await supabase.storage
  .from('chat-attachments')
  .createSignedUrl(path, SharedStorageConfig.chatAttachmentTtlSeconds);
```

## SignedUrlCache

**Location**: `lib/core/utils/signed_url_cache.dart`

In-memory cache for signed URLs to prevent redundant API calls:

- **Success cache**: 90 minutes (refresh before 2hr expiry)
- **Error cache**: 30 seconds (prevent retry storms)
- **Max size**: 1000 entries (eviction when exceeded)

**Usage**:

```dart
// Check cache first
final cached = SignedUrlCache.get(storagePath);
if (cached != null) {
  return cached; // Use cached URL
}

// Generate and cache
final url = await generateSignedUrl(storagePath);
SignedUrlCache.set(storagePath, url);

// Handle errors
if (SignedUrlCache.hasError(storagePath)) {
  return errorPlaceholder; // Don't retry immediately
}

// On error, cache it
try {
  final url = await generateSignedUrl(storagePath);
  SignedUrlCache.set(storagePath, url);
} catch (e) {
  SignedUrlCache.setError(storagePath);
}
```

## Widget Integration

**SignedAvatar** (`lib/core/widgets/signed_avatar.dart`):

- Automatically uses `SignedUrlCache`
- TTL: `SharedStorageConfig.avatarTtlSeconds`

**SignedImage** (`lib/core/widgets/signed_image.dart`):

- Automatically uses `SignedUrlCache`
- TTL: `SharedStorageConfig.taskImageTtlSeconds`

**AttachmentMessageTile** (`lib/features/chat/attachments/widgets/attachment_message_tile.dart`):

- Uses `SignedUrlCache` for chat attachments
- Shows loading/error states
- Caches errors to prevent retry storms
- TTL: `SharedStorageConfig.chatAttachmentTtlSeconds`

## RLS v2 Integration

The cache works in conjunction with hardened RLS policies:

1. **Cache hit**: No API call, instant display
2. **Cache miss**: Calls `createSignedUrl`
3. **RLS check**: Server validates access via `can_access_*` helpers
4. **403 error**: Cached for 30 seconds, shows error state
5. **Success**: Cached for 90 minutes, displays image

## Testing

- Cache behavior: `test/unit/core/signed_url_cache_test.dart`
- Storage RLS: `test/storage_rls_test.dart`
- Full harness: `test/rls/storage_rls_test_harness.dart`

---

# Task Request (Bid) Flow

**Added in v2.18** — 2026-03-06 (Phase 4.4 Complete)

**Purpose**: Complete documentation for the Task Request (Bid/Offer) lifecycle management system, covering submission, award, payment, and work activation.

**Related Documents**:

- API Contract: `.TODO/improvement_the_system/ImplementReady/04_task-request-bid-flow/API_CONTRACT.md`
- Threat Model: `.TODO/improvement_the_system/ImplementReady/04_task-request-bid-flow/THREAT_MODEL.md`
- Execution Log: `.TODO/EXECUTION_LOG_TaskRequestBidFlow.md`

---

## 1. Human-Readable Overview

The Task Request (Bid) Flow enables freelancers to submit offers on tender-type tasks, and clients to review, accept/reject, and pay for those offers. It implements a **two-step award flow** with payment escrow:

### Bid Lifecycle

```
Freelancer submits offer
        ↓
    pending (24h expiration window)
        ↓
Client reviews offers
        ↓
   ┌────┴────┐
   ↓         ↓
accept    reject
   ↓         ↓
accepted  rejected
(payment   (conversation
window)    created)
   ↓
pay_awarded_offer()
   ↓
payment_status='held'
   ↓
task.status='in_progress'
   ↓
Work begins
```

### Key Concepts

1. **Bid Submission**: Freelancers submit one active offer per task (24-hour response window)
2. **Bid Replacement**: Freelancers can withdraw and replace their pending offer with updated terms
3. **Two-Step Award**:
   - Step 1: Client awards offer (locks freelancer, sets payment deadline)
   - Step 2: Client completes payment (funds held in escrow, work begins)
4. **Auto-Expiry**: Unpaid offers automatically expire after 48-hour payment window
5. **Optimistic Concurrency**: Price validation prevents race conditions during award

---

## 2. Architecture

### File Structure

```
lib/features/tasks/
├── models/
│   └── task_request_model.dart       # TaskRequest entity with OfferStatus/PaymentStatus
├── services/
│   └── task_requests_service.dart    # Supabase RPC calls, error mapping
├── viewmodels/
│   ├── task_requests_view_model.dart # MVVM state holder, two-step award flow
│   └── award_expiration_monitor.dart # Live countdown timer for payment deadline
├── view/widgets/requests/
│   ├── requests_list_screen.dart     # Owner view: accept/reject offers
│   ├── submit_request_sheet.dart     # Freelancer view: submit/replace offer
│   └── widgets/
│       ├── request_tile.dart         # Individual offer display
│       ├── expiration_countdown.dart # Payment deadline countdown
│       └── payment_status_badge.dart # Payment state indicator
└── exceptions/
    └── offer_exceptions.dart         # PriceMismatchException, OfferAlreadyAcceptedException
```

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │  SubmitOffer │───▶│   Service   │───▶│  replace_task_request│ │
│  │    Sheet    │    │   (RPC)     │    │  (update in place)   │  │
│  └─────────────┘    └─────────────┘    └─────────────────────┘  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │  AwardFlow  │───▶│   Service   │───▶│  accept_task_request │  │
│  │   (2-step)  │    │   (RPC)     │    │  (award + payment)   │  │
│  └─────────────┘    └─────────────┘    └─────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                      │
                      ▼
            ┌─────────────────┐
            │   SUPABASE RPC   │
            │  (SECURITY       │
            │   DEFINER)       │
            └────────┬────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
┌─────────────┐ ┌─────────┐ ┌─────────────┐
│task_requests│ │  tasks  │ │conversations│
└─────────────┘ └─────────┘ └─────────────┘
```

---

## 3. Database Schema

### task_requests Table (23 columns)

| Column                 | Type        | Purpose                                        |
| ---------------------- | ----------- | ---------------------------------------------- |
| `id`                   | UUID        | Primary key                                    |
| `task_id`              | UUID        | FK to tasks                                    |
| `freelancer_id`        | UUID        | FK to profiles (canonical)                     |
| `bidder_id`            | UUID        | Legacy column (mirrored from freelancer_id)    |
| `client_id`            | UUID        | Denormalized task owner for queries            |
| `price`                | NUMERIC     | Offered price                                  |
| `days`                 | INTEGER     | Delivery duration                              |
| `duration_days`        | INTEGER     | Legacy column (synced to days)                 |
| `note`                 | TEXT        | Optional message                               |
| `message`              | TEXT        | Legacy column (synced to note)                 |
| `status`               | TEXT        | `pending`, `accepted`, `rejected`, `withdrawn` |
| `payment_status`       | TEXT        | `unpaid`, `held`, `released`, `refunded`       |
| `created_at`           | TIMESTAMPTZ | Creation timestamp                             |
| `updated_at`           | TIMESTAMPTZ | Last update timestamp                          |
| `deleted_at`           | TIMESTAMPTZ | Soft delete (withdrawn offers)                 |
| `awarded_at`           | TIMESTAMPTZ | When offer was accepted                        |
| `awarded_by`           | UUID        | Who accepted the offer                         |
| `payment_deadline`     | TIMESTAMPTZ | Payment window expiration (48h default)        |
| `fee_rate_applied_bps` | INTEGER     | Platform fee rate locked at award time         |
| `fee_amount`           | BIGINT      | Calculated fee in cents                        |
| `net_amount`           | BIGINT      | Freelancer payout in cents                     |

### Key Indexes

| Index                                        | Purpose                                                   |
| -------------------------------------------- | --------------------------------------------------------- |
| `idx_task_requests_awarded_unpaid`           | Optimizes cron expiry queries                             |
| `idx_one_accepted_per_task`                  | Partial unique index enforces one accepted offer per task |
| `uq_task_requests_one_active_per_freelancer` | One active offer per freelancer per task                  |

---

## 4. RPC Functions

### 4.1 accept_task_request (Award)

```sql
CREATE OR REPLACE FUNCTION accept_task_request(
    p_task_id UUID,
    p_request_id UUID,
    p_expected_price_cents BIGINT DEFAULT NULL
)
RETURNS TEXT  -- 'accepted' or 'already_accepted'
```

**Purpose**: Accepts a pending offer (Step 1 of two-step award flow)

**Key Features**:

- **Idempotency**: Returns 'already_accepted' on retry
- **Price Validation**: Raises PRICE_MISMATCH if offer changed since viewing
- **Audit Logging**: Logs to admin_logs (PRICE_MISMATCH_ATTEMPT, OFFER_ACCEPTED)
- **Side Effects**:
  - Sets status='accepted', payment_status='unpaid'
  - Sets awarded_at, payment_deadline (48h default)
  - Locks fee_rate_applied_bps, pre-calculates fee_amount/net_amount
  - Updates tasks.status='assigned'
  - Creates activity_log entry

### 4.2 reject_task_request

```sql
CREATE OR REPLACE FUNCTION reject_task_request(
    p_task_id UUID,
    p_request_id UUID
)
RETURNS UUID  -- conversation_id
```

**Purpose**: Rejects a pending offer and creates conversation for follow-up

**Side Effects**:

- Sets status='rejected'
- Creates or reuses task-linked conversation
- Inserts 'offer_rejected' message
- Sends notification to freelancer

### 4.3 replace_task_request

```sql
CREATE OR REPLACE FUNCTION replace_task_request(
    p_task_id UUID,
    p_freelancer_id UUID,
    p_message TEXT,
    p_price NUMERIC,
    p_days INTEGER
)
RETURNS VOID
```

**Purpose**: Updates the caller's existing pending offer **in place** (price, days, note, updated_at). No second row is created; avoids unique constraint `uq_task_requests_one_active_per_freelancer`. Final behavior from migration `20260322000005_replace_task_request_update_in_place.sql`.

**Authorization**:

- Caller must be the offer owner (p_freelancer_id = auth.uid()). No active_role gate.
- Task must be 'open' and not owned by caller.

**Side Effects**:

- UPDATE on the single pending task_requests row for this task and caller; no new row inserted.

**Errors** (for app error mapper): `unauthenticated`; `only the offer owner can replace their offer`; `task_not_found_or_not_open_or_own_task`; `no_pending_offer_to_replace`.

### 4.4 cleanup_expired_awards (Cron)

```sql
CREATE OR REPLACE FUNCTION cleanup_expired_awards()
RETURNS VOID
```

**Purpose**: Auto-expires unpaid offers after payment deadline

**Schedule**: Every 10 minutes via pg_cron

**Criteria**:

- status='accepted'
- payment_status='unpaid'
- payment_deadline < now - 1 hour (1-hour grace period)

**Side Effects**:

- Sets status='rejected' on expired offers
- Reverts task.status='open'
- Sends notifications to both parties
- Logs to admin_logs (AWARD_AUTO_EXPIRED)

---

## 5. Flutter Implementation

### 5.1 TaskRequest Model

```dart
class TaskRequest {
  final String id;
  final String taskId;
  final String bidderId;
  final int price;                    // Cents (int to match DB BIGINT)
  final int days;
  final String? note;
  final OfferStatus status;           // pending, accepted, rejected, withdrawn
  final PaymentStatus paymentStatus;  // unpaid, held, released, refunded
  final DateTime createdAt;
  final DateTime? paymentDeadline;    // Set on award

  // Joined fields
  final String? bidderName;
  final String? bidderAvatar;
  final String? taskTitle;

  // Helper properties
  bool get isPending => status == OfferStatus.pending;
  bool get isAccepted => status == OfferStatus.accepted;
  bool get isPendingPayment => isAccepted && paymentStatus == PaymentStatus.unpaid;
  bool get isActive => isAccepted && paymentStatus == PaymentStatus.held;
  bool get isExpired => isPending && DateTime.now().isAfter(createdAt.add(Duration(hours: 24)));
}
```

### 5.2 TaskRequestsService

```dart
class TaskRequestsService {
  /// Submit new offer with rate limiting
  Future<TaskRequest> submitOffer({
    required String taskId,
    required double price,
    required int days,
    String? note,
  });

  /// Replace existing pending offer
  Future<TaskRequest> replaceOffer({
    required String taskId,
    required double price,
    required int days,
    String? note,
  });

  /// Accept offer (Step 1: Award)
  Future<TaskRequest> accept(
    String requestId, {
    String? taskId,
    int? expectedPriceCents,  // For optimistic concurrency
  });

  /// Reject offer
  Future<TaskRequest> reject(String requestId, {String? taskId});

  /// Check if bid is replaceable
  Future<BidReplaceabilityResult> isBidReplaceable(String taskId);

  /// Get existing active offer for current user
  Future<TaskRequest?> getExistingActiveOfferForCurrentUser(String taskId);
}
```

### 5.3 TaskRequestsViewModel

```dart
class TaskRequestsViewModel extends ChangeNotifier {
  // State flags (prevent double-submit)
  bool get isSubmitting => _isSubmitting;
  bool get isAwarding => _isAwarding;
  bool get isRejecting => _isRejecting;

  // Two-step award flow
  Future<Map<String, dynamic>?> award(
    String requestId, {
    int? expectedPriceCents,
  });

  Future<Map<String, dynamic>?> payForAwardedOffer(String requestId);

  // Cancel awarded-but-unpaid offer
  Future<bool> cancelAwardedOffer(String requestId);

  // Rate limiting
  bool get isSubmitRateLimited => remainingDebounceMs > 0;
  int get remainingDebounceMs;
}
```

### 5.4 Exceptions

```dart
/// Thrown when offer price changed between viewing and accepting
class PriceMismatchException implements Exception {
  final int expectedCents;
  final int actualCents;

  String get userMessage {
    final expectedDollars = (expectedCents / 100).toStringAsFixed(2);
    final actualDollars = (actualCents / 100).toStringAsFixed(2);
    return 'The freelancer updated their offer from \$$expectedDollars to \$$actualDollars.';
  }
}

/// Thrown when trying to accept already-accepted offer (idempotency)
class OfferAlreadyAcceptedException implements Exception {}
```

---

## 6. Two-Step Award & Payment Flow

### Flow Diagram

```
Client views offers
        ↓
   Click "Award"
        ↓
   Capture price
        ↓
award_task_offer() ─────┐
   ↓                    │
accepted + unpaid       │
   ↓                    │
Show countdown          │
(timer starts)          │
   ↓                    │
Client clicks           │
"Complete Payment"      │
   ↓                    │
pay_awarded_offer() ◄───┘
   ↓
payment_status='held'
   ↓
task.status='in_progress'
   ↓
Work can begin
```

### UI Implementation

```dart
// Step 1: Award (with price validation)
try {
  final priceCents = (request.price * 100).round();
  await viewModel.acceptOffer(request, expectedPriceCents: priceCents);
  // Show payment deadline countdown
} on PriceMismatchException catch (e) {
  showPriceMismatchDialog(e);  // Show old vs new price
}

// Step 2: Payment (after countdown)
final result = await viewModel.payForAwardedOffer(request.id);
if (result != null) {
  // Navigate to payment gateway or work screen
}
```

---

## 7. Security & Threat Mitigation

### T1: Direct Status Manipulation

- **Mitigation**: No UPDATE policy on task_requests; only RPC can modify status
- **Verification**: `test/rls/task_requests_rls_test.dart`

### T2: Double Acceptance Race

- **Mitigation**:
  - Database-level unique index: `idx_one_accepted_per_task`
  - RPC-level task status check
  - ViewModel-level `_isAwarding` flag
- **Verification**: `test/unit/tender/race_condition_test.dart`

### T3: Work Without Escrow

- **Mitigation**: Two-step flow enforced by state machine
  - `award_task_offer()` → status='accepted', payment_status='unpaid'
  - `pay_awarded_offer()` → payment_status='held', task.status='in_progress'
- **Verification**: `test/unit/tender/state_machine_test.dart`

### T4: Bid Spam

- **Mitigation**:
  - One active offer per freelancer per task (unique constraint)
  - Client-side rate limiting (2-second debounce)
  - RLS policy with role verification
- **Verification**: `test/unit/tender/rate_limit_test.dart`

### T5: Rejection Without Feedback

- **Mitigation**: `reject_task_request()` creates:
  - Notification to freelancer
  - Task-linked conversation
  - System message in conversation

### T6: Payment Deadline Evasion

- **Mitigation**:
  - Deadline validation in `pay_awarded_offer()`
  - Cron job auto-expires stale awards every 10 minutes
- **Verification**: `test/unit/tender/expiration_test.dart`

### T7: Unauthorized Bid Replacement

- **Mitigation**: `replace_task_request()` verifies caller identity
  - `auth.uid()` must match `p_freelancer_id`
  - JWT role must be 'freelancer'

---

## 8. Configuration

### system_config Keys

| Key                            | Default    | Purpose                 |
| ------------------------------ | ---------- | ----------------------- |
| `tender_payment_timeout_hours` | 48         | Payment window duration |
| `platform_fee_bps`             | 1000 (10%) | Platform fee rate       |

### Cron Schedule

| Job                      | Schedule         | Function                   |
| ------------------------ | ---------------- | -------------------------- |
| `cleanup-expired-awards` | Every 10 minutes | `cleanup_expired_awards()` |

---

## 9. Testing

### Unit Tests

| File                                                  | Purpose                         |
| ----------------------------------------------------- | ------------------------------- |
| `test/unit/tender/task_requests_service_test.dart`    | Service layer, exceptions       |
| `test/unit/tender/task_requests_view_model_test.dart` | ViewModel state management      |
| `test/unit/tender/award_expiration_monitor_test.dart` | Countdown timer, urgency levels |

### Widget Tests

| File                                               | Purpose                |
| -------------------------------------------------- | ---------------------- |
| `test/widget/tasks/expiration_countdown_test.dart` | Countdown UI rendering |

### RLS Tests

| File                                   | Purpose            |
| -------------------------------------- | ------------------ |
| `test/rls/task_requests_rls_test.dart` | Policy enforcement |

### Fixtures

| File                                      | Purpose            |
| ----------------------------------------- | ------------------ |
| `test/fixtures/tender_tasks.dart`         | Complete test data |
| `test/fixtures/task_request_factory.dart` | Factory methods    |

### Smoke Test

- `.TODO/SMOKE_TEST_TENDER.md`: 5-minute manual verification checklist

---

## 10. Monitoring & Rollback

### Rollback Triggers

```sql
-- Alert if > 5% of assigned tasks are stuck > 72 hours
SELECT COUNT(*) FROM task_requests
WHERE status='accepted'
AND payment_status='unpaid'
AND awarded_at < NOW() - INTERVAL '72 hours';
```

### Admin Logs

| Action                   | Description                         |
| ------------------------ | ----------------------------------- |
| `PRICE_MISMATCH_ATTEMPT` | Security signal for bidding attacks |
| `OFFER_ACCEPTED`         | Successful awards                   |
| `AWARD_AUTO_EXPIRED`     | Cron job expirations                |

---

## 11. Error Handling

### Common Error Codes

| Code               | Meaning                    | User Message                                  |
| ------------------ | -------------------------- | --------------------------------------------- |
| `PRICE_MISMATCH`   | Offer changed during award | "The freelancer updated their offer..."       |
| `already_accepted` | Idempotency hit            | "This offer has already been accepted"        |
| `deadline expired` | Payment window closed      | "The payment deadline has expired"            |
| `only task owner`  | Authorization failure      | "Only the task owner can perform this action" |
| `42501`            | RLS denial                 | "You cannot submit an offer on this task"     |

### Error Mapping Pattern

```dart
// In TaskRequestsService
String _mapSubmitOfferError(PostgrestException error) {
  final message = error.message.toLowerCase();
  final code = error.code;

  if (message.contains('ux_task_requests_pending_per_user') ||
      message.contains('duplicate key')) {
    return 'You already have a pending offer on this task.';
  }

  if (code == '42501' || message.contains('policy')) {
    return 'You cannot submit an offer. The task might be closed.';
  }

  // ... more mappings
}
```

---

## 12. Migration Files

| File                                                           | Purpose                                                       |
| -------------------------------------------------------------- | ------------------------------------------------------------- |
| `20260306_tender_guardrails.sql`                               | Indexes, accept_task_request, cleanup_expired_awards          |
| `20260308000000_accept_task_request_reject_remaining_bids.sql` | Reject remaining bids when accepting one (Single Winner Rule) |
| `20260305*.sql`                                                | reject_task_request with conversation creation                |
| `20260322000002`–`20260322000005` (replace_task_request sequence) | replace_task_request RPC (single overload, update-in-place)   |

---

**Document End**

_Verification: All 8 RPCs documented, all 7 threat scenarios covered, complete file references._
