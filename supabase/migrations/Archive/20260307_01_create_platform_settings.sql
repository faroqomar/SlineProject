-- ============================================================================
-- Migration: Create platform_settings table for Dynamic Platform Fee
-- Phase: 1.1 Schema - Create platform_settings table
-- Date: 2026-03-07
-- Depends: None (additive)
-- ============================================================================

BEGIN;

-- Create platform_settings table
CREATE TABLE IF NOT EXISTS public.platform_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now(),
    updated_by UUID REFERENCES auth.users(id)
);

-- Add comment
COMMENT ON TABLE public.platform_settings IS 'Global platform configuration. Modified by admins only. RLS protected.';

-- Seed initial values (feature disabled by default)
INSERT INTO public.platform_settings (key, value) VALUES
('fee_rate_default_bps', '{"value": 1000}'),    -- 10% default
('max_fee_rate_bps', '{"value": 3000}'),          -- 30% max
('fee_locking_enabled', '{"value": false}')       -- Feature disabled initially
ON CONFLICT (key) DO NOTHING;

-- Enable RLS
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "platform_settings_read"
ON public.platform_settings FOR SELECT
TO authenticated USING (true);

CREATE POLICY "platform_settings_write_admin"
ON public.platform_settings FOR ALL
TO authenticated 
USING (auth.uid() IN (SELECT user_id FROM admin_users))
WITH CHECK (auth.uid() IN (SELECT user_id FROM admin_users));

CREATE POLICY "platform_settings_no_anon"
ON public.platform_settings FOR ALL
TO anon USING (false);

-- Create audit trigger function
CREATE OR REPLACE FUNCTION fn_log_platform_settings_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO admin_logs (action, table_name, record_id, old_data, new_data, performed_by)
    VALUES (
        'UPDATE', 
        'platform_settings', 
        NEW.key, 
        jsonb_build_object('value', OLD.value), 
        jsonb_build_object('value', NEW.value), 
        NEW.updated_by
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create audit trigger
DROP TRIGGER IF EXISTS trg_log_platform_settings_change ON public.platform_settings;
CREATE TRIGGER trg_log_platform_settings_change
AFTER UPDATE ON public.platform_settings
FOR EACH ROW EXECUTE FUNCTION fn_log_platform_settings_change();

-- Log migration completion
DO $$
BEGIN
    RAISE NOTICE '✅ platform_settings table created with RLS and audit logging';
END $$;

COMMIT;
