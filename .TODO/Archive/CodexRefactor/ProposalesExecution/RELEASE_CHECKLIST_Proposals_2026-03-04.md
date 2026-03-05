# Release Checklist: Proposals 2026-03-04

**Purpose**: Go/no-go gate for proposal remediation release.

## Hard gates (all must pass)

- [ ] **Live access**: Authenticated Supabase MCP scan evidence exists for proposal tables, RPCs, indexes (or explicit decision to ship app-only with DB blocked).
- [ ] **Analyze**: `flutter analyze lib/features/proposals lib/features/tasks lib/features/profile lib/core` passes.
- [ ] **Unit/widget tests**: `flutter test test/unit/proposals test/widget/proposals` (and existing task/proposal tests) pass.
- [ ] **Integration/manual**: Proposal flows (submit, replace, reject, award, resume, finalize) pass with seeded roles and bounded waits; manual E2E script executed and recorded.
- [ ] **SQL/RLS**: RLS_MATRIX_Proposals verification queries run; spoofed actor IDs fail; allowed actors pass.
- [ ] **Docs sync**: DEVELOPER_GUIDE, SUPABASE_SETUP, MVP_ROADMAP, STRUCTURE, Sline_Log updated; proposal deep-dive present.
- [ ] **Rollback**: Rollback path documented and validated (revert migrations or app-only rollback).

## Reviewer checklist (per PR slice)

- PR1 (contracts + test infra + selectors): Artifacts exist; no code behavior change.
- PR2 (app refactor + unit/widget + compat): MVVM respected; no UI→Supabase; compatibility exports in place.
- PR3 (DB + integration/manual + docs + release): All hard gates above satisfied.
