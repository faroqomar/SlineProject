// @ts-nocheck
import { createClient } from "npm:@supabase/supabase-js@2";

export const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
export const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") || "";
export const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

export const QICARD_PROVIDER_NAME =
  Deno.env.get("QICARD_PROVIDER_NAME") || "qicard";
export const QICARD_API_BASE_URL =
  Deno.env.get("QICARD_API_BASE_URL") || "https://uat-sandbox-3ds-api.qi.iq/api/v1";
export const QICARD_TERMINAL_ID = Deno.env.get("QICARD_TERMINAL_ID") || "";
export const QICARD_USERNAME = Deno.env.get("QICARD_USERNAME") || "";
export const QICARD_PASSWORD = Deno.env.get("QICARD_PASSWORD") || "";
export const QICARD_NOTIFICATION_URL =
  Deno.env.get("QICARD_NOTIFICATION_URL") ||
  `${SUPABASE_URL}/functions/v1/qicard_webhook_handler`;
export const QICARD_FINISH_URL =
  Deno.env.get("QICARD_FINISH_URL") || "https://sline.app/payment/success";
export const BOOKING_PAYMENT_EXPIRY_MINUTES = Number(
  Deno.env.get("BOOKING_PAYMENT_EXPIRY_MINUTES") || "30",
);

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-signature",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function createAdminClient() {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
}

export function createUserClient(req: Request) {
  const authHeader = req.headers.get("Authorization") || "";
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: {
        Authorization: authHeader,
      },
    },
  });
}

export async function requireAuthenticatedUser(req: Request) {
  const userClient = createUserClient(req);
  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) {
    return {
      error: jsonResponse({ error: "Unauthorized" }, 401),
    };
  }

  return {
    user: data.user,
    userClient,
    adminClient: createAdminClient(),
  };
}

export function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
    },
  });
}

export function corsPreflightResponse() {
  return new Response("ok", {
    status: 200,
    headers: corsHeaders,
  });
}

export function buildCorrelationId(
  bookingId: string,
  action: "create" | "recover" | "refund",
) {
  return `booking:${bookingId}:${action}`;
}

export function withQueryParams(
  baseUrl: string,
  params: Record<string, string>,
) {
  const url = new URL(baseUrl);
  Object.entries(params).forEach(([key, value]) => {
    url.searchParams.set(key, value);
  });
  return url.toString();
}

export async function recordBookingAudit(
  adminClient: ReturnType<typeof createAdminClient>,
  {
    bookingId,
    eventType,
    correlationId,
    actorUserId,
    outcome,
    payload,
  }: {
    bookingId: string;
    eventType: string;
    correlationId: string;
    actorUserId?: string | null;
    outcome: string;
    payload: Record<string, unknown>;
  },
) {
  await adminClient.from("booking_payment_audits").insert({
    booking_id: bookingId,
    event_type: eventType,
    correlation_id: correlationId,
    actor_user_id: actorUserId ?? null,
    provider: QICARD_PROVIDER_NAME,
    outcome,
    payload,
  });
}

export async function createBookingNotification(
  adminClient: ReturnType<typeof createAdminClient>,
  {
    userId,
    bookingId,
    title,
    message,
    metadata,
  }: {
    userId: string;
    bookingId: string;
    title: string;
    message: string;
    metadata?: Record<string, unknown>;
  },
) {
  await adminClient.from("notifications").insert({
    user_id: userId,
    title,
    message,
    type: "booking",
    related_entity_id: bookingId,
    related_entity_type: "booking",
    metadata: metadata ?? {},
    is_read: false,
    created_at: new Date().toISOString(),
  });
}

export async function fetchBooking(
  adminClient: ReturnType<typeof createAdminClient>,
  bookingId: string,
) {
  const { data, error } = await adminClient
    .from("bookings")
    .select(
      "id, task_id, slot_id, provider_id, client_id, status, payment_status, price, package_id, due_at, delivery_days, payment_request_id, payment_gateway_id, payment_correlation_id, payment_expires_at, payment_recovered_at",
    )
    .eq("id", bookingId)
    .single();

  if (error || !data) {
    throw new Error("BOOKING_NOT_FOUND");
  }

  return data;
}

