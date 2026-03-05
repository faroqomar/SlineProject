begin;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'seller_level_enum'
  ) THEN
    CREATE TYPE public.seller_level_enum AS ENUM (
      'new_seller',
      'level_1',
      'level_2',
      'top_rated'
    );
  END IF;
END $$;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS seller_level public.seller_level_enum;

WITH task_counts AS (
  SELECT
    assigned_freelancer_id AS profile_id,
    count(*)::integer AS completed_task_count
  FROM public.tasks
  WHERE assigned_freelancer_id IS NOT NULL
    AND status IN ('completed', 'closed')
  GROUP BY assigned_freelancer_id
),
booking_counts AS (
  SELECT
    provider_id AS profile_id,
    count(*)::integer AS completed_booking_count
  FROM public.bookings
  WHERE provider_id IS NOT NULL
    AND status = 'completed'::public.booking_status_enum
  GROUP BY provider_id
),
profile_counts AS (
  SELECT
    p.id,
    COALESCE(tc.completed_task_count, 0) + COALESCE(bc.completed_booking_count, 0) AS completed_count
  FROM public.profiles p
  LEFT JOIN task_counts tc ON tc.profile_id = p.id
  LEFT JOIN booking_counts bc ON bc.profile_id = p.id
)
UPDATE public.profiles p
SET seller_level = CASE
  WHEN pc.completed_count >= 25 THEN 'top_rated'::public.seller_level_enum
  WHEN pc.completed_count >= 10 THEN 'level_2'::public.seller_level_enum
  WHEN pc.completed_count >= 3 THEN 'level_1'::public.seller_level_enum
  ELSE 'new_seller'::public.seller_level_enum
END
FROM profile_counts pc
WHERE p.id = pc.id
  AND p.seller_level IS NULL;

ALTER TABLE public.profiles
  ALTER COLUMN seller_level SET DEFAULT 'new_seller'::public.seller_level_enum;

UPDATE public.profiles
SET seller_level = 'new_seller'::public.seller_level_enum
WHERE seller_level IS NULL;

ALTER TABLE public.profiles
  ALTER COLUMN seller_level SET NOT NULL;

commit;
