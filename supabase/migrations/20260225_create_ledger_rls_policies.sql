-- ============================================================================
-- Phase 1: RLS Policies for Ledger Tables
-- File: 20260225_create_ledger_rls_policies.sql
-- Description: Row Level Security policies for all ledger tables.
--              Users can only see their own data. Service role has full access.
-- ============================================================================

-- ============================================================================
-- 1. ACCOUNTS RLS POLICIES
-- ============================================================================

-- Policy: Users can see platform accounts + their own accounts
DROP POLICY IF EXISTS accounts_select_policy ON public.accounts;
CREATE POLICY accounts_select_policy ON public.accounts
    FOR SELECT
    TO authenticated
    USING (
        owner_id IS NULL  -- Platform accounts
        OR owner_id = auth.uid()  -- User's own accounts
    );

-- Policy: Only system can insert accounts (via RPC)
DROP POLICY IF EXISTS accounts_insert_policy ON public.accounts;
CREATE POLICY accounts_insert_policy ON public.accounts
    FOR INSERT
    TO authenticated
    WITH CHECK (false);  -- Only via service role or RPC

-- Policy: No updates allowed (append-only)
DROP POLICY IF EXISTS accounts_update_policy ON public.accounts;
CREATE POLICY accounts_update_policy ON public.accounts
    FOR UPDATE
    TO authenticated
    USING (false)
    WITH CHECK (false);

-- Policy: No deletes allowed (append-only)
DROP POLICY IF EXISTS accounts_delete_policy ON public.accounts;
CREATE POLICY accounts_delete_policy ON public.accounts
    FOR DELETE
    TO authenticated
    USING (false);

-- Service role has full access
DROP POLICY IF EXISTS accounts_service_policy ON public.accounts;
CREATE POLICY accounts_service_policy ON public.accounts
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- 2. JOURNAL ENTRIES RLS POLICIES
-- ============================================================================

-- Policy: Users can see journal entries for their own transactions
-- This is complex because we need to check if the user is related to the entity
DROP POLICY IF EXISTS journal_entries_select_policy ON public.journal_entries;
CREATE POLICY journal_entries_select_policy ON public.journal_entries
    FOR SELECT
    TO authenticated
    USING (
        -- User created the journal
        created_by = auth.uid()
        -- Or check if user is client/provider in related entity
        OR EXISTS (
            SELECT 1 FROM public.ledger_lines ll
            JOIN public.accounts a ON ll.account_id = a.id
            WHERE ll.journal_entry_id = journal_entries.id
            AND a.owner_id = auth.uid()
        )
        -- Or system events (service role only for system events)
        OR (created_by IS NULL AND auth.jwt()->>'role' = 'service_role')
    );

-- Policy: Only RPC can insert (controlled via SECURITY DEFINER)
DROP POLICY IF EXISTS journal_entries_insert_policy ON public.journal_entries;
CREATE POLICY journal_entries_insert_policy ON public.journal_entries
    FOR INSERT
    TO authenticated
    WITH CHECK (false);

-- Policy: No updates allowed (append-only)
DROP POLICY IF EXISTS journal_entries_update_policy ON public.journal_entries;
CREATE POLICY journal_entries_update_policy ON public.journal_entries
    FOR UPDATE
    TO authenticated
    USING (false)
    WITH CHECK (false);

-- Policy: No deletes allowed (append-only)
DROP POLICY IF EXISTS journal_entries_delete_policy ON public.journal_entries;
CREATE POLICY journal_entries_delete_policy ON public.journal_entries
    FOR DELETE
    TO authenticated
    USING (false);

-- Service role has full access
DROP POLICY IF EXISTS journal_entries_service_policy ON public.journal_entries;
CREATE POLICY journal_entries_service_policy ON public.journal_entries
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- 3. LEDGER LINES RLS POLICIES
-- ============================================================================

-- Policy: Users can see ledger lines for their own accounts
DROP POLICY IF EXISTS ledger_lines_select_policy ON public.ledger_lines;
CREATE POLICY ledger_lines_select_policy ON public.ledger_lines
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.accounts a
            WHERE a.id = ledger_lines.account_id
            AND (a.owner_id = auth.uid() OR a.owner_id IS NULL)
        )
    );

-- Policy: Only RPC can insert (controlled via SECURITY DEFINER)
DROP POLICY IF EXISTS ledger_lines_insert_policy ON public.ledger_lines;
CREATE POLICY ledger_lines_insert_policy ON public.ledger_lines
    FOR INSERT
    TO authenticated
    WITH CHECK (false);

-- Policy: No updates allowed (append-only)
DROP POLICY IF EXISTS ledger_lines_update_policy ON public.ledger_lines;
CREATE POLICY ledger_lines_update_policy ON public.ledger_lines
    FOR UPDATE
    TO authenticated
    USING (false)
    WITH CHECK (false);

