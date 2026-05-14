# Docs Sync - Open Design Amber Dusk Phases 5-8

**Date:** 2026-05-13  
**Agent:** @DocsKeeper  
**Mode:** single-owner documentation pass  
**Scope:** Phase 5-8 Amber Dusk implementation, Step 7 SystemEvolution merge, notification realtime hardening, and stale guidance references.

## Evidence Read

- Plan: `.TODO/PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`
- Plan critique: `.TODO/PLAN_CRITIQUE_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments.md`
- Screenshot manifest: `.TODO/OpenDesign_AmberDusk_Phases5_6_7_8_OpenDesignScreenshots_2026-05-12/README.md`
- Master report: `.TODO/Archive/OpenDesign_AmberDusk_Phases5_6_7_8_2026-05-13/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_Step6.md`
- Emulator checklist: `.TODO/EMULATOR_TEST_CHECKLIST_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8.md`
- Session log: `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`
- System evolution: `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-05-13.md`
- Notification routing diagram: `Sline_everything/AppDigram/All_Diagrams/13_notification-routing.md`

## Documents Updated

| Document | Update |
| --- | --- |
| `Sline_everything/DEVELOPER_GUIDE.md` | Bumped to `2.29.0`; added Phase 5-8 section with scope, implementation rules, validation, references, no-Supabase-change note, and notification realtime behavior. |
| `Sline_everything/MVP_ROADMAP.md` | Updated date; added Amber Dusk Phase 5-8 status row; updated theme, notifications, and current-focus visual gates. |
| `Sline_everything/STRUCTURE.md` | Updated date and feature ownership notes for Amber Dusk Phase 5-8 surfaces, notification realtime reconnect, and wallet disabled-action behavior. |
| `Sline_everything/CODE_REVIEW.md` | Added Phase 5-8 review rule covering missing evidence, action authority, signed URL boundaries, safe URL-facts logging, wrapper harnesses, per-file matrices, and realtime transport tests. |
| `Sline_everything/Sline_Log.md` | Added version `2.29.0` with scope, key files, verification, and open visual gate. |
| `Sline_everything/AppDigram/All_Diagrams/13_notification-routing.md` | Updated to v2.1 with transient realtime reconnect behavior for `NotificationViewModel`. |
| `Sline_everything/SUPABASE_SETUP.md` | Replaced stale additional-resource reference to `GEMINI.md` with `AGENTS.md` and `.cursor/Agents/`. No backend schema content changed. |
| `.cursor/rules/project-rules.mdc` | Replaced stale `GEMINI.md` references with `AGENTS.md` and `.cursor/Agents/`. |
| `.cursor/PROJECT_CONTEXT.md` | Replaced stale `GEMINI.md` references with `AGENTS.md` and `.cursor/Agents/`. |
| `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md` | Marked Step 8 DocsKeeper complete and linked this docs sync note. |

## Why These Updates Were Needed

- Phase 5-8 was a major scoped UI implementation touching auth, chat, notifications, tasks, booking, payment, wallet, work, management, tests, screenshots, and agent rules.
- Step 6 and Step 7 changed durable review/process expectations that must be visible in the core docs.
- The notification realtime fix changed the expected ViewModel behavior for transient Supabase Realtime closes.
- `.cursor` reference files and one `Sline_everything/SUPABASE_SETUP.md` additional-resource entry still pointed to missing `GEMINI.md`; current repo guidance is `AGENTS.md` plus `.cursor/Agents/`.

## Supabase Objects

No Supabase tables, views, RPCs, RLS policies, storage buckets, Edge Functions, or migrations changed in this docs pass or the Phase 5-8 visual implementation.

## Validation

- Verified referenced plan, critique, master report, checklist, session log, and SystemEvolution report paths exist.
- Verified the documented notification file exists: `lib/features/notifications/viewmodels/notification_view_model.dart`.
- Verified stale `GEMINI.md` references were removed from active docs/context files. Remaining `GEMINI.md` mentions, if any, must be historical-only or inside this reference-fix note.
- `git diff --check` passed after documentation edits.
