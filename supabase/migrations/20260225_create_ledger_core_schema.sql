-- ============================================================================
-- Phase 1: Ledger Core Schema
-- File: 20260225_create_ledger_core_schema.sql
-- Description: Creates ENUMs, tables, triggers, and platform accounts for the
--              double-entry ledger system.
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. ENUM TYPES
-- ============================================================================

-- Direction for ledger lines
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ledger_direction_enum') THEN
        CREATE TYPE ledger_direction_enum AS ENUM ('DEBIT', 'CREDIT');
    END IF;
END $$;

-- Account types
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ledger_account_type_enum') THEN
        CREATE TYPE ledger_account_type_enum AS ENUM ('asset', 'liability', 'revenue', 'expense', 'equity');
    END IF;
END $$;

-- Payment event types
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_event_type_enum') THEN
        CREATE TYPE payment_event_type_enum AS ENUM (
            'escrow_hold',
            'release_with_fee',
            'refund',
            'deposit',
            'withdrawal_request',
            'withdrawal_complete',
            'withdrawal_failed',
            'admin_credit',
            'admin_adjustment',
            'reversal',
            'gateway_escrow'
        );
    END IF;
END $$;

-- Entity types that can be related to payment events
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'related_entity_type_enum') THEN
        CREATE TYPE related_entity_type_enum AS ENUM (
            'booking',
            'task_request',
            'withdrawal_request',
            'admin_adjustment'
        );
    END IF;
END $$;

-- Journal entry status
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'journal_status_enum') THEN
        CREATE TYPE journal_status_enum AS ENUM ('posted', 'voided');
    END IF;
END $$;

-- Withdrawal request status
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'withdrawal_status_enum') THEN
        CREATE TYPE withdrawal_status_enum AS ENUM (
            'requested',
            'processing',
            'completed',
            'failed',
            'canceled'
        );
    END IF;
END $$;

-- ============================================================================
-- 2. ACCOUNTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_code TEXT NOT NULL,
    account_type ledger_account_type_enum NOT NULL,
    owner_id UUID REFERENCES auth.users(id) ON DELETE RESTRICT,
    currency TEXT NOT NULL DEFAULT 'IQD',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT uq_accounts_account_code UNIQUE (account_code),
    CONSTRAINT ck_accounts_currency_iqd CHECK (currency = 'IQD'),
    CONSTRAINT ck_accounts_owner_validity CHECK (
        (owner_id IS NULL AND account_code NOT LIKE 'user_%') OR
        (owner_id IS NOT NULL AND account_code LIKE 'user_%:%')
    )
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_accounts_owner_id ON public.accounts(owner_id);

