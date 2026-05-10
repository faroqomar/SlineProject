# Plan Critic: Notification Routing (13_notification-routing)

**Source plan:** `.TODO/PLAN_NotificationRouting_2026-03-08.md`  
**Critic workflow:** `.agents/workflows/plan_critic.md`  
**Date:** 2026-03-08

---

## Mandatory Critique Checklist (Summary)

- **3.1 Scope & Requirements:** Goal is measurable (push when app killed; RLS; sender skip). Non-goals stated (APNs native; new notification types). Edge cases (sender==receiver, retry, >50 unread) now explicit; abuse (token theft, spoofed push) in threat checklist.
- **3.2 Dependencies & Ordering:** Original plan had contract/backend loosely before UI; corrected plan enforces Phase 0 (contract + test infra) → Phase 1 (DB + trigger + Edge) → Phase 2 (MVVM) → Phase 3 (UI) → Phase 4 (QA). No UI before stable contract.
- **3.3 Data Model & Contracts:** user_devices shape and push payload were implied; now in CONTRACT file. DTO boundaries (client vs service_role) and idempotency behaviour codified in contract.
- **3.4 Security:** RLS on notifications (no INSERT) and user_devices (own only) explicit; push path service_role only; threat checklist and “no token in logs” added; audit of push path not callable by client in Phase 4.
- **3.5 Performance:** Trigger must be async (no sync HTTP); latency check added. Stream limit 50 + foreground sync addresses truncation. No N+1 in notification list (single stream).
- **3.6 Error Handling & Observability:** Error mapping for token registration; Edge Function logs success/failure; correlation (user_id/notification_id); no sensitive data in logs.
- **3.7 UX & State Machine:** Loading/empty/error states required; token failure (toast or silent retry); foreground sync prevents wrong badge; no double-submit on token (upsert by user_id, platform).
- **3.8 Testing & QA:** RLS test (INSERT denied) added; sender-exclusion and idempotency assigned to integration; push E2E assigned to e2e; timeout 30s and 1 retry; artifact tag; test infra step in Phase 0. No fixture manifest in original plan — added as “fixture: test user + notification row if needed.”
- **3.9 Release & Migration:** Feature flag optional; backward compatibility (additive only); rollback steps numbered and “never” list added.
- **3.10 Developer Workflow:** Branch strategy assumed (feature branch); review implied; Definition of Done = gate checks per phase; documentation update in Phase 4.

**Failures found:** Missing contract before implementation; token only on login; no RLS test; trigger could block; optional foreground sync undefined; test type mix and infra missing; Edge secret handling and rollback vague; some ordering allowed UI before backend lock. All addressed in Gaps and Corrected Plan.

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (inferred)

- Flutter app already has or will add `firebase_core` and `firebase_messaging` (or equivalent) for FCM; no decision on APNs native vs FCM-for-iOS.
- Supabase project can enable `pg_net` or has an alternative (e.g. Edge Function invoked by webhook/cron polling) for async push; trigger must not block INSERT.
- “Sync all unread on foreground” is optional for first release; badge can show stream-derived count until then.
- Idempotency for `private_create_notification` is deferred unless a concrete race (e.g. double `pay_awarded_offer` call) is reproduced; only documentation of current behaviour is in scope.
- Single device token per (user_id, platform) is sufficient; multi-device per platform is out of scope unless product requires it.
- Branch strategy: feature branch; PR review before merge; no forced squash/merge style specified.
- Test runs: `flutter test` for unit/widget; integration/e2e require running app + Supabase (no mock Supabase for e2e in plan).

### Decision Needed (Blocking)

