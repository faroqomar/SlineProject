// @ts-nocheck
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import * as crypto from "node:crypto";
import {
  corsPreflightResponse,
  createAdminClient,
  jsonResponse,
  submitGatewayEscrowHold,
  submitDirectOfferGatewayEscrow,
  submitTenderGatewayEscrow,
} from "../_shared/booking_payment.ts";

const QICARD_RSA_PUBLIC_KEY_PEM = Deno.env.get("QICARD_RSA_PUBLIC_KEY_PEM") || "";
const QICARD_ALLOW_UNSIGNED_LOCAL_DEV = Deno.env.get("QICARD_ALLOW_UNSIGNED_LOCAL_DEV") === "true";
const supabase = createAdminClient();

function verifySignature(signedData: string, signatureBase64: string, publicKeyPem: string): boolean {
  if (!publicKeyPem) return QICARD_ALLOW_UNSIGNED_LOCAL_DEV;
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
  if (amount == null || amount === "") return "-";
  const parsed = Number(amount);
  return !Number.isFinite(parsed) ? "-" : parsed.toFixed(3);
}

function formatSignatureField(value: unknown): string {
  if (value == null) return "-";
  const normalized = String(value).trim();
  return normalized.length === 0 ? "-" : normalized;
}

function buildQiCardWebhookSignatureString(payload: Record<string, unknown>): string {
  const paymentId = formatSignatureField(payload.paymentId);
  const amount = formatAmount3(payload.amount);
  const currency = formatSignatureField(payload.currency);
  const creationDate = formatSignatureField(payload.creationDate ?? payload.createdDate);
  const status = formatSignatureField(payload.status);
  return `${paymentId}|${amount}|${currency}|${creationDate}|${status}`;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return corsPreflightResponse();
  if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);

  const signatureHeader = (req.headers.get("x-signature") || req.headers.get("signature") || "").trim();
  const rawBody = await req.text();
  let payload: Record<string, unknown>;

  try {
    payload = JSON.parse(rawBody);
  } catch {
    return jsonResponse({ error: "Invalid JSON payload" }, 400);
  }

  // Signature validation
  const signatureCandidates = Array.from(new Set([buildQiCardWebhookSignatureString(payload), rawBody].filter(v => v.length > 0)));
  
  if (!signatureHeader && !QICARD_ALLOW_UNSIGNED_LOCAL_DEV) {
    return jsonResponse({ error: "Missing signature" }, 401);
  }

  const hasValidSignature = signatureCandidates.some(candidate =>
    verifySignature(candidate, signatureHeader, QICARD_RSA_PUBLIC_KEY_PEM)
  );

  if (!hasValidSignature) {
    console.error("Webhook rejected: invalid signature", { payload });
    return jsonResponse({ error: "Invalid signature" }, 401);
  }

  const paymentId = payload.paymentId ? String(payload.paymentId) : "";
  const requestId = payload.requestId ? String(payload.requestId) : "";
  const status = String(payload.status || "").toUpperCase();
  const amount = Number(payload.amount) || 0;
  const currency = String(payload.currency || "IQD");
  const creationDate = String(payload.creationDate || new Date().toISOString());
  const additionalInfo = payload.additionalInfo || {};
  
  const intentId = additionalInfo.intent_id ? String(additionalInfo.intent_id) : "";

  if (!paymentId || !status || !intentId) {
    // Log orphan payment
    await supabase.from('orphan_payments').insert({
      gateway_event_id: paymentId || requestId || "unknown",
      error_reason: "Missing intent_id or paymentId in payload",
      payload: payload
    });
    return jsonResponse({ error: "Missing intent mapping information" }, 400);
  }

  if (status !== "SUCCESS") {
    console.log(`Ignoring non-success payment status=${status} paymentId=${paymentId}`);
    return jsonResponse({ ok: true, message: "Ignored non-success status" }, 200);
  }

  try {
    // 1. Fetch intent
    const { data: intent, error: intentError } = await supabase.from('payment_intents').select('*').eq('id', intentId).single();
    if (intentError || !intent) {
      await supabase.from('orphan_payments').insert({
        gateway_event_id: paymentId,
        error_reason: "Intent not found",
        payload: payload
      });
      throw new Error(`Intent ${intentId} not found`);
    }

    // Idempotency check: if intent is already succeeded, ack it safely
    if (intent.status === 'succeeded') {
      return jsonResponse({ ok: true, message: "Intent already succeeded" }, 200);
    }

    // 2. Track Event
    await supabase.from('payment_events').insert({
      gateway_event_id: paymentId,
      intent_id: intentId,
      event_type: 'webhook_success',
      payload: payload
    });

    // 3. Ledger Processing based on entity_type
    const correlationId = `intent:${intentId}:success`;
    let escrowResult;

    if (intent.entity_type === 'booking') {
      escrowResult = await submitGatewayEscrowHold(supabase, {
        bookingId: intent.entity_id,
        paymentId,
        requestId,
        amount,
        currency,
        timestamp: creationDate,
        correlationId
      });
    } else if (intent.entity_type === 'direct_offer') {
      escrowResult = await submitDirectOfferGatewayEscrow(supabase, {
        offerId: intent.entity_id,
        paymentId,
        requestId,
        amount,
        currency,
        timestamp: creationDate,
        correlationId
      });
    } else if (intent.entity_type === 'task') {
      // tender
      escrowResult = await submitTenderGatewayEscrow(supabase, {
        requestId: intent.entity_id,
        paymentId,
        amount,
        currency,
        timestamp: creationDate,
        correlationId
      });
    }

    // 4. Update intent to succeeded so RT clients know
    await supabase.from('payment_intents').update({
      status: 'succeeded'
    }).eq('id', intentId);

    return jsonResponse({
      ok: true,
      journal_entry_id: escrowResult?.journalEntryId,
      replayed: escrowResult?.replayed,
    }, 200);

  } catch (error: any) {
    console.error("Webhook processing error:", error);
    
    await supabase.from('orphan_payments').insert({
      gateway_event_id: paymentId,
      error_reason: error.message || "Failed to process hook",
      payload: payload
    });

    return jsonResponse({ error: error.message || "Ledger Escrow Rejected" }, 400);
  }
});
