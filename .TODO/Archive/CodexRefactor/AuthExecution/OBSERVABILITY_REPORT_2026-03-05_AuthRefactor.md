# Observability Report: AuthRefactor

**Date:** 2026-03-05
**Scope:** AuthRefactor
**Agent:** @Observability

## Overview

Analyzed logging, tracing, and privacy patterns in `PLAN_AuthFix_2026-03-01.md`.

## Findings

1. **Telemetry Gaps:**
   - Previous system mapped generic unhelpful error clusters without centralized routing.
   - Refactor adopted standard error mapping to prevent exposing internal stacktraces to end users during bad authentication events.
2. **Event Taxonomy:**
   - Addressed AuthChangeEvent mapping inside the globally owned `AuthSessionViewModel`.
   - Logging now properly differentiates "unauthorized" vs "session expired".

3. **Privacy-Safe Logging Plan:**
   - What to log: Auth cycle transitions, network error counts.
   - What NOT to log: Email addresses (must be masked if captured), plaintext passwords, JWTs, Supabase session hashes.
   - `AppLogger` is effectively integrated into the repositories.

## Conclusion

✅ **APPROVED.** Privacy and signal noise are within acceptable tolerances.
