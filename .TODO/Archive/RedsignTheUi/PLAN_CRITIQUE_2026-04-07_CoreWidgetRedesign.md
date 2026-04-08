# @PlanCritic Audit: PLAN_CoreWidgetRedesign_2026-04-07

**Plan audited:** `.TODO/PLAN_CoreWidgetRedesign_2026-04-07.md`
**Audit date:** 2026-04-07
**Verdict:** ❌ **FAIL — 5 critical gaps must be fixed before execution**

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (Inferred Safely)
1. Phase 0 Design System Foundation is confirmed complete (session log shows all 12 criteria pass).
2. `mocktail` library is available for widget tests (already in dev_dependencies per existing test files).
3. `flutter test` can be run incrementally on `test/core/widgets/` subdirectory.

### Decision Needed (Blocking)

**DECISION 1: WorkItem model — move to core or create thin interface?**

The plan says "Move WorkItem model to `lib/core/models/` if shared, OR create WorkItemStatus enum/typedef in core." But the scan reveals:
- WorkItem is imported by **8 files** (6 in dashboard feature, 2 in core — status_badge + dashboard_cache_service).
- WorkItem has nested `WorkItemPermissions` class, uses `WorkItemType` and `PrimaryActionType` from core/app_enums.dart.
- Moving the entire model to core is the cleaner fix since 2 core files already depend on it.

- **Option A (Recommended):** Move `WorkItem` + `WorkItemPermissions` to `lib/core/models/work_item.dart`. Update all 8 import paths. This is a 1-line change per file (import path update).
- **Option B:** Create a thin `StatusInfo` typedef in core that status_badge uses, leaving WorkItem in dashboard. But this doesn't fix `dashboard_cache_service.dart` which also imports it.

**Impact:** Option A is cleaner — 8 import path changes, zero logic changes. Option B is a half-fix.

**DECISION 2: AvatarService / TaskImageService — interface extraction vs simple path move?**

The plan says "Extract interface to core." But the scan reveals:
- Neither service is a Provider — both are instantiated directly (`AvatarService(Supabase.instance.client)`, `TaskImageService()`).
- `signed_avatar.dart` only calls `createSignedUrl(storagePath, {expire})`.
- `signed_image.dart` only calls `createSignedUrl(path, {expire})`.
- Both services share the SAME core behavior: `createSignedUrl(path) → String`.

- **Option A:** Extract a shared `SignedUrlResolver` abstract class in core with one method: `Future<String?> createSignedUrl(String path, {Duration expire})`. Both services implement it. Widgets depend on the abstract class.
- **Option B (Recommended):** Simpler — both widgets already use `SignedUrlCache` from core. The violation is that they instantiate the service to get the Supabase client for signing. Instead, pass a `SupabaseClient` or `StorageUrlSigner` callback directly, avoiding service import entirely. The widgets only need `(String path) → Future<String?> url` — a simple function type.
- **Option C:** Move both services entirely to core. But they contain feature-specific logic (bucket names, upload paths) so they belong in features.

**Impact:** Option B is cleanest — no new interface file, just a function type parameter on the widget. But it changes the widget constructor API.

---

## B) Gate Status

| # | Gate | Status | Reason |
|---|------|--------|--------|
| 1 | Data / Contracts Gate | ✅ PASS | No database changes |
| 2 | Security / RLS Gate | ✅ PASS | No security changes |
| 3 | Backend / Supabase Gate | ✅ PASS | No backend changes |
| 4 | UI / Integration Gate | ❌ **FAIL** | 5 critical gaps below |
| 5 | Release / QA Gate | ❌ **FAIL** | Missing commit strategy, missing test failure threshold |

---

## C) Critical Gaps (Must-Fix)

### GAP 1: Architecture fix for status_badge ALSO needs to fix dashboard_cache_service.dart

**Why it will break:** The plan fixes `status_badge.dart` importing `WorkItem` from features/dashboard, but `dashboard_cache_service.dart` (another core file) has the SAME violation. If you move WorkItem to core/models/ for status_badge, you MUST also update dashboard_cache_service.dart in the same phase — otherwise `flutter analyze` will still show architecture guard failures.

**Fix:**
- [ ] Phase 1.3: Add sub-step to update `lib/core/services/dashboard_cache_service.dart` import path for WorkItem.
- [ ] Phase 1.3: Total files needing import path update = 8 (not just status_badge).

**Owner:** @Architect
**Acceptance check:** Grep for `import.*features/.*work_item` in `lib/core/` returns 0.

---

### GAP 2: No commit strategy defined

**Why it will break:** 10 phases touching 14+ files. Same problem as Phase 0 critique GAP 3.

