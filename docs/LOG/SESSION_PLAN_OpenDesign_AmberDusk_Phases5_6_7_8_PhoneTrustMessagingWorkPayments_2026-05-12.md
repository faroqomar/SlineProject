# Session Log: PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12

**Plan File:** `.TODO/PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`  
**Date Started:** 2026-05-12 11:30:56 +0300  
**Date Closed:** Pending final workflow closure  
**Executed By:** @Executor with read-only gap-scan explorers  
**Final Status:** STEP 8 DOCSKEEPER COMPLETE; FINAL WORKFLOW CLOSURE PENDING

---

## Quick Summary

Phase 5-8 implementation has passed Step 5 gap scanning and gap repair. Open Design and Computer Use were re-checked against the active Amber Dusk project, explorer findings were integrated, focused regressions were fixed, and the broad local gates passed after repair. Runtime Flutter visual QA and any release-style checklist remain pending for later workflow steps.

---

## Agent Improvement Notes

(To be written at session close by Executor)

| Agent | Mistake Made | Rule to Add/Change |
|-------|-------------|-------------------|
| @Executor | Let an attachment signed URL resolver move through an eager `SupabaseAttachmentUploader()` default, which broke unit tests that construct `ChatViewModel` without Supabase initialization. | Any service bridge added to a ViewModel for UI privacy must be lazy or injected so constructor-only unit tests never touch global clients. |
| @Executor | A proposals wrapper test used plain `MaterialApp` while the shared tender payment screen now consumes `context.colorScheme`. | When a shared screen starts using `AppTheme` extensions, update every wrapper/entry test around that screen, not only the primary feature test. |
| Worker delegation | Broad workers did not return final reports before closure, even though their patches existed in the shared workspace. | For wide UI phases, delegate smaller screen clusters and require a checkpoint after the first file edit before continuing. |

---

## Session Timeline

(Executor appends all events here as they happen)

### [PLAN CREATED]

- Plan: `.TODO/PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`
- Created by: @Planner
- Scope: Phone Phase 5 Auth/System Gates, Phase 6 Chat/Direct Offers/Attachments/Notifications, Phase 7 Tasks/Tenders/Proposals/Direct Offers/Work Details, and Phase 8 Booking/Payment/Wallet from `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`.
- PRISM-equivalent phase in SLine roadmap: Amber Dusk phone redesign phases 5, 6, 7, and 8.
- Estimated phases in plan: 6 major execution blocks: preflight/evidence lock, Phase 5, Phase 6, Phase 7, Phase 8, cross-phase QA/docs/handoff.
- High-risk areas identified in planning:
  - Open Design has weak or missing exact evidence for auth/gates, attachment tiles, notification modal content, proposal detail, payment method, payment return, WebView shell, and trusted callback screens.
  - Phases 6-8 touch private messages, attachments, offers, work lifecycle, disputes, booking, payment, wallet, and ledger-backed balances.
  - Payment and lifecycle authority must remain in existing services, Edge Functions, RPCs, RLS, and ViewModels.
  - The Open Design messaging copy has a `Responses/Requests` versus `Received/Sent` conflict that must be resolved before implementation.
  - The Open Design wallet shows active Withdraw, while the master phase expects Withdraw Coming Soon; product/runtime authority must decide.
  - Prior Phases 2-4 had code/test gates closed but runtime visual parity remained open, so phases 5-8 need fresh runtime screenshots before visual completion is claimed.
- Known potential problem areas:
  - `proposals` view files are mostly re-export entry points from `tasks`; do not duplicate implementations.
  - `DirectOfferDetailsScreen`, `WorkItemDetailsScreen`, and payment screens create or depend on screen-scoped ViewModels and provider services; tests must configure dependencies before pump.
  - `ChatViewModel` registers with `RoleSwitchCoordinator`; tests must call `clearForTesting()`.
  - `PaymentPendingStore` is a plain class and must use `Provider.value`, not `ChangeNotifierProvider.value`.
  - `coverage/lcov.info` was absent at planning time; coverage arithmetic is deferred because the plan does not set a new percentage target.

---

