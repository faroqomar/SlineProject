# Phase 0 Audit Workflow (Plan-Only)

## Scope Guard (Phase 0)

- This document defines **how** the audits will be run.
- It does **not** execute the audits.
- It does **not** implement fixes.
- No code changes should be made unless you explicitly say: **`APPLY FIXES`**.

## Recommended Audit Sequence (Risk-Based)

The order below prioritizes identity, money/state transitions, realtime messaging, and cross-feature data surfaces first.

## 1) Feature Audit Order

1. `auth`
   - Reason: identity/session foundation for all other features.
2. `tasks`
   - Reason: core marketplace flow + offers/requests + image uploads + cross-feature dependencies.
3. `booking`
   - Reason: booking lifecycle + payment event RPC + status transitions.
4. `work`
   - Reason: delivery/revision/approval workflows + multiple RPCs + cross-entity state updates.
5. `chat`
   - Reason: realtime, attachments, signed URLs, participant authorization.
6. `wallet`
   - Reason: financial data visibility/integrity and potential ledger drift vs docs.
7. `profile`
   - Reason: PII, avatar uploads, role/account settings, public/private profile boundaries.
8. `dashboard`
   - Reason: aggregated views, role-based action surfaces, cross-feature state summaries.
9. `orders`
   - Reason: orchestration layer over tasks/offers and owner actions.
10. `notifications`
    - Reason: realtime subscriptions and privacy-sensitive payloads.
11. `portfolio`
    - Reason: file uploads/media/public URL behavior and ownership checks.
12. `search`
    - Reason: RPC contracts and result visibility/performance.
13. `favorites`
    - Reason: lighter data model, but tied to DM enablement/business rules.
14. `saved`
    - Reason: saved-task ownership and auth-state synchronization.
15. `home`
    - Reason: feed orchestration/pagination performance and filter state coordination.
16. `categories`
    - Reason: lower complexity, shared reference data.
17. `management`
    - Reason: narrower scope panel/work-log feature.
18. `services`
    - Reason: small support module with table CRUD.
19. `proposals`
    - Reason: currently UI-centric with no direct backend surface observed.

## 2) Cross-Cutting Audit Tracks (Run Alongside Feature Audits)

Run these tracks once early, then refresh selectively as needed:

1. Flutter repo health (`analyze`, formatting, dependency inventory)
2. Platform/build config audit (Android/iOS/Web; flavors/env handling)
3. Asset/localization audit
4. Supabase metadata/policy inventory (tables, RLS, policies, RPCs, triggers, storage)
5. Repo-wide security scans (secrets, service-role usage, logging/PII patterns)

## How to Run Checks (Recommended Commands / Evidence)

## 3) Baseline Repo Commands (Static + Flutter)

Run once before the first feature audit:

```bash
flutter pub get
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter test
flutter pub outdated
flutter pub deps --style=compact
```

Evidence to capture:

- command used
- date/time run
- exit code
- relevant output excerpt (especially feature-related analyzer diagnostics)

## 4) Feature-Scoped Static Checks (Template)

Use the feature name exactly from `01_FEATURES_INDEX.md`.

```bash
# Replace <FEATURE> with exact feature dir name, e.g. tasks
rg --files lib/features/<FEATURE> | sort
flutter analyze lib/features/<FEATURE>
dart format --output=none --set-exit-if-changed lib/features/<FEATURE>
rg -n "Supabase\\.instance|SupabaseClient|http\\.|dio\\." lib/features/<FEATURE>/view --glob '*.dart'
rg -n "^import .*features/.*/view/" lib/features/<FEATURE> --glob '*.dart'
rg -n "ChangeNotifierProvider|Provider\\(|Consumer<|context\\.watch<|context\\.read<" lib/features/<FEATURE> lib/main.dart --glob '*.dart'
rg -n "try\\s*\\{|catch\\s*\\(|AppLogger\\.|throw|rethrow" lib/features/<FEATURE> --glob '*.dart'
rg -n "stream\\(|channel\\(|listen\\(" lib/features/<FEATURE> --glob '*.dart'
rg -n "storage\\.from\\(|upload|createSignedUrl|getPublicUrl" lib/features/<FEATURE> --glob '*.dart'
rg -n "(role|owner|provider|client|freelancer|admin)" lib/features/<FEATURE> --glob '*.dart'
```

