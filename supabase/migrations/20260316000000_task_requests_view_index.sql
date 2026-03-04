-- Index to support vw_unified_work_items third branch (awarded pending payment):
-- JOIN task_requests ON task_id, status = 'accepted', payment_status = 'unpaid'
CREATE INDEX IF NOT EXISTS idx_task_requests_task_status_payment
  ON public.task_requests(task_id, status, payment_status);
