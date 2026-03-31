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
```

## Setup (First Time)

```bash
git config core.hooksPath .githooks  # Enable pre-commit hooks (format + analyze)
```

## CI/CD

GitHub Actions pipeline (`.github/workflows/ci.yml`) runs on push/PR to `main`:
- **Lint & Analyze**: `dart format --set-exit-if-changed .` + `flutter analyze --no-fatal-infos`
- **Architecture Guard**: Checks MVVM boundary violations (warning-only, graduating to hard failure)
- **Tests**: `flutter test --coverage` with coverage reporting
- **Build**: APK (debug) + Web (release) compilation check

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
│   ├── theme/              # AppColors, AppTypography, AppDimens, AppDecorations, AppTheme (single source of truth)
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

## Conventions

### Strict rules

- **Logging**: Use `AppLogger.i/d/w/e()` from `lib/core/services/logger_service.dart`. Never `print()` or `debugPrint()`.
- **Colors**: Use `AppColors.*` or `context.colorScheme.*`. Never hardcode `Color(0xFF...)`.
- **Timestamps**: Store UTC in DB, convert to local in UI via `formatUtcToLocal()` from `lib/core/utils/format_date.dart`.
- **Pagination**: Cursor-based (timestamp), never offset. Pattern: `.lt('created_at', cursorIso).order('created_at', ascending: false).limit(20)`.
- **Storage**: Store file *paths* in DB, generate signed URLs at render time. Never store signed URLs.
- **Queries**: Use Supabase JOINs (`.select('*, profiles!fkey(full_name)')`) to avoid N+1. Batch-fetch as fallback.
- **Async in StatefulWidgets**: Always check `if (!mounted) return;` after `await`.
- **Language**: All code, comments, variable names in English.

### Error handling

Map technical errors to user-friendly messages in ViewModels. Key Postgres codes:
- `42501` = RLS denied (session expired)
- `23505` = unique violation
- `23503` = foreign key violation
- `23514` = check constraint

ViewModel pattern: `_isLoading` + `_error` fields, `try/catch` with `_mapError()`, `notifyListeners()` in `finally`.

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