| # | What is missing | Options | Recommended | Why | Plan impact |
|---|-----------------|---------|-------------|-----|--------------|
| 1 | How to invoke push from DB (trigger → Edge Function) | (A) `pg_net.http_post` from trigger (B) Cron + poll new notifications (C) Realtime webhook / Supabase built-in | **A** if `pg_net` is available; else **B** (cron polling) | A is lowest latency and keeps logic in one place; B avoids extension dependency. C depends on Supabase offering. | Phase 1: either add `pg_net` migration + trigger function, or add cron job + Edge Function that selects un-pushed notifications. |
| 2 | Unique key for `user_devices`: one token per user or per (user, platform)? | (A) One row per user (single token) (B) One row per (user_id, platform) (C) One row per (user_id, token) | **B** | Same user on iOS and Android gets push on both; token refresh overwrites row per platform. | DDL: unique constraint on (user_id, platform); upsert in Flutter by (user_id, platform). |
| 3 | Where to store Edge Function URL for trigger (pg_net) | (A) Supabase vault / secret (B) Hardcoded in migration (project URL) (C) Config table | **A** (vault) or **B** if URL is not secret | Edge Function URL is project-specific; if same project, B is acceptable. | Trigger function reads URL from vault or constant; document in SUPABASE_SETUP. |

---

## B) Gate Status (Pass/Fail)

| Gate | Status | Reason | What to add/fix to pass |
|------|--------|--------|-------------------------|
| **0) Test Infrastructure** | ❌ FAIL | No test harness/bootstrap for notification RLS or push path; no fixture manifest for integration tests; no run command or artifact path for e2e. | Add: test directory contract (unit vs integration vs e2e); RLS test helper (run as service_role vs authenticated); fixture: test user + notification row; doc: how to run notification tests and capture failures. |
| **1) Data/Contracts** | ❌ FAIL | `user_devices` shape and push payload contract are described but not in a single contract file; idempotency behaviour of `private_upsert_notification` vs `private_create_notification` not codified. | Add: `.TODO/.../13_notification-routing/CONTRACT_notification_push.md` with `user_devices` columns, push payload (title, body, data), and “collapse-on-unread” vs “no idempotency key” for each API. |
| **2) Security** | ⚠️ CONDITIONAL | RLS on `notifications` (no INSERT) is correct; `user_devices` RLS not yet written; push path must be service_role only; no explicit “no token in logs” check. | Add: RLS matrix for `user_devices` (SELECT/INSERT/UPDATE/DELETE own only); ThreatModeler checklist: token theft, spoofed push; logging redaction requirement in observability step. |
| **3) Backend/API** | ❌ FAIL | Trigger-on-notifications and Edge Function are not ordered: trigger body (payload shape, error handling) and Edge Function signature (expects what from pg_net?) undefined; no retry/backoff for push failures. | Add: Step “Define trigger payload and Edge Function contract” before implementing trigger; document retry policy (e.g. no retry in trigger; Edge Function may retry FCM once). |
| **4) UI/Integration** | ⚠️ CONDITIONAL | Flutter token registration is “after login” but app lifecycle (resume, token refresh) not specified; no explicit loading/error state for “token registration failed”. | Add: When to register: on login + on app lifecycle resume (token refresh); UX: silent retry or toast on token failure; no UI before backend contract is locked. |
| **5) Release/QA** | ❌ FAIL | Manual E2E only; no smoke test list; no flake/retry policy; no “one behaviour per test” rule; regression points not enumerated. | Add: Smoke test list (RLS insert denied, sender skip, push received when app killed); regression list (realtime stream, mark read, badge); flake: 1 retry max, timeout 30s for e2e; artifact: tag build + test run id. |

---

## C) Critical Gaps (Must-Fix)

