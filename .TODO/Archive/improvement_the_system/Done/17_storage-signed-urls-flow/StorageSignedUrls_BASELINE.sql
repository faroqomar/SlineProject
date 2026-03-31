-- Storage RLS Policies Baseline
-- Captured: 2026-03-06
-- Project: isddrknbjsgaantjojhm
--
-- This baseline captures the state of storage.objects policies BEFORE
-- the storage_rls_v2 migration. Used for rollback if needed.

-- Current SELECT policies (BROAD - to be replaced):
-- 1. avatars_select_authenticated: (bucket_id = 'avatars'::text)
-- 2. chat_attach_select_auth: (bucket_id = 'chat-attachments'::text)
-- 3. task_images_select_authenticated: (bucket_id = 'task-images'::text)

-- Full policy list:

-- avatars policies
CREATE POLICY "avatars_delete_own_folder"
    ON storage.objects FOR DELETE TO authenticated
    USING ((bucket_id = 'avatars'::text) AND (name ~~ (auth.uid() || '/%'::text)));

CREATE POLICY "avatars_insert_own_folder"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK ((bucket_id = 'avatars'::text) AND (name ~~ (auth.uid() || '/%'::text)));

CREATE POLICY "avatars_select_authenticated"
    ON storage.objects FOR SELECT TO authenticated
    USING (bucket_id = 'avatars'::text);

CREATE POLICY "avatars_update_own_folder"
    ON storage.objects FOR UPDATE TO authenticated
    USING ((bucket_id = 'avatars'::text) AND (name ~~ (auth.uid() || '/%'::text)));

-- chat-attachments policies
CREATE POLICY "chat_attach_insert_auth"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'chat-attachments'::text);

CREATE POLICY "chat_attach_select_auth"
    ON storage.objects FOR SELECT TO authenticated
    USING (bucket_id = 'chat-attachments'::text);

-- portfolio policies (public bucket - no change needed)
CREATE POLICY "storage_portfolio_delete_owner"
    ON storage.objects FOR DELETE TO authenticated
    USING ((bucket_id = 'portfolio'::text) AND (split_part(name, '/'::text, 1) = (auth.uid())::text));

CREATE POLICY "storage_portfolio_insert_owner"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK ((bucket_id = 'portfolio'::text) AND (split_part(name, '/'::text, 1) = (auth.uid())::text));

CREATE POLICY "storage_portfolio_select_all"
    ON storage.objects FOR SELECT TO authenticated
    USING (bucket_id = 'portfolio'::text);

CREATE POLICY "storage_portfolio_update_owner"
    ON storage.objects FOR UPDATE TO authenticated
    USING ((bucket_id = 'portfolio'::text) AND (split_part(name, '/'::text, 1) = (auth.uid())::text));

-- task-images policies
CREATE POLICY "task_images_delete_own_folder"
    ON storage.objects FOR DELETE TO authenticated
    USING ((bucket_id = 'task-images'::text) AND (name ~~ (auth.uid() || '/%'::text)));

CREATE POLICY "task_images_insert_own_folder"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK ((bucket_id = 'task-images'::text) AND (name ~~ (auth.uid() || '/%'::text)));

CREATE POLICY "task_images_select_authenticated"
    ON storage.objects FOR SELECT TO authenticated
    USING (bucket_id = 'task-images'::text);

CREATE POLICY "task_images_update_own_folder"
    ON storage.objects FOR UPDATE TO authenticated
    USING ((bucket_id = 'task-images'::text) AND (name ~~ (auth.uid() || '/%'::text)));

-- Note: This baseline represents the "broad" SELECT policies that allow
-- ANY authenticated user to access private storage buckets.
-- These will be replaced with object-level policies in the migration.
