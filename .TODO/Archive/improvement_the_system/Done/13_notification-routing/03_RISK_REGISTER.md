# 03_RISK_REGISTER: Notification Routing

## J1) Risks if we keep the current system

1. **No External Push Notifications (Severity: High, Likelihood: Medium, Impact: High)**
   - **Evidence:** The current diagram and code explicitly rely on `supabase_realtime` and a `limit(50)` stream in Flutter. If the app is killed or backgrounded by the OS (iOS/Android), the user _will not know_ they received a message or offer.
2. **Missing Architectural Definition for Booking/Disputes (Severity: Medium, Likelihood: High, Impact: Medium)**
   - **Evidence:** Diagram has `Booking/Dispute Events ⚠️ UNVERIFIED source`. If an Edge Function handles these, they are hidden from the primary reactive data flow. If they are changed, notifications might silently break.
3. **Stream Limit Truncation (Severity: Low, Likelihood: Low, Impact: Low)**
   - **Evidence:** `notification_service.dart` uses `.limit(50)`. If a user is offline and receives 55 notifications, the stream initialize will truncate the oldest 5 unread notifications from immediate view.

## J2) Risks introduced by improvements

1. **Push Notification (FCM/APNs) Integration Risk**
   - **Risk:** Implementing a real APNs/FCM service via Edge Functions (reacting to `private_upsert_notification`) adds significant complexity and latency.
   - **Mitigation:** Setup a robust webhook trigger off the `notifications` table that safely posts to an Edge Function _asynchronously_ for external delivery.
2. **Enforcing Strict Idempotency in Edge Functions**
   - **Risk:** If Edge Functions generate conflicting or invalid idempotency keys, legitimate notifications will be silently dropped by `private_upsert_notification`.
   - **Mitigation:** Standardize a library/helper for generating notification keys (e.g. `entityType_entityId_action`).