Optional helper commands:

```bash
wc -l $(rg --files lib/features/<FEATURE> | tr '\n' ' ')
rg -n "TODO|FIXME|HACK" lib/features/<FEATURE> --glob '*.dart'
```

## 5) Repo-Wide Security/Privacy Pattern Scans (Plan for Audit Execution)

```bash
rg -n "(service_role|SUPABASE_SERVICE_ROLE|postgres://|jdbc:|BEGIN PRIVATE KEY)" .
rg -n "(anonKey|supabaseAnonKey|supabaseUrl)" lib --glob '*.dart'
rg -n "AppLogger\\.|print\\(" lib --glob '*.dart'
rg -n "Supabase\\.instance\\.client" lib/features/*/view lib/core/widgets --glob '*.dart'
rg -n "storage\\.from\\(" lib --glob '*.dart'
```

Evidence goals:

- classify each hit as expected/public/config-sensitive/needs deep review
- record file references and whether the hit is in UI/ViewModel/Service/Repo/Core

## 6) Platform/Build Audit Commands (Android / iOS / Web)

### Android

```bash
rg -n "productFlavors|flavorDimensions|applicationId|signingConfig|minSdk|targetSdk" android/app/build.gradle.kts
flutter build apk --debug
```

Checks to verify:

- flavor presence/absence is intentional
- app id and signing config are production-ready (in later audit)
- build succeeds on current repo state

### iOS

```bash
rg -n "PRODUCT_BUNDLE_IDENTIFIER|CODE_SIGN|SWIFT_VERSION" ios/Runner.xcodeproj/project.pbxproj
rg -n "#include|DART_DEFINES" ios/Flutter/*.xcconfig
flutter build ios --simulator --no-codesign
```

Checks to verify:

- scheme/config separation (if any)
- bundle id/signing settings
- env propagation via xcconfig / Dart defines

### Web

```bash
flutter build web
rg -n "assets/" web lib pubspec.yaml
```

Checks to verify:

- build output success
- asset references resolve
- any web-specific config/runtime assumptions

## 7) Assets / Localization / Dependency Health Checks

### Assets

```bash
find assets -type f | sort
rg -n "assets:" -n pubspec.yaml
```

Verification goals:

- every referenced asset exists on disk
- casing/path matches declarations (especially for case-sensitive targets)
- orphaned large assets identified for review

### Localization

```bash
rg --files . | rg "l10n|\\.arb$"
rg -n "AppLocalizations|flutter_gen/gen_l10n|supportedLocales|localizationsDelegates" lib pubspec.yaml
```

Verification goals:

- determine whether localization is implemented, planned, or partial
- identify localization coverage expectations by feature

### Dependency Health

```bash
flutter pub outdated
flutter pub deps --style=compact
```

Verification goals:

- identify outdated direct dependencies
- identify deprecated/transitive risk hotspots (to review before fixes)

## 8) Supabase Audit Workflow (DB/RLS/RPC/Storage) — Plan

Because no local migrations folder was found in Phase 0, use a two-source approach during audit execution:

1. **Code-driven inventory** (what the app calls)
2. **DB metadata/docs verification** (what actually exists and is protected)

### 8.1 Code-Driven Inventory (Local)

```bash
rg -n "\\.from\\('([^']+)'|\\.rpc\\('([^']+)'|storage\\.from\\('([^']+)'" lib/features lib/core --glob '*.dart'
```

Capture:

- table/view names
- RPC names
- storage buckets
- feature/file call sites

### 8.2 Docs-Driven Inventory (Local, Best-Effort)

```bash
rg -n "CREATE POLICY|ALTER TABLE .* ENABLE ROW LEVEL SECURITY|CREATE OR REPLACE FUNCTION|CREATE OR REPLACE VIEW" Sline_everything --glob '*.md' --glob '*.sql'
```

Capture:

- candidate policies/functions/views documented in repo docs
- mark each as `docs-only-unverified` until confirmed in live DB metadata

### 8.3 Live DB Metadata Verification (Audit Phase, Requires Access)

Run in Supabase SQL editor or `psql` against the project DB (read-only metadata queries preferred):

