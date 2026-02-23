# Phase 0 Repo Map (Plan-Only)

## Scope Guard (Phase 0)

- This document is **inventory and planning only**.
- It does **not** assert defects, vulnerabilities, or regressions.
- It captures what will be inspected in later audit phases and where evidence is expected to come from.

## 0.1 High-Level Repo Classification

- **Project type:** Production-oriented Flutter client app for a freelance marketplace.
- **Backend/BaaS:** Supabase (`supabase_flutter`).
- **Primary state management:** `provider` + `ChangeNotifier`.
- **Observed architecture style:** Feature-based modular layout with MVVM conventions (`view`, `viewmodels`, `data`, `services`, `models`).
- **Navigation style (observed):**
  - `MaterialApp` with named routes in `lib/main.dart`
  - direct `Navigator.push(...)` / `MaterialPageRoute(...)`
  - bottom-nav screen switching in `lib/app/main_navigation_screen.dart`
  - feature route helpers in some modules (e.g., favorites/saved)
- **Dependency injection style (observed):** Manual constructor injection + global `MultiProvider` setup in `lib/main.dart`.

## 0.1 Root Structure Map (Observed)

- `lib/` — Flutter app source (features + core/shared + app bootstrap)
- `test/` — Test folder exists (Phase 0 scan found no test files under `test/`)
- `android/`, `ios/`, `web/` — Target platforms explicitly present
- `linux/`, `macos/`, `windows/` — Desktop platform folders also present
- `assets/` — Asset files (Phase 0 scan found `assets/images/Logo.png`)
- `pubspec.yaml` / `pubspec.lock` — Package/dependency definitions
- `analysis_options.yaml` — Analyzer/lint config (`flutter_lints`)
- `Sline_everything/` — Project docs/reference materials (includes `SUPABASE_SETUP.md`, feature guides, architecture notes)
- `.TODO/` — Existing planning folder (Phase 0 outputs added here)

## 0.1 Flutter/Dependency Snapshot (Observed)

- Flutter SDK constraint: `sdk: ^3.8.1`
- Key dependencies (direct, observed in `pubspec.yaml`):
  - `supabase_flutter`
  - `provider`
  - `logger`
  - `image_picker`
  - `file_picker`
  - `flutter_image_compress`
  - `cached_network_image`
  - `shared_preferences`
  - `rxdart`
  - `google_fonts`
  - `flutter_localizations`
- Lint baseline: `package:flutter_lints/flutter.yaml`

## 0.1 Platform / Build Config Surface (Observed)

### Android

- Config file present: `android/app/build.gradle.kts`
- Observed checks to audit later:
  - app id / namespace (`com.example.sline_app` in current file)
  - release signing configuration
  - `minSdk/targetSdk/compileSdk`
  - flavor config (no explicit `productFlavors` found in Phase 0 text scan; verify in audit)
  - ProGuard/R8/release hardening settings

### iOS

- Standard Flutter iOS structure present (`ios/Runner.xcodeproj`, `ios/Flutter/*.xcconfig`)
- Observed checks to audit later:
  - schemes/configurations/flavor equivalents
  - bundle identifiers/signing
  - plist/env handling

### Web

- `web/` directory present (web build target exists)
- Audit will cover:
  - web build output viability
  - asset references/case sensitivity
  - any web-specific runtime/config differences

### Desktop (Secondary to user request)

- `linux/`, `macos/`, `windows/` folders are present.
- Phase 0 workflow will prioritize Android/iOS/Web, with desktop as optional follow-up if needed.

## 0.1 Core / Shared / Cross-Cutting Layers (Observed)

### App Layer

- `lib/main.dart`
  - app bootstrap
  - global error handling (`runZonedGuarded`, `FlutterError.onError`, `PlatformDispatcher.instance.onError`)
  - `SupabaseConfig.init()`
  - global provider registration
  - `MaterialApp` routes/home auth gate
- `lib/app/main_navigation_screen.dart`
  - bottom navigation shell
  - main tab screen switching

### Core Layer (`lib/core/`)

- `providers/`
  - `navigation_provider.dart`
  - `theme_mode_provider.dart`
- `services/`
  - `supabase_config.dart` (Supabase init + URL/anon key constants)
  - `logger_service.dart`
  - `deep_link_service.dart`
  - `dashboard_cache_service.dart`
  - `payment_service.dart` / `demo_payment_service.dart`
  - `crash_reporting_service.dart`
- `widgets/`
  - shared UI components (`signed_avatar`, `signed_image`, glass widgets, nav, buttons)
- `theme/`
  - centralized theme files (`app_theme`, colors, typography, dimensions, theme dashboard)
- `utils/`
  - formatting, loading helpers, error mapping, signed URL cache, transitions
- `models/`
  - shared user/profile-related model(s)

### Shared Layer (`lib/shared/`)

- `constants/` (e.g., category constants)

## 0.1 State Management / Provider Wiring (Observed)

### Global `MultiProvider` registrations in `lib/main.dart` (Phase 0 inventory)