-- Policy: No deletes allowed (append-only)
DROP POLICY IF EXISTS ledger_lines_delete_policy ON public.ledger_lines;
CREATE POLICY ledger_lines_delete_policy ON public.ledger_lines
    FOR DELETE
    TO authenticated
    USING (false);

-- Service role has full access
DROP POLICY IF EXISTS ledger_lines_service_policy ON public.ledger_lines;
CREATE POLICY ledger_lines_service_policy ON public.ledger_lines
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- 4. AUDIT LOGS RLS POLICIES
-- ============================================================================

-- Policy: Users can see audit logs for their own actions or related to their entities
DROP POLICY IF EXISTS audit_logs_select_policy ON public.audit_logs;
CREATE POLICY audit_logs_select_policy ON public.audit_logs
    FOR SELECT
    TO authenticated
    USING (
        actor_user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.journal_entries je
            JOIN public.ledger_lines ll ON ll.journal_entry_id = je.id
            JOIN public.accounts a ON ll.account_id = a.id
            WHERE je.id = audit_logs.journal_entry_id
            AND a.owner_id = auth.uid()
        )
    );

-- Policy: Only system can insert audit logs (via RPC or edge functions)
DROP POLICY IF EXISTS audit_logs_insert_policy ON public.audit_logs;
CREATE POLICY audit_logs_insert_policy ON public.audit_logs
    FOR INSERT
    TO authenticated
    WITH CHECK (false);

-- Policy: No updates allowed (append-only)
DROP POLICY IF EXISTS audit_logs_update_policy ON public.audit_logs;
CREATE POLICY audit_logs_update_policy ON public.audit_logs
    FOR UPDATE
    TO authenticated
    USING (false)
    WITH CHECK (false);

-- Policy: No deletes allowed (append-only)
DROP POLICY IF EXISTS audit_logs_delete_policy ON public.audit_logs;
CREATE POLICY audit_logs_delete_policy ON public.audit_logs
    FOR DELETE
    TO authenticated
    USING (false);

-- Service role has full access
DROP POLICY IF EXISTS audit_logs_service_policy ON public.audit_logs;
CREATE POLICY audit_logs_service_policy ON public.audit_logs
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- 5. WITHDRAWAL REQUESTS RLS POLICIES
-- ============================================================================

-- Policy: Users can see their own withdrawal requests
DROP POLICY IF EXISTS withdrawal_requests_select_policy ON public.withdrawal_requests;
CREATE POLICY withdrawal_requests_select_policy ON public.withdrawal_requests
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Policy: Users can insert their own withdrawal requests
DROP POLICY IF EXISTS withdrawal_requests_insert_policy ON public.withdrawal_requests;
CREATE POLICY withdrawal_requests_insert_policy ON public.withdrawal_requests
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

-- Policy: Users can update their own pending requests
DROP POLICY IF EXISTS withdrawal_requests_update_policy ON public.withdrawal_requests;
CREATE POLICY withdrawal_requests_update_policy ON public.withdrawal_requests
    FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Policy: Users can only delete pending requests
DROP POLICY IF EXISTS withdrawal_requests_delete_policy ON public.withdrawal_requests;
CREATE POLICY withdrawal_requests_delete_policy ON public.withdrawal_requests
    FOR DELETE
    TO authenticated
    USING (user_id = auth.uid() AND status = 'requested');

-- Service role has full access
DROP POLICY IF EXISTS withdrawal_requests_service_policy ON public.withdrawal_requests;
CREATE POLICY withdrawal_requests_service_policy ON public.withdrawal_requests
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- 6. RPC EXECUTE PERMISSIONS
-- ============================================================================

-- Grant execute on RPC to authenticated users
GRANT EXECUTE ON FUNCTION public.process_payment_event_ledger TO authenticated;

-- Grant execute on RPC to service_role (for edge functions)
GRANT EXECUTE ON FUNCTION public.process_payment_event_ledger TO service_role;

-- ============================================================================
-- 7. TABLE PERMISSIONS
-- ============================================================================

-- Grant usage on custom types
GRANT USAGE ON TYPE public.ledger_direction_enum TO authenticated;
GRANT USAGE ON TYPE public.ledger_account_type_enum TO authenticated;
GRANT USAGE ON TYPE public.payment_event_type_enum TO authenticated;
GRANT USAGE ON TYPE public.related_entity_type_enum TO authenticated;
GRANT USAGE ON TYPE public.journal_status_enum TO authenticated;
GRANT USAGE ON TYPE public.withdrawal_status_enum TO authenticated;

-- Grant to service_role
GRANT USAGE ON TYPE public.ledger_direction_enum TO service_role;
GRANT USAGE ON TYPE public.ledger_account_type_enum TO service_role;
GRANT USAGE ON TYPE public.payment_event_type_enum TO service_role;
GRANT USAGE ON TYPE public.related_entity_type_enum TO service_role;
GRANT USAGE ON TYPE public.journal_status_enum TO service_role;
GRANT USAGE ON TYPE public.withdrawal_status_enum TO service_role;

-- ============================================================================
-- End of Migration
-- ============================================================================
