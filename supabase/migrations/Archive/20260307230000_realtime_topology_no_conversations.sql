-- ============================================================================
-- Realtime Subscription Topology: conversations MUST NOT be in publication
-- Plan: .TODO/PLAN_RealtimeSubscriptionTopology_2026-03-07.md
-- ============================================================================
-- Inbox realtime is driven by messages stream (receiver_id=userId), not
-- conversations. Adding conversations would cause N+1 and global RLS evaluation.
-- This migration ensures conversations is not in supabase_realtime (idempotent).
-- ============================================================================

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'conversations'
  ) THEN
    ALTER PUBLICATION supabase_realtime DROP TABLE public.conversations;
    RAISE NOTICE 'realtime_topology: dropped conversations from supabase_realtime';
  ELSE
    RAISE NOTICE 'realtime_topology: conversations already not in supabase_realtime';
  END IF;
END $$;
