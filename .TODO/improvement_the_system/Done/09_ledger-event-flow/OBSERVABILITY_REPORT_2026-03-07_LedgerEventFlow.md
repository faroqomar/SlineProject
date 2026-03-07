# Observability Report: Ledger Event Flow (09_ledger-event-flow)

**Scope:** Ledger Event Flow — PLAN_LedgerEventFlow_2026-03-07  
**Date:** 2026-03-07  
**Plan:** `.TODO/PLAN_LedgerEventFlow_2026-03-07.md`

---

## 1. Files Scanned (Evidence)

- `lib/features/wallet/services/ledger_service.dart`
- `test/unit/wallet/ledger_service_test.dart`, `wallet_service_test.dart`, `test/rls/ledger_rls_test.dart`
- Contract and runbook (forensics, smoke checklist)

---

## 2. What Is Logged (Current)

| Location | Event / Level | Fields | Privacy |
|----------|----------------|--------|---------|
| LedgerService.submitPaymentEvent (start) | AppLogger.i | tag: LedgerService, message: event type + entity type + entity id | No PII; entity id is UUID |
| LedgerService (RPC ok: false) | AppLogger.e | tag, error (code/message from RPC) | No raw tokens; error text may be user-facing |
| LedgerService (success) | AppLogger.i | tag, event type + entity type + entity id | No PII |
| LedgerService (PostgrestException) | AppLogger.e | tag, error (e) | No credentials in exception |
| LedgerService (unexpected catch) | AppLogger.e | tag, error | Safe if no stack contains secrets |
| Tests | AppLogger.d/i | tag: ledger_service_test, wallet_service_test, ledger_rls_test | Test-only |

---

## 3. Telemetry Gaps (None Critical)

- **Correlation:** No explicit `request_id` or correlation id in log messages. Contract allows optional `request_id` in p_meta; not yet added. For dispute forensics, `session_id` + journal id (from RPC result) is sufficient. **Recommendation:** Optional later: add a short-lived request_id in meta for high-value flows.
- **Metrics:** No dedicated metric for “ledger_event_submitted” / “ledger_event_failed” (e.g. counter). Acceptable for current scope; add if product needs dashboards.

---

## 4. What NOT to Log (Compliance)

- **Do not log:** p_meta or meta contents in full (could contain PSP payloads or other sensitive data). Current code does not log meta.
- **Do not log:** idempotency_key in plaintext in production if it can be tied to user actions; current code logs only event type and entity ids, which is acceptable.

---

## 5. Correlation Strategy

- **Support/disputes:** Use `journal_entries.id` (returned in RPC result) + `journal_entries.meta->>'session_id'` to correlate with auth user. App side: tag `LedgerService` + event type + entity id is enough to find the relevant log line.

---

## 6. Conclusion

- **Observability:** Sufficient for plan. AppLogger only; no print(); no sensitive data in logs; forensics (session_id) in DB for audit.
- **Blocker:** None.
