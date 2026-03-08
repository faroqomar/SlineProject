# Threat Checklist: Notification Push (13_notification-routing)

**Plan:** `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`

---

## 1. Push token theft

- **Risk:** Attacker obtains FCM token and receives another user’s pushes or spoofs device.
- **Mitigation:** Tokens stored only in `user_devices`; RLS restricts to own rows. Client never logs token; Edge Function never logs token. HTTPS only.
- **Check:** Code review + log audit: no `fcm_token` or raw token in AppLogger/Edge logs.

## 2. Spoofed push / client sends push

- **Risk:** Client or external caller triggers push to arbitrary user.
- **Mitigation:** Push path is server-only: trigger/cron → Edge Function with service_role or server key. Edge Function reads notification from DB and sends to FCM; client cannot invoke “send push” API.
- **Check:** No public/anon-invokable Edge Function that accepts user_id + message and sends FCM.

## 3. Device table abuse

- **Risk:** User fills `user_devices` with junk or enumerates other users’ devices.
- **Mitigation:** RLS: INSERT/UPDATE/DELETE only with user_id = auth.uid(). Unique (user_id, platform) limits rows per user. No list-all endpoint for clients.
- **Check:** RLS matrix tests: user A cannot INSERT/UPDATE/DELETE rows for user B.

## 4. Push path service_role only

- **Risk:** If Edge Function used anon key, RLS could block reading `user_devices` for recipient.
- **Mitigation:** Edge Function uses service_role (or server key) to read `user_devices` and send via FCM. No client key in push path.
- **Check:** Edge Function code and deployment: no anon key used for user_devices select or FCM send.

## 5. No token in logs

- **Requirement:** AppLogger and Edge Function must never log `fcm_token` or FCM server key.
- **Check:** Grep for token/key in log messages; redact in any error payloads.
