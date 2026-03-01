# 📌 Plan: Favorites Fix & Contract Reconcile

## 1) Goal

- Goal:
  - Repair the full `favorites` feature surface and its direct dependencies so favorites state is single-sourced, joins are null-safe, DM handoff follows one verified contract, MVVM boundaries are restored, and regression coverage is deterministic.
- Why:
  - Current runtime has four blocking defects: parser crash risk, split favorites provider ownership, active UI -> service leakage in request-tile flow, and live DM authorization drift between docs, trigger comments, and policy. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/models/favorite_model.dart:65-73`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart:172-175`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart:19-40`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:112-119`, live Supabase scan: `conversations_insert_client_only`, `conversations_before_insert_guard()`.
- Result:
  - One shared favorites state source, one canonical favorites read/mutation contract, no widget-owned favorites service calls, verified RLS/DM behavior, stable test selectors and fixtures, synced docs, and reviewable PR slices.

## 2) Scope

### In-Scope
- Favorites feature runtime files.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/data/favorites_service.dart`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/models/favorite_model.dart`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/viewmodels/favorites_view_model.dart`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/widgets/favorite_card.dart`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/routes/favorites_routes.dart`
- Direct feature dependencies touched by favorites behavior.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart:172-175`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/view/public_profile_screen.dart:138-165`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:19-129`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/requests_list_screen.dart:273-282`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/viewmodels/chat_view_model.dart:58-60`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/viewmodels/chat_view_model.dart:138-149`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/data/chat_repository.dart:26-34`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/services/message_service.dart:18-87`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/services/message_service.dart:429-444`
- Shared core utilities and test harnesses that the fix must reuse.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/error_mapper.dart:18-145`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/format_date.dart:38-45`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/logger_service.dart:82-140`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart:5-18`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/helpers.dart:19-128`
- Live Supabase objects directly used by favorites and favorites-triggered DM flow.
  - References:
    - live Supabase scan: `public.favorites` columns/policies/indexes
    - live Supabase scan: `public.conversations` policies/indexes/triggers/functions

### Out-of-Scope
- Chat message sending, attachments, notifications delivery, and generic inbox behavior after conversation creation.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart:91-121`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/services/message_service.dart:247-427`
- Unrelated feature modules not imported or called by favorites.
- Broad cleanup of overlapping `public.conversations` indexes/policies unless a specific DB reconcile is required by the locked DM rule.

## 3) Evidence & Findings (From Scan)

### Existing
- Favorites is a live routed feature with its own MVVM module.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart:12-138`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/viewmodels/favorites_view_model.dart:13-111`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart:172-175`
- Public profile and request-tile flows already call into favorites behavior.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/view/public_profile_screen.dart:138-165`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:93-129`
- Generic error mapping, date formatting, logging, widget-test harness, and integration harness already exist and should be extended, not replaced.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/error_mapper.dart:18-145`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/format_date.dart:38-45`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/logger_service.dart:40-140`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart:5-18`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/helpers.dart:19-128`
- Live Supabase confirms `public.favorites` exists with RLS enabled and owner-only policies.
  - References:
    - live Supabase scan: `favorites_select_own`, `favorites_insert_self`, `favorites_delete_self`
    - live Supabase scan: `idx_favorites_client`, `idx_favorites_freelancer`, `uq_favorites_client_freelancer`
- Live Supabase confirms direct DM insertion is currently favorites-gated at the policy layer.
  - Reference: live Supabase scan: `conversations_insert_client_only`

### Missing
- Favorites-specific test files are missing.
  - Evidence: repo scan `rg --files test integration_test | rg 'favorite|favorites'` returned no hits.
- Favorites entry points expose no stable test keys/selectors today.
  - Evidence: repo scan `rg -n "Key\(|ValueKey|ObjectKey|GlobalKey|static const .*Key" lib/features/favorites lib/features/profile/view/public_profile_screen.dart lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` returned no hits.
- A source-controlled provenance artifact for live `favorites` SQL is missing from `supabase/migrations/`.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/MVP_ROADMAP.md:82`
    - live Supabase scan: `public.favorites` exists
