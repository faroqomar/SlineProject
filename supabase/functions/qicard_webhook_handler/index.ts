// @ts-nocheck
// deno-lint-ignore-file
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import * as crypto from "node:crypto";

// Type definitions for QiCard webhook payload
interface QiCardPaymentPayload {
  paymentId: string;
  requestId: string;
  status: string;
  amount?: number;
  currency?: string;
  creationDate?: string;
  additionalInfo?: {
    booking_id?: string;
    client_id?: string;
    [key: string]: unknown;
  };
}

interface QiCardLegacyPayload {
  event_type?: string;
  event_id?: string;
  psp_event_id?: string;
  payment_id?: string;
  psp_payment_id?: string;
  request_id?: string;
  psp_request_id?: string;
  status?: string;
  amount?: number;
  currency?: string;
  timestamp?: string;
  user_id?: string;
  related_entity_id?: string;
  [key: string]: unknown;
}

interface RpcResponse {
  ok: boolean;
  journal_entry_id?: string;
  error?: {
    code: string;
    message: string;
  };
}

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
const QICARD_PROVIDER_NAME = Deno.env.get("QICARD_PROVIDER_NAME") || "qicard";
const QICARD_RSA_PUBLIC_KEY_PEM =
  Deno.env.get("QICARD_RSA_PUBLIC_KEY_PEM") || "";

// Service-role client: auth.uid() is null inside RPC (system actor).
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

interface MappedEvent {
  ledgerEventType: string;
  relatedEntityType: string;
}

function verifySignature(
  signedData: string,
  signatureBase64: string,
  publicKeyPem: string,
): boolean {
  if (!publicKeyPem) {
    // Security: Fail closed in production, allow in development
    const isProduction = Deno.env.get("ENVIRONMENT") === "production";
    if (isProduction) {
      console.error("QICARD_RSA_PUBLIC_KEY_PEM required in production");
      return false;
    }
    console.warn("QICARD_RSA_PUBLIC_KEY_PEM not set - skipping signature check (dev only)");
    return true;
  }

  try {
    const verifier = crypto.createVerify("SHA256");
    verifier.update(signedData);
    verifier.end();
    return verifier.verify(publicKeyPem, signatureBase64, "base64");
  } catch (err) {
    console.error("Signature verification error:", err);
    return false;
  }
}

function formatAmount3(amount: unknown): string {
  const parsed = Number(amount);
  if (!Number.isFinite(parsed)) {
    return "0.000";
  }
  return parsed.toFixed(3);
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function isQiCardPaymentPayload(payload: Record<string, unknown>): payload is QiCardPaymentPayload {
  return typeof payload.paymentId === "string" &&
    typeof payload.requestId === "string" &&
    typeof payload.status === "string";
}

function buildQiCardWebhookSignatureString(payload: Record<string, unknown>): string {
  const paymentId = String(payload.paymentId || "");
  const amount = formatAmount3(payload.amount);
  const currency = String(payload.currency || "IQD");
  const creationDate = String(payload.creationDate || "");
  const status = String(payload.status || "");
  return `${paymentId}|${amount}|${currency}|${creationDate}|${status}`;
}

function mapLegacyQiCardEvent(eventType: string, pspStatus: string): MappedEvent | null {
  if (
    eventType === "deposit_success" ||
    (eventType === "deposit" && pspStatus === "success")
  ) {
    return { ledgerEventType: "deposit", relatedEntityType: "admin_adjustment" };
  }

  if (
    eventType === "withdrawal_success" ||
    (eventType === "withdrawal" && pspStatus === "success")
  ) {
    return {
      ledgerEventType: "withdrawal_complete",
      relatedEntityType: "withdrawal_request",
    };
  }

  if (
    eventType === "withdrawal_failure" ||
    (eventType === "withdrawal" && pspStatus === "failed")
  ) {
    return {
      ledgerEventType: "withdrawal_failed",
      relatedEntityType: "withdrawal_request",
    };
  }

  return null;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const signatureHeader = req.headers.get("x-signature") || "";
    const rawBody = await req.text();

    let payload: Record<string, unknown>;
    try {
      payload = JSON.parse(rawBody);
    } catch {
      return jsonResponse({ error: "Invalid JSON payload" }, 400);
    }

    const isPaymentPayload = isQiCardPaymentPayload(payload);
    const signedData = isPaymentPayload
      ? buildQiCardWebhookSignatureString(payload)
      : rawBody;

    if (
      QICARD_RSA_PUBLIC_KEY_PEM &&
      !verifySignature(signedData, signatureHeader, QICARD_RSA_PUBLIC_KEY_PEM)
    ) {
      console.error("Webhook rejected: invalid signature");
      return jsonResponse({ error: "Invalid signature" }, 401);
    }

    if (isPaymentPayload) {
      return await handleQiCardPaymentWebhook(payload);
    }

    return await handleLegacyQiCardWebhook(payload);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("Webhook processing error:", msg);
    return jsonResponse({ error: "Internal processing error" }, 500);
  }
});

