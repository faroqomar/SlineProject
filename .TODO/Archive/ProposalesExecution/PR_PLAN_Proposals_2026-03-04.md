# PR Plan: Proposals 2026-03-04

**Purpose**: Reviewable, rollback-safe slices.

## PR1: Contracts + test infrastructure + selectors

- **Contents**: All Phase 0 .TODO artifacts (TEST_INFRA, FIXTURES, DB_PROVENANCE, RELEASE_CHECKLIST, THREAT_MODEL, DECISIONs, UI_STATE_MATRIX, DONE_CRITERIA, CONTRACT, STATE_MATRIX, MIGRATION, PR_PLAN, plus selector keys in code).
- **Acceptance**: Artifacts exist; keys in requests_list_screen, submit_request_sheet, request_tile, inbox_tab, work_tab, next_actions_list, work_item_details_screen, tender_payment_screen.
- **Rollback**: Revert key additions only (low risk).
- **Reviewer**: @Sentinel; definition of done per RELEASE_CHECKLIST and DONE_CRITERIA.

## PR2: App refactor + unit/widget tests + compatibility exports

- **Contents**: Phase 2 (models, proposal_repository, proposal_award_repository, ViewModels, DI, deprecation, AppLogger) and Phase 3 (route helper, proposals UI module, state matrix, correctness fixes); Phase 4 unit/widget tests; compatibility exports at old task paths.
- **Acceptance**: flutter analyze passes; no UI→Supabase; single proposal data path; tests pass.
- **Rollback**: Revert app/file moves; keep SQL if already applied.
- **Reviewer**: @Architect, @Sentinel; @CodeGuard for HIGH-risk gate.

## PR3: DB reconcile + integration/manual/security + docs + release

- **Contents**: Phase 1 migrations (if not in separate DB-only PR), Phase 4 integration/manual/SQL, Phase 5 docs, RELEASE_CHECKLIST completion.
- **Acceptance**: All release gates pass; docs updated.
- **Rollback**: Per rollback plan (migrations revert or forward-fix).
- **Reviewer**: @Supabase_Ops, @Sentinel, @SlineDocs.

## Reviewer checklist (per slice)

- No direct Supabase in views; AppLogger used; no print().
- Compatibility exports documented in DEPRECATION_Proposals.
- Docs-sync requirements in PR3 and release checklist (per @SlineDocs).
