# Plan Critique: OpenDesign Amber Dusk Phone Phases 2, 3, And 4

**Date:** 2026-05-11  
**Critic:** @PlanCritic  
**Input Plan:** `.TODO/PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md`  
**Corrected Plan:** `.TODO/PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md`  
**Parent Plan:** `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`  
**Session Log:** `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md`

---

## A. Assumptions And Decision Needed

### Assumptions

- This critique is planning-only and does not implement Flutter source changes.
- The active design source is Open Design MCP project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`, entry `Sline V2 Amber Dusk.html`, plus `amber-dusk-design-system.html`.
- Phase 0 created a staged Amber Dusk token layer under `lib/core/theme/designs/amber_dusk/`; it did not globally activate Amber Dusk.
- Phase 1 activated selected shared phone widgets through `AmberDuskTokens.widgetTheme`; code gates passed, but runtime emulator visual QA remains open.
- Phase 2-4 work is visual/view-layer work. Backend, data contracts, ViewModels, services, repositories, Provider registration, Supabase, payment lifecycle, and storage behavior are out of scope.
- The current plan is allowed to create planning, critique, session-log, docs, handoff, and emulator checklist artifacts, but application code changes are reserved for the later Executor step.

### Decisions Needed

No blocking product decision remains after this critique. The plan now resolves the risky decisions as follows:

1. **Missing exact designs for Search/Categories/Saved/Favorites**
   - Decision: token-normalize only unless Open Design MCP or user screenshots provide exact phone states.
   - Recommended path: do not invent layouts from naming alone.
   - Plan impact: Phase 3 includes screenshot decision gates before implementation.

2. **Dashboard-launched screens**
   - Decision: inventory and smoke only; do not redesign launched work, booking, or payment detail screens inside Phase 4.
   - Recommended path: keep Phase 4 to dashboard-rendered shell, tabs, cards, status surfaces, and wallet cards.
   - Plan impact: implementation stops if work spills into detail/payment lifecycle screens.

3. **Phase 1 runtime QA**
   - Decision: treat the Phase 1 emulator checklist as an open visual/release gate, not as a reason to redo shared widgets during Phase 2-4.
   - Recommended path: runtime screenshots from Phase 2-4 can supersede relevant shared-widget route checks only when they explicitly cover those surfaces.
   - Plan impact: final report must state what remains open.

4. **Theme activation**
   - Decision: no global `AppTheme` flip.
   - Recommended path: consume existing Amber Dusk tokens/adapters in scoped views/widgets only.
   - Plan impact: no app-wide theme activation or broad visual claims.

5. **Font assets**
   - Decision: do not bundle Open Design font files without license/source evidence.
   - Recommended path: continue using existing font strategy and Amber Dusk typography roles.
   - Plan impact: no pubspec font asset work in Phase 2-4.

---

## B. Gate Status

| Gate | Draft Status | Corrected Status | Reason | Fix Applied |
|---|---|---|---|---|
| Gate 0: Test Infrastructure Gate | PARTIAL | PASS AFTER CORRECTION | The draft listed tests but did not force fixture matrices, Provider type classification, singleton cleanup, or bounded animation waits before writing tests. | Added a mandatory fixture/provider/state matrix and cleanup gate before tests. |
| Data / Contracts Gate | PASS | PASS | No DTO, model, ViewModel, repository, or service contract changes are planned. | Added a hard stop if UI work exposes a missing data contract. |
| Security / RLS Gate | PASS | PASS | No RLS, storage policy, auth, or privileged backend work is planned. | Added invariant checks for no direct Supabase in Views and no UI-only lifecycle enforcement. |
| Backend / Supabase Gate | PASS | PASS | Backend work is out of scope. | Any backend need now requires a separate `Skill: supabase-migration` plan. |
| UI / Integration Gate | PARTIAL | PASS AFTER CORRECTION | The draft was detailed but did not classify evidence authority tightly enough and could over-implement missing screens. | Added evidence classification, screenshot authority, exact-match limits, and Phase 1 visual caveat. |
| Release / QA Gate | PARTIAL | PASS AFTER CORRECTION; VISUAL CLOSURE STILL GATED | The draft listed QA but did not inherit Phase 1's open runtime visual gate strongly enough. | Added explicit runtime screenshot and final-report requirements. |

---

## C. Critical Gaps Found

### Gap 1: Critique artifact was missing.

- **Why it will break:** Executor and Sentinel need a persisted risk register and gate table, not only a rewritten plan.
- **Fix:** Create this `.TODO/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard.md` artifact.
- **Owner:** @PlanCritic.
- **Acceptance check:** Critique file exists and the plan references it.

### Gap 2: Evidence authority was not strict enough.

- **Why it will break:** A provisional screenshot pack or old Flutter baseline could be mistaken for runtime visual QA.
- **Fix:** Add an evidence classification matrix covering Open Design MCP, user screenshots, provisional screenshots, old runtime baselines, final runtime QA, and manual notes.
- **Owner:** @Pixel + @Sentinel.
- **Acceptance check:** Every screenshot or visual note in the session log is labeled by evidence type.

### Gap 3: Missing exact designs could lead to invented screens.

- **Why it will break:** Search results, Categories, Saved, and Favorites lack strong Open Design phone evidence.
- **Fix:** Limit those screens to token-normalization unless exact Open Design MCP or user screenshot evidence is available.
- **Owner:** @Pixel.
- **Acceptance check:** No pixel-match claim for those screens without a screenshot or artifact path.

### Gap 4: Dashboard scope could expand into lifecycle/payment flows.

- **Why it will break:** Phase 4 dashboard cards touch payment, offer, work, and booking actions; visual edits could accidentally affect business behavior.
- **Fix:** Mark launched detail/payment/work screens as inventory-and-smoke only.
- **Owner:** @Architect.
- **Acceptance check:** No launched detail/payment/work screen edits unless explicitly recorded as embedded dashboard UI.

### Gap 5: Test infrastructure was under-gated.

- **Why it will break:** Type B screens, auto-loading VMs, Provider type mistakes, and singleton state can produce flaky or misleading widget tests.
- **Fix:** Add Gate 0 requiring fixture/state matrices, Provider classification, singleton cleanup, and bounded pump strategy.
- **Owner:** @Sentinel.
- **Acceptance check:** Session log records fixture/provider matrix before test implementation.

### Gap 6: Phase 1 runtime visual QA risk was not prominent enough.

- **Why it will break:** Phase 2-4 could claim complete visual closure while shared-widget runtime QA remains unexecuted.
- **Fix:** Treat Phase 1 emulator checklist as an inherited release/visual gate.
- **Owner:** @Sentinel.
- **Acceptance check:** Final report states whether Phase 1 visual checklist is executed, superseded by current screenshots, or remains open.

### Gap 7: Worker ownership needed a hard stop.

- **Why it will break:** Multi-agent implementation could collide on shared files like `custom_bottom_nav_bar.dart`, card widgets, or test helpers.
- **Fix:** Add a stop rule requiring the main executor to pause and reassign ownership before a second worker touches an owned file.
- **Owner:** @Architect.
- **Acceptance check:** Session log records ownership handoffs before overlapping edits.

---

## D. Invariants And Success Criteria

- No View imports or calls Supabase directly.
- No ViewModel, service, repository, Provider registration, payment, storage, or backend behavior changes are allowed for this visual phase.
- No schema, RLS, RPC, trigger, storage policy, Edge Function, or SQL test changes are allowed.
- Dashboard payment return recovery and CTA routing behavior must remain unchanged.
- Create Tender/Booking behavior and edit mode must remain unchanged.
- Reusable visual values must come from the theme/token/adapter layer.
- No new `BackdropFilter`, `ImageFilter.blur`, frosted glass, or deleted `glass_*` file recreation.
- New code paths use `AppLogger`; no `print()` or `debugPrint()`.
- Every changed widget or screen has focused tests for the states introduced or affected.
- Visual closure requires runtime Flutter screenshots or explicit manual runtime notes, not Open Design reference images alone.
- Documentation and web handoff must describe verified implementation only.

---

## E. Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|---|---|---:|---:|---|---|---|---|
| Missing screen designs get invented | Search, Categories, Saved, Favorites | High | Medium | Phase 3 UX drift | No screenshot/artifact path in log | Token-normalization only without evidence | Defer exact match and request screenshots |
| Phase 4 expands into payment/work lifecycle | Dashboard cards and launched screens | Medium | High | Payment/work regressions | Edits in payment/detail files | Inventory-and-smoke boundary | Revert launched-screen edits and document future phase |
| Phase 1 visual QA gap is ignored | Shared widgets used by Phase 2-4 | High | Medium | Visual closure false positive | Final report lacks emulator evidence | Runtime screenshot matrix | Keep visual gate open |
| Worker file collision | Multi-agent execution | Medium | High | Merge conflicts or lost edits | Two agents modify same file | Ownership stop rule | Main executor resolves and reruns tests |
| Provider test setup is wrong | Widget tests | Medium | Medium | Flaky/misleading tests | MissingStubError, provider not found | Gate 0 fixture/provider matrix | Add seam or lower-level harness |
| Teal/raw values remain | Target screens | High | Medium | Incomplete redesign | Raw-token scan hits | Classify/fix before phase gate | Document legacy exception or fix |
| Screenshot evidence over-applied | Visual QA | Medium | Medium | Inconsistent UI | Details copied beyond visible area | Evidence matrix | Fall back to tokens/MCP |
| AppLogger requirement missed | New branches | Medium | Medium | Poor observability | New async path without log | Observability checklist | Add logs before close |
| Full test/coverage skipped | Cross-phase QA | Medium | High | CI regression | No lcov result | Mandatory coverage gate | Document blocker and run before merge |

---

## F. Pre-Mortem

- This fails when an executor starts from the draft plan and misses this PlanCritic artifact.
- This fails when Open Design reference images are treated as Flutter runtime QA.
- This fails when Categories, Saved, Favorites, or Search results are redesigned without actual screen evidence.
- This fails when Dashboard visual cleanup edits payment checkout, work details, or booking details behavior.
- This fails when multiple workers touch `custom_bottom_nav_bar.dart`, card widgets, or shared test helpers without coordination.
- This fails when Type B screens create ViewModels internally and tests assume ancestor-provided mocks.
- This fails when Phase 1's manual emulator checklist remains open but final Phase 2-4 docs say the visual system is complete.
- This fails when feature files receive new raw Amber Dusk colors, font sizes, shadows, or duration constants.
- This fails when new async UI paths are added without `AppLogger`.

---

## G. Plan Fixes

1. **Goal:** Persist the PlanCritic source-of-truth gate.
   - **Why:** Executors and reviewers need a durable artifact.
   - **How:** Add this critique file and reference it from the plan.
   - **Output artifact:** `.TODO/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard.md`.
   - **Stop condition:** Missing critique file blocks execution.

2. **Goal:** Prevent fake visual evidence.
   - **Why:** Prior Phase 1 screenshot pack had duplicate hashes and was reference-only.
   - **How:** Add evidence classification and runtime QA requirements.
   - **Output artifact:** Session-log evidence table during execution.
   - **Stop condition:** No runtime evidence means no visual closure claim.

3. **Goal:** Keep Phase 3 grounded where designs are missing.
   - **Why:** Several secondary discovery screens lack exact Open Design phone states.
   - **How:** Token-normalize without screenshots; request screenshots for exact matching.
   - **Output artifact:** Phase 3 evidence note.
   - **Stop condition:** Exact-match work blocked without evidence.

4. **Goal:** Keep Phase 4 from changing lifecycle behavior.
   - **Why:** Dashboard cards route into payment/work/booking flows.
   - **How:** Inventory launched screens and smoke routes only.
   - **Output artifact:** Dashboard-launched screen inventory note.
   - **Stop condition:** Any required lifecycle edit triggers a separate plan.

5. **Goal:** Stabilize tests before implementation.
   - **Why:** Provider and singleton mistakes cause misleading widget tests.
   - **How:** Add Gate 0 fixture/provider/singleton matrix.
   - **Output artifact:** Test infrastructure matrix in session log.
   - **Stop condition:** Tests cannot be written until matrix exists.

6. **Goal:** Avoid multi-agent edit collisions.
   - **Why:** The later Executor step is multi-agent.
   - **How:** Treat file ownership as a hard lock and handoff rule.
   - **Output artifact:** Worker ownership log.
   - **Stop condition:** Overlap requires main-executor coordination before edit.

---

## H. Corrected Plan Reference

The corrected source-of-truth execution plan is:

`.TODO/PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md`

Implementation must follow that corrected plan plus this critique file, not the pre-critique draft and not the broad parent phone-plan sections alone.

Corrected plan structure:

- PlanCritic assumptions and resolved decisions.
- Gate status table, including Test Infrastructure Gate.
- Critical corrections.
- Evidence classification matrix.
- Non-negotiable invariants.
- Corrected execution order.
- Original detailed execution phases for Phase 2, Phase 3, Phase 4, cross-phase QA, docs, acceptance criteria, and rollback.

---

## I. Change Report

### Original Issues Summary

- The draft plan was detailed but lacked a persisted PlanCritic artifact.
- The draft plan did not classify evidence types strongly enough.
- The draft plan could allow exact matching for missing Search/Categories/Saved/Favorites designs.
- Dashboard-launched detail/payment/work screens needed a stronger boundary.
- Test setup needed a dedicated infrastructure gate.
- Phase 1 runtime visual QA caveat needed to be elevated into Phase 2-4 release criteria.
- Worker ownership needed a hard stop rule, not just a table.

### Added Steps

- Added critique artifact reference to the plan.
- Added assumptions and resolved decisions.
- Added Gate 0 Test Infrastructure Gate.
- Added corrected gate status table.
- Added critical correction list.
- Added evidence classification matrix.
- Added non-negotiable invariants.
- Added corrected execution order.
- Added release/visual closure language tied to Phase 1 open QA.

### Removed Steps

- Removed no steps from the implementation body. The rewrite adds constraints and gates without narrowing the master Phase 2-4 coverage.

### Reordered Steps

- Evidence lock now precedes every section.
- Test infrastructure now precedes test writing.
- Worker ownership lock now precedes multi-agent implementation.
- Docs and web handoff remain after verification, not before.

### Expanded Steps

- Screenshot handling expanded from "ask/pull screenshots" into evidence classification and stop conditions.
- Test planning expanded into fixture/provider/singleton rules.
- Dashboard launched-screen boundary expanded into inventory, smoke, and separate-plan trigger.
- Phase 1 visual caveat expanded into a release gate.

### Why

The draft could be executed, but it still allowed ambiguity in the exact places prior Amber Dusk phases already exposed as risky: screenshot authority, runtime visual QA, activation scope, hidden test infrastructure, and broad dashboard/payment boundaries. The corrected plan makes those risks explicit gates.

### Residual Risks

- Runtime emulator visual evidence is still not available at planning time.
- Open Design MCP may still lack full states for secondary discovery screens.
- No golden-test infrastructure exists.
- Full Phase 2-4 implementation is large and must be split by strict file ownership.
- If implementation discovers a real data-contract gap, this visual plan must stop and a separate architecture/backend plan must be created.