export async function promoteBookingAfterHold(
  adminClient: ReturnType<typeof createAdminClient>,
  bookingId: string,
) {
  await adminClient
    .from("bookings")
    .update({
      status: "paid_request_pending",
      payment_recovered_at: new Date().toISOString(),
    })
    .eq("id", bookingId)
    .in("status", ["pending", "confirmed"]);
}

export async function submitGatewayEscrowHold(
  adminClient: ReturnType<typeof createAdminClient>,
  {
    bookingId,
    paymentId,
    requestId,
    amount,
    currency,
    timestamp,
    correlationId,
  }: {
    bookingId: string;
    paymentId: string;
    requestId: string;
    amount: number;
    currency: string;
    timestamp: string;
    correlationId: string;
  },
) {
  const idempotencyKey = `qicard:${paymentId}:gateway_escrow:SUCCESS`;
  const meta = {
    psp_provider: QICARD_PROVIDER_NAME,
    psp_event_id: requestId,
    psp_payment_id: paymentId,
    psp_request_id: requestId,
    psp_status: "SUCCESS",
    psp_timestamp: timestamp,
    booking_id: bookingId,
    correlation_id: correlationId,
  };

  const { data, error } = await adminClient.rpc("process_payment_event_ledger", {
    p_event_type: "gateway_escrow",
    p_related_entity_type: "booking",
    p_related_entity_id: bookingId,
    p_idempotency_key: idempotencyKey,
    p_amount_gross: amount,
    p_currency: currency,
    p_meta: meta,
  });

  if (error) {
    if (error.message?.includes("ERR_IDEMPOTENCY_REPLAY")) {
      await promoteBookingAfterHold(adminClient, bookingId);
      return {
        replayed: true,
        journalEntryId: null,
      };
    }

    throw new Error(error.message || "LEDGER_GATEWAY_ESCROW_FAILED");
  }

  if (data?.ok === false) {
    throw new Error(extractLedgerError(data.error));
  }

  await promoteBookingAfterHold(adminClient, bookingId);

  return {
    replayed: false,
    journalEntryId: data?.journal_entry_id ?? null,
  };
}

function extractLedgerError(error: unknown): string {
  if (typeof error === "string" && error.length > 0) {
    return error;
  }

  if (error && typeof error === "object") {
    const code = typeof error.code === "string" ? error.code : null;
    const message = typeof error.message === "string" ? error.message : null;
    if (code && message) {
      return `${code}: ${message}`;
    }
    if (message) {
      return message;
    }
    if (code) {
      return code;
    }
  }

  return "LEDGER_GATEWAY_ESCROW_REJECTED";
}

function qicardAuthHeader() {
  return `Basic ${btoa(`${QICARD_USERNAME}:${QICARD_PASSWORD}`)}`;
}

function ensureQiCardConfig() {
  const missing = [
    !QICARD_TERMINAL_ID ? "QICARD_TERMINAL_ID" : null,
    !QICARD_USERNAME ? "QICARD_USERNAME" : null,
    !QICARD_PASSWORD ? "QICARD_PASSWORD" : null,
  ].filter(Boolean);

  if (missing.length > 0) {
    throw new Error(`QICARD_CONFIG_MISSING:${missing.join(",")}`);
  }
}

async function parseQiCardResponse(response: Response) {
  const raw = await response.text();
  let body: Record<string, unknown> = {};
  try {
    body = raw ? JSON.parse(raw) : {};
  } catch {
    body = {};
  }

  if (!response.ok) {
    const message =
      body?.error?.description ||
      body?.error?.message ||
      body?.message ||
      `QiCard request failed with status ${response.status}`;
    throw new Error(String(message));
  }

  return body;
}

export async function qicardCreatePayment({
  requestId,
  amount,
  currency,
  description,
  finishPaymentUrl,
  additionalInfo,
}: {
  requestId: string;
  amount: number;
  currency: string;
  description: string;
  finishPaymentUrl: string;
  additionalInfo: Record<string, unknown>;
}) {
  ensureQiCardConfig();

  const response = await fetch(`${QICARD_API_BASE_URL}/payment`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: qicardAuthHeader(),
      "X-Terminal-Id": QICARD_TERMINAL_ID,
    },
    body: JSON.stringify({
      requestId,
      amount: Number(amount.toFixed(3)),
      currency,
      finishPaymentUrl,
      notificationUrl: QICARD_NOTIFICATION_URL,
      description,
      additionalInfo,
    }),
  });

  const body = await parseQiCardResponse(response);
  return {
    paymentId: body.paymentId ? String(body.paymentId) : null,
    formUrl: body.formUrl ? String(body.formUrl) : null,
    raw: body,
  };
}

