# Portfolio Contract 2026-03-01

**Status:** Active  
**Version:** 1.0  
**Plan Reference:** `.TODO/PLAN_ProtfolioFix_2026-03-01.md`

---

## 1. Database Schema (Source of Truth)

### Table: `public.portfolio_items`

| Column | Type | Null | Description |
|--------|------|------|-------------|
| `id` | `uuid` | NOT NULL | Primary key, auto-generated |
| `owner_id` | `uuid` | NOT NULL | FK to auth.users (RLS owner) |
| `title` | `text` | NOT NULL | User-provided title |
| `description` | `text` | NULL | Optional description |
| `image_path` | `text` | NULL | **Canonical:** Storage path (e.g., `ownerId/filename.jpg`) |
| `image_url` | `text` | NULL | **Legacy:** Public URL (backwards compatibility) |
| `created_at` | `timestamptz` | NOT NULL | Auto-generated, UTC |

### Indexes

- `idx_portfolio_owner_created` on `(owner_id, created_at DESC, id DESC)`

### RLS Policies

| Policy | Command | Rule |
|--------|---------|------|
| `portfolio_select_all_auth` | SELECT | `true` (public read) |
| `portfolio_insert_owner` | INSERT | `owner_id = auth.uid()` |
| `portfolio_update_owner` | UPDATE | `owner_id = auth.uid()` |
| `portfolio_delete_owner` | DELETE | `owner_id = auth.uid()` |

---

## 2. Storage Contract

### Bucket: `portfolio`

- **Visibility:** Public (for now - may migrate to private + signed URLs later)
- **Path Pattern:** `{ownerId}/{timestamp}_{sanitized_filename}`
- **Example:** `550e8400-e29b-41d4-a716-446655440000/1709123456789_photo.jpg`

### Storage Policies

| Policy | Command | Rule |
|--------|---------|------|
| `portfolio_select_all` | SELECT | `true` (public bucket) |
| `portfolio_insert_own` | INSERT | `bucket_id = 'portfolio' AND name LIKE auth.uid() || '/%'` |
| `portfolio_delete_own` | DELETE | `bucket_id = 'portfolio' AND name LIKE auth.uid() || '/%'` |

---

## 3. App DTO Contract

### Dart Model: `PortfolioItem`

```dart
class PortfolioItem {
  final String id;                    // UUID
  final String ownerId;               // User ID
  final String title;                 // Non-null
  final String? description;          // Nullable
  final String? imagePath;            // **Canonical** - storage path
  final String? imageUrl;             // **Legacy** - public URL (fallback only)
  final DateTime createdAt;           // UTC
}
```

### Factory Methods

**From JSON (Database):**
- Primary: Read `image_path` if present
- Fallback: Read `image_url` for backwards compatibility
- Never both - prefer `image_path`

**To JSON (Database):**
- Write only to `image_path` (canonical)
- Do NOT write to `image_url` (legacy)

---

## 4. Pagination Cursor Contract

### Composite Cursor

For stable pagination, use composite `(created_at, id)` ordering:

```sql
ORDER BY created_at DESC, id DESC
```

### Cursor Encoding

```dart
// Cursor format: ISO timestamp
String encodeCursor(DateTime createdAt, String id) => createdAt.toIso8601String();

// For same-timestamp rows, client may need to skip already-seen IDs
```

### Page Size

- Default: 30 items
- Max: 100 items
- Client must request specific page size

---

## 5. Image Resolution Contract

### Rendering Flow

1. **If `imagePath` exists:**
   - For public bucket: `getPublicUrl('$bucket/$path')`
   - For private bucket: `createSignedUrl('$bucket/$path', expiresIn: 3600)`

2. **Else if `imageUrl` exists (legacy fallback):**
   - Use URL directly (for backwards compatibility)

3. **Else:**
   - Show placeholder (no image)

### Migration Strategy

1. **Phase 1 (Current):** Write to `image_path`, read `image_path` with fallback to `image_url`
2. **Phase 2 (Future):** Backfill `image_path` from valid `image_url` values
3. **Phase 3 (Future):** Deprecate and drop `image_url` column

---

## 6. Delete Semantics

### DB Row Deletion

```dart
await _client.from('portfolio_items').delete().eq('id', id);
```

### Storage Cleanup

1. Fetch item to get `imagePath` or `imageUrl`
2. Delete DB row first (RLS-protected)
3. If storage path can be resolved, attempt storage deletion
4. **Do NOT fail** if storage deletion fails (avoid breaking UX)

### Path Resolution

**From `imagePath` (canonical):**
- Use directly: `$bucket/$imagePath`

**From `imageUrl` (legacy):**
- Parse URL pattern: `.../object/public/portfolio/{path}`
- Extract path after bucket name

---

## 7. Error Mapping Contract

| Backend Error | User-Facing Message |
|---------------|---------------------|
| `Postgrest 42501` (RLS) | "Not authorized. Please sign in." |
| Storage permission denied | "Unable to save image. Please try again." |
| Network/timeout | "Connection failed. Please check your network." |
| Unknown | "Something went wrong. Please try again." |

---

## 8. Verification Checklist

- [ ] Model reads `image_path` first, falls back to `image_url`
- [ ] Model writes only to `image_path`
- [ ] Storage path format follows `{ownerId}/{timestamp}_{filename}`
- [ ] Pagination uses composite cursor `(created_at, id)`
- [ ] Delete cleans up storage when path is resolvable
- [ ] All errors mapped to user-friendly messages
- [ ] AppLogger used for all operations (no print statements)

---

*Contract Version 1.0 - Created 2026-03-01*
