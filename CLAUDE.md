# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SLine is a Flutter freelance marketplace app connecting clients with service providers. Backend is Supabase (PostgreSQL + Auth + Storage + Edge Functions + Realtime). The app supports tender-based bidding, direct bookings, real-time chat, escrow payments (QiCard), and role-switching (client/freelancer).

## Build & Run Commands

```bash
flutter pub get                      # Install dependencies
flutter run                          # Run on connected device
flutter run -d <device_id>           # Run on specific device (use `flutter devices` to list)
flutter analyze                      # Static analysis (must pass clean)
dart format .                        # Format code
flutter test                         # Run unit/widget tests
flutter test test/rls/               # Run RLS policy tests
flutter test integration_test/       # Run integration tests
flutter build apk                    # Android release
flutter build ios                    # iOS release
flutter build web                    # Web release
flutter clean && flutter pub get     # Clean rebuild
flutter gen-l10n                     # Regenerate localization files (after editing .arb)
flutter run --dart-define=SENTRY_DSN=<dsn>  # Enable Sentry crash reporting
flutter run --dart-define=SENTRY_ENV=production  # Set Sentry environment
```

## Setup (First Time)

```bash
git config core.hooksPath .githooks  # Enable pre-commit hooks (format + analyze)
```

## CI/CD

GitHub Actions pipeline (`.github/workflows/ci.yml`) runs on push/PR to `main`:
- **Lint & Analyze**: `dart format --set-exit-if-changed .` + `flutter analyze --no-fatal-infos`
- **Architecture Guard**: 7 MVVM boundary checks (hard failure). Blocks PRs with Supabase in views, controllers/Navigator in VMs, view imports in VMs, repo imports in views. Check 7 blocks `core/` importing from `features/` (max 5 threshold).
- **Tests**: `flutter test --coverage` with coverage reporting + **40% coverage floor** (regression prevention, raises incrementally). 1196 tests across 27 VM test files + 28 widget test files.
- **Build**: APK (debug) + Web (release) compilation check
- **Note**: Architecture guard Check 3 tightened in Phase D — catches `Supabase.instance.client.auth.*` in VM method bodies (only `?? Supabase.instance` DI defaults are allowed)

## Architecture

**Strict MVVM** with feature-based modules and Provider state management.

```
View (StatelessWidget/StatefulWidget)
  ↓  Consumer<ViewModel> / context.read / context.watch
ViewModel (ChangeNotifier → notifyListeners)
  ↓  calls services
Service/Repository (Supabase queries, error mapping)
  ↓
Supabase Backend (PostgreSQL + RLS)
```

### Directory layout

```
lib/
├── app/                    # MainNavigationScreen, app-level routing
├── core/
│   ├── config/             # Auth, storage, payment runtime config
│   ├── models/             # Global shared models
│   ├── providers/          # NavigationProvider, ThemeModeProvider, SystemConfigViewModel
│   ├── services/           # SupabaseConfig, AppLogger, AccountGuardService, PaymentService, DeepLinkService
│   ├── theme/              # THREE-LAYER DESIGN SYSTEM (see Architecture Principle below)
│   │   ├── Layer 1 THEME:  # AppColors, AppTypography, AppMotion, AppDecorations, AppStates, AppTheme
│   │   ├── Layer 2 LAYOUT: # AppLayout (card sizes, avatar sizes, spacing rhythm, button heights)
│   │   └── Layer 2b:       # AppDimens (spacing + border radius tokens)
│   ├── utils/              # format_date, format_price, error_mapper, transitions
│   └── widgets/            # Shared: GlassContainer, SignedAvatar, SignedImage, AppButton, AppTextField, CustomBottomNavBar
└── features/<name>/        # Each feature has: view/, viewmodels/, services/, models/, (optional: data/, exceptions/)
```

21 feature modules: auth, home, tasks, chat, profile, portfolio, booking, favorites, saved, categories, dashboard, orders, notifications, wallet, proposals, direct_offers, management, work, services, search, safety.

### Key architectural rules

- **UI must never call Supabase directly** -- always go through ViewModel -> Service.
- **Provider registration** lives in `lib/main.dart` (40+ providers).
- **No code generation** (no build_runner/freezed) -- models use manual `fromJson`/`toJson`/`copyWith`.
- **Navigation**: Provider-based tab switching via `NavigationProvider` + `AnimatedSwitcher` in `MainNavigationScreen`. Named routes for auth screens.
- **Sealed ViewState pattern**: `ViewState<T>` (`loading | loaded(T) | error(AppFailure)`) in `lib/core/models/view_state.dart`. Used in DirectOfferDetailsVM, BookingVM, WorkItemDetailsVM. Preferred for new VMs over raw `_isLoading`/`_error` fields.
- **DeepLinkRegistry**: `DeepLinkService` has zero feature imports. Each feature registers its own handler via `DeepLinkRegistry` pattern (6 handler files in feature directories).
- **Design/Theme Separation (Three-Layer Architecture)**:
  - **Layer 1 — Theme** (colors, typography, motion, elevation): `app_colors.dart`, `app_typography.dart`, `app_motion.dart`, `app_decorations.dart`, `app_states.dart`, `app_theme.dart`
  - **Layer 2 — Layout** (spacing, sizes, structure, proportions): `app_layout.dart`, `app_dimens.dart`
  - **Layer 3 — Components** (widgets that CONSUME Layer 1 + Layer 2): All widgets in `lib/core/widgets/` and `lib/features/*/view/`
  - **Rule:** Components NEVER hardcode colors, font sizes, durations, padding, avatar sizes, card heights, or spacing. They ALWAYS reference Layer 1 or Layer 2 tokens. Redesign = change token files, not 134 widget files.

