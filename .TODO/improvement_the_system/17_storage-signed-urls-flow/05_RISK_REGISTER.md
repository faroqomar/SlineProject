# Risk Register: Storage Signed URLs Flow

## R1: Unauthorized Data Access (High Severity)

- **Description**: A logged-in user guesses the path of a private attachment (e.g., `convos/<convo_id>/...`) and accesses it despite not being a participant.
- **Likelihood**: Medium (Conversation IDs are UUIDs, but could be shared or leaked).
- **Impact**: High (Privacy breach, potential leakage of sensitive project files).
- **Evidence**: `SUPABASE_SETUP.md` §11.2 shows broad SELECT access for authenticated users in some buckets.
- **Mitigation**: Implement strict RLS on `storage.objects` using the `can_access_chat_attachment` helper.

## R2: URL Hijacking (Medium Severity)

- **Description**: A signed URL is intercepted (e.g., via non-HTTPS proxy or clipboard sharing) and used by an attacker.
- **Likelihood**: Low (HTTPS is mandatory).
- **Impact**: Medium (Attacker can see the image until it expires).
- **Evidence**: TTL values in code are up to 2 hours.
- **Mitigation**: Minimize TTL to 15-30 minutes for highly sensitive chat attachments.

## R3: Denial of Service (Low Severity)

- **Description**: An attacker uploads thousands of large files to their "own folder" in a private bucket, filling storage or exhausting bandwidth.
- **Likelihood**: low (requires authenticated account).
- **Impact**: Medium (Increased costs, potential performance degradation).
- **Mitigation**: Enforce per-user storage quotas and file size limits at the storage bucket configuration level.

## R4: Migration Interruption (Low Severity)

- **Description**: Changing storage RLS policies incorrectly locks out legitimate users from their uploaded images.
- **Likelihood**: Medium (RLS on storage can be tricky).
- **Mitigation**: Use an "Additive" migration strategy—add stricter policies alongside existing ones, then phase out the broad ones after verification.
