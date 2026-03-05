-- Proposals: minimum-field profile summary for proposal bidders (owner view).
-- Allows owner to get bidder display info without relying on direct profiles join that may conflict with profiles_select_self.
BEGIN;

-- Returns id, full_name, avatar_url for bidders on the given task. Caller must be task owner.
CREATE OR REPLACE FUNCTION public.get_proposal_bidder_summaries(p_task_id UUID)
RETURNS TABLE (
  id UUID,
  full_name TEXT,
  avatar_url TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.id,
    p.full_name,
    p.avatar_url
  FROM public.task_requests tr
  JOIN public.tasks t ON t.id = tr.task_id AND t.owner_id = auth.uid()
  JOIN public.profiles p ON p.id = COALESCE(tr.freelancer_id, tr.bidder_id)
  WHERE tr.task_id = p_task_id;
$$;

COMMENT ON FUNCTION public.get_proposal_bidder_summaries(UUID) IS
  'Minimum-field profile summaries for bidders on a task (owner only). Use for proposal list display.';

COMMIT;
