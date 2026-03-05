-- Work feature: work_contracts, change_requests, extension_requests tables and RLS.
-- Source-of-truth in repo; safe to run when objects already exist (IF NOT EXISTS / DROP IF EXISTS).

-- 1. work_contracts
CREATE TABLE IF NOT EXISTS public.work_contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  related_entity_type text NOT NULL CHECK (related_entity_type IN ('task', 'booking')),
  related_entity_id uuid NOT NULL,
  version int4 NOT NULL,
  snapshot jsonb NOT NULL,
  contract_hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.work_contracts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS work_contracts_select ON public.work_contracts;
CREATE POLICY work_contracts_select ON public.work_contracts
  FOR SELECT USING (
    public.is_work_log_participant(related_entity_id, related_entity_type, auth.uid())
  );

-- 2. change_requests
CREATE TABLE IF NOT EXISTS public.change_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  related_entity_type text NOT NULL CHECK (related_entity_type IN ('task', 'booking')),
  related_entity_id uuid NOT NULL,
  requester_id uuid NOT NULL REFERENCES public.profiles(id),
  scope_diff text,
  price_diff numeric,
  days_diff int4,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
  applied_contract_version int4,
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz
);

ALTER TABLE public.change_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS change_requests_select ON public.change_requests;
CREATE POLICY change_requests_select ON public.change_requests
  FOR SELECT USING (
    requester_id = auth.uid()
    OR public.is_work_log_participant(related_entity_id, related_entity_type, auth.uid())
  );

DROP POLICY IF EXISTS change_requests_insert ON public.change_requests;
CREATE POLICY change_requests_insert ON public.change_requests
  FOR INSERT WITH CHECK (
    requester_id = auth.uid()
    AND public.is_work_log_participant(related_entity_id, related_entity_type, auth.uid())
  );

DROP POLICY IF EXISTS change_requests_soft_delete ON public.change_requests;
CREATE POLICY change_requests_soft_delete ON public.change_requests
  FOR UPDATE USING (requester_id = auth.uid());

-- 3. extension_requests
CREATE TABLE IF NOT EXISTS public.extension_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  related_entity_type text NOT NULL CHECK (related_entity_type IN ('task', 'booking')),
  related_entity_id uuid NOT NULL,
  requester_id uuid NOT NULL REFERENCES public.profiles(id),
  new_deadline timestamptz NOT NULL,
  reason text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.extension_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS extension_requests_select ON public.extension_requests;
CREATE POLICY extension_requests_select ON public.extension_requests
  FOR SELECT USING (
    requester_id = auth.uid()
    OR public.is_work_log_participant(related_entity_id, related_entity_type, auth.uid())
  );

DROP POLICY IF EXISTS extension_requests_insert ON public.extension_requests;
CREATE POLICY extension_requests_insert ON public.extension_requests
  FOR INSERT WITH CHECK (
    requester_id = auth.uid()
    AND public.is_work_log_participant(related_entity_id, related_entity_type, auth.uid())
  );

-- Grants
GRANT SELECT, INSERT, UPDATE ON public.work_contracts TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.change_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.extension_requests TO authenticated;
