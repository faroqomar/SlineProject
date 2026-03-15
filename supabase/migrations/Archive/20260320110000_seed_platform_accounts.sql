-- Migration to ensure core platform accounts exist in the ledger
-- These are required for the ledger to function correctly.

INSERT INTO public.accounts (account_code, account_type, currency)
VALUES
    ('platform_cash', 'asset', 'IQD'),
    ('platform_escrow', 'liability', 'IQD'),
    ('platform_revenue', 'equity', 'IQD'),
    ('platform_receivable', 'asset', 'IQD'),
    ('platform_payable', 'liability', 'IQD'),
    ('platform_test_float', 'asset', 'IQD')
ON CONFLICT (account_code) DO NOTHING;
