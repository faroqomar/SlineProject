# Risk Register: Role Switching Flow

## J1) Risks if we keep the current system

1. **Data Leakage (State Pollution) [Severity: High, Likelihood: Medium]**
   - _Evidence:_ The current flow suggests UI simply flips the DB value. Flutter Provider streams might retain previous role data.
2. **Bypass UI Logic [Severity: Critical, Likelihood: Low]**
   - _Evidence:_ If only RPCs like `replace_task_request` check `active_role` but core tables miss it, users could interact illegally via API.
   - _Impact:_ Clients bidding on their own jobs to manipulate pricing.

## J2) Risks introduced by improvements

1. **JWT Custom Claim Sync Delay [Severity: Low, Likelihood: High]**
   - If migrating to JWT claims for performance, a token refresh is required post-DB update, causing a momentary desync.
   - _Mitigation:_ Await `supabase.auth.refreshSession()` before resolving the UI state switch.
2. **Complexity in Teardown [Severity: Medium, Likelihood: Medium]**
   - Unsubscribing from all active realtime channels might cause stutter.
   - _Mitigation:_ Implement a clean app-level reload sequence or specific `reset()` methods on ViewModels.
