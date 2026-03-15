-- Migration: 20260306120000_auth_profile_orphan_sweeper.sql
-- Purpose: Orphaned auth.users cleanup (no matching profiles) for auth-profile-provisioning hardening.
-- Pre-verification: pg_cron is available (pg_available_extensions) but may not be installed;
--   if installed_version is null, cron schedule step is skipped (see comment at end).

-- 1. Orphan monitoring view (for observability and manual checks)
CREATE OR REPLACE VIEW vw_orphaned_auth_users AS
SELECT u.id, u.email, u.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- 2. Sweeper function: deletes auth.users with no profile, older than 15 minutes
CREATE OR REPLACE FUNCTION sweep_orphaned_auth_users()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    deleted_count integer;
BEGIN
    DELETE FROM auth.users
    WHERE id NOT IN (SELECT id FROM public.profiles)
      AND created_at < NOW() - INTERVAL '15 minutes';

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE 'Orphan sweep completed: % users deleted', deleted_count;

    RETURN deleted_count;
END;
$$;

-- 3. Cron schedule: see 20260306120100_pg_cron_orphan_sweeper_schedule.sql
--    (enables pg_cron and schedules sweep every 15 minutes)
