# Evidence Privacy Proof: Dispute Evidence

## `dispute_evidence` Table

**Schema** (`SUPABASE_SETUP.md` §5.26):

- `file_url` (text) — storage path
- `uploader_id` (uuid) — FK to profiles
- `dispute_id` (uuid) — FK to disputes

## RLS Policies — ❌ NONE FOUND

No RLS policies exist for `dispute_evidence` in any migration file.

| Check                          | Result       |
| ------------------------------ | ------------ |
| SELECT policy for complainant  | ❌ Not found |
| SELECT policy for defendant    | ❌ Not found |
| SELECT policy for admin        | ❌ Not found |
| INSERT policy for participants | ❌ Not found |

> **Effect:** With RLS enabled and no policies, `dispute_evidence` is **completely locked** for all users including admin via `authenticated` role. This is accidentally secure but means the feature is **non-functional**.

## Storage Bucket for Evidence — ❌ MISSING

**Evidence:** `SUPABASE_SETUP.md` §11.1 lists 4 buckets: `avatars`, `task-images`, `chat-attachments`, `portfolio`. No `dispute-evidence` or `disputes` bucket exists.

> **Gap:** Evidence file uploads have no dedicated storage bucket. Code would need to use an existing bucket (e.g., `chat-attachments`) or a new `dispute-evidence` bucket must be created.

## Privacy Verdict

| Item                      | Status                           | Risk                         |
| ------------------------- | -------------------------------- | ---------------------------- |
| Evidence table RLS        | Blocked by default (no policies) | Feature non-functional       |
| Cross-party evidence leak | N/A (table is locked)            | No current risk              |
| Storage bucket            | Missing                          | Cannot upload evidence files |
| Storage policies          | Missing                          | N/A (no bucket)              |

> **Verdict:** No privacy breach possible because the feature is entirely non-functional. Before enabling it, proper RLS (participant-scoped SELECT, uploader INSERT) and a private storage bucket are required.
