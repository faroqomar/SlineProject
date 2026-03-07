-- ============================================================================
-- Chat Realtime Sync: Add conversation_presence to realtime publication
-- Plan: .TODO/PLAN_ChatRealtimeSync_2026-03-07_PlanCritic.md
-- ============================================================================
-- Idempotent: only adds table if not already in publication.
-- Canonical migration for presence + full schema is 20260307219900_chat_presence_and_rls_full.sql.
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'conversation_presence'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.conversation_presence;
  END IF;
END
$$;
