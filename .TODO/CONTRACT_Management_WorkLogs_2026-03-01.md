# Contract: Management Work Logs

- Plan reference: `.TODO/PLAN_Management_Remediation_2026-03-01.md`
- Scope:
  - `lib/features/management/**`
  - task and booking detail host embeddings

## Canonical Scope Type

- Preferred type name: `WorkLogScope`
- Planned file:
  - `lib/features/management/models/work_log_scope.dart`

## Scope Fields

- `entityId`
  - type: `String`
  - required: yes
  - semantics: target task or booking identifier
- `entityType`
  - type: `String`
  - required: yes
  - allowed values:
    - `task`
    - `booking`

## Read Contract

- Current broken form:
  - `Future<List<WorkLog>> getLogs(String entityId)`
- Locked target form:
  - `Future<List<WorkLog>> getLogs(WorkLogScope scope)`
- Required query semantics:
  - filter by `related_entity_id = scope.entityId`
  - filter by `related_entity_type = scope.entityType`
  - order by `created_at` ascending

## Write Contract

- Locked target form:
  - `postNote({ required WorkLogScope scope, required String content, bool isPrivate = false })`
  - implementation may preserve named parameters internally, but public flow must use the same scope semantics as reads
- Required semantics:
  - trim user content before persistence
  - reject whitespace-only content
  - preserve draft in UI if write fails

## Result Contract

- `postNote(...)` must not silently complete on failure
- Preferred result:
  - `Future<bool>`
- Allowed alternative:
  - typed result object carrying `success` and optional user-facing error
- Not allowed:
  - `Future<void>` with swallowed error that still triggers UI success cleanup

## UI State Contract

- Timeline states are distinct:
  - `loading`
  - `empty`
  - `error`
  - `populated`
- Required rule:
  - `empty` must render only when there is no error and no data
  - `error` must render a distinct message and retry affordance

## Error Contract

- Management authz failures must not be mislabeled as session-expired by default
- If global mapper cannot be safely changed, management flow must locally map `42501` to an authorization-appropriate message

## Data Shape Assumptions

- `WorkLog` row expects:
  - `id`
  - `author_id`
  - `related_entity_id`
  - `related_entity_type`
  - `content`
  - `is_private`
  - `metadata`
  - `created_at`
- Optional joined profile payload:
  - `profiles.full_name`
  - `profiles.avatar_url`

## Validation Gates

- No read path may exist without `entityType`
- No panel/viewmodel/service boundary may split scope into incompatible contracts
- No UI success cleanup may happen without confirmed send success
- Final contract must be revalidated against live DB schema and policy reality before Phase 2 execution continues