```sql
-- Tables / views used by app
select table_schema, table_name
from information_schema.tables
where table_schema in ('public', 'storage')
order by table_schema, table_name;

-- RLS enabled status (public tables)
select n.nspname as schema_name,
       c.relname as table_name,
       c.relrowsecurity as rls_enabled,
       c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where c.relkind = 'r' and n.nspname = 'public'
order by c.relname;

-- Policies
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname in ('public', 'storage')
order by schemaname, tablename, policyname;

-- RPC functions (public)
select n.nspname as schema_name,
       p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
order by p.proname;

-- Triggers (public)
select event_object_table as table_name,
       trigger_name,
       action_timing,
       event_manipulation
from information_schema.triggers
where trigger_schema = 'public'
order by event_object_table, trigger_name;

-- Storage buckets
select id, name, public
from storage.buckets
order by name;
```

Verification goals:

- every app-used table/view/RPC/bucket exists
- RLS is enabled where expected
- policies exist and align with feature access patterns
- storage buckets/public/private status align with app URL usage (`getPublicUrl` vs signed URLs)

### 8.4 RLS/Policy Test Execution (Later Audit Phase)

For high-risk features (`auth`, `tasks`, `booking`, `chat`, `wallet`, `work`, `profile`):

- test unauthenticated access
- test cross-user access
- test privileged action attempts
- test RPC authorization behavior
- test storage bucket policy behavior (upload/read/delete)

Evidence to capture for each test:

- actor context (anon / user A / user B)
- request/query performed
- expected result
- actual result
- policy/RPC implicated

## 9) Feature Audit Execution Loop (Repeat Per Feature)

1. Confirm exact feature name from `01_FEATURES_INDEX.md`.
2. Re-read that feature section in `01_FEATURES_INDEX.md`.
3. Run feature-scoped static checks (Section 4).
4. Trace primary flows from entry UI -> ViewModel -> Service/Repo -> Supabase.
5. Run security/privacy checks for that feature (Section 5 + feature-specific `C` checks).
6. Run performance/data-integrity review for that feature (`D` and `E` checks).
7. Produce findings report (audit-only, no changes).
8. Stop and wait for your direction unless you request continuing to the next feature or say `APPLY FIXES`.

## 10) Recommended Audit Output Format (Future Phases)

For each audited feature, write a new file in `.TODO/`:

- `.TODO/10_AUDIT_<FEATURE>.md` (findings + evidence + open questions)

Recommended sections:

- Scope audited
- Commands run
- Evidence summary
- Findings (severity-ordered)
- Open questions / assumptions
- Fix strategy blueprint (no code changes unless `APPLY FIXES`)

## Definition of "Done" (Phase 0 and Later Audit Acceptance Criteria)

## 11) Phase 0 Done Criteria (This Turn)

- [x] `00_REPO_MAP.md` exists in `.TODO/`
- [x] `01_FEATURES_INDEX.md` exists in `.TODO/`
- [x] `02_AUDIT_WORKFLOW.md` exists in `.TODO/`
- [x] Feature inventory is based on folder structure + routing + providers/viewmodels/repositories usage
- [x] Per-feature plans include `A`–`F` categories (plan-only)
- [x] No code fixes implemented

## 12) Feature Audit Done Criteria (Future Phase)

A feature audit is considered done only when all are true:

- [ ] The feature section checklist (`A`–`F`) from `01_FEATURES_INDEX.md` has been executed with evidence.
- [ ] Findings (if any) are documented with file references and impact.
- [ ] Security/RLS assumptions for the feature are mapped to actual DB metadata (or explicitly marked blocked by missing access).
- [ ] Primary user flows for the feature were manually traced and verified.
- [ ] Test coverage expectations were documented (existing tests and missing high-value tests).
- [ ] No fixes were applied unless you explicitly instructed `APPLY FIXES`.

## 13) Full Repo Audit Done Criteria (Future Phase)

The full repo audit is complete only when:

- [ ] All features in `01_FEATURES_INDEX.md` have individual audit reports.
- [ ] Cross-cutting tracks (platform/build, assets/localization, dependency health, repo-wide security scans, Supabase metadata) are completed.
- [ ] A final consolidated audit summary exists (risk-ranked, with remediation phases).
- [ ] Any blocked items (e.g., missing DB access) are explicitly listed with exact missing inputs.

## Stop Rule

- After Phase 0, stop and ask which feature to audit first.
- Do not implement fixes unless explicitly instructed with: **`APPLY FIXES`**.

