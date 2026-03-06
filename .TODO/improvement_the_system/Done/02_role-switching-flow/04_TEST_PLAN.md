# Test Plan for Role Switching Flow

## Verification Checklist (Production Readiness)

- [ ] **Unit Tests (View Models):** Test that calling `switchRole` on the ProfileViewModel successfully clears local caches (`TaskViewModel`, `InboxViewModel`) to prevent data leaking.
- [ ] **Integration Tests (UI):** Render Profile view, tap switch role, verify Dashboard resets to the default tab for that role, and data calls fetch for the new persona.
- [ ] **RLS Checks (DB):**
  - Write a pgTAP test attempting to perform a freelancer action (e.g., `replace_task_request`) when the test user's `active_role` is 'client'. It MUST fail.
  - Attempt to submit a new task as a 'freelancer'. Depending on business rules, it should fail if clients only can post, but SLine might allow both. The key is enforcing that only the correct persona accesses restricted features.
- [ ] **Session Refresh Check:** Ensure that after the DB `update({'active_role': '...'})`, `supabase.auth.refreshSession()` is called if JWT custom claims are implemented.
- [ ] **Audit Logs (Observability):** Verify that the `update` on `profiles` tracking `active_role` triggers a row in an admin `audit_logs` table for traceability.
