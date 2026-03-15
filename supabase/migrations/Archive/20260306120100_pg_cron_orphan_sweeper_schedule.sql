-- Migration: 20260306120100_pg_cron_orphan_sweeper_schedule.sql
-- Purpose: Enable pg_cron and schedule orphan auth sweep (depends on sweep_orphaned_auth_users() from 20260306120000).

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;

-- Idempotent: schedule only if job does not exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'sweep-orphaned-auth-users') THEN
    PERFORM cron.schedule(
      'sweep-orphaned-auth-users',
      '*/15 * * * *',
      'SELECT sweep_orphaned_auth_users()'
    );
  END IF;
END
$$;
