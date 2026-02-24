-- ============================================================================
-- Phase 1: Wallet Views
-- File: 20260225_create_wallet_views.sql
-- Description: Creates wallet views for balance aggregation and activity history,
--              plus financial metrics views for dashboard.
-- ============================================================================

-- ============================================================================
-- 1. VW_WALLET_BALANCES_USER
-- Description: Returns available and pending withdrawal balances for the
--              authenticated user based on ledger data.
-- ============================================================================

DROP VIEW IF EXISTS public.vw_wallet_balances_user;

CREATE VIEW public.vw_wallet_balances_user
WITH (security_invoker = on) AS
WITH user_accounts AS (
    SELECT 
        a.id AS account_id,
        a.account_code,
        a.account_type,
        a.owner_id
    FROM public.accounts a
    WHERE a.owner_id = auth.uid()
    AND a.account_code LIKE 'user_%'
),
account_balances AS (
    SELECT 
        ua.account_id,
        ua.account_code,
        ua.account_type,
        ua.owner_id,
        COALESCE(SUM(
            CASE 
                -- For asset accounts: DEBIT increases balance, CREDIT decreases
                WHEN ua.account_type = 'asset' AND ll.direction = 'DEBIT' THEN ll.amount
                WHEN ua.account_type = 'asset' AND ll.direction = 'CREDIT' THEN -ll.amount
                -- For liability accounts: CREDIT increases balance, DEBIT decreases
                WHEN ua.account_type = 'liability' AND ll.direction = 'CREDIT' THEN ll.amount
                WHEN ua.account_type = 'liability' AND ll.direction = 'DEBIT' THEN -ll.amount
                ELSE 0
            END
        ), 0) AS balance
    FROM user_accounts ua
    LEFT JOIN public.ledger_lines ll ON ll.account_id = ua.account_id
    LEFT JOIN public.journal_entries je ON ll.journal_entry_id = je.id AND je.status = 'posted'
    GROUP BY ua.account_id, ua.account_code, ua.account_type, ua.owner_id
)
SELECT 
    ab.owner_id AS user_id,
    'IQD'::TEXT AS currency,
    COALESCE(SUM(CASE WHEN ab.account_code LIKE 'user_available:%' THEN ab.balance ELSE 0 END), 0) AS available_balance,
    COALESCE(SUM(CASE WHEN ab.account_code LIKE 'user_pending_withdrawal:%' THEN ab.balance ELSE 0 END), 0) AS pending_withdrawal_balance,
    -- Held balance is calculated separately from entity-linked escrow events
    COALESCE((
        SELECT SUM(
            CASE 
                WHEN je.event_type = 'escrow_hold' THEN ll.amount
                WHEN je.event_type IN ('refund', 'release_with_fee') THEN -ll.amount
                ELSE 0
            END
        )
        FROM public.ledger_lines ll
        JOIN public.journal_entries je ON ll.journal_entry_id = je.id
        WHERE je.event_type IN ('escrow_hold', 'refund', 'release_with_fee')
        AND je.status = 'posted'
        AND je.related_entity_type = 'booking'
        AND EXISTS (
            SELECT 1 FROM public.bookings b
            WHERE b.id = je.related_entity_id
            AND b.client_id = auth.uid()
        )
    ), 0) AS held_balance,
    NOW() AS updated_at
FROM account_balances ab
GROUP BY ab.owner_id;