- Favorites-specific fixture manifest, selector map, UI state matrix, PR slicing, and release checklist artifacts do not exist yet.

### Must NOT duplicate
- Do not add a feature-local error-mapper when `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/error_mapper.dart` already exists.
- Do not keep or create a second long-lived `FavoritesViewModel` instance when `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart:172-175` already provides one globally.
- Do not add raw date formatting in favorites UI when `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/format_date.dart:38-45` already provides `formatUtcToLocal()`.
- Do not change direct-DM authorization semantics as an incidental side effect of repairing favorites. If product wants non-favorites DMs, that is a separate scoped change.
- Do not backfill a fake historical favorites migration just to “match” live DB; only add forward-safe migration(s) if live contract needs to change.

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)
- Live policy says direct DMs require favorites; live trigger comment/body says favorites were removed for DMs.
  - References:
    - live Supabase scan: `conversations_insert_client_only`
    - live Supabase scan: `conversations_before_insert_guard()`
- `SUPABASE_SETUP.md` says DMs no longer require favorites, but current `DEVELOPER_GUIDE.md`, favorites deep-dive, and live policy still tie DM access to favorites.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md:81-83`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md:97-108`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md:192-192`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:25-34`
- Historical `CODE_REVIEW.md` claims request-tile service calls were fixed, but the current callsite still activates the direct service fallback.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/CODE_REVIEW.md:258-268`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:112-119`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/requests_list_screen.dart:273-282`
- Public profile and favorites screen can diverge because there are two favorites provider owners today.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart:172-175`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart:19-40`

## 4) System Impact Map

- UI:
  - Favorites screen, favorite card, public profile heart toggle, request-tile “Add to favorites” action, chat-start/remove snackbars, stable keys/selectors.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart:44-138`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/widgets/favorite_card.dart:18-68`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/view/public_profile_screen.dart:138-165`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:33-129`
- MVVM/App Logic:
  - Shared provider ownership, typed mutation results, pending-action guards, single canonical read path, explicit load contract.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/viewmodels/favorites_view_model.dart:28-110`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart:172-175`
- Database:
  - `public.favorites` CRUD contract, `public.conversations` DM gate, provenance risk from missing checked-in favorites SQL, optional DB reconcile path only if needed.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/data/favorites_service.dart:21-107`
    - live Supabase scan: `public.favorites`
    - live Supabase scan: `public.conversations`
- RLS/Security:
  - Favorites owner-only CRUD, direct-DM gate, no client-side privileged bypasses, no raw backend error exposure.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart:116-120`
    - live Supabase scan: `favorites_*` policies
    - live Supabase scan: `conversations_insert_client_only`
- Realtime/Notifications (if any):
  - Favorites itself has no realtime or notifications behavior; only chat conversation creation is in scope.
- Storage:
  - Favorites reads profile avatar URLs but does not write storage.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/widgets/favorite_card.dart:26-33`
