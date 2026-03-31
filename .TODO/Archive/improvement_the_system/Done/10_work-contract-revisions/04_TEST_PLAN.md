# Verification Checklist: Work Contract Revisions

## Skills Selected

- **Test Design (High-Value Tests)**: To map boundary conditions for state reversions.
- **Invariants & Contracts**: Ensure assertions map exactly to the enforced rules.

## Checklist

### 1. State Guard Tests

- [ ] Attempt `rpc_request_revision` on an `active` task. Must fail with "Can only request revision on delivered work".
- [ ] Attempt `rpc_request_revision` on a `completed` task. Must fail.
- [ ] Attempt `rpc_request_revision` on a `delivered` task. Must succeed.

### 2. Cap Limit Tests

- [ ] Set `revisions_total = 1`, `revisions_used = 1`. Attempt `rpc_request_revision`. Must fail with "No revisions remaining".
- [ ] Set `revisions_total = 1`, `revisions_used = 0`. Attempt `rpc_request_revision`. Must succeed, and `revisions_used` becomes 1.

### 3. Role/RLS Tests

- [ ] Attempt `rpc_request_revision` as the Freelancer. Must fail with "Only client can request revision".
- [ ] Attempt `rpc_request_revision` as a random third-party user. Must fail.

### 4. Mutation Assertions

- [ ] On successful revision, verify `delivered_at` IS NULL.
- [ ] On successful revision, verify `review_expires_at` IS NULL.
- [ ] On successful revision, verify `revision_note` matches input.
