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

| Resource | Purpose | Used by | Notes |
| --- | --- | --- | --- |
| `public.profiles` | shared user identity metadata | `UserProfile`, `SignedAvatar` consumers | avatar path is stored in DB; signed URL is created at render time |
| `avatars` bucket | private avatar storage | `SignedAvatar`, profile flows | signed URL required for display |
| `task-images` bucket | private task image storage | `SignedImage`, task flows | signed URL required for display |
| `chat-attachments` bucket | private chat file storage | chat feature widgets/services | same signed-URL pattern |

### 2.2 Shared payment runtime contracts

Core owns the app-side payment runtime interfaces used by the booking feature:
- `PaymentService`: abstract contract for payment providers
- `QiCardPaymentService`: server-backed QiCard integration
- `DemoPaymentService`: fallback/demo provider
- `PaymentPendingStore`: persists pending browser payment state on web
- `payment_runtime_config.dart`: callback host validation and callback parsing

### 2.3 Web safety helpers

Core also owns two browser-specific stability helpers:
- `LoadingUtils.show(...) -> LoadingHandle`: overlay-based loading UI with no navigator mutation
- `flutter_error_filters.dart`: filters the known disposed `EngineFlutterView` assertion on web before crash-reporting/log spam

## 3. File Inventory

| File | Layer | Description |
| --- | --- | --- |
| `lib/core/services/supabase_config.dart` | bootstrap | Initializes Supabase once and exposes the shared client. |
| `lib/core/services/logger_service.dart` | service | `AppLogger` for structured debug/error logging. |
| `lib/core/services/crash_reporting_service.dart` | service | Crash-reporting abstraction with a quiet no-op implementation by default. |
| `lib/core/services/payment_service.dart` | contract | Shared payment DTOs and the `PaymentService` interface. |
| `lib/core/services/demo_payment_service.dart` | service | Local/demo payment implementation and legacy fallback path. |
| `lib/core/services/qicard_payment_service.dart` | service | Server-backed QiCard create/recover/refund orchestration. |
| `lib/core/services/payment_pending_store.dart` | service | Persists pending payment context across same-tab web redirects. |
| `lib/core/services/deep_link_service.dart` | service | Shared deep-link plumbing used by app navigation flows. |
| `lib/core/config/payment_runtime_config.dart` | config | Compile-time finish URL, callback host rules, payment callback parsing. |
| `lib/core/utils/loading_utils.dart` | utility | Root overlay loading helper that returns an idempotent `LoadingHandle`. |
| `lib/core/utils/flutter_error_filters.dart` | utility | Filters the known web engine disposal assertion. |
| `lib/core/utils/error_mapper.dart` | utility | Shared PostgREST/Auth/network error mapping. |
| `lib/core/utils/format_date.dart` | utility | UTC-to-local date/time formatting helpers. |
| `lib/core/utils/format_price.dart` | utility | Shared price formatting helpers. |
| `lib/core/utils/signed_url_cache.dart` | utility | Short-lived cache for generated signed URLs. |
| `lib/core/providers/navigation_provider.dart` | provider | Global navigation tab state. |
| `lib/core/providers/theme_mode_provider.dart` | provider | Light/dark theme mode state. |
| `lib/core/models/user_profile.dart` | model | Shared typed profile model. |
| `lib/core/models/payment_return_args.dart` | model | Shared typed browser payment callback payload. |
| `lib/core/theme/app_colors.dart` | theme | Central palette definitions. |
| `lib/core/theme/app_dimens.dart` | theme | Spacing, radius, sizing tokens. |
| `lib/core/theme/app_typography.dart` | theme | Shared typography and fallback font configuration. |
| `lib/core/theme/app_theme.dart` | theme | Builds the app `ThemeData` and `AppThemeExtension`. |
| `lib/core/widgets/custom_bottom_nav_bar.dart` | widget | Shared app shell bottom nav. |
| `lib/core/widgets/signed_avatar.dart` | widget | Renders private avatar paths through signed URLs. |
| `lib/core/widgets/signed_image.dart` | widget | Renders private image paths through signed URLs. |

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

| Origin | Error | Handling |
| --- | --- | --- |
| Supabase bootstrap | bad URL/key/session setup | fail fast during app startup; log through `AppLogger` |
| Signed URL creation | missing object / expired URL | return placeholder and regenerate URL when needed |
| Web engine assertion | disposed `EngineFlutterView` | filtered by `isIgnoredFlutterWebEngineDisposeError(...)` |
| Payment callback parsing | invalid host / invalid booking reference | handled in `PaymentReturnScreen` with explicit terminal messaging |

## 6. Testing Checklist

- Boot the app and confirm `SupabaseConfig.init()` succeeds before rendering feature screens.
- Render `SignedAvatar` and `SignedImage` using valid private paths.
- Verify `LoadingHandle.close()` is safe even when a route closes during async work.
- On web, confirm a payment callback loads `PaymentReturnScreen` instead of falling back to the main shell immediately.
- Confirm the known disposed `EngineFlutterView` assertion is filtered and not duplicated in debug logs.
- Confirm Arabic user-generated text renders with the theme fallback stack.
