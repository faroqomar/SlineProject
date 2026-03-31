# CodeGuard Review: Escrow Invariants & Idempotency

**Scope:** EscrowInvariantsIdempotency  
**Plan:** `.TODO/PLAN_EscrowInvariantsIdempotency_2026-03-07_CRITIC.md`  
**Date:** 2026-03-07  
**Agent:** @CodeGuard

---

## 1) Review Mode

**STANDARD** — Business logic (approval flow), service + ViewModel + UI, and DB migration (RPC + index). No new RLS; SECURITY DEFINER unchanged.

---

## 2) Security

| Check | Result | Evidence |
|-------|--------|----------|
| RLS | No change | Migration only replaces function body; no policy changes. |
| AuthZ | Unchanged | `rpc_approve_delivery` still checks `client_id = auth.uid()` for task/booking. |
| Secrets | None logged | AppLogger payloads: entityId, entityType, sourceType only. No tokens. |
| SQL injection | N/A | RPC uses parameters (entity_type, entity_id); no dynamic SQL in app. |
| Idempotency | Hardened | Stable key + FOR UPDATE + UNIQUE on idempotency_key prevent double release. |

**Verdict:** No security regressions. Idempotency improvement reduces risk.

---

## 3) Performance

| Check | Result | Evidence |
|-------|--------|----------|
| N+1 | None introduced | Single RPC call per approval. |
| Rebuilds | Acceptable | Modal uses one-shot guard; VM notifyListeners only on start/error/finally. |
| DB | FOR UPDATE adds row lock | One row locked for booking; released at commit. Acceptable. |
| Index | Duplicate dropped | `idx_journal_entries_idempotency` removed; constraint-backed index remains. |

**Verdict:** No performance concerns.

---

## 4) Compatibility

| Check | Result | Evidence |
|-------|--------|----------|
| RPC signature | Unchanged | `rpc_approve_delivery(entity_type, entity_id)`; no new params. |
| App | No breaking change | Same call from service; older app versions still work. |
| Migration | Additive / replace | CREATE OR REPLACE FUNCTION + DROP INDEX IF EXISTS; no table drop. |

**Verdict:** Backward compatible.

---

## 5) SLine Compliance

- **MVVM:** View does not call Supabase; Service is single RPC path. ✅  
- **Single source of truth:** One approval path (VM → Service → RPC). ✅  
- **AppLogger:** No print(); tags used. ✅  
- **Docs:** Diagram and SUPABASE_SETUP updated. ✅  

---

## 6) Verification Commands

```bash
flutter analyze lib/features/work/
# Expected: No issues found.
```

```sql
-- Confirm function uses stable key (no now())
SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'rpc_approve_delivery';
-- Expect: v_status || ':' || v_payment_status in digest; no now()
```

```sql
-- Confirm duplicate index dropped
SELECT indexname FROM pg_indexes WHERE tablename = 'journal_entries';
-- Expect: idx_journal_entries_idempotency NOT present
```

---

## 7) Risk Rating

| Area | Rating | Notes |
|------|--------|--------|
| Security | LOW | No new surface; idempotency hardened. |
| Data integrity | LOW | Stable key + FOR UPDATE reduce double-release risk. |
| Performance | LOW | Single RPC; short lock. |
| Compatibility | LOW | Signature unchanged. |

**Overall:** LOW risk.

---

## 8) Blockers

**None.** No BLOCKER or Critical issues.

---

## 9) Decision

**APPROVED ✅**

Proceed to Master Report. No pipeline block.