- Observability (if any):
  - Existing `AppLogger` should remain the diagnostics path; no new raw error interpolation in UI.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/data/favorites_service.dart:35-42`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/viewmodels/favorites_view_model.dart:37-44`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/logger_service.dart:126-139`
- Compatibility & Migration:
  - Code changes are mandatory; DB changes are optional and only after the DM rule is explicitly locked and re-verified.
- Contracts:
  - Joined favorites read contract, mutation result contract, UI state matrix contract, direct-DM authorization contract.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.0 Test Infrastructure Gate

- [ ] (@Sentinel) Create `.TODO/TEST_INFRA_Favorites_2026-03-01.md` that extends existing harnesses instead of inventing new ones.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart:5-18`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/helpers.dart:19-128`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/pubspec.yaml:59-63`
- [ ] (@Pixel) Define a selector/key map for favorites-critical UI in `.TODO/TEST_INFRA_Favorites_2026-03-01.md` and then implement those selectors in:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/widgets/favorite_card.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/view/public_profile_screen.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/widgets/request_tile.dart`
- [ ] (@Sentinel) Create `.TODO/FIXTURES_Favorites_2026-03-01.md` with deterministic staging data requirements: client account, freelancer account(s), at least one existing favorite row, one non-favorite freelancer, and cleanup/reset instructions.
- [ ] (@Sentinel) Define bounded waits, rerun policy, and failure artifact path/tagging in `.TODO/TEST_INFRA_Favorites_2026-03-01.md` for widget/integration tests.
- **Verify (@Sentinel):** selectors, fixtures, commands, and fail-fast preconditions exist before any favorites test file is added.

### 0.1 Spec Lock

- [ ] (@Architect) Create `.TODO/DECISION_Favorites_DM_2026-03-01.md` and lock the canonical rule for this fix: direct client-initiated DMs remain favorites-gated unless a separate product/security change is approved.
- [ ] (@Sentinel) Create `.TODO/DONE_CRITERIA_Favorites_2026-03-01.md` with measurable non-regression conditions: no parser crash, no split provider ownership, no direct widget -> favorites service call, no false-success remove, no raw backend chat error, verified DM contract, deterministic tests.
- [ ] (@Architect) Confirm touched modules and entry points are frozen to the files listed in Scope.
- **Verify (@Sentinel):** implementation is blocked until DM rule and done criteria are written.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Create `.TODO/THREAT_MODEL_Favorites_2026-03-01.md` covering unauthorized favorites CRUD, duplicate-add abuse, stale provider state leading to invalid actions, and backend error disclosure.
- [ ] (@ThreatModeler) Add explicit negative checks for: cross-user favorites access, direct DM without favorites under the locked rule, rapid repeated add/remove taps, and UI raw exception leakage.
- **Verify (@Sentinel):** every threat has a matching Phase 4 test or manual check.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Create `.TODO/CONTRACT_FavoritesJoin_2026-03-01.md` with the exact joined read contract:
  - required root fields
  - required joined fields
  - `freelancer` relation nullable
  - fallback source for `freelancer_id`
  - placeholder rendering behavior when joined profile fields are absent
- [ ] (@APIContract) Create `.TODO/CONTRACT_FavoritesMutation_2026-03-01.md` and lock a typed mutation result contract for `add` and `remove` instead of `Future<void>` + side-channel `error`.
- [ ] (@Pixel) Create `.TODO/UI_STATE_MATRIX_Favorites_2026-03-01.md` covering Favorites screen, Public Profile toggle, and Request Tile entry point states:
  - loading
  - empty
  - recoverable error
  - duplicate add
  - unauthenticated
  - forbidden/RLS denied
  - remove success
  - remove failure
  - chat-start failure
  - pending-action disable state
- **Verify (@Sentinel):** joined contract, mutation contract, and UI state matrix are all written before app-layer changes begin.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Create `.TODO/MIGRATION_Favorites_DM_Reconcile_2026-03-01.md` with an explicit decision tree:
  - docs-only reconcile if live policy is kept as canonical
  - forward migration only if live DM behavior must change
  - no retroactive fake migration for historical `favorites` SQL provenance
- [ ] (@DataMigration) Add a provenance note to the same file documenting that `public.favorites` exists live but is not represented in checked-in `supabase/migrations/` history.
- **Verify (@Sentinel):** the plan does not rely on unsafe historical backfill SQL.

### 0.5 Delivery Slicing / Rollout

- [ ] (@Architect) Create `.TODO/PR_PLAN_Favorites_2026-03-01.md` with 3 slices:
  - PR1: contracts + test infrastructure + selector wiring
  - PR2: app-layer/provider/UI fixes + unit/widget tests
  - PR3: docs sync + optional DB reconcile + integration/release gate
- [ ] (@Sentinel) Add per-PR done criteria and rollback notes to `.TODO/PR_PLAN_Favorites_2026-03-01.md`.
- **Verify (@Sentinel):** work is reviewable and rollback-safe before implementation starts.

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan `public.favorites` and `public.conversations` immediately before implementation to confirm columns, policies, indexes, triggers, and function bodies still match the planning evidence.
- [ ] (@Supabase_Ops) Export SQL verification output for:
  - `pg_policies` on `favorites` and `conversations`
  - `pg_indexes` on `favorites` and `conversations`
  - function definition of `conversations_before_insert_guard()`
- [ ] (@Supabase_Ops) Record drift explicitly in `.TODO/MIGRATION_Favorites_DM_Reconcile_2026-03-01.md` if live state changed since planning.
- **Verify (@Sentinel):** implementation is blocked if live state no longer matches the locked DM decision.

### 1.1 Schema / Provenance (Additive-first)

- [ ] (@Supabase_Ops) Confirm no schema change is required for parser/provider/UI fixes if the DM rule remains favorites-gated.
- [ ] (@DataMigration) If no live behavior change is needed, document provenance instead of inventing a retrospective `favorites` migration.
- [ ] (@Supabase_Ops) If a DB reconcile is required, limit it to the minimal object(s) needed for the locked DM rule; do not bundle duplicate-index/policy cleanup in this feature fix.
- **Verify (@Sentinel):** no unnecessary SQL change is introduced.

### 1.2 RLS

- [ ] (@Supabase_Ops) Preserve owner-only favorites CRUD and confirm app changes keep treating RLS as the source of truth.
- [ ] (@Supabase_Ops) Create `.TODO/RLS_CHECK_Favorites_2026-03-01.md` with explicit positive and negative checks for:
  - own favorites select/insert/delete
  - cross-user select/delete denial
  - direct DM insert with favorites present
  - direct DM insert without favorites under the locked rule
- [ ] (@ThreatModeler) Mark release-blocking security invariant: cross-user favorites access must fail and DM behavior must match the locked rule in live DB.
- **Verify (@Sentinel):** SQL evidence and staging behavior both prove the rule.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Reconcile `conversations_before_insert_guard()` comments/body with the locked direct-DM rule so trigger/function text no longer contradicts policy behavior.
- [ ] (@APIContract) Update the DM contract doc to reference the actual enforcing layer(s): policy and any relevant trigger/function behavior.
- **Verify (@Sentinel):** code comments, docs, and live DB agree on one DM rule.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) If SQL changes are required, execute them in staging first and store before/after verification queries in `.TODO/MIGRATION_Favorites_DM_Reconcile_2026-03-01.md`.
- **Verify (@Sentinel):** no unrelated chat flow regresses after the reconcile.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Split joined profile parsing into a dedicated model file for explicit nullability and cleaner imports.
  - Create `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/models/favorite_with_profile_model.dart`
  - Keep base row model in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/models/favorite_model.dart`
