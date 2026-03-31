# Storage RLS v2 - Rollback Playbook

**Date**: 2026-03-06  
**Author**: @DataMigration  
**Emergency Contact**: DevOps / Backend Team

---

## Rollback Triggers (Any ONE triggers immediate rollback)

| # | Trigger | Metric | Detection |
|---|---------|--------|-----------|
| 1 | 403 Spike | >5% increase in storage 403 errors within 1 hour of deploy | Supabase Dashboard / Sentry |
| 2 | User Complaint | Support ticket: "Cannot see my chat images" | Support channel |
| 3 | RLS Test Failure | Any RLS test (T50-T57) fails in staging | CI/CD pipeline |
| 4 | Manual Check Fail | Non-participant can access private attachment | Manual testing |

---

## Rollback Procedure (< 5 minutes)

### Step 1: Disable Feature Flag (Immediate - 30 seconds)
```sql
-- This immediately disables strict RLS, falls back to broad access
UPDATE public.app_config SET storage_rls_v2_enabled = false;
```

**Verification**:
```sql
SELECT storage_rls_v2_enabled FROM public.app_config;
-- Should return: false
```

### Step 2: Restore Broad Policies (If needed - 2 minutes)
```sql
-- Only run if disabling feature flag didn't resolve the issue
-- This restores the original broad policies from baseline

-- Restore chat-attachments broad policy
CREATE POLICY "chat_attach_select_auth"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'chat-attachments');

DROP POLICY IF EXISTS "chat_attach_select_restricted_v2" ON storage.objects;

-- Restore task-images broad policy
CREATE POLICY "task_images_select_authenticated"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'task-images');

DROP POLICY IF EXISTS "task_images_select_restricted_v2" ON storage.objects;

-- Restore avatars broad policy
CREATE POLICY "avatars_select_authenticated"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_select_v2" ON storage.objects;
```

**Verification**:
```sql
SELECT policyname FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND cmd = 'SELECT';
-- Should see: chat_attach_select_auth, task_images_select_authenticated, avatars_select_authenticated
```

### Step 3: Verify Access (1 minute)
```sql
-- Test that participants can still access their data
-- This should succeed:
SELECT * FROM storage.objects 
WHERE bucket_id = 'chat-attachments' 
LIMIT 1;
```

### Step 4: Communicate (30 seconds)
```
POST in #incidents channel:
"Rollback executed for Storage RLS v2. 
- Feature flag disabled: storage_rls_v2_enabled = false
- Root cause: [to be determined]
- Impact: Brief period of broad storage access (same as pre-migration state)
- Next steps: Fix forward in staging, re-test, re-deploy"
```

---

## Decision Tree

```
ALERT: Storage RLS Issue Detected
│
├─ Is it affecting production users?
│  ├─ YES → Execute Step 1 (Disable feature flag) immediately
│  │        → Monitor for 2 minutes
│  │        → If resolved: Document and investigate
│  │        → If NOT resolved: Execute Step 2 (Restore broad policies)
│  │
│  └─ NO (staging only) → 
│         → Skip rollback
│         → Fix forward in staging
│         → Re-run test suite before re-deploy
│
└─ Is it a test failure only?
   ├─ YES → Don't rollback production
   │      → Fix test / fix code in staging
   │      → Re-run full test suite
   │
   └─ NO (ambiguous) → 
          → Consult with team lead
          → Default to "Disable feature flag" (Step 1) as precaution
```

---

## Monitoring Queries

### Check 403 Error Rate
```sql
-- Requires pg_stat_statements extension
-- Or check Supabase Dashboard > Logs > Storage
```

### Check Current Policies
```sql
SELECT policyname, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects'
ORDER BY policyname;
```

### Check Feature Flag Status
```sql
SELECT * FROM public.app_config;
```

---

## Post-Rollback Actions

1. **Document**: Record what triggered rollback, what was the symptom
2. **Investigate**: Review logs, check if feature flag was enabled prematurely
3. **Fix Forward**: Create patch for identified issue
4. **Re-test**: Run full RLS test suite in staging
5. **Re-deploy**: Only after all tests pass

---

## Files Reference

| File | Purpose |
|------|---------|
| `.TODO/StorageSignedUrls_BASELINE.sql` | Original broad policies (for full rollback) |
| `supabase/migrations/20260306_storage_rls_v2_policy_swap.sql` | Migration that created new policies |
| `supabase/migrations/20260306_storage_rls_helper_functions.sql` | Helper functions |
| `test/storage_rls_test.dart` | Test suite to verify after rollback |

---

**Tested On**: Staging environment  
**Rollback Time**: < 5 minutes  
**Last Updated**: 2026-03-06