async function handleQiCardPaymentWebhook(
  payload: QiCardPaymentPayload,
): Promise<Response> {
  const paymentId = payload.paymentId || "";
  const requestId = payload.requestId || "";
  const status = (payload.status || "").toUpperCase();
  const amount = Number(payload.amount) || 0;
  const currency = payload.currency || "IQD";
  const creationDate = payload.creationDate || new Date().toISOString();
  const additionalInfo = payload.additionalInfo || {};
  const bookingId = additionalInfo.booking_id || "";

  if (!paymentId || !requestId || !status) {
    return jsonResponse({ error: "Missing required payment webhook fields" }, 400);
  }

  if (status !== "SUCCESS") {
    console.log(
      `Ignoring non-success payment status=${status} paymentId=${paymentId}`,
    );
    return jsonResponse({ ok: true, message: "Ignored non-success status" }, 200);
  }

  if (!bookingId || !isUuid(bookingId)) {
    console.warn(
      `Skipping webhook: invalid additionalInfo.booking_id paymentId=${paymentId}`,
    );
    return jsonResponse(
      { ok: true, message: "Missing or invalid booking_id. Skipped safely." },
      200,
    );
  }

  const idempotencyKey = `qicard:${paymentId}:gateway_escrow:${status}`;
  const meta: Record<string, unknown> = {
    psp_provider: QICARD_PROVIDER_NAME,
    psp_event_id: requestId,
    psp_payment_id: paymentId,
    psp_request_id: requestId,
    psp_status: status,
    psp_timestamp: creationDate,
    booking_id: bookingId,
  };

  const { data, error } = await supabase.rpc("process_payment_event_ledger", {
    p_event_type: "gateway_escrow",
    p_related_entity_type: "booking",
    p_related_entity_id: bookingId,
    p_idempotency_key: idempotencyKey,
    p_amount_gross: amount,
    p_currency: currency,
    p_meta: meta,
  });

  if (error) {
    console.error("Ledger RPC failed [gateway_escrow]:", error.message);
    if (error.message?.includes("ERR_IDEMPOTENCY_REPLAY")) {
      return jsonResponse({ ok: true, message: "Idempotent replay" }, 200);
    }
    return jsonResponse({ error: error.message }, 400);
  }

  if (data?.ok === false) {
    return jsonResponse({ error: data.error || "Ledger RPC rejected event" }, 400);
  }

  console.log(`gateway_escrow recorded: journal=${data?.journal_entry_id}`);
  return jsonResponse({ ok: true, journal_entry_id: data?.journal_entry_id }, 200);
}

async function handleLegacyQiCardWebhook(
  payload: QiCardLegacyPayload,
): Promise<Response> {
  const eventType = payload.event_type || "";
  const pspEventId = payload.psp_event_id || payload.event_id || "";
  const pspPaymentId = payload.payment_id || "";
  const pspRequestId = payload.request_id || "";
  const pspStatus = (payload.status || "").toLowerCase();
  const amount = Number(payload.amount) || 0;
  const currency = payload.currency || "IQD";
  const pspTimestamp = payload.timestamp || new Date().toISOString();
  const userId = payload.user_id || "";

  const mapped = mapLegacyQiCardEvent(eventType, pspStatus);
  if (!mapped) {
    return jsonResponse({ ok: true, message: "Ignored event type/status" }, 200);
  }

  const idempotencyKey = `qicard:${pspPaymentId}:${mapped.ledgerEventType}:${pspStatus}`;
  const meta: Record<string, unknown> = {
    psp_provider: QICARD_PROVIDER_NAME,
    psp_event_id: pspEventId,
    psp_payment_id: pspPaymentId,
    psp_request_id: pspRequestId,
    psp_status: pspStatus,
    psp_timestamp: pspTimestamp,
  };
  if (mapped.ledgerEventType === "deposit" && userId) {
    meta.user_id = userId;
  }

  const relatedEntityId = String(
    payload.related_entity_id || pspRequestId || pspPaymentId,
  );

  const { data, error } = await supabase.rpc("process_payment_event_ledger", {
    p_event_type: mapped.ledgerEventType,
    p_related_entity_type: mapped.relatedEntityType,
    p_related_entity_id: relatedEntityId,
    p_idempotency_key: idempotencyKey,
    p_amount_gross: amount,
    p_currency: currency,
    p_meta: meta,
  });

  if (error) {
    console.error(`Ledger RPC failed [${mapped.ledgerEventType}]:`, error.message);
    if (error.message?.includes("ERR_IDEMPOTENCY_REPLAY")) {
      return jsonResponse({ ok: true, message: "Idempotent replay" }, 200);
    }
    return jsonResponse({ error: error.message }, 400);
  }

  if (data?.ok === false) {
    return jsonResponse({ error: data.error || "Ledger RPC rejected event" }, 400);
  }

  return jsonResponse({ ok: true, journal_entry_id: data?.journal_entry_id }, 200);
}

function jsonResponse(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Connection": "keep-alive",
    },
  });
}