**Fix:** Add commit strategy:
1. After Phase 1 (architecture fixes — independently revertible)
2. After Phases 2 (test infrastructure — independent)
3. After Phase 3 (foundation widgets — ScaleButton/GlassContainer/GlassCard)
4. After Phase 4 (interactive widgets — AppButton/AppTextField/CircleIconButton/GlassButton)
5. After Phase 5 (display widgets — SignedAvatar/SignedImage/StatusBadge)
6. After Phase 6 (navigation widgets — BottomNavBar/SliverTabBarDelegate)
7. After Phase 7 (skeleton expansion)
8. After Phase 8 (button themes)
- **Total: 8 commits.**

**Owner:** @Sentinel

---

### GAP 3: GlassContainer default blur change (20→12) is a visual breaking change for 21 files

**Why it will break:** The plan reduces the default `blurRadius` from `AppDimens.p20` (20) to 12 (`GlassIntensity.medium`). This changes the appearance of **every GlassContainer in the app** (21 feature files). While not a code break, it's a VISIBLE change that should be explicitly called out and visually verified.

**Fix:**
- [ ] Phase 3.2: Add explicit sub-step: "Run app on emulator. Navigate to 5+ screens using GlassContainer. Screenshot before and after. Confirm glass effect is still visible and not too subtle at blur=12."
- [ ] Phase 3.2: If blur=12 is too subtle on dark mode (glass disappears into dark background), adjust to blur=14 or keep at 16. Document the decision.
- [ ] Phase 3.2: Consider keeping `blurRadius: AppDimens.p20` as default but adding `intensity` as an ADDITIONAL optional parameter. This way existing usage is unchanged. New code can opt into intensity levels.

**Owner:** @Pixel
**Acceptance check:** Visual comparison screenshots in session log.

---

### GAP 4: AppButton success state requires StatefulWidget conversion

**Why it will break:** The plan adds success state (flash green, show check, revert after 1500ms) and loading state animation to AppButton. Currently AppButton is a **StatelessWidget** (line 126). Success/loading animations require `AnimationController` → needs `SingleTickerProviderStateMixin` → needs **StatefulWidget**.

This is a non-trivial refactor. The plan treats it as "add optional params" but it actually changes the widget's class type. While constructor params stay backward-compatible, the internal architecture changes significantly.

**Fix:**
- [ ] Phase 4.1: Add explicit sub-step: "Convert AppButton from StatelessWidget to StatefulWidget. Move build logic to State class. Verify all 21 feature files still compile."
- [ ] Phase 4.1: Add AnimationController for success flash + loading crossfade. Use `SingleTickerProviderStateMixin`.
- [ ] Phase 4.1: This MUST be its own sub-phase with a dedicated `flutter test` gate between the StatefulWidget conversion and the state additions.

**Owner:** @Pixel + @Architect
**Acceptance check:** `flutter analyze` clean after conversion, before adding new states.

---

### GAP 5: AppTextField error shake requires StatefulWidget conversion

**Why it will break:** Same as GAP 4 — AppTextField is currently a **StatelessWidget** (line 73). Adding error shake animation (3 cycles, 4px, 300ms per AppInteractionStates) requires AnimationController → needs StatefulWidget.

The plan also adds `showClearButton` (needs to listen to TextEditingController changes for show/hide) and `showPasswordToggle` (needs local state for eye icon toggle). These ALSO require StatefulWidget.

**Fix:**
- [ ] Phase 4.2: Add explicit sub-step: "Convert AppTextField from StatelessWidget to StatefulWidget."
- [ ] Phase 4.2: The `showClearButton` feature needs to create an internal `TextEditingController` if the user doesn't provide one, AND listen for changes. This is a significant complexity increase.
- [ ] Phase 4.2: Split into: Sub-phase 4.2a (StatefulWidget conversion + password toggle) and Sub-phase 4.2b (clear button + character counter). Test between each.

**Owner:** @Pixel
**Acceptance check:** `flutter analyze` clean after conversion. 15 feature files verified.

---

## D) Invariants & Success Criteria (Non-Negotiable)