## Conventions

### Strict rules

- **Linting**: `very_good_analysis` with ~70+ rules active (27 rules disabled with tracking in `.TODO/LINT_DEBT_PhaseE.md`). Run `flutter analyze` -- must pass clean.
- **Logging**: Use `AppLogger.i/d/w/e()` from `lib/core/services/logger_service.dart`. Never `print()` or `debugPrint()`.
- **Colors**: Use `AppColors.*` or `context.colorScheme.*`. Never hardcode `Color(0xFF...)`.
- **Timestamps**: Store UTC in DB, convert to local in UI via `formatUtcToLocal()` from `lib/core/utils/format_date.dart`.
- **Pagination**: Cursor-based (timestamp), never offset. Pattern: `.lt('created_at', cursorIso).order('created_at', ascending: false).limit(20)`.
- **Storage**: Store file *paths* in DB, generate signed URLs at render time. Never store signed URLs.
- **Queries**: Use Supabase JOINs (`.select('*, profiles!fkey(full_name)')`) to avoid N+1. Batch-fetch as fallback.
- **Async in StatefulWidgets**: Always check `if (!mounted) return;` after `await`.
- **Language**: All code, comments, variable names in English.
- **Motion tokens**: Use `AppMotion.*` for all animation durations and curves. Never hardcode `Duration(milliseconds:...)` in feature code.
- **Elevation**: Use `AppDecorations.elevation(level)` for card/surface shadows. Never hardcode `BoxShadow(...)` in feature code.
- **Typography**: Use `AppTypography.*` for all text styles. Never hardcode `fontSize:` in feature code.

### Code comments (MANDATORY)

Every piece of code MUST include comments that explain **WHAT** it does and **WHY** it exists. This is non-negotiable.

- **Every new file**: top-level `///` doc comment explaining what the file provides and why it was created.
- **Every public class/method/widget**: `///` doc comment explaining what it does and why.
- **Non-obvious logic**: inline `//` comment explaining why that approach was chosen (complex conditions, workarounds, performance choices, design decisions).
- **Animation parameters**: comment explaining the design intent (e.g., `// 500ms stagger — first interactive element ready within 400ms`).
- **Token choices**: comment explaining why a specific token was chosen when the choice isn't obvious (e.g., `// curveSpring for delight, not curveDecel — button should feel alive`).
- **Do NOT comment the obvious** (`// increment counter` above `counter++`). Comments add information the code alone does not convey.

### Error handling

Map technical errors to user-friendly messages in ViewModels. Key Postgres codes:
- `42501` = RLS denied (session expired)
- `23505` = unique violation
- `23503` = foreign key violation
- `23514` = check constraint

ViewModel pattern: `_isLoading` + `_error` fields, `try/catch` with `_mapError()`, `notifyListeners()` in `finally`. For new VMs, prefer sealed `ViewState<T>` + `AppFailure` from `lib/core/models/`.

### Payment system

`USE_QICARD_PAYMENT` compile-time flag selects `QiCardPaymentService` vs `DemoPaymentService`. Edge functions handle payment creation (`qicard_payment_create`), webhooks (`qicard_webhook_handler`), and refunds (`booking_decline_refund`).

## Supabase Backend

- **Config**: `lib/core/services/supabase_config.dart` (URL + anon key).
- **RLS**: Enabled on ALL tables. All client queries go through anon key + RLS policies.
- **Storage buckets**: `avatars` (private, 2h TTL), `task-images` (private, 2h), `chat-attachments` (private, 1h), `portfolio` (public).
- **Realtime**: WebSocket subscriptions for chat messages and notifications via `supabase_realtime_service.dart`.
- **Edge functions**: Located in `supabase/functions/` (payment, push notifications).
- **Key RPCs**: `accept_task_request`, `reject_task_request`, `replace_task_request`, `pay_awarded_offer`, `rpc_approve_delivery`, `cleanup_expired_awards`.
- **Schema reference**: `Sline_everything/SUPABASE_SETUP.md` is the single source of truth for tables, RLS policies, triggers, and indexes.
- **Migration review**: Reference `MIGRATION_REVIEW_CHECKLIST.md` for every PR with `supabase/migrations/` files.
- **SQL tests**: `supabase/tests/` contains SQL assertion tests for critical RPCs (accept_task_request, escrow idempotency, role switch).

## Documentation

- `Sline_everything/DEVELOPER_GUIDE.md` -- complete feature documentation with MVVM examples
- `Sline_everything/SUPABASE_SETUP.md` -- database schema, RLS, triggers, storage
- `Sline_everything/STRUCTURE.md` -- file organization
- `Sline_everything/CODE_REVIEW.md` -- common issues, N+1 fixes
- `Sline_everything/ARCHITECTURE_ANALYSIS.md` -- architecture decisions
- `.cursor/rules/error-handling.mdc` -- error code mapping table
- `.cursor/PROJECT_CONTEXT.md` -- quick architecture reference

## Environment

- Flutter SDK ^3.8.1, Dart ^3.8.1
- Android: Kotlin DSL (`build.gradle.kts`), namespace `com.example.sline_app`
- iOS: Swift AppDelegate, CocoaPods
- Key deps: `supabase_flutter`, `provider`, `google_fonts`, `rxdart`, `cached_network_image`, `webview_flutter`, `image_picker`, `shared_preferences`
