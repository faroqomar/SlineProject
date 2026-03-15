-- ============================================================================
-- Chat Realtime Sync: Full presence table, RLS, and realtime publication
-- Plan: .TODO/PLAN_ChatRealtimeSync_2026-03-07_PlanCritic.md
--       .TODO/improvement_the_system/ImplementReady/08_chat-realtime-sync/02_PATCH_PLAN.md
-- Idempotent: safe to run on DB that already has table/policies (IF NOT EXISTS, DROP IF EXISTS).
-- ============================================================================

-- 1. Create presence table if missing (live may already have it)
CREATE TABLE IF NOT EXISTS public.conversation_presence (
    conversation_id uuid NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_typing boolean NOT NULL DEFAULT false,
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (conversation_id, user_id)
);

-- 2. Enable RLS (no-op if already enabled)
ALTER TABLE public.conversation_presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 3. Presence RLS policies (drop + create so idempotent)
DROP POLICY IF EXISTS presence_select_participant ON public.conversation_presence;
CREATE POLICY presence_select_participant ON public.conversation_presence
    FOR SELECT
    USING (
        conversation_id IN (
            SELECT id FROM public.conversations
            WHERE user1_id = auth.uid() OR user2_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS presence_upsert_self ON public.conversation_presence;
CREATE POLICY presence_upsert_self ON public.conversation_presence
    FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND conversation_id IN (
            SELECT id FROM public.conversations
            WHERE user1_id = auth.uid() OR user2_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS presence_update_self ON public.conversation_presence;
CREATE POLICY presence_update_self ON public.conversation_presence
    FOR UPDATE
    USING (auth.uid() = user_id);

-- 4. Messages: only ensure RLS is on (policies already exist in live: messages_select, messages_insert, messages_update_by_receiver)
-- No new message policies here to avoid duplicating existing ones.

-- 5. Add tables to realtime publication only if not already present
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'conversation_presence'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.conversation_presence;
    END IF;
END
$$;

-- 6. Feature flag for presence and receipt UI
INSERT INTO public.app_config (key, value, description)
VALUES (
    'chat_presence_receipts_enabled',
    'true',
    'Enable typing indicator and delivered/read receipt ticks in chat. Set to false to disable.'
)
ON CONFLICT (key) DO NOTHING;