| Gap | Why it will break | Fix (exact step(s)) | Owner | Acceptance check |
|-----|-------------------|---------------------|-------|-------------------|
| Trigger payload and Edge Function contract not defined before implementation | Trigger and Edge Function will disagree on JSON shape; debugging push failures will be costly. | Insert step in Phase 1: “Define CONTRACT: trigger passes { notification_id, user_id, title, message, type, related_entity_id, related_entity_type } to Edge Function; Edge Function returns 2xx or logs error.” Write this in CONTRACT file. | Backend / @APIContract | CONTRACT file exists; trigger and Edge Function code both reference it. |
| Token registration only “on login” | Token refresh (e.g. FCM) or app resume after long background will leave stale/missing token; user stops receiving push. | Add step: “Register or refresh token on (1) login/session restore, (2) app lifecycle resume (AppLifecycleState.resumed), (3) FirebaseMessaging.onTokenRefresh.” | Frontend / @Architect | Code path: at least login + one lifecycle hook; token updated in `user_devices` when refreshed. |
| No RLS test for `notifications` INSERT denial | Regression could re-enable client INSERT; security would be violated without detection. | Add step: “RLS test: as authenticated user, attempt INSERT into notifications; expect PostgrestException with 42501 or RLS violation.” Use test helper that runs with anon key + auth. | QA / @Sentinel | Test exists; fails if INSERT policy is added for authenticated. |
| Push trigger blocks INSERT transaction | If trigger calls synchronous HTTP, notification INSERT will be slow and timeouts will cause failed inserts. | Enforce: trigger must only enqueue work (pg_net.http_post or INSERT into job table). Add verification step: “Measure notification INSERT latency with trigger enabled; must not increase by >50ms p99.” | Backend / @Supabase_Ops | Trigger implementation uses only async enqueue; latency check documented or automated. |
| No explicit “foreground sync” decision | Plan says “optional” but doesn’t decide; implementers may skip and badge will be wrong for users with >50 unread. | Decision: Either (1) implement “fetch count unread on foreground, then stream(50)” in this plan, or (2) document as known limitation and add to backlog. Recommend (1) for correctness. | Product / @Architect | Decision recorded; if (1), step added in Phase 2 and verified in Phase 4. |
| Test type mix not assigned to behaviours | RLS, sender exclusion, idempotency, push E2E need different test types; mixing them causes flaky or slow tests. | Assign: RLS + sender exclusion = integration (Supabase + test DB or local); idempotency = integration or unit (if RPC is mockable); push E2E = e2e (real device/simulator + FCM). Document in Test Plan section. | QA / @Sentinel | Each acceptance criterion has a test type and location (file or dir). |
| Secrets for FCM in Edge Function not verified | Pushing without verifying secrets leads to silent failure in production. | Add step: “Edge Function: read FCM key from secrets; at cold start, validate key format or send a no-op; log clearly if secret missing or invalid (no key value in log).” | Backend / @Supabase_Ops | Code review: no key in logs; startup check exists. |
| Rollback of push trigger not step-by-step | “Drop trigger” is vague; if dependencies are wrong, rollback can fail. | Add: “Rollback order: (1) Disable trigger (comment out or drop); (2) Deploy Edge Function that no-ops; (3) Optional: drop user_devices if desired. Never drop notifications or alter RLS on notifications.” | @DataMigration / @Sentinel | Rollback section has numbered steps and “never” list. |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to enforce | How to verify |
|-----------|----------------|---------------|
| Clients never INSERT into `notifications` | RLS: no INSERT policy for anon/authenticated; REVOKE on `private_upsert_notification`/`private_create_notification` from anon/authenticated. | Test: authenticated INSERT → 42501. Policy list: no policy name containing insert for notifications. |
| Users see only their own notifications and devices | RLS: notifications SELECT/UPDATE by user_id = auth.uid(); user_devices SELECT/INSERT/UPDATE/DELETE by user_id = auth.uid(). | RLS matrix: negative test (other user’s notification/device); positive test (own rows). |
| Sender never receives notification for their own message | Trigger `messages_after_insert_notify_receiver`: IF NEW.receiver_id = NEW.sender_id THEN RETURN NEW. | Integration test: insert message with sender_id = receiver_id; assert 0 new rows in notifications for that conversation. |
| Push path is server-only (no client calls FCM) | Edge Function uses service_role or server key; trigger invokes Edge Function via pg_net; client only writes to user_devices. | No FCM SDK or server key in Flutter client; Edge Function has no public anon-invokable path that sends push. |
| One source of truth for notification list in UI | ViewModel exposes single stream + optional initial unread fetch; no duplicate subscriptions. | Single stream in NotificationViewModel; no second .from('notifications') in view layer. |
| Trigger on notifications does not block INSERT | Trigger body only enqueues async work (pg_net or queue table); no await of HTTP in trigger. | Code review; optional: measure INSERT latency with/without trigger. |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|--------------|------------|----------|
| FCM key leak or misconfiguration | Edge Function secrets | Med | High | Security-breach | Push stops; error log “invalid key” | Secrets in vault only; no log of key; startup validation | Disable push trigger; fix secret; re-enable |
| pg_net not available or rate-limited | Supabase project | Low | High | Feature | Trigger fails; net.http_post error in logs | Check extension availability before Phase 1; fallback to cron polling | Implement cron-based push job |
| Token registration fails silently | Flutter auth/lifecycle | Med | Med | Feature (user misses push) | No rows for user in user_devices after login | Log failure; optional toast; retry on resume | User still gets realtime when app open |
| Duplicate notifications on RPC retry | pay_awarded_offer etc. | Low | Med | Feature (noise) | Duplicate rows for same event | Document; optional idempotency key in future migration | Accept until idempotency added |
| Trigger fires but Edge Function timeout | Edge Function cold start / FCM latency | Med | Low | Local (that notification) | Edge Function log timeout; FCM non-2xx | Timeout ≥10s; no retry in trigger to avoid double send | User gets notification on next app open (realtime/fetch) |
| Badge shows wrong count (e.g. >50 unread) | Flutter stream limit 50 | Med | Low | Local | User report “missing notifications” | Implement “sync unread count on foreground” | Document limitation; backlog fix |
| RLS regression allows notification INSERT | Future migration | Low | High | Security-breach | RLS test fails | RLS test in CI; review all policy changes | Revert policy; redeploy |
| Push trigger increases INSERT latency | Trigger body | Low | Med | App-wide | Slow notification UI / timeouts | Trigger only enqueues; no sync HTTP | Simplify trigger; use queue table + worker |

