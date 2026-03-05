CREATE INDEX IF NOT EXISTS idx_work_logs_entity_scope_created_at
ON public.work_logs (
  related_entity_id,
  related_entity_type,
  created_at DESC
);