- [ ] (@Architect) Update `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/data/favorites_service.dart` joined select to include root `freelancer_id` alongside the joined profile object, per the locked contract.
- [ ] (@Architect) Update joined parser logic so `freelancer == null` does not crash and placeholder rendering still has a stable `freelancerId`.
  - Current risk reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/models/favorite_model.dart:65-73`
- [ ] (@Architect) Prefer extending `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/error_mapper.dart` only if favorites-specific wording is truly required; do not create a duplicate feature-local mapper by default.
- **Verify (@Sentinel):** type/nullability matches the contract doc and null-join rows load safely.

### 2.2 Services/Repositories

- [ ] (@Architect) Choose and document one canonical read path for favorites:
  - preferred: single joined query + derived `FavoriteModel` membership/cache data in VM
  - fallback only if justified: separate simple + joined reads with explicit reason
- [ ] (@Architect) Define mutation idempotency and error taxonomy for add/remove using `.TODO/CONTRACT_FavoritesMutation_2026-03-01.md`.
- [ ] (@Architect) Remove `FavoritesService` imports/calls from `RequestTile` and route favorites actions through ViewModel or parent callback only.
  - Current violation: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:4-5`, `:112-119`
- [ ] (@Architect) Update `requests_list_screen` to pass the chosen callback/VM contract explicitly.
  - Current callsite: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/requests_list_screen.dart:273-282`
- **Verify (@Sentinel):** no widget performs direct favorites service work and the service contract is single-sourced.

### 2.3 ViewModels

- [ ] (@Architect) Remove screen-owned provider duplication by making `FavoritesScreen` consume the app-level `FavoritesViewModel` only.
  - Current split: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart:172-175`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart:19-40`
- [ ] (@Architect) Add an explicit `ensureLoaded()`-style guard so public profile and favorites screen can rely on a known load contract without duplicated fetch churn.
- [ ] (@Architect) Introduce a typed mutation result in a new file:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/models/favorites_mutation_result.dart`
- [ ] (@Architect) Update `add` and `remove` to return that typed result and track pending-action state (`Set<String>` or equivalent) for duplicate-tap prevention.
- [ ] (@Architect) Ensure remove failures do not mutate in-memory state or emit success-like signals.
- [ ] (@Architect) Reduce unnecessary `notifyListeners()` calls once correctness is restored.
- **Verify (@Sentinel):** favorites state is single-sourced, transitions are deterministic, and duplicate taps are controlled.

