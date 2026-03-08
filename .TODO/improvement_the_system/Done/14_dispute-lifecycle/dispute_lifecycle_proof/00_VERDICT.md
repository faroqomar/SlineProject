# VERDICT: Dispute Lifecycle — NEW vs OLD

## Executive Summary

The NEW dispute lifecycle design from the [Holistic Audit Report](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/improvement_the_system/14_dispute-lifecycle/00_HOLISTIC_REPORT.md) is **architecturally correct** and identifies all real gaps. However, **none of the proposed guards have been implemented** in the database. The system is **not safer in practice** — only on paper.

---

## Score Card

| Area                                | OLD (Diagram)    | NEW (Report)                      | ACTUAL (Code/DB)                       | Gap                       |
| ----------------------------------- | ---------------- | --------------------------------- | -------------------------------------- | ------------------------- |
| State machine enum                  | ❌ Plain text    | ✅ Proposes `dispute_status_enum` | ❌ Still plain text                    | **Not implemented**       |
| Transition guard trigger            | ❌ None          | ✅ Proposes `trg_dispute_guard`   | ❌ No trigger exists                   | **Not implemented**       |
| `resolved_at` auto-stamp            | ❌ Manual        | ✅ Proposes trigger stamp         | ❌ Still manual nullable               | **Not implemented**       |
| Escrow race prevention              | ❌ Not mentioned | ✅ Proposes dispute check in RPC  | ❌ `rpc_approve_delivery` has no check | 🔴 **PRODUCTION BLOCKER** |
| RLS: INSERT                         | ❓ Unknown       | ✅ Proposes complainant-only      | ✅ `disputes_insert_own` exists        | ✅ Match                  |
| RLS: SELECT                         | ❓ Unknown       | ✅ Proposes party-only            | ✅ `disputes_select_party` exists      | ✅ Match                  |
| RLS: UPDATE deny                    | ❓ Unknown       | ✅ Proposes admin-only            | ✅ Secure by omission (no policy)      | ⚠️ Implicit, not explicit |
| `dispute_messages` RLS              | ❌ Not mentioned | ❌ Not detailed                   | ❌ None exist                          | **Not implemented**       |
| `dispute_evidence` RLS              | ❌ Not mentioned | ❌ Not detailed                   | ❌ None exist                          | **Not implemented**       |
| Admin UI                            | ❌ "UNVERIFIED"  | ✅ Proposes admin tooling         | ❌ No admin UI in repo                 | **Not built**             |
| Freelancer notification             | ❌ Not mentioned | ❌ Not mentioned                  | ❌ Not implemented                     | **Not built**             |
| Client dispute visible in dashboard | ❌ Not mentioned | ❌ Not mentioned                  | ✅ `disputed` maps to Active           | ✅ Exists                 |

---

## Verdict

### Is the NEW design safer?

**As a design document: YES.** The NEW report correctly identifies:

- The escrow race vulnerability (Section F, Scenario 1)
- The status tampering risk (Section F, Scenario 2)
- The need for DB-level enforcement (Section G, Phase 1)

**As implemented code: NO.** None of the proposed Phase 1-4 changes exist in the codebase or database. The gap between design and implementation is 100%.

### Production Readiness

| Component                        | Ready?                                              |
| -------------------------------- | --------------------------------------------------- |
| Dispute submission (client → DB) | ✅ YES — works via `DisputeService.submitDispute()` |
| Dispute prevents escrow release  | 🔴 NO — `rpc_approve_delivery` has no check         |
| Dispute prevents auto-approval   | 🔴 NO — `rpc_finalize_auto_approval` has no check   |
| Admin can resolve disputes       | ❌ NO — no admin RPC or UI exists                   |
| Freelancer can respond           | ❌ NO — no UI exists                                |
| Evidence management              | ❌ NO — no RLS, no storage bucket                   |
| Dispute messaging                | ❌ NO — no RLS policies                             |

### Ship Decision

> ⛔ **DO NOT SHIP** dispute feature to production without **Patch 1** (Escrow Race Guard).
>
> Current state: A client can file a dispute AND approve delivery simultaneously, releasing escrow funds and making the dispute financially unresolvable.

### Recommended Action Order

1. 🔴 **Immediate:** Apply [Patch 1 (Escrow Guard)](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/dispute_lifecycle_proof/07_MINIMAL_PATCH_PLAN.md) — prevents money loss.
2. 🟡 **Next sprint:** Apply Patches 2-3 (Deny policies + Enum) — hardens schema.
3. 📋 **Backlog:** Build dispute messaging RLS, evidence RLS + bucket, admin UI, freelancer UI.

---

## Evidence Index

| Deliverable            | Path                                                                                                                                                |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| DB Enforcement Proof   | [01_DB_ENFORCEMENT_PROOF.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/dispute_lifecycle_proof/01_DB_ENFORCEMENT_PROOF.md)         |
| Escrow Race Proof      | [02_ESCROW_RACE_PROOF.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/dispute_lifecycle_proof/02_ESCROW_RACE_PROOF.md)               |
| RLS Proof              | [03_RLS_PROOF.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/dispute_lifecycle_proof/03_RLS_PROOF.md)                               |
| Evidence Privacy Proof | [04_EVIDENCE_PRIVACY_PROOF.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/dispute_lifecycle_proof/04_EVIDENCE_PRIVACY_PROOF.md)     |
| UI Surfaces & Wiring   | [05_UI_SURFACES_AND_WIRING.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/dispute_lifecycle_proof/05_UI_SURFACES_AND_WIRING.md)     |
| Screenshots Checklist  | [06_UI_SCREENSHOTS_CHECKLIST.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/dispute_lifecycle_proof/06_UI_SCREENSHOTS_CHECKLIST.md) |
| Minimal Patch Plan     | [07_MINIMAL_PATCH_PLAN.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/dispute_lifecycle_proof/07_MINIMAL_PATCH_PLAN.md)             |
