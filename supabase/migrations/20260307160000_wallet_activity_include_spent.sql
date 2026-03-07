-- ============================================================================
-- Wallet Activity: Include Spent Transactions (gateway_escrow)
-- File: 20260307160000_wallet_activity_include_spent.sql
-- Description: Expands vw_wallet_activity_user to include client "spent"
--              transactions from gateway payments (QiCard). These use
--              user_pending_withdrawal DEBIT, not user_available.
-- ============================================================================

DROP VIEW IF EXISTS public.vw_wallet_activity_user;

CREATE VIEW public.vw_wallet_activity_user
WITH (security_invoker = on) AS
WITH user_ledger_lines AS (
    SELECT 
        ll.id AS ledger_line_id,
        ll.journal_entry_id,
        ll.account_id,
        ll.direction,
        ll.amount,
        ll.currency
    FROM public.ledger_lines ll
    JOIN public.accounts a ON ll.account_id = a.id
    WHERE a.owner_id = auth.uid()
    AND (
        a.account_code LIKE 'user_available:%'
        OR (a.account_code LIKE 'user_pending_withdrawal:%' AND ll.direction = 'DEBIT'::public.ledger_direction_enum)
    )
),
user_journals AS (
    SELECT DISTINCT
        je.id AS journal_entry_id,
        je.event_type,
        je.related_entity_type,
        je.related_entity_id,
        je.created_at,
        je.meta,
        je.currency
    FROM public.journal_entries je
    JOIN user_ledger_lines ull ON je.id = ull.journal_entry_id
    WHERE je.status = 'posted'
)
SELECT 
    uj.journal_entry_id,
    uj.created_at,
    uj.event_type,
    -- Gross amount (total transaction amount)
    COALESCE((
        SELECT SUM(ll.amount)
        FROM public.ledger_lines ll
        JOIN public.accounts a ON ll.account_id = a.id
        WHERE ll.journal_entry_id = uj.journal_entry_id
        AND a.account_code NOT IN ('platform_revenue')
        AND ll.direction = (CASE 
            WHEN uj.event_type IN ('escrow_hold', 'withdrawal_request', 'gateway_escrow') THEN 'DEBIT'::public.ledger_direction_enum
            ELSE 'CREDIT'::public.ledger_direction_enum
        END)
    ), 0) AS amount_gross,
    -- Net amount (what the user actually received/paid excluding fees)
    COALESCE((
        SELECT SUM(CASE WHEN ull.direction = 'CREDIT'::public.ledger_direction_enum THEN ull.amount ELSE -ull.amount END)
        FROM user_ledger_lines ull
        WHERE ull.journal_entry_id = uj.journal_entry_id
    ), 0) AS amount_net,
    -- Fee amount (if applicable)
    COALESCE((
        SELECT SUM(ll.amount)
        FROM public.ledger_lines ll
        JOIN public.accounts a ON ll.account_id = a.id
        WHERE ll.journal_entry_id = uj.journal_entry_id
        AND a.account_code = 'platform_revenue'
    ), 0) AS fee_amount,
    uj.currency,
    uj.related_entity_type,
    uj.related_entity_id,
    -- Counterparty user ID
    CASE 
        WHEN uj.event_type = 'escrow_hold' THEN (uj.meta->>'provider_id')::UUID
        WHEN uj.event_type = 'gateway_escrow' THEN (uj.meta->>'provider_id')::UUID
        WHEN uj.event_type = 'release_with_fee' THEN (uj.meta->>'client_id')::UUID
        WHEN uj.event_type = 'refund' THEN (uj.meta->>'provider_id')::UUID
        ELSE NULL
    END AS counterparty_user_id,
    -- Status derived from journal status
    'posted'::TEXT AS status
FROM user_journals uj
ORDER BY uj.created_at DESC;

COMMENT ON VIEW public.vw_wallet_activity_user IS 
'User wallet activity including received (user_available) and spent (user_available DEBIT, user_pending_withdrawal DEBIT for gateway_escrow) transactions.';
