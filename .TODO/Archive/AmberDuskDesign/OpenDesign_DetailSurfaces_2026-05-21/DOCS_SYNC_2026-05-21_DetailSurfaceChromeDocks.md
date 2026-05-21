# Docs Sync - Detail Surface Chrome And Compact Docks

**Date:** 2026-05-21  
**Agent:** DocsKeeper  
**Mode:** single-owner docs sync, no subagents  
**Session Log:** `docs/LOG/SESSION_OpenDesign_DetailSurfaces_2026-05-21.md`  
**SystemEvolution Report:** `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-05-21.md`  
**Supabase objects changed:** none

## Why This Update Was Needed

The 2026-05-21 detail-surface pass materially changed route chrome and bottom
action presentation for direct offer, work item, task, and booking details. It
also merged new SystemEvolution rules into the agent files requiring
production-route tests for chrome/dock changes and explicit wrapper-only
coverage disclosure. The source-of-truth docs needed to reflect the changed UI
contracts, the test expectation, and the remaining emulator visual QA gate.

## Documents Updated

- `README.md`
  - Bumped documentation badge/status to `2.34.0`.
  - Added the detail-route floating chrome/compact dock refresh and
    SystemEvolution 2026-05-21 production-route test rules to latest changes.
  - Added the detail-surface routes to the open Amber Dusk emulator parity gate.

- `Sline_everything/DEVELOPER_GUIDE.md`
  - Bumped to version `2.34.0`.
  - Added `Amber Dusk Detail Surface Chrome And Compact Docks (2026-05-21)`.
  - Documented the exact changed Flutter files, unchanged MVVM/payment/chat
    behavior, production-route tests, and open runtime visual QA states.

- `Sline_everything/STRUCTURE.md`
  - Updated the last-updated summary.
  - Updated `.cursor/Agents/SystemEvolution.md` latest merge-report reference.
  - Updated booking, direct-offer, tasks, and work feature ownership notes for
    the floating chrome and compact dock treatment.

- `Sline_everything/CODE_REVIEW.md`
  - Added the 2026-05-21 detail-route chrome and compact dock review rule.
  - Extended the SystemEvolution merge-runs section to include
    `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-05-21.md`.

- `Sline_everything/MVP_ROADMAP.md`
  - Updated status date.
  - Added the 2026-05-21 detail-surface work to theme, booking details, direct
    chat offers, unified work, agent system evolution, UI redesign progress, and
    current focus.

- `Sline_everything/UI_SURFACE_INVENTORY.md`
  - Updated task details, booking details, dashboard shell, work item details,
    work item bottom actions, work item guard widgets, and direct-offer detail
    rows with the current chrome/dock/report-guard responsibilities.

- `Sline_everything/Sline_Log.md`
  - Added version `2.34.0` with scope, verification, and open runtime gate.

- `.cursor/Agents/*.md`
  - Fixed stale `Sline_everything/AppDigram` references to
    `Sline_everything/AppDiagram`; see
    `.TODO/Archive/AmberDuskDesign/OpenDesign_DetailSurfaces_2026-05-21/DOCS_REFERENCE_FIX_2026-05-21_AppDiagramPaths.md`.

## References Validated

- Workflow: `.TODO/Archive/AmberDuskDesign/OpenDesign_DetailSurfaces_2026-05-21/WORKFLOW_OpenDesign_Redesign_To_Flutter_2026-05-21.md`
- Session log: `docs/LOG/SESSION_OpenDesign_DetailSurfaces_2026-05-21.md`
- SystemEvolution report: `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-05-21.md`
- Diagram index: `Sline_everything/AppDiagram/README.md`
- Key Flutter files:
  - `lib/features/direct_offers/view/direct_offer_details_screen.dart`
  - `lib/features/work/view/work_item_details_screen.dart`
  - `lib/features/work/view/widgets/work_item_bottom_actions.dart`
  - `lib/features/work/view/widgets/work_item_guard_widgets.dart`
  - `lib/features/booking/view/booking_details_screen.dart`
  - `lib/features/tasks/view/task_details_screen.dart`
  - `lib/features/chat/view/messages_screen.dart`
  - `lib/features/dashboard/view/dashboard_screen.dart`
  - `lib/features/tasks/view/widgets/booking_task_card.dart`
  - `lib/features/tasks/view/widgets/tender_task_card.dart`
- Key tests:
  - `test/widget/direct_offers/direct_offer_details_screen_test.dart`
  - `test/widget/work/work_item_details_screen_test.dart`
  - `test/widget/booking/booking_details_screen_test.dart`
  - `test/widget/tasks/task_details_screen_test.dart`

## Validation Commands

- `rg -n "AppDigram" . Sline_everything .cursor README.md AGENTS.md`
- `test -e Sline_everything/AppDiagram/README.md`
- `rg -ni "evi""dence" .cursor/Agents .cursor/rules`
- `git diff --check`

## Notes

- `Sline_everything/SUPABASE_SETUP.md` was inspected and left unchanged because
  this pass changed no Supabase schema, RLS policy, RPC, trigger, storage
  bucket, or Edge Function behavior.
- `Sline_everything/DOC_SOURCE_MAP.md` and
  `Sline_everything/AppDiagram/README.md` already route the touched task,
  booking, chat, dashboard, direct-offer, work, UI redesign, safety/report, and
  payment areas correctly; no ownership or diagram routing changes were needed.
