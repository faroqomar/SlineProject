# SLine System Critic Verdict: Auth & Profile Provisioning

## A) Verdict (Is NEW truly better than OLD?)

**Yes, but it was not production-ready yet.**

**Score OLD (05_DIAGRAM_V1.md): 3/10**

1. Missed `AccountGuardService` completely, exposing the app to banned users logging in.
2. Missed the implicit network/DB delay in triggers (race condition on signup).
3. Pretended the system was a "happy-path only" flow without error handles.
4. Lacked any indication of Session Restore (app starts already logged in).

**Score NEW (Initial Draft): 7/10**

1. (+) Fixed the signup race condition by adding an explicit retry loop.
2. (+) Documented `AccountGuardService` on manual login.
3. (-) Failed to document the **Session Restore** path (which is 90% of app launches).
4. (-) Failed to define what happens if the 3 retries **fail** (failure policy).
5. (-) Failed to provide an automated recovery plan for orphaned auth users.

**What NEW fixed compared to OLD:**

- Eliminated immediate crash/hang UX on delayed database triggers.
- Enforced ban/suspension rules synchronously on login.

---

## B) Critical Gaps in NEW (Addressed in Final Rewrite)

1. **Session restore / cold start guard path**: The diagram only showed manual login. The majority of app boots use `supabase.auth.currentSession`. If this path does not run `AccountGuardService`, a banned user retains access until their token naturally expires.
2. **Failure policy after profile retries**: If 3 retries failed, the diagram ambiguously "went to dashboard". If no profile exists, the UI crashes because `ProfileModel` cannot be null. We must aggressively `signOut()` to clear corrupt state.
3. **Orphan auth user recovery plan**: If a trigger fails, the `auth.users` row is orphaned. The user cannot sign up again (email taken). We must document an Admin RPC / cleanup job to purge `auth.users` without profiles older than 15 minutes.
4. **RLS verification requirements**: The `public.profiles` policy must explicitly allow users to `SELECT` and `UPDATE` their newly created row via `USING (id = auth.uid())` _before_ the trigger is fully complete in some high-concurrency environments.

---

## C) Minimal Necessary Improvements

1. **Change**: Add Session Restore path to the logic flow natively alongside Explicit Login.
   - **Why it matters**: Banned users must be intercepted on cold boot, not just on fresh logins.
   - **How to test**: Ban a logged-in user in DB, kill the app, and reopen it.
2. **Change**: Add Failure Fallback on Signup Loop (`signOut()`).
   - **Why it matters**: Prevents corrupt client state (session exists but profile null).
   - **How to test**: Disable the DB trigger, signup, wait 3 retries, verify app returns to login screen.
3. **Change**: Add Orphan Recovery Cron Job notes to Risk Register.
   - **Why it matters**: Unblocks users who failed provisioning from trying again.
   - **How to test**: Insert `auth.users` row manually without profile, verify cron sweeps it.

---

## D) Final Output

_(See the completely rewritten `00_HOLISTIC_REPORT.md` and `06_DIAGRAM_FINAL.md` for the unified, production-hardened system diagram and documentation)._
