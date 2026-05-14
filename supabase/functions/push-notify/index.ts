// @ts-nocheck
// Plan: .TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md
// Single notification payload → FCM. Internal/cron only; set PUSH_NOTIFY_SECRET and use Authorization: Bearer.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createAdminClient, corsHeaders, jsonResponse } from "../_shared/booking_payment.ts";

const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY") ?? "";
const PUSH_NOTIFY_SECRET = Deno.env.get("PUSH_NOTIFY_SECRET") ?? "";

interface PushPayload {
  notification_id: string;
  user_id: string;
  title: string;
  message: string;
  type: string;
  related_entity_id?: string | null;
  related_entity_type?: string | null;
}

function validatePayload(body: unknown): PushPayload | null {
  if (!body || typeof body !== "object") return null;
  const o = body as Record<string, unknown>;
  if (typeof o.notification_id !== "string" || typeof o.user_id !== "string" ||
      typeof o.title !== "string" || typeof o.message !== "string" || typeof o.type !== "string") return null;
  return {
    notification_id: o.notification_id as string,
    user_id: o.user_id as string,
    title: o.title as string,
    message: o.message as string,
    type: o.type as string,
    related_entity_id: o.related_entity_id as string | null | undefined,
    related_entity_type: o.related_entity_type as string | null | undefined,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }
  if (PUSH_NOTIFY_SECRET && PUSH_NOTIFY_SECRET.length >= 8) {
    const auth = req.headers.get("Authorization") ?? "";
    if (auth !== `Bearer ${PUSH_NOTIFY_SECRET}`) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }
  }

  if (!FCM_SERVER_KEY || FCM_SERVER_KEY.length < 10) {
    console.error("FCM secret missing or invalid (value not logged)");
    return jsonResponse({ error: "Push not configured" }, 503);
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, 400);
  }
  const payload = validatePayload(body);
  if (!payload) {
    return jsonResponse({ error: "Invalid payload shape" }, 400);
  }

  const supabase = createAdminClient();
  const { data: devices, error: devError } = await supabase
    .from("user_devices")
    .select("fcm_token")
    .eq("user_id", payload.user_id);
  if (devError) {
    console.error("user_devices lookup failed notification_id=" + payload.notification_id, devError.message);
    return jsonResponse({ error: "Device lookup failed" }, 500);
  }
  const tokens = (devices ?? []).map((r: { fcm_token: string }) => r.fcm_token).filter(Boolean);
  if (tokens.length === 0) {
    return jsonResponse({ sent: 0, reason: "No device tokens" }, 200);
  }

  let sent = 0;
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
          notification: { title: payload.title, body: payload.message },
          data: {
            notification_id: payload.notification_id,
            type: payload.type,
            ...(payload.related_entity_id && { related_entity_id: payload.related_entity_id }),
            ...(payload.related_entity_type && { related_entity_type: payload.related_entity_type }),
          },
        }),
      });
      if (res.ok) sent++;
      else console.error("FCM send non-2xx notification_id=" + payload.notification_id);
    } catch (e) {
      console.error("FCM request failed notification_id=" + payload.notification_id, (e as Error).message);
    }
  }
  return jsonResponse({ sent, total: tokens.length }, 200);
});
