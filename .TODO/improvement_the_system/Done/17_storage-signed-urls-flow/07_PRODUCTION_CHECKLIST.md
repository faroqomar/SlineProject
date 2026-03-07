# Production Checklist: Storage Signed URLs Flow

## Security

- [ ] Implement `is_admin()` check in `can_access_chat_attachment`.
- [ ] Apply `can_access_chat_attachment` as a `SELECT` policy on `storage.objects` for the `chat-attachments` bucket.
- [ ] Apply participant-scoping for `task-images` bucket `SELECT` policy.
- [ ] Verify that `portfolio` bucket public access is truly intended or if signed URLs should be strictly required via RLS.

## Reliability

- [ ] Set uniform standard TTLs: 1h for attachments, 2h for profiles.
- [ ] Implement Flutter-side `TimedCache` for signed URLs.
- [ ] Add unit tests for `can_access_chat_attachment` function in Postgres.

## Observability

- [ ] Log `createSignedUrl` failures in `admin_logs` to detect potential brute-force guessing.
- [ ] Add monitoring for Storage bucket size growth by user.

## Migration

- [ ] Apply stricter `SELECT` policies using the "Additive" strategy to prevent lockout.
- [ ] Verify that existing chat attachments still render correctly after policy update.