---

## F) Pre-Mortem (How this fails in real life)

- **This fails when** the trigger calls the Edge Function synchronously and FCM is slow, so notification INSERTs time out and message senders see errors.
- **This fails when** the Edge Function is invoked with a payload shape the function doesn’t expect, so push is never sent and there are no logs because the function doesn’t validate input.
- **This fails when** token is only registered on login, user backgrounds the app for a day, FCM refreshes the token, and the app never updates `user_devices`, so push stops working.
- **This fails when** someone adds an INSERT policy on `notifications` “for testing” and it gets merged, and no RLS test exists to catch it.
- **This fails when** rollback is “drop trigger” but the trigger has a typo or dependency and the drop fails, leaving push half-disabled and confusing.
- **This fails when** E2E “push when app killed” is run without a real FCM token and passes falsely because the test only checks “no crash.”
- **This fails when** the plan doesn’t decide “sync unread on foreground” and the team ships without it; users with 50+ unread see wrong badge and complain.
- **This fails when** FCM server key is committed in a migration or in client code and is leaked.

---

## G) Plan Fixes (Concrete Additions / Expansions)

| Goal | Why | How | Output artifact | Stop condition |
|------|-----|-----|-----------------|----------------|
| Lock push contract before code | Avoid trigger/Edge mismatch | Write CONTRACT file: trigger payload JSON keys; Edge Function input/output; error logging. | `.TODO/.../13_notification-routing/CONTRACT_notification_push.md` | Contract reviewed; trigger and Edge Function implementations reference it. |
| Test infrastructure for notifications | RLS and integration tests need repeatable setup | Define: test dirs (unit/widget vs integration vs e2e); how to get auth session for integration; fixture: one test user, one notification row; run commands. | Test plan section in doc; optional `test/fixtures/notification_fixture.md` | `flutter test` and integration run command documented; at least one RLS test runs. |
| Token registration on lifecycle | Avoid stale tokens | Implement: register on login + on AppLifecycleState.resumed + on FirebaseMessaging.onTokenRefresh; upsert by (user_id, platform). | Code in notification or auth feature: service + call sites | Token in user_devices after login and after resume with refreshed token. |
| RLS test: no client INSERT notifications | Catch RLS regression | Integration test: as authenticated user, INSERT into notifications; expect exception (42501 or RLS). | Test file in test/integration or test/unit with Supabase mock | Test fails if INSERT policy exists for anon/authenticated. |
| Trigger non-blocking guarantee | Prevent INSERT latency regression | Implement trigger to only call pg_net.http_post (or insert into queue); add verification step: measure INSERT time with trigger. | Migration + one-line verification note or script | Trigger code contains no synchronous HTTP; latency check done or documented. |
| Foreground unread sync decision | Correct badge for >50 unread | Decision: implement in this plan. Step: on foreground, fetch count(is_read = false) or first page of unread, then start stream(50). | Decision in plan; code in ViewModel | Badge reflects full unread count after app open. |
| Edge Function secret validation | Fail fast if FCM key wrong | In Edge Function init: read secret; if missing or invalid format, log “FCM secret missing/invalid” (no value); optionally no-op send. | Edge Function code + review | No secret in logs; startup log exists when secret bad. |
| Rollback steps explicit | Safe rollback | Document: (1) Drop push trigger. (2) Deploy Edge Function no-op. (3) Optional drop user_devices. Never drop notifications or change notifications RLS. | Rollback section in plan | Numbered steps; “never” list. |
| Test type per behaviour | Right test type per behaviour | Assign: RLS = integration; sender skip = integration; idempotency = integration; push E2E = e2e. List in QA phase. | Plan section 4.3 + test plan | Each acceptance criterion has test type and location. |
| Flake and timeout policy | E2E stability | E2E: timeout 30s; 1 retry on failure; tag run with build id; no infinite wait. | QA section or test README | Documented; CI uses timeout and retry. |

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Contracts, Security, and Test Readiness

