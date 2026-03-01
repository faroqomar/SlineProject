# Observability: Management

- Plan reference: `.TODO/PLAN_Management_Remediation_2026-03-01.md`
- Logging rule:
  - Use `AppLogger` only
  - Do not use `print()`

## Current Observability Findings

- Current sensitive leakage site:
  - `lib/features/management/services/work_log_service.dart:60`
  - raw note content is interpolated into a success log
- Current shared authz ambiguity site:
  - `lib/core/utils/error_mapper.dart:61-62`
  - `42501` maps to `Session expired. Please log in again.`

## Required Logging Outcomes

- Allowed management log categories:
  - load started / load failed
  - send started / send failed / send succeeded
  - blocked or suspicious authz outcomes
- Required sanitized fields if logging is needed:
  - `entityType`
  - `isPrivate`
  - content length only
  - error category/code only
- Forbidden fields:
  - raw note content
  - private note body fragments
  - joined profile PII beyond already-sanitized identifiers

## Recommended Event Points

- Service layer:
  - read failure
  - write failure
  - sanitized write success
- ViewModel layer:
  - transition into explicit error state
  - retry action triggered
- UI layer:
  - no direct logging unless a future plan explicitly requires it

## Verification Requirements

- Sample sanitized success log proves note body is absent
- Forced send failure proves user-facing error is visible and logs remain sanitized
- Forced authz failure proves logs help triage without misreporting as generic session expiry

## Stop Condition

- Do not mark management remediation complete while the raw-content log at `lib/features/management/services/work_log_service.dart:60` still exists
