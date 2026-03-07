# Architect Report: Ledger Event Flow (09_ledger-event-flow)

**Scope:** Ledger Event Flow — PLAN_LedgerEventFlow_2026-03-07  
**Date:** 2026-03-07  
**Plan:** `.TODO/PLAN_LedgerEventFlow_2026-03-07.md`

---

## 1. Files Scanned (Evidence)

- `lib/features/wallet/services/ledger_service.dart` (modified)
- `test/unit/wallet/ledger_service_test.dart` (new)
- `test/unit/wallet/wallet_service_test.dart` (new)
- `test/rls/ledger_rls_test.dart` (new)
- `.TODO/improvement_the_system/ImplementReady/09_ledger-event-flow/CONTRACT_ledger_event_flow.md` (new)
- `.TODO/improvement_the_system/ImplementReady/09_ledger-event-flow/SMOKE_CHECKLIST_AND_RUNBOOK.md` (new)
- Contract and plan references in DEVELOPER_GUIDE / Wallet_Feature

---

## 2. Architecture / Logic Findings

### 2.1 MVVM boundary check — PASS

- **LedgerService** remains in `lib/features/wallet/services/`. Only the service layer calls `_client.rpc(...)`. No View or ViewModel was given a Supabase client or direct RPC call.
- **Data flow:** View → ViewModel → LedgerService/WalletService → Supabase RPC. Single source of truth for ledger submission is LedgerService.

### 2.2 Data flow map

- **Forensics:** `_mergeForensics(meta)` reads `_client.auth.currentUser?.id` and injects `session_id` into meta when absent. Callers can still pass custom meta; forensics are merged, not overwritten. No new repository or model; contract (CONTRACT_ledger_event_flow) is the single contract for p_meta shape.

### 2.3 Contract alignment

- **CONTRACT_ledger_event_flow.md** defines `process_payment_event_ledger` params and p_meta forensics (session_id required when from app, optional request_id/device_id). LedgerService implements: (1) session_id from auth when missing, (2) p_meta passed as `metaWithForensics`. No param or key mismatch found.

### 2.4 Path / name validation

- All referenced paths exist: `logger_service.dart`, `mock_supabase.dart`, `rls_test_helper.dart`, wallet services and models. RPC name `process_payment_event_ledger` and table names `ledger_lines`, `journal_entries` match Supabase setup.

---

## 3. Proposed Refactors (Optional, Non-Blocking)

- **None required.** Optional: add a small `ForensicsProvider` or core util that returns `{session_id, request_id?}` so all ledger call sites share one forensics source; current in-service merge is acceptable and matches contract.

---

## 4. Risk Notes

- **Low:** `_mergeForensics` only adds `session_id` when null; it does not log or expose PII. Auth user id is already used in RPC context and stored in journal_entries.meta per contract.

---

## 5. Conclusion

- **Architecture:** Compliant. MVVM preserved; single service path for ledger submission; contract implemented.
- **Blocker:** None.
