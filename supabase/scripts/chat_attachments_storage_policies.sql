-- Chat-attachments bucket: SELECT and INSERT policies on storage.objects
--
-- Run this in Supabase Dashboard → SQL Editor (not via migrations).
-- Migrations cannot alter storage.objects (42501: must be owner of relation).
-- Dashboard runs with privileges that allow creating these policies.
--
-- Why: Without these, createSignedUrl() returns 404 for chat attachment images.

-- 1) SELECT: allow when user is conversation participant or storage_rls_v2 not enabled
DROP POLICY IF EXISTS "chat_attach_select_restricted_v2" ON storage.objects;
DROP POLICY IF EXISTS "chat_attach_select_auth" ON storage.objects;
CREATE POLICY "chat_attach_select_restricted_v2"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'chat-attachments'
    AND (
      public.can_access_chat_attachment(name, auth.uid())
      OR (SELECT value FROM public.app_config WHERE key = 'storage_rls_v2_enabled' LIMIT 1) IS DISTINCT FROM 'true'
    )
  );

-- 2) INSERT: allow authenticated uploads to bucket
DROP POLICY IF EXISTS "chat_attach_insert_auth" ON storage.objects;
CREATE POLICY "chat_attach_insert_auth"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'chat-attachments');
