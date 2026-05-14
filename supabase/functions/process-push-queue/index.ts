// @ts-nocheck
// Plan: .TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md
// Drains notification_push_queue: select pending, get device tokens, send FCM, update status.
// Requires CRON_SECRET in production; invoke with Authorization: Bearer <CRON_SECRET>.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createAdminClient, corsHeaders, jsonResponse } from "../_shared/booking_payment.ts";

const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY") ?? "";
const CRON_SECRET = Deno.env.get("CRON_SECRET") ?? "";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: corsHeaders });
  }
  if (req.method !== "POST" && req.method !== "GET") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }
  if (!CRON_SECRET || CRON_SECRET.length < 8) {
    console.error("CRON_SECRET not set; queue processor disabled");
    return jsonResponse(
      { error: "Queue processor disabled; set CRON_SECRET and invoke with Authorization: Bearer <CRON_SECRET>" },
      503,
    );
  }
  const auth = req.headers.get("Authorization") ?? "";
  if (auth !== `Bearer ${CRON_SECRET}`) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  if (!FCM_SERVER_KEY || FCM_SERVER_KEY.length < 10) {
    console.error("FCM secret missing or invalid (value not logged)");
    return jsonResponse({ error: "Push not configured" }, 503);
  }

  const supabase = createAdminClient();
  const { data: rows, error: fetchError } = await supabase
    .from("notification_push_queue")
    .select("id, notification_id, user_id, title, message, type, related_entity_id, related_entity_type")
    .eq("status", "pending")
    .order("created_at", { ascending: true })
    .limit(50);
  if (fetchError) {
    console.error("Queue select failed:", fetchError.message);
    return jsonResponse({ error: "Queue read failed" }, 500);
  }
  const pending = rows ?? [];
  if (pending.length === 0) {
    return jsonResponse({ processed: 0 }, 200);
  }

  let sent = 0;
  let failed = 0;
  for (const row of pending) {
    const { data: devices } = await supabase
      .from("user_devices")
      .select("fcm_token")
      .eq("user_id", row.user_id);
    const tokens = (devices ?? []).map((r: { fcm_token: string }) => r.fcm_token).filter(Boolean);
    let ok = false;
    for (const token of tokens) {
      try {
        const res = await fetch("https://fcm.googleapis.com/fcm/send", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `key=${FCM_SERVER_KEY}`,
          },
          body: JSON.stringify({
            to: token,
            notification: { title: row.title, body: row.message },
            data: {
              notification_id: row.notification_id,
              type: row.type,
              ...(row.related_entity_id && { related_entity_id: row.related_entity_id }),
              ...(row.related_entity_type && { related_entity_type: row.related_entity_type }),
            },
          }),
        });
        if (res.ok) ok = true;
      } catch (e) {
        console.error("FCM request failed notification_id=" + row.notification_id, (e as Error).message);
      }
    }
    await supabase
      .from("notification_push_queue")
      .update({ status: ok ? "sent" : "failed" })
      .eq("id", row.id);
    if (ok) sent++; else failed++;
  }
  console.error(JSON.stringify({ event: "push_batch", processed: pending.length, sent, failed }));
  return jsonResponse({ processed: pending.length, sent, failed }, 200);
});
