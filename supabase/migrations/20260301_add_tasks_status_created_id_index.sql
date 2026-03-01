begin;

CREATE INDEX IF NOT EXISTS idx_tasks_status_created_id
ON public.tasks USING btree (status, created_at DESC, id DESC);

commit;
