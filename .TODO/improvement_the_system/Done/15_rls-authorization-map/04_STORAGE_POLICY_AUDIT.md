# 04_STORAGE_POLICY_AUDIT — Live Evidence

> Extracted: 2026-03-06 from `pg_policies WHERE schemaname = 'storage'`

## Summary

**14 storage policies** on `storage.objects`. **ALL use `authenticated` role**. No `public` / `anon` access.

## Policy Table

### Avatars Bucket

| Policy                         | CMD    | qual                    | with_check                                               |
| ------------------------------ | ------ | ----------------------- | -------------------------------------------------------- |
| `avatars_select_authenticated` | SELECT | `bucket_id = 'avatars'` | —                                                        |
| `avatars_insert_own_folder`    | INSERT | —                       | `bucket_id = 'avatars' AND name ~~ auth.uid() \|\| '/%'` |
| `avatars_update_own_folder`    | UPDATE | same as insert          | same as insert                                           |
| `avatars_delete_own_folder`    | DELETE | same as insert          | —                                                        |

✅ **Secure**: Read is permissive (any authenticated user can list avatar objects — needed for signed URL generation). Write is sandboxed to `uid/%`.

### chat-attachments Bucket

| Policy                    | CMD    | qual                             | with_check                                              |
| ------------------------- | ------ | -------------------------------- | ------------------------------------------------------- |
| `chat_attach_select_auth` | SELECT | `bucket_id = 'chat-attachments'` | —                                                       |
| `chat_attach_insert_auth` | INSERT | —                                | `bucket_id = 'chat-attachments' AND owner = auth.uid()` |

⚠️ **Gap**: No UPDATE or DELETE policies. Users cannot update or delete their own attachments. This may be intentional (immutability) but should be documented.

⚠️ **Gap**: SELECT allows ANY authenticated user to read any chat attachment object metadata. The actual file download requires a signed URL, but the metadata (path, size) is visible. Consider adding `can_access_chat_attachment(name, auth.uid())` check.

### task-images Bucket

| Policy                             | CMD    | qual                        | with_check                                                   |
| ---------------------------------- | ------ | --------------------------- | ------------------------------------------------------------ |
| `task_images_select_authenticated` | SELECT | `bucket_id = 'task-images'` | —                                                            |
| `task_images_insert_own_folder`    | INSERT | —                           | `bucket_id = 'task-images' AND name ~~ auth.uid() \|\| '/%'` |
| `task_images_update_own_folder`    | UPDATE | same                        | same                                                         |
| `task_images_delete_own_folder`    | DELETE | same                        | —                                                            |

✅ **Secure**: Same pattern as avatars.

### portfolio Bucket

| Policy                           | CMD    | qual                      | with_check                                                          |
| -------------------------------- | ------ | ------------------------- | ------------------------------------------------------------------- |
| `storage_portfolio_select_all`   | SELECT | `bucket_id = 'portfolio'` | —                                                                   |
| `storage_portfolio_insert_owner` | INSERT | —                         | `bucket_id = 'portfolio' AND split_part(name, '/', 1) = auth.uid()` |
| `storage_portfolio_update_owner` | UPDATE | same                      | same                                                                |
| `storage_portfolio_delete_owner` | DELETE | same                      | —                                                                   |

✅ **Secure**: Public read (bucket is public), writes sandboxed to `uid/`.

## Sandbox Bypass Analysis

The path sandboxing uses two patterns:

1. `name ~~ auth.uid() || '/%'` — LIKE pattern matching
2. `split_part(name, '/', 1) = auth.uid()::text` — First path segment check

**Risk Assessment**: Both patterns are effective. The `~~` (LIKE) pattern could theoretically be bypassed with `%` in the UID, but UUIDs don't contain `%` characters. **No bypass vector found**.

## Verdict

✅ Storage policies are well-configured. Minor gap on chat-attachments SELECT permissiveness.