### Notes from Planner to Executor

- Re-check Open Design MCP before each implementation phase.
- Treat exact visual matching as allowed only for states visible in Open Design MCP or user-provided screenshots.
- Treat missing exact design evidence as token-normalization/adaptation only.
- Do not edit Supabase migrations, functions, tests, RLS, storage policies, RPCs, or live backend state in this visual plan.
- Do not globally activate Amber Dusk through `MaterialApp` or `AppTheme`.
- Preserve MVVM boundaries and keep views free of direct Supabase, `.from()`, `.rpc()`, and storage calls.
- Preserve auth, realtime, direct-offer, notification, tender, booking, payment, wallet, ledger, dispute, and role-switch contracts.
- Run phase-focused tests before broad gates.
- Capture runtime Flutter visual evidence before claiming visual completion.
- Keep docs, session log, final report, visual QA, and Mohammed web handoff connected.

---

### [PLANCRITIC SOURCE-OF-TRUTH GATE]

- Critique artifact: `.TODO/PLAN_CRITIQUE_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments.md`
- Corrected plan: `.TODO/PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`
- Created by: @PlanCritic
- Mode: single-agent critique/rewrite gate.
- Related files read:
  - `.cursor/Agents/PlanCritic.md`
  - `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`
  - `.TODO/PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`
  - `.TODO/Archive/OpenDesign_AmberDusk_2026-05-10/PLAN_CRITIQUE_2026-05-10_OpenDesign_AmberDusk.md`
  - `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase0_PhoneFoundation.md`
  - `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets.md`
  - `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard.md`
  - `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/MASTER_REPORT_2026-05-11_OpenDesign_AmberDusk_Phase0.md`
  - `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/MASTER_REPORT_2026-05-11_OpenDesign_AmberDusk_Phase1_CoreWidgets.md`
  - `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md`
  - `.TODO/PLAN_OpenDesign_AmberDusk_Web_Mohammed_2026-05-10.md`
  - `.TODO/WebRedsign/HANDOFF_OpenDesign_AmberDusk_Phase0_ToWeb_2026-05-11.md`
  - `.TODO/WebRedsign/HANDOFF_OpenDesign_AmberDusk_Phase1_CoreWidgets_ToWeb_2026-05-11.md`
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/STRUCTURE.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `.cursor/PROJECT_CONTEXT.md`
  - `.cursor/rules/error-handling.mdc`
