-- ============================================================================
-- Phase 3: Freeze Legacy Wallet Transactions
-- File: 20260225_freeze_wallet_transactions.sql
-- Description: Blocks all INSERT/UPDATE/DELETE operations on the legacy
--              wallet_transactions table. Forces use of new ledger system.
-- ============================================================================

-- ============================================================================
-- 1. CREATE FREEZE TRIGGER FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION trg_wallet_transactions_freeze_fn()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'wallet_transactions is frozen. Use process_payment_event_ledger RPC instead. ' ||
                    'Operation: %, Table: wallet_transactions, Attempted at: %',
                    TG_OP, NOW();
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. CREATE FREEZE TRIGGER
-- ============================================================================

DROP TRIGGER IF EXISTS trg_wallet_transactions_freeze ON public.wallet_transactions;

CREATE TRIGGER trg_wallet_transactions_freeze
    BEFORE INSERT OR UPDATE OR DELETE ON public.wallet_transactions
    FOR EACH ROW
    EXECUTE FUNCTION trg_wallet_transactions_freeze_fn();

-- ============================================================================
-- 3. ADD COMMENT
-- ============================================================================

COMMENT ON FUNCTION trg_wallet_transactions_freeze_fn IS 
'Prevents all writes to wallet_transactions table. Legacy table frozen after migration to ledger system.';

-- ============================================================================
-- 4. ROLLBACK INSTRUCTIONS (as comment)
-- ============================================================================

/*
ROLLBACK INSTRUCTIONS:
If you need to unfreeze wallet_transactions temporarily:

1. Drop the trigger:
   DROP TRIGGER IF EXISTS trg_wallet_transactions_freeze ON public.wallet_transactions;

2. Drop the function (optional):
   DROP FUNCTION IF EXISTS trg_wallet_transactions_freeze_fn();

3. To re-enable, re-run this migration.
*/

-- ============================================================================
-- End of Migration
-- ============================================================================
