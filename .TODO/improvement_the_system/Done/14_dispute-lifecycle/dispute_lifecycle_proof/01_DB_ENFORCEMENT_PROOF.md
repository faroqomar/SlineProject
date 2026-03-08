# DB Enforcement Proof: Dispute Lifecycle

## A) State Machine Enforcement

### A1) `dispute_status_enum` — ❌ DOES NOT EXIST

**Evidence:**

- Searched all `supabase/migrations/` for `dispute_status_enum` → **No results**.
- `SUPABASE_SETUP.md` §5.24: `status` column is `text`, nullable, with no CHECK constraint.
- No `CREATE TYPE ... dispute_status_enum` found in any migration file.

> **Verdict**: `disputes.status` accepts arbitrary strings. A client could theoretically insert `status='resolved'` if RLS allowed it.

### A2) `trg_dispute_guard` — ❌ DOES NOT EXIST

**Evidence:**

- Searched all `supabase/migrations/` for `trg_dispute` → **No results**.
- `SUPABASE_SETUP.md` §8 (Triggers): No trigger listed for the `disputes` table.
- Original diagram `14_dispute-lifecycle.md` line 14: `"NO trigger found on disputes table"`.

> **Verdict**: No transition enforcement exists. The `open → active → resolved` flow is not enforced at the DB level. Any UPDATE with sufficient RLS privileges can set any status.

### A3) `resolved_at` Auto-Stamping — ❌ NOT AUTO-STAMPED

**Evidence:**

- `SUPABASE_SETUP.md` §5.24: `resolved_at` is `timestamptz`, nullable, no `DEFAULT`.
- No trigger or RPC sets `resolved_at` automatically. The field depends on manual admin writes.

> **Verdict**: `resolved_at` can be NULL even if `status = 'resolved'`, creating broken data.

---

## Summary

| Check                                    | Status      | Evidence                                         |
| ---------------------------------------- | ----------- | ------------------------------------------------ |
| `dispute_status_enum` exists             | ❌ MISSING  | No enum in pg_type or migrations                 |
| `trg_dispute_guard` enforces transitions | ❌ MISSING  | No trigger in migrations or SUPABASE_SETUP.md §8 |
| `resolved_at` auto-stamped               | ❌ MISSING  | No trigger; column is nullable with no DEFAULT   |
| `open → resolved` directly blocked       | ❌ POSSIBLE | No guard exists                                  |

> **All three NEW-report proposals (Phase 1) are NOT yet implemented.**