**Goal:** Lock data/API contracts and security model; ensure test infrastructure exists so progress is measurable.  
**Why:** Building trigger and Flutter without a contract causes rework; testing without harness causes flaky or missing tests.  
**How:** Write contract; RLS matrix; threat checklist; test dirs and one RLS test.  
**Result:** CONTRACT file, RLS matrix, threat checklist, at least one RLS test runnable.

**Steps:**

0.1 (@APIContract) Write `.TODO/improvement_the_system/ImplementReady/13_notification-routing/CONTRACT_notification_push.md`: `user_devices` columns (id, user_id, fcm_token, platform, created_at, updated_at); unique (user_id, platform); push payload from trigger (notification_id, user_id, title, message, type, related_entity_id, related_entity_type); Edge Function response contract; idempotency behaviour of `private_upsert_notification` (collapse-on-unread) and `private_create_notification` (no key).

0.2 (@Supabase_Ops) Add RLS matrix for `user_devices`: SELECT/INSERT/UPDATE/DELETE where user_id = auth.uid(); negative: other user’s row forbidden. File in same folder or `.TODO/`.

0.3 (@ThreatModeler) Threat checklist: push token theft, spoofed push, device table abuse; push path service_role only; no token in logs. File in `.TODO/` or 13 folder.

0.4 (@Sentinel) Test setup: document test dirs (unit/widget vs integration vs e2e); run command for notification tests; add one RLS test “authenticated INSERT into notifications → expect 42501 or RLS error.” Fixture: test user + one notification row if needed.

0.5 (@Architect) Decision: “Sync unread on foreground” = yes. Record in plan; will be implemented in Phase 2.

**GATE CHECK (Phase 0):** CONTRACT exists and is reviewed; RLS matrix exists; at least one RLS test runs; “sync unread on foreground” decision recorded. If any fails, do not proceed to Phase 1.

---

### Phase 1: Data and Backend (DB + Edge)

**Goal:** Add `user_devices`, push trigger, and Edge Function so notifications can be delivered via FCM without blocking INSERT.  
**Why:** Push is the main missing capability; trigger must be async to avoid slowing notifications.  
**How:** DDL for user_devices and RLS; enable pg_net if used; trigger function that enqueues only; Edge Function that reads payload and calls FCM; secret validation.  
**Result:** user_devices table and RLS; trigger on notifications INSERT; Edge Function deployable; INSERT latency unchanged.

**Steps:**

1.1 (@Supabase_Ops) Live re-scan: notifications, triggers, RLS; confirm no conflict with new objects.

1.2 (@Supabase_Ops) Migration: create `user_devices` (id, user_id, fcm_token, platform, created_at, updated_at); unique (user_id, platform); index on user_id. RLS policies per matrix (own rows only).

