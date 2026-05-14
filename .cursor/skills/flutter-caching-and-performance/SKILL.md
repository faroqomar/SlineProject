---
name: flutter-caching-and-performance
description: Improve SLine Flutter caching and rendering performance across shared_preferences caches, signed Supabase image URLs, cached_network_image, list rendering, and offline-friendly stale-while-revalidate flows.
metadata:
  last_modified: Thu, 14 May 2026 00:00:00 GMT
---

# Flutter Caching And Performance For SLine

## SLine Defaults

SLine already uses:

- `shared_preferences` for small persistent key-value caches.
- `cached_network_image` for network image caching.
- Supabase Storage paths in the database, with signed URLs generated at render time.
- `DashboardCacheService` for a stale-while-revalidate style dashboard cache.
- `SignedImage`, `SignedAvatar`, and `SignedUrlCache` for private media rendering.

Do not introduce a new persistence dependency such as `sqflite`, `path_provider`, or a custom file cache unless the data requirements clearly exceed the existing cache layer and the user accepts the added dependency.

## Decision Logic

Choose the smallest cache that fits the data:

- Current-session only: in-memory cache owned by a service or ViewModel.
- Small user preferences or lightweight JSON snapshots: `shared_preferences`.
- Supabase private images/files: store paths in the database, generate signed URLs at render time, and reuse `SignedUrlCache` plus `cached_network_image`.
- Larger relational offline data: propose a database-backed cache first; do not implement until dependency and migration impact are accepted.
- Android FlutterEngine pre-warming: out of scope for SLine unless the app becomes a hybrid native host. Do not add engine caching to the current Flutter app.

## Implementation Rules

- Keep Supabase access in services/repositories, never in views.
- Use `AppLogger.i/d/w/e()` for cache diagnostics; never use `print()` or `debugPrint()`.
- Map cache failures to graceful misses. A corrupt or expired cache should not block fresh network loading.
- Store UTC timestamps or epoch milliseconds for cache freshness, and convert display times in UI only.
- Keep cache keys role/user scoped when data differs by authenticated user or active role.
- Add focused tests for expiration, cache miss, corrupt payload, role scoping, and stale-while-revalidate behavior.

## Existing Patterns To Reuse

Before adding new code, inspect:

```bash
rg -n "class .*Cache|SharedPreferences|SignedUrlCache|CachedNetworkImage" lib test
```

Prefer extending these existing surfaces:

- `lib/core/services/dashboard_cache_service.dart`
- `lib/core/utils/signed_url_cache.dart`
- `lib/core/widgets/signed_image.dart`
- `lib/core/widgets/signed_avatar.dart`
- `test/unit/core/dashboard_cache_service_test.dart`

## Offline-Friendly Repository Pattern

When a feature needs cached data plus fresh remote data, use a stream or explicit two-step API that returns cached data first, then refreshes through the service layer:

```dart
Stream<List<Item>> watchItems() async* {
  final cached = await _cache.getItems();
  if (cached != null) yield cached;

  try {
    final fresh = await _service.fetchItems();
    await _cache.saveItems(fresh);
    yield fresh;
  } on Exception catch (error) {
    AppLogger.w('Fresh item fetch failed; served cache when available', error: error);
  }
}
```

## Rendering Performance

- Prefer lazy builders (`ListView.builder`, `GridView.builder`, slivers) for unbounded lists.
- Avoid intrinsic layout passes in repeated list/card rows when fixed constraints can express the layout.
- Avoid unnecessary `Opacity`, `ShaderMask`, `ColorFilter`, and `Clip.antiAliasWithSaveLayer` in scrolling surfaces.
- Do not override `operator ==` on widgets to force caching. Use `const` constructors and stable child extraction instead.
- Constrain image dimensions at the widget boundary; do not load full-resolution media into small thumbnails.
- Verify any newer Flutter scrolling/cache API against the installed SDK before using it. Do not introduce analyzer-breaking APIs.

## Validation

Run focused tests first, then broader checks when shared cache behavior changes:

```bash
flutter test test/unit/core/dashboard_cache_service_test.dart
flutter analyze --no-fatal-infos
```

If media rendering changed, also run the relevant widget tests for `SignedImage`, `SignedAvatar`, or the feature screen that consumes them.
