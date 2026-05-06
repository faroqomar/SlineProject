# Docs Sync — replace_task_request update-in-place, 20260322 migrations, wallet & error mapper

**Date:** 2026-03-22

## Doc files updated

| File | Summary of changes |
|------|--------------------|
| `Sline_everything/SUPABASE_SETUP.md` | replace_task_request: described as **update-in-place** (no withdraw+insert), no active_role gate, single overload `(p_task_id, p_freelancer_id, p_message, p_price NUMERIC, p_days)`; errors including `no_pending_offer_to_replace`. §9 short blurb, §9.6 long description, §15 test snippet, §17 changelog. New Version 2.20.2: 20260322000000 (get_public_system_config), 20260322000001 (ledger parameter 40 text cast), 20260322000002–000005 (replace_task_request sequence). Version 2.18.1 note superseded by 2.20.2. |
| `Sline_everything/DEVELOPER_GUIDE.md` | §4.3 replace_task_request: update-in-place, no active_role, errors list. Data flow diagram: "(update in place)" instead of "(withdraw + insert)". Error mapping: generic user-facing messages, _looksLikeTechnicalMessage, TaskRequestsService._mapReplaceOfferError for no_pending_offer_to_replace and ambiguity. Wallet: WalletViewModel refresh after withdrawal, ensureLoaded _loadingFuture. Migration table: 20260322000002–000005 for replace_task_request. |
| `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md` | WalletViewModel: refresh balance and activities after withdrawal; ensureLoaded() uses _loadingFuture for concurrent callers. |
| `Sline_everything/Sline_Log.md` | New top entry for 2026-03-22 (replace_task_request update-in-place, 20260322 migrations, wallet & error mapper). Last Updated set to 2026-03-22. Tasks Tender Fix section: added "Current behavior (2026-03-22)" pointer. Migration list: 20260311* replaced by 20260322000002–000005. |
| `Sline_everything/FEATURE_BID_FLOW.md` | Migration table: replace_task_request row updated to 20260322000002–000005, update-in-place, final migration 20260322000005. |
| `Sline_everything/AppDigram/All_Diagrams/04_task-request-bid-flow.md` | State diagram: "Freelancer replaces (replace_task_request; update in place)"; removed "pending → withdrawn: Freelancer replaces (old row)". |

## References validated

- Migration filenames confirmed present: `supabase/migrations/20260322000000_ensure_get_public_system_config.sql`, `20260322000001_ledger_parameter_40_text_cast.sql`, `20260322000002_fix_replace_task_request_single_overload.sql`, `20260322000003_replace_task_request_no_role_gate.sql`, `20260322000004_replace_task_request_set_deleted_at.sql`, `20260322000005_replace_task_request_update_in_place.sql`.
- RPC signature and behavior taken from `20260322000005_replace_task_request_update_in_place.sql`.
- No code or migration SQL was edited; documentation only.

## Why each update was needed

- **replace_task_request**: Implementation changed from withdraw+insert to update-in-place; role gate removed; single overload and new error `no_pending_offer_to_replace` are the current contract. Docs had to match so developers and error mapper reference the same behavior.
- **20260322 migrations**: New migrations (system_config, ledger parameter 40, replace_task_request sequence) required changelog and RPC/function documentation.
- **Wallet / error mapper**: App-side behavior (refresh after withdrawal, ensureLoaded coalescing, generic error messages and replace-offer mapping) is now documented for maintainers.
