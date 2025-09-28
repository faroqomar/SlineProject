
# Core Module Reference

## 1. Human Explanation
The core module (`lib/core/`) provides shared infrastructure used across all features:
- **Supabase bootstrapping** via `supabase_config.dart`.
- **Global state** like navigation via `providers/`.
- **Cross-cutting utilities** (date/price formatting), **theme** constants, and **shared widgets** (signed images/avatars, bottom nav).
- **Lightweight models** reused across features (e.g., `UserProfile`).
This keeps feature modules small and focused while centralizing common concerns.

## 2. Database & Supabase Mapping
Core does not own tables, but it integrates with key Supabase resources used throughout the app.

### 2.1 `public.profiles` (consumed by core model/widgets)
| Column | Type | Purpose / Usage | Notes |
| --- | --- | --- | --- |
| `id` | `uuid` | User identity (FK → `auth.users.id`) | Mirrors Supabase Auth user id |
| `full_name` | `text` | Display name | Optional |
| `email` | `text` | Cached email for display | Should mirror `auth.users.email` |
| `avatar_url` | `text` | Private storage path to avatar | Used by `SignedAvatar` to create signed URL |
| `created_at` | `timestamptz` | Profile creation time (UTC) | Default `now()` |

RLS: Users can read/update only their own row (`auth.uid() = id`). This affects any profile reads from core helpers/widgets.

### 2.2 Storage buckets (private)
| Bucket | Purpose | Used by | Notes |
| --- | --- | --- | --- |
| `avatars` | Store profile avatars | `SignedAvatar` | Private; generate short-lived signed URLs before rendering |
| `task-images` | Store task images | `SignedImage` | Private; signed URL generation on demand |

Policies: Buckets are private; reads require signed URLs. Writes require authenticated user and policy compliance (feature-specific).

### 2.3 Supabase client (SDK)
- Core exposes a single configured client from `supabase_config.dart` for the rest of the app.
- All repositories/services import it to perform queries and to ensure consistent session handling for RLS.

## 3. File Inventory
| File | Layer | Description |
| --- | --- | --- |
| `lib/core/services/supabase_config.dart` | Service bootstrap | Initializes Supabase SDK once; exposes `Supabase.instance.client`. |
| `lib/core/services/logger_service.dart` | Utility | Centralized logging (`AppLogger`) with safe formatting. |
| `lib/core/providers/navigation_provider.dart` | Provider | App-wide bottom navigation state (`ChangeNotifier`). |
| `lib/core/utils/format_date.dart` | Utility | UTC-to-local formatting (`formatUtcToLocal`, `formatRangeUtcToLocal`). |
| `lib/core/utils/format_price.dart` | Utility | Integer-to-currency formatting for budgets/prices. |
| `lib/core/theme/app_colors.dart` | Theme | Material 3 color constants used across features. |
| `lib/core/widgets/custom_bottom_nav_bar.dart` | Widget | Bottom navigation bar bound to `NavigationProvider`. |
| `lib/core/widgets/signed_avatar.dart` | Widget | Renders a profile avatar from a private storage path via signed URL. |
| `lib/core/widgets/signed_image.dart` | Widget | Renders an image from a private storage path via signed URL. |
| `lib/core/models/user_profile.dart` | Model | Maps DB `profiles` row to a typed object used across features. |

## 4. ERD Diagram (context)
```mermaid
erDiagram
  AUTH_USERS ||--|| PROFILES : "id=id"
  PROFILES ||--o{ TASKS : "user_id"
  PROFILES ||--o{ STORAGE_AVATARS : "avatar_url (path)"

  AUTH_USERS { uuid id PK }
  PROFILES { uuid id PK/FK, text full_name, text email, text avatar_url }
  TASKS { uuid id PK, uuid user_id FK }
  STORAGE_AVATARS { text path PK }
```

```text
auth.users (id)
   └── profiles (id, full_name, email, avatar_url)
            └──(path) avatars bucket (private, signed URLs)
```

## 5. Supabase Snippets

### 5.1 Initialize Supabase client once
```dart
// lib/core/services/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> init({required String url, required String anonKey}) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}

// Usage at app startup (e.g., main())
// await SupabaseConfig.init(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
final supabase = Supabase.instance.client;
```

### 5.2 Fetch profile for current user (RLS requires session)
```dart
final user = Supabase.instance.client.auth.currentUser;
if (user != null) {
  final row = await Supabase.instance.client
      .from('profiles')
      .select('id, full_name, email, avatar_url')
      .eq('id', user.id)
      .maybeSingle();
}
```

### 5.3 Create a signed URL for a private avatar path
```dart
// Given a storage path like 'avatars/<uid>/<file>.jpg'
final storage = Supabase.instance.client.storage.from('avatars');
final String signedUrl = await storage.createSignedUrl(path, 60 * 10); // 10 minutes
```

## 6. Error Handling
| Origin | Error | User Message | Mitigation |
| --- | --- | --- | --- |
| Profiles read | `42501` (RLS denied) | "Session expired. Please log in again." | Refresh session, re-authenticate. |
| Storage read | 404 (object missing) | "Image not available." | Show placeholder; allow re-upload. |
| Signed URL | Expired URL | "Session for image expired. Refreshing…" | Regenerate signed URL lazily. |
| Supabase init | Invalid URL/key | "App configuration error." | Validate env vars; avoid hardcoding secrets in code. |

## 7. Extra Notes & Testing Checklist
- **Secrets**: Do not hardcode the Supabase anon key in source for production. Prefer env/CI secrets.
- **UTC**: All timestamps are UTC; use `formatUtcToLocal()` for display.
- **Caching**: `SignedAvatar/SignedImage` may cache signed URLs for a short time to reduce churn.
- **RLS**: Ensure `auth.currentUser` is present before any RLS-protected fetch.

Testing checklist:
- Initialize Supabase on app start and verify a simple `select` from `profiles` works only when logged in.
- Render `SignedAvatar` with a valid private `avatar_url` path and confirm the image loads.
- Expire a signed URL and confirm the widget regenerates it and rerenders.
- Navigate tabs with `NavigationProvider` and confirm `CustomBottomNavBar` syncs state.
