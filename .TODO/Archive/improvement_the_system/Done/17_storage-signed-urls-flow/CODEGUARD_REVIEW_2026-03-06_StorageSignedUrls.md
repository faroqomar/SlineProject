# CodeGuard Review Report: Storage Signed URLs Flow v2

**Date**: 2026-03-06  
**Reviewer**: @CodeGuard  
**Scope**: Storage Signed URLs Flow Implementation  
**Risk Level**: LOW ✅ (No Blockers)

---

## Scope

- **Change Type**: MEDIUM (Storage RLS hardening, caching layer, TTL centralization)
- **Areas**: Storage Security, RLS Policies, Caching, Flutter Services
- **Files Reviewed**:
  1. `lib/core/config/storage_config.dart` (NEW)
  2. `lib/core/utils/signed_url_cache.dart` (MODIFIED)
  3. `lib/features/chat/attachments/widgets/attachment_message_tile.dart` (MODIFIED)
  4. `lib/features/profile/services/avatar_service.dart` (MODIFIED)
  5. `lib/features/tasks/services/task_image_service.dart` (MODIFIED)
  6. `lib/features/chat/services/attachment_service.dart` (MODIFIED)

---

## Evidence Collected

### Commands Run
```bash
flutter analyze                    # 83 issues (none in scope files)
flutter pub outdated               # Dependencies outdated (not in scope)
flutter pub deps --style=compact   # Verified dependency tree
```

### Documentation Scanned
- `Sline_everything/SUPABASE_SETUP.md` (Storage RLS v2 section 11.2, 11.3)
- `Sline_everything/DEVELOPER_GUIDE.md` (MVVM compliance)
- `.TODO/PLAN_StorageSignedUrls_CONTRACT.md` (API contracts)
- `.TODO/PLAN_StorageSignedUrls_THREATS.md` (Threat model)
- `.TODO/PLAN_StorageSignedUrls_SCHEMA.md` (Schema verification)
- `supabase/migrations/Archive/20260302_chat_archive_rpc_and_storage_helper.sql`

---

## Security Review

### ✅ RLS Policies - CORRECT

| Policy | Bucket | Rule Status |
|--------|--------|-------------|
| `avatars_select_v2` | avatars | ✅ Uses `name LIKE auth.uid() || '/%'` + `is_admin()` + feature flag fallback |
| `task_images_select_restricted_v2` | task-images | ✅ Uses `can_access_task_image()` helper + feature flag fallback |
| `chat_attach_select_restricted_v2` | chat-attachments | ✅ Uses `can_access_chat_attachment()` helper + feature flag fallback |

### ✅ Helper Functions - CORRECT

1. **`is_admin(p_uid uuid)`**:
   - Correctly checks `roles @> '{admin}'` against `profiles.roles` (text[])
   - Uses `SECURITY DEFINER` for proper privilege elevation
   - Handles NULL input gracefully

2. **`can_access_chat_attachment(path, uid)`**:
   - Correctly parses `convos/<conversation_id>/` path format
   - Validates conversation participation (user1_id OR user2_id)
   - Admin bypass included
   - Exception handling for invalid UUIDs

3. **`can_access_task_image(path, uid)`**:
   - Correctly extracts owner from first path segment
   - Uses `split_part(name, '/', 1) = p_uid::text`
   - Admin bypass included

### ✅ Feature Flag Safety

- `app_config.storage_rls_v2_enabled` controls enforcement
- Fallback to broad access when flag is `false` (backward compatible)
- Allows gradual rollout and instant rollback

### ✅ Storage Service Security

All services follow secure patterns:
- Store paths in DB, NOT signed URLs
- Generate signed URLs at render time
- Short TTLs (1-2 hours)
- No hardcoded secrets

---

## Performance Review

### ✅ Caching Implementation - CORRECT

**`SignedUrlCache` (lib/core/utils/signed_url_cache.dart)**:

| Aspect | Implementation | Status |
|--------|----------------|--------|
| Memory Bounds | Max 1000 entries | ✅ Prevents unbounded growth |
| Eviction Strategy | LRU (oldest expiry first) | ✅ Efficient cleanup |
| Error Caching | 30-second cache for 403s | ✅ Prevents retry storms |
| TTL Strategy | 90 min cache vs 1-2 hr signed URL | ✅ Early refresh before expiry |

**`SharedStorageConfig` (lib/core/config/storage_config.dart)**:

| Data Type | Bucket | TTL | Cache Duration | Status |
|-----------|--------|-----|----------------|--------|
| Chat Attachments | chat-attachments | 3600s (1hr) | 90min | ✅ |
| Avatars | avatars | 7200s (2hr) | 90min | ✅ |
| Task Images | task-images | 7200s (2hr) | 90min | ✅ |