### 2.4 Observability (If needed)

- [ ] (@Observability) Only if additional telemetry is required, create `.TODO/OBSERVABILITY_Favorites_2026-03-01.md` covering correlation fields and privacy redaction.
- [ ] (@Architect) Keep diagnostics in service/viewmodel layers; UI should never interpolate raw backend exceptions.
- **Verify (@Sentinel):** logs are useful and UI remains sanitized.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Refactor `FavoritesScreen` into a shared-provider consumer and extract a list body widget if needed for readability/testability.
  - Potential new file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/widgets/favorites_list_body.dart`
- [ ] (@Pixel) Apply the selector/key map from `TEST_INFRA_Favorites` to favorites-critical widgets.
- [ ] (@Pixel) Implement UI behavior exactly as defined in `.TODO/UI_STATE_MATRIX_Favorites_2026-03-01.md` for:
  - Favorites screen load/empty/error/list/remove/chat states
  - Public profile toggle pending/success/error states
  - Request tile add-to-favorites pending/success/error states
- [ ] (@Pixel) Use `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/format_date.dart:38-45` in `FavoriteCard` instead of raw `DateTime` interpolation.
- [ ] (@Pixel) Replace raw `Failed to start chat: $e` UI text with safe English copy.
  - Current issue: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart:116-120`
- **Verify (@Sentinel):** visible behavior matches the state matrix and widgets use ViewModels only.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Add low-risk polish only after correctness: disabled action states, clearer placeholder text for unavailable profiles, and consistent snackbar copy.
- **Verify (@Sentinel):** polish does not change the locked contracts or reintroduce flake risk.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Validate implementation against all Phase 0 artifacts:
  - `DECISION_Favorites_DM`
  - `CONTRACT_FavoritesJoin`
  - `CONTRACT_FavoritesMutation`
  - `UI_STATE_MATRIX_Favorites`
  - `RLS_CHECK_Favorites`
- [ ] (@Sentinel) Run DB verification queries for `public.favorites` and `public.conversations` and attach results to the execution log.
- [ ] (@DataMigration) If SQL reconcile shipped, include staging before/after evidence in the release log.
- **Verify (@Sentinel):** no unresolved contract drift remains.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute the threat-model negative checks for:
  - cross-user favorites access denial
  - duplicate add behavior
  - unauthenticated favorites behavior
  - direct DM without favorites under the locked rule
  - raw backend error leakage grep/test
- [ ] (@Sentinel) Run grep regressions:
  - `rg -n "FavoritesService\(" lib/features/tasks/view --glob '*.dart'`
  - `rg -n "Failed to start chat: \$e" lib/features/favorites --glob '*.dart'`
- **Verify (@Sentinel):** unauthorized access is impossible and raw backend messages are absent from UI.

### 4.3 Functional QA

