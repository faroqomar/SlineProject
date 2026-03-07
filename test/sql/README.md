# SQL verification scripts

Scripts in this folder are run manually (Supabase SQL Editor or `psql`) to verify database guards and lifecycle.

## direct_offer_guard_verification.sql

**Purpose:** Verifies `fn_direct_offer_guard` and ledger integration for direct offers.

**Fixture:**
- Two profile IDs (client, freelancer) and one conversation ID where both are participants.
- Conversation must exist in `public.conversations` with `user1_id`/`user2_id` matching the two profiles.

**Steps:**
1. Replace in the script:
   - `v_client_id` — client profile UUID
   - `v_freelancer_id` — freelancer profile UUID
   - `v_conv_id` — conversation UUID
2. Run the script in Supabase SQL Editor (or with `psql` using service_role).
3. Expected: NOTICEs for each passed check; no exception. Script creates one offer, runs illegal transition (must be blocked), legal transition, ledger escrow_hold, then deletes the test row.

**Pass criteria:** No unhandled exception; NOTICE "All guard checks passed" at end.