1.3 (@Supabase_Ops) Decision (from 0): If pg_net: enable extension. Create function `notifications_after_insert_push()`: in body only call pg_net.http_post(Edge Function URL, payload from NEW). No synchronous HTTP. Payload shape per CONTRACT. Create trigger AFTER INSERT on notifications EXECUTE this function.

1.4 (@Supabase_Ops) If pg_net not used: create job table or use cron to poll “notifications not yet pushed” and call Edge Function from cron (design in CONTRACT).

1.5 (@Architect / Backend) Edge Function `push-notify` (or equivalent): read payload from body; validate shape; read FCM secret; at startup log “FCM secret missing/invalid” if bad (never log value); send to FCM; log success/failure (no token in log). Deploy with secret.

1.6 (@DataMigration) Run migration(s); verify trigger fires and does not increase notification INSERT latency (measure or document).

**GATE CHECK (Phase 1):** user_devices exists with RLS; trigger exists and is async-only; Edge Function deployed and accepts contract payload; RLS test still passes. If trigger is sync or INSERT is slow, fix before Phase 2.

---

### Phase 2: App Layer (MVVM)

**Goal:** Register FCM token and optionally sync unread on foreground; keep single source of truth for notification list.  
**Why:** Without token registration push never reaches device; without foreground sync badge is wrong for >50 unread.  
**How:** Model for UserDevice; service/repository to upsert token; call from login + lifecycle resume + onTokenRefresh; ViewModel: on foreground fetch unread count or first page then stream(50).  
**Result:** Token in user_devices after login and refresh; badge correct after foreground; no direct Supabase in UI.

**Steps:**

2.1 (@Architect) Model/DTO for device registration aligned to CONTRACT (user_devices shape). Error mapping for registration failures.

2.2 (@Architect) Service or repository: upsert device (user_id, fcm_token, platform). Called after login/session restore; on AppLifecycleState.resumed; on FirebaseMessaging.onTokenRefresh. Use authenticated client; RLS enforces own row only.

2.3 (@Architect) NotificationViewModel: on app foreground (or stream start), fetch unread count or first page of unread (e.g. .eq('is_read', false).limit(50)); then start existing stream(50). Single stream + initial fetch = one source of truth.

2.4 (@Observability) Event list: token registration success/failure, push delivery failure (Edge Function side). No token in logs. Correlation: user_id or notification_id.

**GATE CHECK (Phase 2):** Token appears in user_devices after login; foreground sync implemented; no UI calls Supabase directly. If token never written, fix registration path before Phase 3.

---

### Phase 3: UI and Polish

**Goal:** Notification UI uses ViewModel only; loading/empty/error and token failure handled.  
**Why:** MVVM and stable UX.  
**How:** Ensure all notification screens use Consumer/read of ViewModel; handle token registration failure (toast or silent retry).  
**Result:** No regressions; clear states.

**Steps:**

3.1 (@Pixel) Confirm notification list and badge use ViewModel only; add or confirm loading/empty/error states; token registration failure: toast or silent retry (no crash).

3.2 (@Pixel) Optional: low-risk micro-interactions. No perf regression.

**GATE CHECK (Phase 3):** No direct Supabase in notification views; loading/error visible. Proceed to Phase 4.

---

### Phase 4: QA, Security, and Release

**Goal:** All acceptance criteria verified; security and observability validated; release-safe.  
**Why:** Prevent regressions and leaks.  
**How:** Contract and RLS tests; sender-exclusion and idempotency tests; push E2E (app killed); observability and rollback check.  
**Result:** All gates pass; release checklist done.

**Steps:**

4.1 (@Sentinel) Contract check: Flutter models and push payload match CONTRACT. Migration verification queries if any.

4.2 (@Sentinel) Security: RLS test (INSERT notifications denied); user_devices RLS (own only); ThreatModeler checklist executed. No token in logs.

4.3 (@Sentinel) Functional: E2E send message → in-app notification; E2E send message → other user kills app → OS push received. Sender == receiver → 0 notifications. Idempotency: duplicate call → single notification (if implemented). Timeout 30s; 1 retry; artifact tagged.

4.4 (@Sentinel) Observability: push failure and token failure logged; redaction verified.