| # | Invariant | How to Enforce | How to Verify |
|---|-----------|----------------|---------------|
| 1 | No feature files modified (except architecture import path updates) | Plan scope | `git diff --name-only` shows only core/ and test/ (plus 8 import path changes in features for WorkItem move) |
| 2 | All widget constructors backward-compatible | Optional params only, no removals | Compare constructor signatures before/after |
| 3 | Zero `import.*features/` in lib/core/ | Architecture fixes | `grep -r "import.*features/" lib/core/` returns 0 |
| 4 | `flutter test` baseline maintained | Fast Feedback Gate after each phase | Before/after test counts |
| 5 | All new tokens from AppMotion/AppStates/AppDecorations | No hardcoded Duration/Curves/shadows | `grep` in lib/core/widgets/ |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| GlassContainer blur reduction visible on 21 screens | Phase 3.2 | HIGH (80%) | MED | 21 files | Visual check | Keep default, add opt-in intensity | Revert blur to 20 |
| AppButton StatefulWidget conversion breaks tests | Phase 4.1 | MED (40%) | HIGH | 21 files | `flutter test` | Convert first, test, then add features | Git revert phase 4 |
| AppTextField complexity explosion (clear + toggle + shake + counter) | Phase 4.2 | MED (50%) | MED | 15 files | Code review | Split into 2 sub-phases | Implement toggle only, defer others |
| WorkItem move breaks dashboard feature | Phase 1.3 | LOW (20%) | MED | 8 files | `flutter analyze` | Update all 8 import paths atomically | Revert move |
| CustomBottomNavBar label addition changes layout height | Phase 6.1 | MED (40%) | LOW | 1 file | Visual check | Make labels opt-in | Hide labels |
| skeleton_card.dart exceeds 800 lines | Phase 7 | HIGH (90%) | LOW | File organization | Line count | Split preemptively | Single file is OK for documentation |

---

## F) Pre-Mortem