- Open Design refreshed: project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`, files `Sline V2 Amber Dusk.html`, `amber-dusk-design-system.html`, and `sline-v2-amber-dusk-web.html`.
- Gate result: corrected plan passes as an execution plan after rewrite, but runtime visual closure remains gated until Flutter screenshots/manual runtime evidence are captured during execution.
- Decisions resolved:
  - Phase 6 message modes use `Received` and `Sent` unless product explicitly overrides.
  - Phase 8 must preserve current wallet withdrawal behavior and cannot add a new active withdrawal flow in this visual plan.
  - Missing exact Open Design targets remain adaptation-only until exact Open Design or user screenshot evidence exists.
  - Open Design font binaries remain blocked until license/source evidence exists.

---

### [OPEN DESIGN SCREENSHOT EXPORT]

- Created by: Codex single-agent export step.
- Scope: pre-implementation screenshot export and visual notes for Phase 5-8.
- Open Design MCP re-check before notes:
  - Project `1674a1db-7a74-4c80-8e2c-196a0385a8f7` still resolves to `Sline V2 Amber Dusk.html`.
  - Entry file remains `Sline V2 Amber Dusk.html`.
  - Project `updatedAt` remains `1778418973981`.
  - `list_files(since: 1778418973981)` returned no newer files before notes were appended.
  - `search_files("Received", pattern: "*.html")` still finds dashboard, design-system, and web evidence for `Received` and `Sent`.
- Export folder: `.TODO/OpenDesign_AmberDusk_Phases5_6_7_8_OpenDesignScreenshots_2026-05-12/`
- Manifest: `.TODO/OpenDesign_AmberDusk_Phases5_6_7_8_OpenDesignScreenshots_2026-05-12/README.md`
- Export count: 22 PNG files.
- Phone screenshot dimensions verified: 14 files at `430 x 932`.
- Supplemental web screenshot dimensions verified: 8 files at `1440 x 1000`.
- Zero-byte check: no zero-byte PNG files found.
- Plan updated: appended `H.16 Open Design Screenshot Export And Visual Notes` to `.TODO/PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`.
- Evidence authority:
  - Phone screenshots are implementation references only where phone evidence exists.
  - Supplemental web screenshots clarify copy, taxonomy, and density only.
  - Missing exact phone artboards remain adaptation-only.
  - Open Design screenshots do not replace Flutter runtime screenshots.
- Important visual notes:
  - The Open Design bottom sheets show a blurred backdrop; Flutter implementation must keep the no-glass/no-backdrop rule and use approved dim/elevation tokens instead.
  - Phone Messages screenshots still show `Responses`/`Requests`, but corrected plan copy remains `Received`/`Sent` based on dashboard inbox, web, and design-system evidence.
  - Wallet screenshots are visual references only and do not authorize active withdrawal behavior.

---

### [2026-05-12 11:30:56 +03] SESSION STARTED

- Agent: @Executor.
- Mode: main multi-agent implementation step.
- Plan: `.TODO/PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`.
- Critique gate: `.TODO/PLAN_CRITIQUE_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments.md`.
- Starting status: pre-execution context scan and file-ownership mapping. No Flutter source edits yet.
- User constraints recorded:
  - Follow Open Design MCP evidence before each implementation section.
  - Use only provided/exported screenshots as visual references.
  - Add `AppLogger` instrumentation on every new code path.
  - Add tests for every new unit.
  - Spawn multiple worker agents only after file ownership is clear.
  - Each worker must have a separate write scope.
  - No two agents may edit the same file unless explicitly coordinated.
  - No improvisation outside the design system.

### [2026-05-12 11:33:10 +03] PROBLEM ENCOUNTERED

- Phase/step: Executor pre-execution documentation scan.
- Problem: `.cursor/rules/project-rules.mdc` references `GEMINI.md`, but `GEMINI.md` is not present in this checkout.
- Root cause: repo guidance has been supplied in this thread through `AGENTS.md`, and the current repo also carries `.cursor/PROJECT_CONTEXT.md`; the older `GEMINI.md` reference is stale for this workspace snapshot.
- Could it have been caught earlier: yes, by checking required doc paths before implementation.
- Resolution: continue using the user-provided `AGENTS.md` instructions, `.cursor/PROJECT_CONTEXT.md`, `.cursor/rules/`, `.cursor/skills/`, and `Sline_everything/*` docs as the active guidance. No Flutter source edits were made before recording this.

### [2026-05-12 11:33:24 +03] STEP COMPLETED

- Phase/step: baseline static analysis before implementation.
- Command: `flutter analyze --no-fatal-infos`.
- Result: pass, `No issues found!`.
- Evidence: analyzer completed in `6.7s`.

### [2026-05-12 11:36:40 +03] STEP COMPLETED

- Phase/step: Executor pre-execution scan and execution strategy.
- Evidence confirmed:
  - Plan and critique artifacts exist.
  - `.cursor/skills/` contains the UI skills referenced by the plan.
  - Planned Flutter view paths exist.
  - Direct Supabase scan over planned view scopes returned no hits.
  - Local Supabase migrations/functions/docs contain referenced payment/chat/work/wallet objects; no backend edits are planned.
- Ownership map:
  - Worker 1 owns Phase 5 auth/system gate views and auth widget tests only.
  - Worker 2 owns Phase 6 chat/attachment/notification views and matching widget tests only.
  - Worker 3 owns Phase 7 task/request/proposal/direct-offer/work/management views and matching widget tests only.
  - Worker 4 owns Phase 8 booking/payment/wallet views and matching widget tests only.
  - Main executor owns coordination, session log, integration review, and final verification. No shared core/theme file edits will be done in parallel.
- Baseline gate: `flutter analyze --no-fatal-infos` passed before source edits.

### [2026-05-12 11:39:20 +03] PHASE STARTED

- Phase/step: multi-agent implementation delegation.
- Workers spawned after ownership map was recorded:
  - Worker 1 `019e1b57-2fbc-7152-a170-9b9666fa9ddf`: Phase 5 auth/system gates.
  - Worker 2 `019e1b57-346b-7903-9593-6eccdb775976`: Phase 6 chat/attachments/notifications.
  - Worker 3 `019e1b57-37d5-77c1-a3a1-977e77c8bc09`: Phase 7 tasks/proposals/direct-offers/work/management.
  - Worker 4 `019e1b57-ef38-7011-abad-a70dc13208de`: Phase 8 booking/payment/wallet.
- Coordination note: initial Worker 4 spawn hit the agent thread limit. Older completed read-only agents were closed, then Worker 4 was spawned. No source edits were made during that thread-limit recovery.
- Each worker received a disjoint production/test write scope and a requirement to re-check Open Design MCP before implementation.

### [2026-05-12 11:41:54 +03] STEP COMPLETED

- Phase/step: baseline full test run before integrating worker changes.
- Command: `flutter test`.
- Result: pass.
- Evidence: `All tests passed!` with final counter `+1523 ~30`.
- Notes: integration-test plugin warnings appeared for tests under `test/integration_test/`; these were warnings from the baseline command, not failures.

### [2026-05-12 11:56:40 +03] PROBLEM ENCOUNTERED

- Phase/step: multi-agent implementation delegation.
- Problem: all four worker agents remained `running` after repeated bounded waits and did not return status checkpoints.
- Root cause: the delegated scopes were likely too broad for the worker sessions to produce timely patches.
- Could it have been caught earlier: yes; Phase 5-8 should have been split into smaller per-screen batches or only one implementation phase at a time.
- Resolution: closed the unresponsive worker sessions before integration. No worker patch was merged. Executor is switching to a smaller local implementation slice with explicit file ownership and verification.
- Rule to add/change: For wide UI phases, delegate at most one screen cluster per worker and require a checkpoint after the first file edit before continuing.

### [2026-05-12 12:10:35 +03] CORRECTION

- Phase/step: worker integration status.
- Correction: after the worker sessions were closed, their edits were present in the shared workspace even though no worker returned a final report.
- Resolution: treat all worker edits as untrusted integration patches; inspect, format, fix analyzer failures, run focused tests, run full tests, and record the final changed-file surface.
- Integration fixups made by Executor:
  - Replaced invalid `context.amber` references with `context.amberColors`.
  - Removed invalid `const` uses around runtime token getters.
  - Replaced undefined `AmberDuskColors.danger/warning` static access with `AmberDuskTokens.colors.danger/warning`.
  - Removed unused imports introduced by worker edits.
  - Replaced remaining raw transparent app-bar colors in changed booking screens with `AmberDuskColors.transparent`.

### [2026-05-12 12:10:35 +03] OPEN DESIGN MCP RE-CHECK

- Project: `1674a1db-7a74-4c80-8e2c-196a0385a8f7`.
- Name/entry: `Sline V2 Amber Dusk.html`.
- `updatedAt`: `1778418973981`.
- `list_files(since: 1778418973981)`: no newer files.
- `search_files("Received", "*.html")`: confirms `Received`/`Sent` in dashboard, design-system, web, and older staged variants; phone Messages screenshots still show `Responses`/`Requests` and remain copy-conflict references.
- `search_files("Wallet", "*.html")`: still confirms wallet as display/summary surface and does not add authority for a new active withdrawal route.

### [2026-05-12 12:10:35 +03] STEP COMPLETED

- Phase/step: Phase 5-8 execution integration.
- Production files touched: 44 tracked Flutter feature files across auth, chat, notifications, tasks, booking/payment, wallet, work, and management surfaces.
- Test files touched: 6 Dart test files: `test/widget/chat/messages_screen_test.dart`, new `test/widget/chat/phase6_attachment_message_tile_test.dart`, `test/widget/dashboard/inbox_tab_test.dart`, `test/widget/proposals/proposal_payment_screen_test.dart`, `test/widget/tasks/tender_payment_screen_test.dart`, and `test/widget/wallet/wallet_shared_body_test.dart`.
- Main implementation notes:
  - Phase 5 auth screens were moved onto Amber Dusk surfaces/tokens while preserving current auth and signup-disable behavior.
  - Phase 6 messaging copy now uses `Received` and `Sent`; attachment error UI and logs no longer expose private storage paths.
  - Phase 6 chat/notification surfaces use semantic/tokenized treatment with AppLogger instrumentation on new interaction paths.
  - Phase 7 tender/request award surfaces use Amber Dusk tokenized status treatment while preserving existing ViewModel/service authority.
  - Phase 8 booking/payment surfaces were tokenized; wallet behavior was not activated or changed.
- Architecture/design scans:
  - Direct Supabase scan over changed view scopes returned no hits.
  - Raw color/font/shadow scan found no raw `Color(0x...)`, `fontSize:`, or `BoxShadow(...)` in changed files.
  - Remaining `Duration(...)` hits are business date windows, not motion timings.
- Verification:
  - `dart format` on changed Dart files: pass.
  - `flutter analyze --no-fatal-infos`: pass, `No issues found!`.
  - Focused touched-surface widget tests: pass.
  - `flutter test`: pass, final counter `+1525 ~30`.
  - Post-cleanup booking focused tests: pass, final counter `+51`.
  - `git diff --check`: pass.

### [2026-05-12 13:02:13 +03] STEP 5 GAP SCAN COMPLETED

- Phase/step: Step 5 gap scan and repair after implementation.
- User constraint honored: no Step 6 test checklist was created or emitted.
- Read-only explorer roles:
  - Agent A compared implementation against the corrected phase plan.
  - Agent B compared implementation against Open Design MCP and exported screenshots.
  - Agent C scanned tests, logs, privacy-sensitive states, and missed UI states.
- Reference re-check:
  - Computer Use confirmed Open Design is active on project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`, file `Sline V2 Amber Dusk.html`.
  - Open Design MCP `get_artifact` re-confirmed Amber Dusk solid dark surfaces, raised amber panels, 22-24 px card radii, compact rows, grouped profile settings, Received/Sent message modes, and wallet/booking visual density.
- Gaps fixed:
  - `BookingCard` now renders task image paths through `SignedImage` instead of avatar storage.
  - `AttachmentMessageTile` no longer creates Supabase storage access inside the widget; signed URL resolution is supplied from `ChatViewModel`.
  - `SupabaseAttachmentUploader` now lazily creates `AttachmentService`, so unit tests can construct `ChatViewModel` without initializing global Supabase.
  - Login, signup, payment, WebView, payment return, and award-dialog logging were sanitized to avoid raw exception strings, private IDs, callback URLs, and storage-path details in new UI paths.
  - Signup validation now matches the visible 8-character requirement.
  - Messages use `Received` and `Sent` as visual copy only; no latest-message direction filtering is applied until a stable conversation direction contract exists.
  - Dashboard Inbox keeps `Sent` visually present but disabled until a separate sent-offer data contract exists.
  - Wallet hero and snapshot actions now read `Withdraw soon` and `Top up soon`, with disabled semantics, so unavailable actions do not look active.
  - Phase 5 auth/system gate surfaces, Phase 7 work/management/payment-adjacent surfaces, and Phase 8 booking/payment/wallet surfaces received token/semantic cleanups without backend or lifecycle authority changes.
  - Proposal payment wrapper tests now provide `AppTheme.light()` for the shared tender payment screen.
- Remaining visual authority notes:
  - Exact Flutter pixel parity is not claimed for auth gates, attachment tile, notification modal, proposal detail, payment return, or WebView states because exact phone artboards remain missing.
  - Profile/account settings received token cleanup only; the full Open Design grouped settings editor remains a larger product/UI implementation target.
  - Runtime Flutter screenshot comparison remains pending for later workflow steps.
- Verification after repairs:
  - `dart format lib/features/chat/attachments/services/upload_service.dart test/widget/proposals/proposal_payment_screen_test.dart`: pass.
  - Focused repaired tests: `flutter test test/unit/chat/chat_view_model_test.dart test/widget/proposals/proposal_payment_screen_test.dart`: pass.
  - `flutter analyze --no-fatal-infos`: pass, `No issues found!`.
  - `flutter test`: pass, final counter `+1525 ~30`.
  - `git diff --check`: pass.
  - View-scope direct Supabase/storage diff scan: no hits.
  - Backend diff gate for `supabase/migrations`, `supabase/functions`, and `supabase/tests`: no changed files.

### [2026-05-12 13:28:00 +03] STEP 6 ORCHESTRATOR REVIEW COMPLETED

- Phase/step: Step 6 review with `.cursor/Agents/Orchestrator.md`.
- Review agents:
  - Agent A / UI-design: `019e1ba8-4042-7602-be84-a2cbe2eabd69`.
  - Agent B / architecture-MVVM: `019e1ba8-43b4-7032-a40f-695768abf2dc`.
  - Agent C / test-QA: `019e1ba8-4785-7313-a711-cd4a4a5b767a`.
- Master Report: `.TODO/Archive/OpenDesign_AmberDusk_Phases5_6_7_8_2026-05-13/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_Step6.md`.
- Emulator checklist: `.TODO/EMULATOR_TEST_CHECKLIST_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8.md`.
- Findings fixed:
  - Restored Messages `Received`/`Sent` toggle to visual-only behavior so latest-message direction does not hide active conversations.
  - Removed Supabase/ErrorMapper imports from `AttachmentMessageTile`; signed URL resolution stays behind `ChatViewModel` and chat attachment services.
  - Sanitized `PaymentWebViewScreen` URL logging to URL facts only: parse state, scheme kind, path kind, trusted booleans, and query-key presence.
  - Fixed solid Amber Dusk payment/award CTA contrast by using inverse foreground tokens.
  - Added coverage verification and the per-file emulator/manual QA matrix.
  - Corrected the changed-file surface from the earlier integration snapshot to 44 production Dart files and 6 test Dart files.
- Fixture/provider matrix:
  - Auth/system gates: existing app/auth fixtures; emulator owns visual states.
  - Chat/messages/attachments: mock `ChatViewModel`, injected attachment resolver, and signed URL cache paths.
  - Dashboard Inbox: mock dashboard providers.
  - Task/tender/request/payment-adjacent: existing request/tender fixtures.
  - Booking/payment/WebView: existing booking/payment fixtures.
  - Wallet: existing wallet summary fixtures.
  - Work/management/notifications/profile settings: full-suite coverage plus emulator/manual visual QA.
- Verification after Step 6 fixes:
  - `dart format` on touched repair files: pass.
  - `flutter analyze --no-fatal-infos`: pass, `No issues found!`.
  - Focused touched-surface tests: pass, final counter `+97`.
  - `flutter test --coverage`: pass, final counter `+1525 ~30`.
  - Coverage parse: `instrumented=25571 hit=12727 pct=49.77`.
  - Removed generated `coverage/lcov.info`.
  - `git diff --check`: pass.
  - View-scope direct Supabase/storage scan: no hits.
  - Payment WebView raw URL log scan: no hits.
  - Backend diff gate for `supabase/migrations`, `supabase/functions`, and `supabase/tests`: no changed files.
  - Global activation gate for `lib/main.dart`, `lib/core/theme/app_theme.dart`, and `pubspec.yaml`: no changed files.

### [2026-05-13] STEP 7 SYSTEM EVOLUTION COMPLETED

- Phase/step: Step 7 with `.cursor/Agents/SystemEvolution.md`.
- Mode: single-agent merge mode; no sub-agents were spawned.
- Report: `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-05-13.md`.
- Agent files updated:
  - `.cursor/Agents/SystemEvolution.md`
  - `.cursor/Agents/Executor.md`
  - `.cursor/Agents/Architect.md`
  - `.cursor/Agents/Sentinel.md`
  - `.cursor/Agents/Observability.md`
  - `.cursor/Agents/DocsKeeper.md`
  - `.cursor/Agents/Orchestrator.md`
- Findings merged:
  - wide UI worker checkpoint and untrusted worker-patch handling
  - lazy/injected ViewModel service bridge testability
  - theme-extension wrapper test harness requirements
  - per-file emulator/manual matrix requirements
  - safe URL-facts logging for payment/WebView/deep-link paths
  - realtime transient close handling, cached state, reconnect, and tests
  - stale guidance path validation and cleanup ownership
  - explicit SystemEvolution merge mode when the human requests direct agent-file updates
- Dedupe notes:
  - unsafe model contract inference was already covered by `Architect.md`
  - visual-reference versus runtime evidence was already covered by `Executor.md`, `Pixel.md`, `Sentinel.md`, and `Orchestrator.md`
  - coverage arithmetic was already covered by `Planner.md` and `PlanCritic.md`
  - direct Supabase/storage-in-widget boundaries were already covered by MVVM and storage rules
- Remaining Step 8 DocsKeeper target:
  - stale `GEMINI.md` references still exist in non-agent context/rule files and should be cleaned in the docs pass.

### [2026-05-13] STEP 8 DOCSKEEPER COMPLETED

- Phase/step: Step 8 with `.cursor/Agents/DocsKeeper.md`.
- Mode: single-owner DocsKeeper pass; no sub-agents were used.
- Docs sync note: `.TODO/Archive/OpenDesign_AmberDusk_Phases5_6_7_8_2026-05-13/DOCS_SYNC_2026-05-13_OpenDesign_AmberDusk_Phases5_6_7_8.md`.
- Reference fix note: `.TODO/Archive/OpenDesign_AmberDusk_Phases5_6_7_8_2026-05-13/DOCS_REFERENCE_FIX_2026-05-13_GuidancePaths.md`.
- Documents updated:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/STRUCTURE.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/Sline_Log.md`
  - `Sline_everything/AppDigram/All_Diagrams/13_notification-routing.md`
  - `.cursor/rules/project-rules.mdc`
  - `.cursor/PROJECT_CONTEXT.md`
- Documentation outcomes:
  - recorded Amber Dusk Phase 5-8 scope, validation, changed surfaces, and open emulator visual QA gate
  - documented no Supabase object changes
  - documented `NotificationViewModel` transient Supabase Realtime close handling
  - cleaned stale `GEMINI.md` references from active `.cursor` guidance files
- Validation:
  - referenced plan, critique, master report, emulator checklist, screenshot manifest, session log, and SystemEvolution report paths exist
  - `rg -n "GEMINI" .cursor/rules/project-rules.mdc .cursor/PROJECT_CONTEXT.md`: no matches
  - `git diff --check`: pass

### [2026-05-13] TODO ARCHIVE CLEANUP COMPLETED

- Scope: completed generated Phase 5-8 status artifacts only.
- Archive folder: `.TODO/Archive/OpenDesign_AmberDusk_Phases5_6_7_8_2026-05-13/`.
- Archived files:
  - `.TODO/Archive/OpenDesign_AmberDusk_Phases5_6_7_8_2026-05-13/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_Step6.md`
  - `.TODO/Archive/OpenDesign_AmberDusk_Phases5_6_7_8_2026-05-13/DOCS_SYNC_2026-05-13_OpenDesign_AmberDusk_Phases5_6_7_8.md`
  - `.TODO/Archive/OpenDesign_AmberDusk_Phases5_6_7_8_2026-05-13/DOCS_REFERENCE_FIX_2026-05-13_GuidancePaths.md`
- Manifest added: `.TODO/Archive/OpenDesign_AmberDusk_Phases5_6_7_8_2026-05-13/README.md`.
- Left active:
  - master phone/web plans
  - Phase 5-8 plan and critique
  - emulator checklist
  - Open Design screenshot evidence
  - `.TODO/Future_Plans/`
  - `.TODO/WebRedsign/`
- Validation:
  - root `.TODO` inventory checked after moves
  - stale root-path references replaced with archive paths
  - no files deleted
