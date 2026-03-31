# RLS Check Matrix: Dispute Lifecycle

**Plan:** PLAN_DisputeLifecycle_2026-03-08  
**Migration:** 20260308140000_dispute_lifecycle_escrow_guard_rls.sql

## disputes

| Role           | SELECT | INSERT | UPDATE | DELETE |
|----------------|--------|--------|--------|--------|
| authenticated  | ✅ party only (complainant_id or defendant_id = auth.uid()) | ✅ complainant only (disputes_insert_own) | ❌ denied (disputes_deny_update) | ❌ denied (disputes_deny_delete) |
| service_role   | ✅     | ✅     | ✅     | ✅     |
| anon           | ❌     | ❌     | ❌     | ❌     |

Policies: `disputes_select_party`, `disputes_insert_own`, `disputes_deny_update`, `disputes_deny_delete`.

## dispute_messages

| Role           | SELECT | INSERT | UPDATE | DELETE |
|----------------|--------|--------|--------|--------|
| authenticated  | ✅ participant only (complainant or defendant of dispute) | ✅ participant only | ❌ no policy (denied by default) | ❌ no policy (denied) |
| service_role   | ✅     | ✅     | ✅     | ✅     |

Policies: `dispute_messages_select_participant`, `dispute_messages_insert_participant`.

## dispute_evidence

| Role           | SELECT | INSERT | UPDATE | DELETE |
|----------------|--------|--------|--------|--------|
| authenticated  | ✅ participant only | ✅ participant + uploader_id = auth.uid() | ❌ no policy | ❌ no policy |
| service_role   | ✅     | ✅     | ✅     | ✅     |

Policies: `dispute_evidence_select_participant`, `dispute_evidence_insert_participant`.

## Verification

- Non-participant cannot SELECT from disputes / dispute_messages / dispute_evidence.
- Authenticated cannot UPDATE or DELETE disputes (explicit deny).
- Status changes on disputes must go through SECURITY DEFINER RPC or service_role (no app policy).