- [ ] (@Sentinel) Add unit tests:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/features/favorites/models/favorite_with_profile_model_test.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/features/favorites/viewmodels/favorites_view_model_test.dart`
- [ ] (@Sentinel) Add widget tests:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/features/favorites/view/favorites_screen_test.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/features/favorites/view/widgets/favorite_card_test.dart`
- [ ] (@Sentinel) Add integration coverage:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/favorites_cross_feature_flow_test.dart`
- [ ] (@Sentinel) Use the Phase 0 fixture manifest and selector map to verify cross-screen consistency and request-tile behavior.
- **Verify (@Sentinel):** no crashes, no false success, and no cross-screen state divergence remain.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Confirm service/viewmodel logs remain actionable for auth, duplicate, and parser failures.
- [ ] (@Sentinel) Confirm privacy redaction still applies and UI remains free of raw DB payloads.
- **Verify (@Sentinel):** telemetry is actionable without leaks.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update the favorites deep-dive, developer guide, and Supabase setup docs to match the locked DM rule and the final implementation.
  - References:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md`
- [ ] (@SlineDocs) Update historical review notes if the request-tile direct-service fallback is fully removed.
  - Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/CODE_REVIEW.md:258-268`
- [ ] (@SlineDocs) Add a provenance note if `public.favorites` remains live without historical repo migration coverage after this fix.
- **Verify (@Sentinel):** docs match code, live DB, and the locked contract with no contradictory DM statements.

---

## 7) Acceptance Criteria (MANDATORY)

- Favorites load does not crash when a joined profile row is missing.
- `FavoritesScreen` no longer creates its own long-lived ViewModel/provider instance.
- `RequestTile` no longer imports or calls `FavoritesService` directly.
- `add` and `remove` expose a typed result contract, and remove success is shown only on true success.
- Public Profile, Favorites screen, and Request Tile all follow the same favorites state source and UI state matrix.
- Direct-DM rule is explicitly locked and matches live DB verification at release time.
- Stable selectors/keys exist for favorites-critical widget/integration tests.
- Favorites-specific unit, widget, and integration tests exist and pass.
- `flutter analyze` passes for favorites and all direct touchpoints.
- Docs match final code and live DB behavior.

## 8) Rollback Plan

- DB rollback / forward-fix:
  - If no SQL reconcile was shipped, rollback is app/docs only.
  - If a DM-rule reconcile migration shipped, revert via a forward-fix migration after re-running the saved verification queries; do not perform ad hoc manual SQL edits.
  - Do not roll back by dropping overlapping live conversation policies/indexes during incident response.
- App rollback:
  - Keep parser null-safety and sanitized-error fixes unless they directly cause regressions.
  - If shared-provider unification regresses behavior, revert provider ownership changes separately from parser/test-selector changes.
  - If request-tile callback wiring regresses, restore the last known-good parent callback/VM path, not the direct service fallback.
- Emergency disable strategy:
  - If DM handoff becomes unstable after contract reconcile, disable the favorites “Start Chat” CTA temporarily while keeping favorites CRUD available.
  - If request-tile add-to-favorites becomes unstable, disable the CTA in offers list temporarily while preserving Favorites screen and Public Profile entry points.

## 9) References (From Scan)

- Docs:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/MVP_ROADMAP.md`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/CODE_REVIEW.md`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/STRUCTURE.md`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md`
- Code:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/supabase_config.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/logger_service.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/error_mapper.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/format_date.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/data/favorites_service.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/models/favorite_model.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/viewmodels/favorites_view_model.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/widgets/favorite_card.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/routes/favorites_routes.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/view/public_profile_screen.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/widgets/request_tile.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/requests_list_screen.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/viewmodels/chat_view_model.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/data/chat_repository.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/services/message_service.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/helpers.dart`
- Live Supabase scan evidence:
  - `public.favorites` table exists with RLS enabled.
  - `public.favorites` policies: `favorites_select_own`, `favorites_insert_self`, `favorites_delete_self`.
  - `public.favorites` indexes: `idx_favorites_client`, `idx_favorites_freelancer`, `uq_favorites_client_freelancer`.
  - `public.conversations` policy `conversations_insert_client_only` currently requires favorites for non-task DM inserts.
  - `public.conversations_before_insert_guard()` currently contains text indicating favorites check removal, which conflicts with the live insert policy.
  - Storage buckets present: `chat-attachments`, `portfolio`, `avatars`, `task-images`.