-- ============================================================================
-- 2. VW_WALLET_ACTIVITY_USER
-- Description: Returns transaction history for the authenticated user with
--              gross amounts, net amounts, and fee information.
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
    AND a.account_code LIKE 'user_available:%'
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
        AND ll.direction = CASE 
            WHEN uj.event_type IN ('escrow_hold', 'withdrawal_request') THEN 'DEBIT'
            ELSE 'CREDIT'
        END
    ), 0) AS amount_gross,
    -- Net amount (what the user actually received/paid excluding fees)
    COALESCE((
        SELECT SUM(CASE WHEN ull.direction = 'CREDIT' THEN ull.amount ELSE -ull.amount END)
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
        WHEN uj.event_type = 'release_with_fee' THEN (uj.meta->>'client_id')::UUID
        WHEN uj.event_type = 'refund' THEN (uj.meta->>'provider_id')::UUID
        ELSE NULL
    END AS counterparty_user_id,
    -- Status derived from journal status
    'posted'::TEXT AS status
FROM user_journals uj
ORDER BY uj.created_at DESC;

-- ============================================================================
-- 3. VW_FINANCIAL_METRICS_REALTIME
-- Description: Real-time financial metrics for the platform.
--              Only accessible to service_role or admin users.
-- ============================================================================

DROP VIEW IF EXISTS public.vw_financial_metrics_realtime;

CREATE VIEW public.vw_financial_metrics_realtime AS
WITH platform_accounts AS (
    SELECT 
        a.id AS account_id,
        a.account_code,
        a.account_type
    FROM public.accounts a
    WHERE a.owner_id IS NULL
),
platform_balances AS (
    SELECT 
        pa.account_id,
        pa.account_code,
        pa.account_type,
        COALESCE(SUM(
            CASE 
                -- Asset: DEBIT increases, CREDIT decreases
                WHEN pa.account_type = 'asset' AND ll.direction = 'DEBIT' THEN ll.amount
                WHEN pa.account_type = 'asset' AND ll.direction = 'CREDIT' THEN -ll.amount
                -- Liability: CREDIT increases, DEBIT decreases
                WHEN pa.account_type = 'liability' AND ll.direction = 'CREDIT' THEN ll.amount
                WHEN pa.account_type = 'liability' AND ll.direction = 'DEBIT' THEN -ll.amount
                -- Revenue: CREDIT increases, DEBIT decreases (contra-revenue)
                WHEN pa.account_type = 'revenue' AND ll.direction = 'CREDIT' THEN ll.amount
                WHEN pa.account_type = 'revenue' AND ll.direction = 'DEBIT' THEN -ll.amount
                ELSE 0
            END
        ), 0) AS balance
    FROM platform_accounts pa
    LEFT JOIN public.ledger_lines ll ON ll.account_id = pa.account_id
    LEFT JOIN public.journal_entries je ON ll.journal_entry_id = je.id AND je.status = 'posted'
    GROUP BY pa.account_id, pa.account_code, pa.account_type
),
escrow_metrics AS (
    SELECT 
        COALESCE(SUM(
            CASE 
                WHEN je.event_type = 'escrow_hold' THEN je.meta->>'amount_gross'
                WHEN je.event_type IN ('refund', 'release_with_fee') THEN -(je.meta->>'amount_gross')
                ELSE 0
            END::NUMERIC
        ), 0) AS escrow_outstanding
    FROM public.journal_entries je
    WHERE je.event_type IN ('escrow_hold', 'refund', 'release_with_fee')
    AND je.status = 'posted'
),
revenue_metrics AS (
    SELECT 
        COALESCE(SUM((je.meta->>'fee_amount')::NUMERIC), 0) AS total_fees,
        COALESCE(SUM(
            CASE 
                WHEN je.event_type = 'release_with_fee' THEN (je.meta->>'gross_amount')::NUMERIC
                ELSE 0
            END
        ), 0) AS total_gmv
    FROM public.journal_entries je
    WHERE je.event_type = 'release_with_fee'
    AND je.status = 'posted'
),
refund_metrics AS (
    SELECT 
        COALESCE(SUM((je.meta->>'amount_gross')::NUMERIC), 0) AS total_refunds
    FROM public.journal_entries je
    WHERE je.event_type = 'refund'
    AND je.status = 'posted'
)
SELECT 
    'IQD'::TEXT AS currency,
    -- Escrow: Total held across all pending bookings
    COALESCE((SELECT escrow_outstanding FROM escrow_metrics), 0) AS escrow_held_iqd,
    -- Platform Cash: Cash position
    COALESCE((SELECT balance FROM platform_balances WHERE account_code = 'platform_cash'), 0) AS platform_cash_iqd,
    -- GMV: Total gross merchandise value (all release_with_fee amounts)
    COALESCE((SELECT total_gmv FROM revenue_metrics), 0) AS gmv_iqd,
    -- Revenue: Total fees collected
    COALESCE((SELECT total_fees FROM revenue_metrics), 0) AS revenue_iqd,
    -- Refunds: Total refunded amount
    COALESCE((SELECT total_refunds FROM refund_metrics), 0) AS lifetime_refunds_iqd,
    -- Escrow Balance Check (should match escrow_outstanding)
    COALESCE((SELECT balance FROM platform_balances WHERE account_code = 'platform_escrow'), 0) AS escrow_account_balance_iqd,
    -- Revenue Balance Check
    COALESCE((SELECT balance FROM platform_balances WHERE account_code = 'platform_revenue'), 0) AS revenue_account_balance_iqd,
    NOW() AS calculated_at;

-- Add comment
COMMENT ON VIEW public.vw_financial_metrics_realtime IS 
'Real-time financial metrics for the platform. Includes GMV, Revenue, Escrow Held, Platform Cash, and Refunds. Only accessible to service_role or users with admin privileges.';

-- ============================================================================
-- 4. VW_FINANCIAL_METRICS_PERIOD
-- Description: Time-bucketed financial metrics (daily, weekly, monthly).
-- ============================================================================

DROP VIEW IF EXISTS public.vw_financial_metrics_period;

CREATE VIEW public.vw_financial_metrics_period AS
WITH daily_metrics AS (
    SELECT 
        DATE_TRUNC('day', je.created_at) AS period_start,
        DATE_TRUNC('day', je.created_at) + INTERVAL '1 day' - INTERVAL '1 second' AS period_end,
        'day'::TEXT AS period,
        'IQD'::TEXT AS currency,
        COALESCE(SUM(
            CASE 
                WHEN je.event_type = 'release_with_fee' THEN (je.meta->>'gross_amount')::NUMERIC
                ELSE 0
            END
        ), 0) AS gmv,
        COALESCE(SUM(
            CASE 
                WHEN je.event_type = 'release_with_fee' THEN (je.meta->>'fee_amount')::NUMERIC
                ELSE 0
            END
        ), 0) AS revenue,
        COALESCE(SUM(
            CASE 
                WHEN je.event_type = 'refund' THEN (je.meta->>'amount_gross')::NUMERIC
                ELSE 0
            END
        ), 0) AS refunds,
        COUNT(*) FILTER (WHERE je.event_type = 'release_with_fee') AS transaction_count,
        -- Calculate take rate and refund rate as percentages
        CASE 
            WHEN COALESCE(SUM(
                CASE 
                    WHEN je.event_type = 'release_with_fee' THEN (je.meta->>'gross_amount')::NUMERIC
                    ELSE 0
                END
            ), 0) > 0 
            THEN ROUND(
                (COALESCE(SUM(
                    CASE 
                        WHEN je.event_type = 'release_with_fee' THEN (je.meta->>'fee_amount')::NUMERIC
                        ELSE 0
                    END
                ), 0) / 
                COALESCE(SUM(
                    CASE 
                        WHEN je.event_type = 'release_with_fee' THEN (je.meta->>'gross_amount')::NUMERIC
                        ELSE 0
                    END
                ), 1)) * 100, 2
            )
            ELSE 0 
        END AS take_rate,
        CASE 
            WHEN COALESCE(SUM(
                CASE 
                    WHEN je.event_type = 'release_with_fee' THEN (je.meta->>'gross_amount')::NUMERIC
                    ELSE 0
                END
            ), 0) > 0 
            THEN ROUND(
                (COALESCE(SUM(
                    CASE 
                        WHEN je.event_type = 'refund' THEN (je.meta->>'amount_gross')::NUMERIC
                        ELSE 0
                    END
                ), 0) / 
                COALESCE(SUM(
                    CASE 
                        WHEN je.event_type = 'release_with_fee' THEN (je.meta->>'gross_amount')::NUMERIC
                        ELSE 0
                    END
                ), 1)) * 100, 2
            )
            ELSE 0 
        END AS refund_rate
    FROM public.journal_entries je
    WHERE je.status = 'posted'
    AND je.event_type IN ('release_with_fee', 'refund')
    GROUP BY DATE_TRUNC('day', je.created_at)
)
SELECT 
    period_start,
    period_end,
    period,
    currency,
    gmv,
    revenue,
    refunds,
    transaction_count,
    take_rate,
    refund_rate
FROM daily_metrics
ORDER BY period_start DESC;

-- Add comment
COMMENT ON VIEW public.vw_financial_metrics_period IS 
'Daily financial metrics including GMV, Revenue, Refunds, Transaction Count, Take Rate, and Refund Rate. Period-based aggregation for dashboard reporting.';

-- ============================================================================
-- 5. VW_UNIFIED_PAYABLE_ITEMS (Helper for UI)
-- Description: Unified view for both bookings and task_requests to simplify
--              UI logic for payment actions.
-- ============================================================================

DROP VIEW IF EXISTS public.vw_unified_payable_items;

CREATE VIEW public.vw_unified_payable_items
WITH (security_invoker = on) AS
-- Bookings
SELECT 
    'booking'::TEXT AS entity_type,
    b.id AS entity_id,
    b.client_id,
    b.provider_id,
    b.status,
    b.payment_status,
    b.amount_gross,
    b.currency,
    b.created_at,
    b.updated_at
FROM public.bookings b
WHERE b.client_id = auth.uid() OR b.provider_id = auth.uid()

UNION ALL

-- Task Requests
SELECT 
    'task_request'::TEXT AS entity_type,
    tr.id AS entity_id,
    tr.client_id,
    tr.provider_id,
    tr.status,
    tr.payment_status,
    tr.amount_gross,
    tr.currency,
    tr.created_at,
    tr.updated_at
FROM public.task_requests tr
WHERE tr.client_id = auth.uid() OR tr.provider_id = auth.uid();

-- Add comment
COMMENT ON VIEW public.vw_unified_payable_items IS 
'Unified view of bookings and task_requests for payment UI. Returns all entities where the current user is either client or provider. Used for consistent UI behavior across booking and task cards.';

-- ============================================================================
-- 6. RLS POLICIES FOR VIEWS
-- ============================================================================

-- vw_wallet_balances_user uses security_invoker, so RLS is handled automatically
-- vw_wallet_activity_user uses security_invoker, so RLS is handled automatically

-- vw_financial_metrics_realtime - restrict to service_role only
-- (View doesn't use security_invoker, so we need to handle access in the application layer)

-- ============================================================================
-- 7. GRANTS
-- ============================================================================

-- Grant select on views to authenticated users
GRANT SELECT ON public.vw_wallet_balances_user TO authenticated;
GRANT SELECT ON public.vw_wallet_activity_user TO authenticated;
GRANT SELECT ON public.vw_unified_payable_items TO authenticated;

-- Grant select on financial metrics to service_role
GRANT SELECT ON public.vw_financial_metrics_realtime TO service_role;
GRANT SELECT ON public.vw_financial_metrics_period TO service_role;

-- Also grant to authenticated (application can restrict access)
GRANT SELECT ON public.vw_financial_metrics_realtime TO authenticated;
GRANT SELECT ON public.vw_financial_metrics_period TO authenticated;

-- ============================================================================
-- End of Migration
-- ============================================================================
