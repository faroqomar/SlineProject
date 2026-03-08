# Runbook: Notification Push (Edge Functions)

**Plan:** `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`

---

## 1) Required secrets (Supabase Edge Function secrets)

| Secret | Required | Purpose |
|--------|----------|---------|
| `FCM_SERVER_KEY` | Yes (for push) | FCM legacy server key; never log or expose. |
| `CRON_SECRET` | Yes (for process-push-queue) | Must be set (min 8 chars). Processor returns 503 if unset. Invoke with `Authorization: Bearer <CRON_SECRET>`. |
| `PUSH_NOTIFY_SECRET` | Optional | If set (min 8 chars), push-notify requires `Authorization: Bearer <PUSH_NOTIFY_SECRET>`. Use for internal/cron callers. |

---

## 2) process-push-queue

- **URL:** `POST https://<project>.supabase.co/functions/v1/process-push-queue`
- **Auth:** Required. Set `CRON_SECRET` in project secrets; call with header `Authorization: Bearer <CRON_SECRET>`.
- **If CRON_SECRET not set:** Function returns 503 "Queue processor disabled; set CRON_SECRET and invoke with Authorization: Bearer <CRON_SECRET>".
- **Cron:** Invoke every 1–2 minutes (e.g. GitHub Actions, or external cron). Example:
  ```bash
  curl -X POST "https://<project>.supabase.co/functions/v1/process-push-queue" \
    -H "Authorization: Bearer $CRON_SECRET"
  ```

---

## 3) push-notify

- **URL:** `POST https://<project>.supabase.co/functions/v1/push-notify`
- **Auth:** If `PUSH_NOTIFY_SECRET` is set, send `Authorization: Bearer <PUSH_NOTIFY_SECRET>`. If not set, no auth (restrict by network or do not expose publicly).
- **Body:** JSON per CONTRACT (notification_id, user_id, title, message, type, related_entity_id?, related_entity_type?).
- **Use:** Internal or pg_net/cron single-payload send. Do not expose publicly without setting PUSH_NOTIFY_SECRET.

---

## 4) Deployment

1. Set secrets: `FCM_SERVER_KEY`, `CRON_SECRET`, optionally `PUSH_NOTIFY_SECRET`.
2. Deploy: `supabase functions deploy process-push-queue push-notify --project-ref <ref>`.
3. Schedule cron to call process-push-queue with Bearer token.
