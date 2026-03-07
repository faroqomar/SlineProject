-- Fix avatars bucket: allow any authenticated user to read (so profile avatars show in feed/cards)
-- and ensure INSERT policy allows uploads (fix 403 on avatar upload).
--
-- Root cause: avatars_select_v2 restricted SELECT to name LIKE auth.uid() || '/%', so users could
-- only get signed URLs for their own avatar; other users' avatars failed → "avatars not showing".
-- Profile pics are discoverable; SELECT should be per-bucket for authenticated.
--
-- INSERT 403: ensure avatars_insert_own_folder exists and allows path {auth.uid()}/{filename}.

-- 1) Avatars SELECT: allow any authenticated user to read (discoverable profile pics)
DROP POLICY IF EXISTS "avatars_select_v2" ON storage.objects;
DROP POLICY IF EXISTS "avatars_select_authenticated" ON storage.objects;
CREATE POLICY "avatars_select_authenticated"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'avatars');

-- 2) Avatars INSERT: ensure upload to own folder is allowed (path = auth.uid() || '/' || filename)
DROP POLICY IF EXISTS "avatars_insert_own_folder" ON storage.objects;
CREATE POLICY "avatars_insert_own_folder"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND name LIKE (auth.uid()::text || '/%')
  );

-- 3) Avatars UPDATE/DELETE: keep own-folder restriction (unchanged)
-- avatars_update_own_folder and avatars_delete_own_folder left as-is; no drop/create here.
