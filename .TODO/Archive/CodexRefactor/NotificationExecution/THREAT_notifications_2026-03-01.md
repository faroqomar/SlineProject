# Threat Model: Notifications (2026-03-01)

## In scope

- Cross-user notification injection (client writing to another user's notifications).
- Unauthorized read/update of notifications (RLS bypass).
- `task_request` route misuse (e.g. opening wrong conversation/task).
- Stale-session stream behavior (notifications after logout or wrong user).
- Metadata/ID leakage in logs or crash reports.
- Deterministic test seed abuse (e.g. fixture IDs in prod paths).

## Mitigations (mapped to phases)

1. **Cross-user writes**  
   Client never inserts into `public.notifications`. Server-only via triggers/RPC. RLS denies authenticated insert. Phase 2 grep gate; Phase 4/5 two-user insert-denied check.

2. **Read/update authz**  
   RLS: select_own, update_own. Client adds current-user filter as defense-in-depth. Phase 2 RLS matrix; Phase 5 two-user select/update checks.

3. **task_request routing**  
   App resolves from metadata (conversation_id first, else task_id); no arbitrary navigation. Phase 3 routing adapter; Phase 5 tests.

4. **Stale session**  
   Auth-aware ViewModel: connect when session ready, clear state and disconnect on logout. Phase 3 lifecycle; Phase 5 lifecycle tests.

5. **Log/crash privacy**  
   No message body or PII in logs; type/entity type/IDs only. Observability redaction rules. Phase 2 logging cleanup; Phase 5 review.

6. **Test seeds**  
   Fixture IDs only in test/env config; not hardcoded in production code. Phase 0 TEST doc; Phase 5 integration contract.

## Verification

- Each threat maps to at least one Phase 4/5 check (test, RLS run, or manual QA). See `.TODO/RLS_notifications_matrix_2026-03-01.md` and acceptance doc.