- `AuthViewModel`
- `ProfileViewModel`
- `NavigationProvider`
- `ThemeModeProvider`
- `SavedTasksViewModel`
- `HomeViewModel`
- `TaskFilterViewModel`
- `TaskViewModel`
- `ChatViewModel`
- `BookingViewModel`
- `OrdersViewModel`
- `DashboardViewModel`
- `NotificationViewModel`
- `FavoritesViewModel`
- `WalletViewModel`
- Stateless providers/services:
  - `TaskRequestsService`
  - `DeepLinkService`
  - `DashboardCacheService`

### Local/feature-scoped providers also observed

- `SearchViewModel`
- `PortfolioViewModel`
- `CategoriesViewModel`
- `TaskRequestsViewModel`
- `WorkItemDetailsViewModel`
- `PublicProfileViewModel`
- `AuthViewModel` instances in auth screens
- Others via `ChangeNotifierProvider`/`Consumer` patterns in feature views

## 0.1 Routing / Navigation Map (Observed)

### `MaterialApp` named routes in `lib/main.dart`

- `/login`
- `/main`
- `/signup`
- `/home`
- `/categories`
- `/favorites` (via `FavoritesRoutes.routeName`)
- `/availability` (booking availability flow, argument-driven)

### Bottom navigation tabs (from `lib/app/main_navigation_screen.dart`)

- `home` -> `HomeScreen`
- `tasks/tenders` -> `TendersScreen`
- `booking` -> `BookingsDiscoveryScreen`
- `dashboard` -> `DashboardScreen`
- `chat` -> `MessagesScreen`
- `profile` -> `ProfileScreen`
- `wallet` -> `WalletDashboardScreen`

### Additional route helpers observed

- `lib/features/favorites/routes/favorites_routes.dart`
- `lib/features/saved/routes/saved_routes.dart`

## 0.1 Assets / Localization / Tests (Observed for Planning)

### Assets

- `pubspec.yaml` declares Flutter asset(s)
- `assets/images/` contains at least one logo image file (Phase 0 inventory)
- Audit plan will include:
  - pubspec declarations vs on-disk files
  - case sensitivity checks (important for Android/Linux/Web/CDN builds)
  - unused assets review

### Localization

- `flutter_localizations` dependency is present in `pubspec.yaml`
- Phase 0 scans did not find:
  - `lib/l10n/`
  - `.arb` files
  - `AppLocalizations` usages
- Audit plan will treat localization as a repo-level coverage check (configured vs actively implemented)

### Testing Surface

- `test/` directory exists
- Phase 0 scan found no `.dart` files under `test/`
- `integration_test/` directory not present in Phase 0 scan
- Audit plan will include explicit coverage expectations by feature (unit/widget/integration where applicable)

## 0.1 Supabase Integration Points (Observed)

### Client Initialization / Configuration

- `lib/core/services/supabase_config.dart`
  - `Supabase.initialize(...)`
  - project URL constant
  - anon key constant
- `lib/main.dart`
  - app startup waits for `SupabaseConfig.init()`
  - auth gate reads `Supabase.instance.client.auth.currentUser`

### Auth/session listeners

- `lib/features/auth/viewmodels/auth_view_model.dart`
  - `auth.onAuthStateChange` listener
- `lib/features/saved/viewmodels/saved_tasks_view_model.dart`
  - auth state listener for saved state sync

### Database access pattern (observed surface)

- Feature services/repositories call Supabase across many modules via:
  - `.from('table_or_view')`
  - `.rpc('function_name')`
  - `.stream(primaryKey: ...)`
  - storage bucket operations and signed/public URL creation

### Storage usage (best-effort from code inventory)

- `avatars` (profile/avatar)
- `task-images` (task attachments/images)
- `chat-attachments` (chat/file attachments)
- `portfolio` (portfolio media)

### Realtime usage (observed)

- Chat messages/conversations streams (`messages`, `conversations`)
- Notifications stream (`notifications`)

### Supabase schema/policy documentation sources in repo (Phase 0)

- No local `supabase/` migrations folder found
- No local `migrations/` folder found
- Best-effort schema/policy references available in:
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/DEVELOPER_GUIDE*.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/Sline_Log.md`

## 0.1 Critical Assumptions (To Verify During Audit Phases)

- **Assumption A:** The repo reflects the currently deployed Supabase schema/RLS/policies (no local migrations were found in Phase 0).
- **Assumption B:** `README`/`Sline_everything/*` docs may contain historical or planned schema references; audit will distinguish code-used vs docs-only constructs.
- **Assumption C:** Feature module boundaries are intended to follow strict MVVM (`View -> ViewModel -> Service/Repository -> Supabase`), but boundary conformance is deferred to feature audits.
- **Assumption D:** Platform targets include Android/iOS/Web at minimum; desktop folders exist but may not be production targets.

## Phase 0 Deliverable Status

- Repo map complete (planning-level)
- No deep feature audits performed
- No fixes implemented