function normalizeQiCardPaymentStatus(
  body: Record<string, unknown>,
  fallbackRequestId: string | null,
) {
  const statusSource =
    body.status ??
    body.payment?.status ??
    body.data?.status;
  const amountSource =
    body.amount ??
    body.payment?.amount ??
    body.data?.amount;
  const currencySource =
    body.currency ??
    body.payment?.currency ??
    body.data?.currency;
  const createdAtSource =
    body.creationDate ??
    body.createdDate ??
    body.payment?.creationDate ??
    body.data?.creationDate;
  const requestIdSource =
    body.requestId ??
    body.paymentRequestId ??
    body.payment?.requestId ??
    body.data?.requestId ??
    fallbackRequestId;

  return {
    requestId: requestIdSource ? String(requestIdSource) : "",
    status: String(statusSource || "UNKNOWN").toUpperCase(),
    amount: Number(amountSource || 0),
    currency: String(currencySource || "IQD"),
    createdAt: String(createdAtSource || new Date().toISOString()),
    raw: body,
  };
}

async function qicardFetchPaymentStatus(
  path: string,
  fallbackRequestId: string | null,
) {
  ensureQiCardConfig();

  const response = await fetch(`${QICARD_API_BASE_URL}${path}`, {
    headers: {
      "Content-Type": "application/json",
      Authorization: qicardAuthHeader(),
      "X-Terminal-Id": QICARD_TERMINAL_ID,
    },
  });

  const body = await parseQiCardResponse(response);
  return normalizeQiCardPaymentStatus(body, fallbackRequestId);
}

export async function qicardGetPaymentStatus({
  paymentId,
  paymentRequestId,
}: {
  paymentId?: string | null;
  paymentRequestId?: string | null;
}) {
  ensureQiCardConfig();

  if (!paymentId && !paymentRequestId) {
    throw new Error("QICARD_PAYMENT_STATUS_IDENTIFIER_MISSING");
  }

  let lastResult = {
    requestId: paymentRequestId ? String(paymentRequestId) : "",
    status: "UNKNOWN",
    amount: 0,
    currency: "IQD",
    createdAt: new Date().toISOString(),
    raw: <Record<string, unknown>>{},
  };

  if (paymentId) {
    lastResult = await qicardFetchPaymentStatus(
      `/payment/${paymentId}/status`,
      paymentRequestId ? String(paymentRequestId) : null,
    );
    if (lastResult.status !== "UNKNOWN") {
      return lastResult;
    }
  }

  if (paymentRequestId) {
    lastResult = await qicardFetchPaymentStatus(
      `/payment/status/by/request/${paymentRequestId}`,
      String(paymentRequestId),
    );
  }

  return lastResult;
}

export async function qicardRefundPayment({
  paymentId,
  amount,
  currency,
  reason,
}: {
  paymentId: string;
  amount: number;
  currency: string;
  reason?: string;
}) {
  ensureQiCardConfig();

  const requestId = crypto.randomUUID();
  const response = await fetch(`${QICARD_API_BASE_URL}/payment/${paymentId}/refund`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: qicardAuthHeader(),
      "X-Terminal-Id": QICARD_TERMINAL_ID,
    },
    body: JSON.stringify({
      requestId,
      amount: Number(amount.toFixed(3)),
      currency,
      ...(reason ? { description: reason } : {}),
    }),
  });

  const body = await parseQiCardResponse(response);
  return {
    requestId,
    refundId: body.refundId ? String(body.refundId) : String(body.paymentId || ""),
    status: String(body.status || "PENDING").toUpperCase(),
    raw: body,
  };
}

export function isTerminalRefundStatus(status: string | null | undefined) {
  const normalized = String(status || "").toUpperCase();
  return ["SUCCESS", "COMPLETED", "REFUNDED"].includes(normalized);
}
