-- Backfill admin cases for already-active disputes that were accepted before
-- admin_accept_dispute started creating cases.

DO $$
DECLARE
  v_row RECORD;
  v_case_id uuid;
BEGIN
  FOR v_row IN
    SELECT d.id, d.task_id, d.reason
    FROM public.disputes d
    WHERE d.status::text = 'active'
      AND NOT EXISTS (
        SELECT 1
        FROM public.admin_case_entities e
        JOIN public.admin_cases c ON c.id = e.case_id
        WHERE e.entity_type = 'dispute'
          AND e.entity_id = d.id
          AND c.status::text IN ('open', 'in_progress', 'pending')
      )
  LOOP
    INSERT INTO public.admin_cases (subject, source, status, priority)
    VALUES (
      COALESCE(NULLIF(trim(v_row.reason), ''), 'Dispute investigation') || ' (' || left(v_row.id::text, 8) || ')',
      'dispute',
      'open',
      'high'
    )
    RETURNING id INTO v_case_id;

    INSERT INTO public.admin_case_entities (case_id, entity_type, entity_id)
    VALUES (v_case_id, 'dispute', v_row.id)
    ON CONFLICT (case_id, entity_type, entity_id) DO NOTHING;

    IF v_row.task_id IS NOT NULL THEN
      INSERT INTO public.admin_case_entities (case_id, entity_type, entity_id)
      VALUES (v_case_id, 'task', v_row.task_id)
      ON CONFLICT (case_id, entity_type, entity_id) DO NOTHING;
    END IF;
  END LOOP;
END $$;
