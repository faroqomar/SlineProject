# Storage Signed URLs - API Contracts

**Date**: 2026-03-06  
**Author**: @APIContract  
**Status**: DRAFT - Pending review

---

## 1. Database Contracts

### 1.1 is_admin() Function

**Signature**: `public.is_admin(p_uid uuid) RETURNS boolean`

**Behavior**:
- Returns `true` if user has `'admin'` in their `roles` array
- Returns `false` if user not found or no admin role
- Returns `false` if `p_uid` is NULL

**Implementation**:
```sql
CREATE OR REPLACE FUNCTION public.is_admin(p_uid uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = p_uid AND roles @> '{admin}'
  );
$$;
```

**Test Cases**:
| User | roles | Expected |
|------|-------|----------|
| user-1 | `{client}` | `false` |
| user-2 | `{client,admin}` | `true` |
| user-3 | `{admin}` | `true` |
| NULL | - | `false` |

---

### 1.2 can_access_chat_attachment() Function

**Signature**: `public.can_access_chat_attachment(p_object_name text, p_uid uuid) RETURNS boolean`

**Behavior**:
1. Returns `true` if `is_admin(p_uid)` is true
2. Returns `false` if path doesn't start with `convos/`
3. Extracts `conversation_id` from path `convos/<id>/...`
4. Returns `true` if `p_uid` is `user1_id` or `user2_id` of conversation
5. Returns `false` if conversation not found

**Implementation**:
```sql
CREATE OR REPLACE FUNCTION public.can_access_chat_attachment(
  p_object_name text, 
  p_uid uuid
)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_parts text[];
  v_conversation_id uuid;
  v_user1 uuid;
  v_user2 uuid;
BEGIN
  IF p_uid IS NULL OR p_object_name IS NULL OR p_object_name = '' THEN
    RETURN false;
  END IF;

  -- Admin bypass
  IF public.is_admin(p_uid) THEN
    RETURN true;
  END IF;

  -- Expected path: convos/<conversation_id>/...
  v_parts := string_to_array(p_object_name, '/');
  IF array_length(v_parts, 1) < 2 OR v_parts[1] <> 'convos' THEN
    RETURN false;
  END IF;

  BEGIN
    v_conversation_id := v_parts[2]::uuid;
  EXCEPTION WHEN OTHERS THEN
    RETURN false;
  END;

  SELECT user1_id, user2_id INTO v_user1, v_user2
  FROM public.conversations
  WHERE id = v_conversation_id;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  RETURN p_uid = v_user1 OR p_uid = v_user2;
END;
$$;
```

**Test Cases**:
| Path | User | Role | Expected |
|------|------|------|----------|
| `convos/abc-123/file.jpg` | user-1 | participant | `true` |
| `convos/abc-123/file.jpg` | user-2 | participant | `true` |
| `convos/abc-123/file.jpg` | user-3 | non-participant | `false` |
| `convos/abc-123/file.jpg` | admin | admin | `true` |
| `other/path/file.jpg` | user-1 | participant | `false` |

---

### 1.3 can_access_task_image() Function

**Signature**: `public.can_access_task_image(p_object_name text, p_uid uuid) RETURNS boolean`

**Behavior**:
1. Returns `true` if `is_admin(p_uid)` is true
2. Extracts first segment of path (owner_id)
3. Returns `true` if owner_id matches p_uid
4. Returns `false` otherwise

**Implementation**:
```sql
CREATE OR REPLACE FUNCTION public.can_access_task_image(
  p_object_name text, 
  p_uid uuid
)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_owner_id text;
BEGIN
  IF p_uid IS NULL OR p_object_name IS NULL OR p_object_name = '' THEN
    RETURN false;
  END IF;

  -- Admin bypass
  IF public.is_admin(p_uid) THEN
    RETURN true;
  END IF;

  -- Path format: <user_id>/<filename>
  v_owner_id := split_part(p_object_name, '/', 1);
  
  RETURN v_owner_id = p_uid::text;
END;
$$;
```

**Test Cases**:
| Path | User | Owner | Expected |
|------|------|-------|----------|
| `user-1/file.jpg` | user-1 | user-1 | `true` |
| `user-1/file.jpg` | user-2 | user-1 | `false` |
| `user-1/file.jpg` | admin | - | `true` |

---

## 2. Storage RLS Policy Contracts

### 2.1 chat-attachments SELECT Policy

**Policy Name**: `chat_attach_select_restricted_v2`

**Contract**:
```sql
CREATE POLICY "chat_attach_select_restricted_v2"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'chat-attachments' AND
  (
    public.can_access_chat_attachment(name, auth.uid()) OR
    NOT (SELECT storage_rls_v2_enabled FROM app_config LIMIT 1)
  )
);
```

**Behavior**:
- Allows SELECT if user is participant or admin
- Falls back to broad access if feature flag is disabled
- Returns 403 if user is not participant and flag is enabled

