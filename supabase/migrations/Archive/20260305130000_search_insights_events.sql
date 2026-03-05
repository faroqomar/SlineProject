-- Search telemetry backing /api/v1/search/insights KPI cards.
-- Dashboard/local migration; copy equivalent DDL to canonical sline_app migrations.

CREATE TABLE IF NOT EXISTS public.admin_search_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  query_text text NOT NULL CHECK (char_length(query_text) >= 2 AND char_length(query_text) <= 200),
  entity_types text[] NOT NULL DEFAULT '{}'::text[],
  result_count integer NOT NULL DEFAULT 0 CHECK (result_count >= 0),
  duration_ms integer NOT NULL DEFAULT 0 CHECK (duration_ms >= 0),
  timed_out boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_search_events_created_at
  ON public.admin_search_events (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_search_events_admin_user_created_at
  ON public.admin_search_events (admin_user_id, created_at DESC);

ALTER TABLE IF EXISTS public.admin_search_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_search_events_service_role_all ON public.admin_search_events;
CREATE POLICY admin_search_events_service_role_all ON public.admin_search_events
  FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);