### ✅ Widget Performance

**`AttachmentMessageTile`**:
- Uses `didUpdateWidget` to reload only when `storagePath` changes
- Checks error cache before success cache (prevents wasted calls)
- Graceful error states (no crash on 403)

---

## Compatibility Review

### ✅ Flutter/Dart Compatibility
- No deprecated APIs used in scope files
- Follows null-safety patterns
- No `dart:io` platform-specific code in storage services

### ✅ Supabase Compatibility
- Client calls align with v1.10.25 SDK
- Uses standard `createSignedUrl(path, seconds)` API
- All storage paths use bucket-appropriate formats

### ✅ Backward Compatibility
- Feature flag allows gradual rollout
- Existing code continues to work if flag disabled
- No breaking changes in service APIs

---

## Critical Issues (BLOCKERS)

**None identified.** ✅

---

## Warnings (Should Fix)

### ⚠️ LOW: Outdated Dependencies
- `supabase_flutter` 1.10.25 → 2.12.0 available (major upgrade)
- Not a blocker for this feature, but should be scheduled
- **Owner**: @CodeGuard (separate dependency upgrade task)

### ⚠️ LOW: Test File Issues
- Several test files have compilation errors (not in scope)
- These are pre-existing issues unrelated to Storage Signed URLs
- **Owner**: @Sentinel (separate test fix task)

---

## Passed Checks

- ✅ All RLS policies use object-level access checks
- ✅ Helper functions use `SECURITY DEFINER` correctly
- ✅ Feature flag fallback implemented
- ✅ Cache has bounded memory (1000 entries)
- ✅ Error caching prevents retry storms
- ✅ TTL alignment correct (cache < signed URL expiry)
- ✅ No hardcoded TTL values in service files
- ✅ All services use `SharedStorageConfig`
- ✅ Path storage (not URL storage) in database
- ✅ Admin bypass correctly implemented

---

## Risk Notes

### Threat Model Mitigations (Verified)

| Threat | Mitigation | Status |
|--------|------------|--------|
| T1: Path Guessing Attack | `can_access_chat_attachment()` validates participation | ✅ Mitigated |
| T2: Task Image Enumeration | `can_access_task_image()` validates ownership | ✅ Mitigated |
| T3: Admin Bypass Abuse | Audit logging + least privilege | ✅ Accepted Risk |
| T4: Signed URL Interception | Short TTLs + HTTPS | ✅ Accepted Risk |
| T5: Cache Stampede/DoS | Bounded cache + error caching | ✅ Mitigated |
| T6: Policy Syntax Error | Feature flag allows rollback | ✅ Mitigated |

### Regression Risks
- **LOW**: Feature flag ensures safe rollback if issues arise
- **LOW**: No changes to existing public APIs
- **LOW**: Cache eviction prevents memory leaks

---

## Dependency Status

| Package | Current | Latest | Action |
|---------|---------|--------|--------|
| supabase_flutter | 1.10.25 | 2.12.0 | Schedule upgrade (breaking) |
| storage_client | 1.5.4 | 2.4.1 | Schedule upgrade |

**Security Advisories**: None found for current versions in scope.

---

## Final Decision

### APPROVED ✅

**Rationale**:
1. Security controls properly implemented (RLS v2, helper functions, feature flag)
2. Performance optimizations in place (bounded cache, TTL alignment)
3. No breaking changes or compatibility issues
4. All findings are LOW priority or informational
5. Threat model mitigations verified

---

## Next Actions

| Priority | Action | Owner |
|----------|--------|-------|
| P2 | Schedule `supabase_flutter` v2 migration | @CodeGuard |
| P3 | Fix pre-existing test file compilation errors | @Sentinel |
| P3 | Add RLS policy integration tests | @Sentinel |
| P4 | Monitor cache hit rates in production | @Observability |

---

## Verification Commands

```bash
# Verify no issues in scope files
flutter analyze lib/core/config/storage_config.dart lib/core/utils/signed_url_cache.dart lib/features/chat/attachments/widgets/attachment_message_tile.dart lib/features/profile/services/avatar_service.dart lib/features/tasks/services/task_image_service.dart lib/features/chat/services/attachment_service.dart

# Verify dependencies
flutter pub deps --style=compact | grep -E "(supabase|storage)"

# Run focused tests (when available)
flutter test test/storage_signed_urls/
```

---

**Document Version**: 1.0  
**Review Completed**: 2026-03-06  
**Status**: APPROVED - Ready for merge