---

### 2.2 task-images SELECT Policy

**Policy Name**: `task_images_select_restricted_v2`

**Contract**:
```sql
CREATE POLICY "task_images_select_restricted_v2"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'task-images' AND
  (
    public.can_access_task_image(name, auth.uid()) OR
    NOT (SELECT storage_rls_v2_enabled FROM app_config LIMIT 1)
  )
);
```

**Behavior**:
- Allows SELECT if user is owner or admin
- Falls back to broad access if feature flag is disabled
- Returns 403 if user is not owner and flag is enabled

---

### 2.3 avatars SELECT Policy

**Policy Name**: `avatars_select_v2`

**Contract**:
```sql
CREATE POLICY "avatars_select_v2"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'avatars' AND
  (
    name LIKE (auth.uid() || '/%') OR
    public.is_admin(auth.uid()) OR
    NOT (SELECT storage_rls_v2_enabled FROM app_config LIMIT 1)
  )
);
```

**Behavior**:
- Allows SELECT if user is owner or admin
- Falls back to broad access if feature flag is disabled
- Avatars may be more discoverable by design

---

## 3. Flutter App Contracts

### 3.1 SharedStorageConfig

**File**: `lib/core/config/storage_config.dart`

**Contract**:
```dart
class SharedStorageConfig {
  // TTL constants (seconds)
  static const int chatAttachmentTtlSeconds = 3600;  // 1 hour
  static const int avatarTtlSeconds = 7200;            // 2 hours
  static const int taskImageTtlSeconds = 7200;         // 2 hours
  
  // Cache durations
  static const Duration cacheDuration = Duration(minutes: 90);
  static const Duration errorCacheDuration = Duration(seconds: 30);
  
  // Maximum cache size to prevent memory issues
  static const int maxCacheSize = 1000;
  
  // Helper method
  static int ttlForBucket(String bucket) => switch (bucket) {
    'chat-attachments' => chatAttachmentTtlSeconds,
    'avatars' => avatarTtlSeconds,
    'task-images' => taskImageTtlSeconds,
    _ => 3600,
  };
}
```

---

### 3.2 SignedUrlCache Error Handling

**File**: `lib/core/utils/signed_url_cache.dart`

**Contract**:
```dart
class SignedUrlCache {
  // Existing success cache methods...
  
  // Error caching
  static void setError(String storagePath);
  static bool hasError(String storagePath);
  
  // Eviction
  static void _cleanupIfNeeded(); // Called automatically when size > maxCacheSize
}
```

**Behavior**:
- `setError()` caches a 403 or other error for 30 seconds
- `hasError()` returns true if error is still cached
- Errors prevent immediate retry but don't block future attempts after expiry
- Cache eviction removes oldest entries when size exceeds 1000

---

### 3.3 AttachmentMessageTile Cache Integration

**File**: `lib/features/chat/attachments/widgets/attachment_message_tile.dart`

**Contract**:
```dart
class _AttachmentMessageTileState extends State<AttachmentMessageTile> {
  String? _resolvedUrl;
  bool _loading = true;
  String? _error;

  Future<void> _loadSignedUrl() async {
    // 1. Check error cache first
    // 2. Check success cache
    // 3. Call API if not cached
    // 4. Store result in appropriate cache
    // 5. Update UI state
  }
}
```

**Behavior**:
- Uses `SignedUrlCache` to prevent redundant API calls
- Shows loading state during fetch
- Shows error state on 403 or network error
- Error prevents retry for 30 seconds

---

## 4. TTL Alignment

| Data Type | Bucket | TTL | Cache Duration | Refresh Before |
|-----------|--------|-----|------------------|----------------|
| Chat Attachments | chat-attachments | 3600s (1hr) | 90min | 30min before expiry |
| Avatars | avatars | 7200s (2hr) | 90min | 30min before expiry |
| Task Images | task-images | 7200s (2hr) | 90min | 30min before expiry |

**Note**: Cache duration (90min) is intentionally less than minimum TTL (3600s) to ensure URLs are refreshed before they expire.

---

## 5. Acceptance Criteria

### Database
- [ ] `is_admin()` returns true for users with `roles @> '{admin}'`
- [ ] `can_access_chat_attachment()` correctly parses `convos/<id>/` paths
- [ ] `can_access_task_image()` correctly extracts owner from first path segment

### RLS Policies
- [ ] Non-participant gets 403 on chat-attachments
- [ ] Non-owner gets 403 on task-images
- [ ] Admin gets 200 on all private buckets
- [ ] Feature flag can disable strict policies

### Flutter
- [ ] All services use `SharedUrlCache` with centralized TTLs
- [ ] `AttachmentMessageTile` uses cache and shows error states
- [ ] No hardcoded TTL values in service files

---

**Document Version**: 1.0  
**Status**: Pending @Sentinel review
