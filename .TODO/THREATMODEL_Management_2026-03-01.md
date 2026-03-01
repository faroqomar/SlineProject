# Threat Model: Management

- Plan reference: `.TODO/PLAN_Management_Remediation_2026-03-01.md`
- Feature scope:
  - `lib/features/management/**`
  - host embeddings in task and booking detail screens

## Assets To Protect

- Private note content in `work_logs`
- Participant-only access to task/booking timelines
- Correct per-entity timeline scope (`related_entity_id` + `related_entity_type`)
- Accurate authz failure signaling
- User drafts during failed send attempts

## Trust Boundaries

- Client UI is not an authorization boundary
- `work_logs` RLS is the authorization source of truth
- Shared logging/error-mapping utilities can leak or mislabel sensitive outcomes if used incorrectly

## Threats

### TM-01 Private note leakage via logs

- Current evidence:
  - `lib/features/management/services/work_log_service.dart:60`
  - `lib/core/services/logger_service.dart:82-117`
- Threat:
  - private or sensitive note content is emitted to debug/device logs
- Required control:
  - replace raw content logging with sanitized metadata only
- Negative check:
  - send a private note and verify no note body appears in logs

### TM-02 Non-participant access to timeline data

- Current evidence:
  - docs-only contract for `work_logs_select`: `Sline_everything/SUPABASE_SETUP.md:1115-1122`
  - helper function intent: `Sline_everything/SUPABASE_SETUP.md:1263-1274`
- Threat:
  - non-participant reads or writes logs if live RLS/policies drift from docs
- Required control:
  - live policy verification through MCP before implementation continues
- Negative check:
  - unrelated authenticated user cannot read/write management logs for task or booking

### TM-03 Cross-entity timeline mix-up

- Current evidence:
  - `lib/features/management/services/work_log_service.dart:15-25`
  - `lib/features/management/viewmodels/order_management_view_model.dart:21-29`
- Threat:
  - fetch path ignores `related_entity_type`, so logs may be selected for the wrong entity class
- Required control:
  - canonical typed scope contract used across panel/viewmodel/service
- Negative check:
  - task and booking timelines with overlapping IDs or fixtures do not cross-contaminate

### TM-04 Draft loss masks failed mutation

- Current evidence:
  - `lib/features/management/viewmodels/order_management_view_model.dart:41-68`
  - `lib/features/management/view/order_management_panel.dart:144-155`
- Threat:
  - failed write still clears user draft, hiding the failure and risking sensitive content loss
- Required control:
  - explicit success/failure result from `postNote(...)`
  - clear input only on success
- Negative check:
  - forced send failure preserves draft and shows visible error state

### TM-05 Authz failure misreported as session failure

- Current evidence:
  - `lib/core/utils/error_mapper.dart:59-63`
  - `lib/core/utils/error_mapper.dart:132-145`
- Threat:
  - RLS denial is reported as session expiry, causing bad triage and ambiguous security signals
- Required control:
  - management-specific authz-safe messaging or proven-safe global mapper change
- Negative check:
  - `42501` from management path does not render as session-expired unless the session is actually expired

## Security Gates Before Phase 2

- Live `work_logs` schema verified via MCP
- Live `work_logs_*` policies verified via MCP
- Live `is_work_log_participant(...)` verified via MCP
- RLS matrix written and reviewed
- Raw note-content logging removed only after Phase 1 gate passes

## Manual Negative Test List

- Attempt to read another user’s private note as the other participant
- Attempt to access management logs as a non-participant
- Force send failure and verify draft remains
- Force load failure and verify error state is distinct from empty state
- Capture logs during public/private note send and verify note bodies are absent
