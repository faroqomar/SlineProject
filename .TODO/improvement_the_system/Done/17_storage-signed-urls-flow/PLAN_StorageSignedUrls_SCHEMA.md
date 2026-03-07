# Storage Signed URLs - Schema Verification Document

**Date**: 2026-03-06  
**Verified By**: @Supabase_Ops via MCP  
**Status**: ✅ CONFIRMED

---

## 1. Profiles Role Column Schema

### Query
```sql
SELECT column_name, data_type, udt_name 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND (column_name = 'role' OR column_name = 'roles');
```

### Result
| column_name | data_type | udt_name |
|-------------|-----------|----------|
| roles       | ARRAY     | _text    |

### Implication
- `profiles.roles` is a PostgreSQL `text[]` array
- `is_admin()` function should use: `roles @> '{admin}'`
- Implementation confirmed correct

---

## 2. Storage Path Structure Verification

### Query
```sql
SELECT DISTINCT 
    bucket_id,
    split_part(name, '/', 1) as first_segment,
    COUNT(*) as count
FROM storage.objects 
WHERE bucket_id IN ('task-images', 'chat-attachments', 'avatars')
GROUP BY bucket_id, first_segment
ORDER BY bucket_id, count DESC;
```

### Results

#### avatars
| first_segment | count |
|---------------|-------|
| 954eb6c9-625a-43b3-95cb-93307863356e | 2 |
| e7a44757-bde3-487e-9b72-cb98ac7e628a | 1 |

**Pattern**: `<user_uuid>/<filename>`

#### chat-attachments
| first_segment | count |
|---------------|-------|
| convos | 8 |
| bd47da21-a0df-466e-b408-29a03cd0588c | 1 |

**Pattern**: 
- Primary: `convos/<conversation_id>/<filename>` (8 objects)
- Legacy: `<user_uuid>/<filename>` (1 object)

#### task-images
| first_segment | count |
|---------------|-------|
| e7a44757-bde3-487e-9b72-cb98ac7e628a | 5 |

**Pattern**: `<user_uuid>/<filename>`

### Implications

1. **avatars**: Owner-based access - check `name LIKE (auth.uid() || '/%')` ✅
2. **chat-attachments**: 
   - Primary path uses `convos/<id>/` prefix
   - `can_access_chat_attachment()` should parse path for `convos/<conversation_id>/`
   - Legacy direct UUID path should still work (treat as owner-based)
3. **task-images**: Owner-based access - check `split_part(name, '/', 1) = auth.uid()::text` ✅

---

## 3. Confirmed Assumptions

| Assumption | Status | Notes |
|------------|--------|-------|
| `profiles.roles` is text[] | ✅ | Verified |
| Avatar path: `<user_id>/<filename>` | ✅ | Verified |
| Chat path: `convos/<conversation_id>/<filename>` | ✅ | Verified (primary) |
| Task image path: `<user_id>/<filename>` | ✅ | Verified |

---

## 4. Implementation Notes

### is_admin() function
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
**Status**: Confirmed correct based on schema

### can_access_chat_attachment() function
Must handle two path patterns:
1. `convos/<conversation_id>/<filename>` - Check conversation participation
2. `<user_uuid>/<filename>` - Check ownership

### can_access_task_image() function
```sql
CREATE OR REPLACE FUNCTION public.can_access_task_image(p_object_name text, p_uid uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  IF p_uid IS NULL OR p_object_name IS NULL THEN RETURN false; END IF;
  IF public.is_admin(p_uid) THEN RETURN true; END IF;
  
  RETURN split_part(p_object_name, '/', 1) = p_uid::text;
END;
$$;
```
**Status**: Confirmed correct based on path structure

---

**Document Version**: 1.0  
**Next Step**: Create threat model and contracts
