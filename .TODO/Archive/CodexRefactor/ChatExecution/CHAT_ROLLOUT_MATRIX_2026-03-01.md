# Chat Rollout & Rollback Matrix (2026-03-01)

**Purpose:** Deploy order, PR slicing, and rollback triggers. Rollout order and stop/rollback conditions must be explicit before Phase 1 begins.

---

## 1. PR / deploy order

| PR | Contents | Deploy order |
|----|----------|--------------|
| PR1 | Decisions, audits, contracts, test strategy (Phase 0–1 artifacts) | First; no DB or app behavior change |
| PR2 | Additive DB: archive RPC, storage helper, new RLS policies (Phase 2 additive only) | Staging first; then production. App still uses old behavior until PR3 |
| PR3 | App-layer contract and realtime corrections (Phase 3: models, message_service, repository, viewmodel split, archive RPC usage) | After PR2 verified in staging |
| PR4 | UI states, tests, docs sync, release checklist (Phase 4–5) | After PR3; includes removal of weak policies if not done in PR2 |

**Rule:** Additive first (new RPC, new helper, new policies). App switches to new contract and archive RPC in PR3. Destructive policy removal only after allow/deny matrix passes.

---

## 2. Rollback triggers

If any of the following occur, rollback or freeze as below.

| Trigger | Action |
|---------|--------|
| Valid participant read fails (messages or conversations) | Rollback: restore captured message/conversation policies; fix app/DB before re-enabling |
| Attachment access fails for valid participants | Rollback: restore storage select policy or fix helper; temporary exception for legacy paths if audited |
| DM creation failure rate rises after policy changes | Rollback: re-enable previous insert policy; forward-fix with favorites check |
| Archive hides wrong conversation state or RPC misbehaves | Rollback: revert app to read-only archive or client-side hide; fix RPC before re-enabling |

---

## 3. Rollback SQL

- **Before Phase 2:** Capture exact SQL for all touched policies, functions, and publication membership (messages, conversations, storage.objects for chat-attachments). Store in CHAT_LIVE_SQL_BASELINE and in this doc or a rollback snippet file.
- **After each destructive change:** Record the exact policy/function drop or replace so it can be re-applied if needed.
- **Archive RPC:** If rollback required, stop calling from app; do not drop function until app is reverted (avoids orphaned behavior).

---

## 4. Feature fallback (realtime)

- If `conversations` realtime publication is not enabled or is rolled back: app must rely on fetch-refresh only (screen open, post-send, post-archive, pull-to-refresh). No assumption that conversation list updates in real time.
- Fallback behavior remains valid and tested; optional realtime is additive and gated in a later pass.

---

## 5. Stop conditions

- **Before Phase 2:** Do not apply security migrations until live SQL baseline, data audit, contract map, and compatibility window are complete (Phase 1 gate).
- **Before Phase 3:** Do not start app-layer dependency changes until RLS/storage checks pass and rollback SQL is captured (Phase 2 gate).
- **Before release:** Release only after post-rollout smoke checks, RLS/storage validation, and docs sync (Phase 5 gate).