-- Enable RLS
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 3. JOURNAL ENTRIES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type payment_event_type_enum NOT NULL,
    related_entity_type related_entity_type_enum,
    related_entity_id UUID,
    idempotency_key TEXT NOT NULL,
    status journal_status_enum NOT NULL DEFAULT 'posted',
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    currency TEXT NOT NULL DEFAULT 'IQD',
    meta JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT uq_journal_entries_idempotency_key UNIQUE (idempotency_key),
    CONSTRAINT ck_journal_entries_currency_iqd CHECK (currency = 'IQD'),
    CONSTRAINT ck_journal_entries_entity_null_pair CHECK (
        (related_entity_type IS NULL AND related_entity_id IS NULL) OR
        (related_entity_type IS NOT NULL AND related_entity_id IS NOT NULL)
    )
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_journal_entries_entity ON public.journal_entries(related_entity_type, related_entity_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_event_type ON public.journal_entries(event_type);
CREATE INDEX IF NOT EXISTS idx_journal_entries_status ON public.journal_entries(status);
CREATE INDEX IF NOT EXISTS idx_journal_entries_created_at ON public.journal_entries(created_at);

-- Unique index for reversal tracking
CREATE UNIQUE INDEX IF NOT EXISTS uq_journal_entries_single_reversal 
ON public.journal_entries((meta->>'reversal_of_journal_entry_id')) 
WHERE meta->>'reversal_of_journal_entry_id' IS NOT NULL;

-- Enable RLS
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. LEDGER LINES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.ledger_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    journal_entry_id UUID NOT NULL REFERENCES public.journal_entries(id) ON DELETE RESTRICT,
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE RESTRICT,
    direction ledger_direction_enum NOT NULL,
    amount NUMERIC NOT NULL,
    currency TEXT NOT NULL DEFAULT 'IQD',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT ck_ledger_lines_amount_positive CHECK (amount > 0),
    CONSTRAINT ck_ledger_lines_currency_iqd CHECK (currency = 'IQD')
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ledger_lines_journal_entry_id ON public.ledger_lines(journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_ledger_lines_account_id ON public.ledger_lines(account_id);
CREATE INDEX IF NOT EXISTS idx_ledger_lines_created_at ON public.ledger_lines(created_at);

-- Enable RLS
ALTER TABLE public.ledger_lines ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. AUDIT LOGS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    related_entity_type related_entity_type_enum,
    related_entity_id UUID,
    journal_entry_id UUID REFERENCES public.journal_entries(id) ON DELETE SET NULL,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_user_id ON public.audit_logs(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_journal_entry_id ON public.audit_logs(journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action);

-- Enable RLS
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 6. WITHDRAWAL REQUESTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.withdrawal_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    status withdrawal_status_enum NOT NULL DEFAULT 'requested',
    amount NUMERIC NOT NULL,
    currency TEXT NOT NULL DEFAULT 'IQD',
    gateway_provider TEXT,
    gateway_payment_id TEXT,
    gateway_request_id TEXT,
    failure_reason TEXT,
    processed_at TIMESTAMPTZ,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT ck_withdrawal_requests_amount_positive CHECK (amount > 0),
    CONSTRAINT ck_withdrawal_requests_currency_iqd CHECK (currency = 'IQD')
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_user_id ON public.withdrawal_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status ON public.withdrawal_requests(status);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_created_at ON public.withdrawal_requests(created_at);

-- Enable RLS
ALTER TABLE public.withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_withdrawal_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_withdrawal_requests_updated_at ON public.withdrawal_requests;
CREATE TRIGGER trg_withdrawal_requests_updated_at
    BEFORE UPDATE ON public.withdrawal_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_withdrawal_requests_updated_at();

-- ============================================================================
-- 7. APPEND-ONLY TRIGGERS
-- ============================================================================

-- Journal entries append-only
CREATE OR REPLACE FUNCTION trg_journal_entries_append_only_fn()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'journal_entries is append-only. UPDATE not allowed. Journal ID: %', OLD.id;
    ELSIF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'journal_entries is append-only. DELETE not allowed. Journal ID: %', OLD.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_journal_entries_append_only ON public.journal_entries;
CREATE TRIGGER trg_journal_entries_append_only
    BEFORE UPDATE OR DELETE ON public.journal_entries
    FOR EACH ROW
    EXECUTE FUNCTION trg_journal_entries_append_only_fn();

-- Ledger lines append-only
CREATE OR REPLACE FUNCTION trg_ledger_lines_append_only_fn()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'ledger_lines is append-only. UPDATE not allowed. Line ID: %', OLD.id;
    ELSIF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'ledger_lines is append-only. DELETE not allowed. Line ID: %', OLD.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_ledger_lines_append_only ON public.ledger_lines;
CREATE TRIGGER trg_ledger_lines_append_only
    BEFORE UPDATE OR DELETE ON public.ledger_lines
    FOR EACH ROW
    EXECUTE FUNCTION trg_ledger_lines_append_only_fn();

-- Accounts append-only (optional but recommended)
CREATE OR REPLACE FUNCTION trg_accounts_append_only_fn()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        -- Allow updates only to owner_id for user accounts (migration edge cases)
        IF OLD.account_code LIKE 'user_%' AND NEW.account_code = OLD.account_code THEN
            RETURN NEW;
        END IF;
        RAISE EXCEPTION 'accounts is append-only. UPDATE not allowed except owner_id for user accounts. Account ID: %', OLD.id;
    ELSIF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'accounts is append-only. DELETE not allowed. Account ID: %', OLD.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_accounts_append_only ON public.accounts;
CREATE TRIGGER trg_accounts_append_only
    BEFORE UPDATE OR DELETE ON public.accounts
    FOR EACH ROW
    EXECUTE FUNCTION trg_accounts_append_only_fn();

-- ============================================================================
-- 8. CREATE PLATFORM ACCOUNTS
-- ============================================================================

INSERT INTO public.accounts (account_code, account_type, owner_id, currency)
VALUES
    ('platform_cash', 'asset', NULL, 'IQD'),
    ('platform_escrow', 'liability', NULL, 'IQD'),
    ('platform_revenue', 'revenue', NULL, 'IQD'),
    ('platform_test_float', 'asset', NULL, 'IQD')
ON CONFLICT (account_code) DO NOTHING;

-- ============================================================================
-- 9. COMMENTS
-- ============================================================================

COMMENT ON TABLE public.accounts IS 'Chart of accounts for double-entry ledger system. Platform accounts have NULL owner_id. User accounts have owner_id and account_code like user_<type>:<user_id>';
COMMENT ON TABLE public.journal_entries IS 'Header records for financial transactions. Append-only. Status controls visibility in balances (posted vs voided).';
COMMENT ON TABLE public.ledger_lines IS 'Individual debit/credit lines for each journal entry. Append-only. Must balance (sum debits = sum credits) per journal.';
COMMENT ON TABLE public.audit_logs IS 'Audit trail for all payment-related actions. Written by RPC and edge functions.';
COMMENT ON TABLE public.withdrawal_requests IS 'User withdrawal requests. Status tracks request through gateway processing.';

-- ============================================================================
-- End of Migration
-- ============================================================================
