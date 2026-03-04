# Sentinel Acceptance - Dashboard App Link (2026-03-03)

## Goal
Define measurable completion and rollback triggers for app-dashboard linkage enforcement.

## Done Conditions

1. Force logout enforcement
- Given `profiles.force_logout_after` is newer than session issue time,
  when app starts/resumes, user is signed out and sent to login.
- Verified on cold start and foreground resume.

2. Moderation enforcement
- Given `profiles.account_status` is `suspended` or `banned`,
  when user attempts sensitive actions (task apply/book, chat send/offer, withdrawal request),
  then action is blocked and user sees clear reason.

3. Report flow coverage
- User can submit `reports` row from:
  - task details (entity_type `task`)
  - chat screen (entity_type `chat`)
  - user profile surface (entity_type `user`)
- Submission success/failure states are visible in UI.

4. Dispute flow coverage
- Booking details `Report Issue` is no longer placeholder.
- User can submit dispute intent with reason and receive confirmation/error.

5. System config UX
- App can consume public keys:
  - `maintenance_mode`
  - `disable_signups`
  - `min_app_version`
  - `app_banner`
- Maintenance and version block are enforced at shell/auth entry.
- Signup is blocked when `disable_signups.enabled=true`.

6. Regression and architecture
- No direct Supabase calls in `view/` files.
- Existing booking/direct-offer/wallet happy paths still work.

## Rollback Triggers
- Any false-positive account lockout for active users.
- Sign-in blocked while `maintenance_mode.enabled=false`.
- Report/dispute submits consistently failing due RLS mismatch.
- Critical regressions in booking payment or direct-offer payment flows.
