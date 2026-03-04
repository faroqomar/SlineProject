-- Copy into sline_app/supabase/migrations/
-- Extend related_entity_type_enum for admin audit (task, admin_user, profile).
-- Requires PostgreSQL 15+ for IF NOT EXISTS; otherwise remove IF NOT EXISTS and run once.

ALTER TYPE related_entity_type_enum ADD VALUE IF NOT EXISTS 'task';
ALTER TYPE related_entity_type_enum ADD VALUE IF NOT EXISTS 'admin_user';
ALTER TYPE related_entity_type_enum ADD VALUE IF NOT EXISTS 'profile';
