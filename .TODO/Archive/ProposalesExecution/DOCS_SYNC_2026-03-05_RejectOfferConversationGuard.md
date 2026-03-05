# DOCS_SYNC — Reject-offer conversation guard (2026-03-05)

**Workflow:** `.agents/workflows/slinedocs.md`  
**Scope:** Document reject-offer fix (conversations guard GUC + `reject_task_request`).

---

## Doc files updated

| File | Changes |
|------|--------|
| `Sline_everything/SUPABASE_SETUP.md` | Last Updated line; §5.5 conversations Important Notes (reject exception); §8.3 Conversations Triggers (guard behavior paragraph); RPC `reject_task_request(p_task_id, p_request_id)` description (GUC + migration); Key Business Rules (task-linked exception); Changelog §17 (Version 2.17.3 entry). |
| `Sline_everything/Sline_Log.md` | New version entry: "Reject-offer conversation guard" with Implemented, Impact, Verification, Technical Notes; checklist and migration paths. |
| `Sline_everything/DEVELOPER_GUIDE.md` | Chat §2.5 Triggers/Functions: corrected trigger/function names (`trg_conversations_before_insert_guard`, `conversations_before_insert_guard()`); added exception for owner-created task convo via `reject_task_request` and migration ref. |

---

## Summary of changes

- **Why:** Rejecting an offer from Inbox (or task Offers list) failed with "task owner cannot start a task-linked conversation" and "initiated_by must equal current user". Migration `20260305071000_conversations_guard_allow_owner_reject.sql` adds a GUC exception so `reject_task_request` can create the task-linked conversation with `initiated_by = v_owner`.
- **Docs:** SUPABASE_SETUP is the single source of truth for the guard behavior, RPC contract, and changelog; Sline_Log records the change with verification refs; DEVELOPER_GUIDE aligns Chat triggers with actual names and the reject exception.

---

## References validated

- `supabase/migrations/20260305071000_conversations_guard_allow_owner_reject.sql` — exists.
- `supabase/migrations/20260305070000_reject_task_request_conversation_initiator.sql` — exists (superseded).
- `.TODO/Archive/ProposalesExecution/CHECKLIST_Proposals_App_Verification_2026-03-05.md` — exists; Reject-offer fix section references 071000 migration.
- Section numbers in SUPABASE_SETUP (§5.5, §8.3, §17) and DEVELOPER_GUIDE (§2.5) — confirmed in files.

---

## Why each update was needed

1. **SUPABASE_SETUP.md** — DB changes (trigger function + RPC) must be documented immediately per SlineDocs; changelog and key rules keep history and behavior discoverable.
2. **Sline_Log.md** — Feature/fix completion must have a release-style entry with plan/checklist links and technical notes per SlineDocs template.
3. **DEVELOPER_GUIDE.md** — Trigger names and guard behavior must match SUPABASE_SETUP and code; the reject exception is a contract detail that affects when the owner can create a task-linked conversation.