1. **This fails when** AppButton is converted to StatefulWidget but an existing test creates it with a const constructor (StatefulWidgets can't be const in most patterns), causing compile errors in 21 feature files.
2. **This fails when** GlassContainer blur goes from 20→12 and the dark mode glass effect becomes invisible, making 21 screens look broken, but nobody checks until Phase 9.
3. **This fails when** WorkItem is moved to core/models/ but the plan forgets to update dashboard_cache_service.dart, leaving 1 architecture violation that blocks CI.
4. **This fails when** AppTextField's `showClearButton` creates an internal TextEditingController that conflicts with the externally-provided one, causing double-dispose crashes in 15 screens.
5. **This fails when** all 14 widgets are changed without committing between phases, Phase 6 breaks, and reverting loses Phases 3-5.
6. **This fails when** the 8 new skeleton variants don't match the real card layouts because nobody compared them side-by-side, and they look obviously wrong on first use in Phase 2+.
7. **This fails when** StatusBadge's pulse animation on "pending" runs continuously, consuming battery and causing jank on low-end devices.

---

## G) Plan Fixes (Concrete Additions)

### FIX 1: Add dashboard_cache_service.dart to Phase 1.3
- **Goal:** Fix ALL WorkItem imports in core, not just status_badge.
- **Why:** dashboard_cache_service.dart has the same violation.
- **How:** Move WorkItem to core/models/, update all 8 import paths.
- **Output:** Zero `import.*features/.*work_item` in lib/core/.
- **Stop condition:** Grep returns 0.

### FIX 2: Add commit strategy
- **Goal:** Each phase independently revertible.
- **Why:** 10 phases, 14+ files. Can't batch.
- **How:** 8 commits at defined boundaries.
- **Output:** Git log with clean commits.
- **Stop condition:** Each commit passes `flutter analyze`.

### FIX 3: GlassContainer — keep default blur, add opt-in intensity
- **Goal:** Prevent visual breaking change for 21 files.
- **Why:** Changing default blur from 20→12 affects every GlassContainer silently.
- **How:** Keep `blurRadius: AppDimens.p20` as default. Add `intensity` as ADDITIONAL optional parameter. When intensity is provided, it overrides blurRadius. Existing code unchanged. New code can opt into intensity levels.
- **Output:** No visual change to existing screens. New intensity API available.
- **Stop condition:** All 21 feature files render identically before and after.

### FIX 4: Split AppButton into conversion + feature sub-phases
- **Goal:** Prevent cascading failure from StatefulWidget conversion.
- **Why:** Converting StatelessWidget → StatefulWidget is a structural change that should be tested independently before adding animation features.
- **How:** Phase 4.1a: Convert to StatefulWidget, verify 21 files compile. Phase 4.1b: Add 8-state model, animations, haptics.
- **Output:** Two separate sub-phases with a test gate between them.
- **Stop condition:** `flutter test` passes after 4.1a before starting 4.1b.

### FIX 5: Split AppTextField into conversion + features
- **Goal:** Same as FIX 4.
- **Why:** Same structural risk. Plus clear button has TextEditingController lifecycle complexity.
- **How:** Phase 4.2a: Convert to StatefulWidget + add password toggle (simplest). Phase 4.2b: Add clear button + character counter. Phase 4.2c: Add error shake (needs AnimationController).
- **Output:** Three sub-phases for AppTextField.
- **Stop condition:** `flutter test` passes after each sub-phase.

### FIX 6: Add visual comparison checkpoints for high-blast-radius widgets
- **Goal:** Catch visual regressions early, not at Phase 9.
- **Why:** GlassContainer (21 files), AppButton (21 files), SignedAvatar (14 files) affect the most screens.
- **How:** After Phases 3, 4, and 5: run app on emulator, navigate to 3+ screens using the changed widget, verify visual correctness.
- **Output:** Session log entry with visual verification note.
- **Stop condition:** No visual regressions.

### FIX 7: StatusBadge pulse — add battery/performance guard
- **Goal:** Prevent continuous animation draining battery.
- **Why:** Pulse on "pending" repeats indefinitely.
- **How:** Limit pulse to 3 repetitions, then stop. Or only pulse when widget is visible (using `VisibilityDetector` or `TickerMode`). Use `AppMotion.respectMotion()` to skip on reduced motion.
- **Output:** Pulse animation is bounded.
- **Stop condition:** Animation stops after 3 cycles or when scrolled off-screen.

---

## H) Corrected Plan Changes

The corrected plan applies all 7 fixes above. Key modifications to original:

### Phase 0: Add Sub-phase 0.4 Commit Strategy
- 8 commits at defined boundaries (same pattern as Phase 0 critique).

### Phase 1.3: Expand WorkItem Move
- Move WorkItem + WorkItemPermissions to `lib/core/models/work_item.dart`.
- Update ALL 8 import paths (6 dashboard, 1 status_badge, 1 dashboard_cache_service).
- Gate: `grep -r "import.*features/.*work_item" lib/core/` returns 0.

### Phase 3.2: GlassContainer — Keep Default, Add Opt-In Intensity
- Keep `blurRadius: AppDimens.p20` as default (NOT changed to 12).
- Add `intensity` as ADDITIONAL optional `GlassIntensity?` parameter.
- When `intensity` is non-null, it overrides `blurRadius`.
- Existing code unchanged. Zero visual diff for 21 screens.
- Add `GlassContainer.elevated` factory that uses `GlassIntensity.strong`.
- Add visual verification sub-step after Phase 3 completion.

### Phase 4.1: Split AppButton into 4.1a + 4.1b
- **4.1a:** Convert StatelessWidget → StatefulWidget. Zero feature changes. `flutter test` gate.
- **4.1b:** Add 8-state model (disabled, loading crossfade, success flash, Semantics, haptics, elevation).
- Visual verification checkpoint after Phase 4.

### Phase 4.2: Split AppTextField into 4.2a + 4.2b + 4.2c
- **4.2a:** Convert StatelessWidget → StatefulWidget + add password toggle.
- **4.2b:** Add clear button + character counter.
- **4.2c:** Add error shake animation.
- `flutter test` gate between each.

### Phase 5.3: StatusBadge pulse — Add Bounded Repetition
- Pulse limited to 3 repetitions then stops.
- Use `AppMotion.respectMotion()` to skip on reduced motion.

### Phases 3, 4, 5: Add Visual Verification Sub-Steps
- After each high-blast-radius phase: run app, check 3+ screens, note in session log.

---

## I) Change Report (Diff-Style)

### 1. Original Issues Summary
- Plan was well-structured with 10 phases, 80+ steps, proper agent/skill tags.
- 5 critical gaps found: incomplete architecture fix, no commit strategy, visual breaking change, StatefulWidget conversions unaccounted, TextField complexity unmanaged.

### 2. Added Steps (24 new)
- Phase 0.4: Commit strategy (1 step)
- Phase 1.3: dashboard_cache_service.dart update (2 steps)
- Phase 3.2: Visual verification checkpoint (2 steps)
- Phase 4.1: Split into 4.1a + 4.1b with gate (4 steps)
- Phase 4.2: Split into 4.2a + 4.2b + 4.2c with gates (6 steps)
- Phase 5: Visual verification checkpoint (2 steps)
- Phase 5.3: Pulse bounded repetition (2 steps)
- Phase 4: Visual verification checkpoint (2 steps)
- Phase 3.2: GlassContainer keep-default strategy (3 steps)

### 3. Changed Steps
- Phase 3.2 GlassContainer: "Reduce default blur 20→12" → "Keep default blur 20, add opt-in intensity parameter"
- Phase 1.3 StatusBadge: "Move WorkItem or create typedef" → "Move WorkItem to core/models, update all 8 paths"

### 4. Why
- GAP 1: dashboard_cache_service missed → CI would fail
- GAP 2: No commits → cascading revert risk
- GAP 3: Blur change → 21 screens silently broken
- GAP 4: AppButton conversion → compile errors in 21 files
- GAP 5: AppTextField complexity → crash risk with TextEditingController

### 5. Residual Risks
- AppButton StatefulWidget conversion may still surprise if any test uses `const AppButton(...)`.
- WorkItem move touches 8 files including 6 in features/dashboard — could break dashboard tests.
- CustomBottomNavBar label addition changes visual balance — may need height adjustment.

---

**Plan is PASS-ready once all 7 fixes are applied.**

END.
