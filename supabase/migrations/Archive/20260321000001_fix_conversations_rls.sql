-- Migration to fix RLS INSERT policy on conversations table
-- The previous policy 'conversations_insert_client_only' restricted inserts to clients and favorites.
-- We are replacing it with a policy that allows any authenticated user to insert.
-- Note: The conversations_before_insert_guard trigger already enforces rate limits and task ownership rules.

BEGIN;

-- Drop the old restrictive policy
DROP POLICY IF EXISTS conversations_insert_client_only ON public.conversations;

-- Create a new permissive policy for authenticated users
CREATE POLICY conversations_insert_authenticated ON public.conversations
    FOR INSERT
    TO authenticated
    WITH CHECK (initiated_by = auth.uid());

COMMIT;