4.5 (@DocsKeeper) Update DEVELOPER_GUIDE, SUPABASE_SETUP, diagram 13_notification-routing to match implementation and CONTRACT. Correct `private_upsert_notification` description (collapse-on-unread; no idempotency_key unless added).

**GATE CHECK (Phase 4):** All acceptance criteria have a passing test or manual sign-off; RLS tests pass; push E2E passes when app killed; docs updated. If any fails, do not release.

---

### Phase 5: Rollback and Residual Risk

**Rollback (explicit order):**  
(1) Drop trigger on notifications (push).  
(2) Deploy Edge Function that no-ops or remove invocation.  
(3) Optional: drop user_devices.  
**Never:** Drop notifications table or change RLS on notifications to allow client INSERT.

**Residual risks:** FCM quota/rate limits; multi-device per user not supported; idempotency for `private_create_notification` not in scope (documented).

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- Contract for push payload and user_devices not written before implementation; risk of trigger/Edge mismatch.
- Token registration only on login; no lifecycle or refresh.
- No RLS test for “client cannot INSERT notifications”; regression risk.
- Trigger could block INSERT if implemented synchronously.
- “Sync unread on foreground” left optional; badge wrong for >50 unread.
- Test types and test infrastructure not defined; no RLS test, no flake/timeout policy.
- Edge Function secret handling not explicit; rollback steps vague.
- Ordering: some UI/Flutter steps could start before contract/backend locked.

### 2) Added steps (bullet list)

- Write CONTRACT_notification_push.md (payload, user_devices, idempotency behaviour).
- RLS matrix for user_devices; threat checklist (token theft, no token in logs).
- Test infrastructure: dirs, run command, one RLS test (INSERT denied).
- Decision: “Sync unread on foreground” = yes.
- Token registration on login + lifecycle resume + onTokenRefresh.
- Trigger implementation rule: async only (pg_net or queue); latency check.
- Edge Function: secret validation at startup; no key in logs.
- Rollback: numbered steps; “never” list.
- Test type per behaviour (integration vs e2e); timeout 30s, 1 retry; artifact tag.
- Gate checks at end of each phase (0–4).

### 3) Removed steps

- None removed; several “optional” items made mandatory (foreground sync, contract first, RLS test).

### 4) Reordered steps

- Contract and RLS matrix moved to Phase 0 (before any DB or app code).
- Test infrastructure and one RLS test moved to Phase 0 (Gate 0).
- Trigger and Edge Function contract defined in Phase 0; implementation in Phase 1 in dependency order (DDL → RLS → trigger → Edge Function).
- Token registration call sites (lifecycle + refresh) added and ordered after service exists (Phase 2).
- QA and docs moved to Phase 4 with explicit gate check before release.

### 5) Expanded steps

- Phase 0: from “Contracts” and “Threat model” to concrete CONTRACT file, RLS matrix file, threat checklist file, test dir + one RLS test, and foreground-sync decision.
- Phase 1: trigger specified as “async only”; Edge Function startup secret check; latency verification.
- Phase 2: token registration expanded to login + resume + onTokenRefresh; ViewModel foreground sync described (fetch unread then stream).
- Phase 4: test type per behaviour; timeout/retry; artifact tag; rollback steps numbered and “never” list.
- Rollback: from short bullets to numbered steps and explicit “never” list.

### 6) Why (short, practical)

- Contract first avoids rework and gives a single place to verify payload and schema.
- Token on lifecycle prevents “push worked once then stopped” on token refresh.
- RLS test prevents accidental re-enable of client INSERT.
- Async-only trigger keeps notification INSERT fast and avoids timeouts.
- Foreground sync fixes badge for power users with many unread.
- Test infra and one RLS test unblock measurable progress and catch regressions.
- Explicit rollback and “never” list avoid destructive mistakes.

### 7) Residual risks (what still remains risky)

- FCM quota and rate limits (mitigation: monitor; back off in Edge Function if needed).
- Multi-device per user not in scope (one token per platform); may need later.
- Idempotency for `private_create_notification` not implemented; duplicate notifications on RPC retry possible until added.
- E2E push test depends on real FCM and device/simulator; can be flaky; 1 retry and timeout limit blast.

---

**END OF PLAN CRITIC OUTPUT**
