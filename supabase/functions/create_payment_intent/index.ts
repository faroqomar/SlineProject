// @ts-nocheck
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  BOOKING_PAYMENT_EXPIRY_MINUTES,
  buildCorrelationId,
  corsPreflightResponse,
  jsonResponse,
  qicardCreatePayment,
  recordBookingAudit,
  requireAuthenticatedUser,
  withQueryParams,
  resolveQiCardFinishUrl,
} from "../_shared/booking_payment.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return corsPreflightResponse();
  if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);

  const auth = await requireAuthenticatedUser(req);
  if (auth.error) return auth.error;

  try {
    const { entity_type, entity_id, success_url, cancel_url } = await req.json();

    if (!entity_type || !entity_id) {
      return jsonResponse({ error: "entity_type and entity_id are required" }, 400);
    }
    if (!['task', 'booking', 'direct_offer'].includes(entity_type)) {
      return jsonResponse({ error: "Invalid entity_type" }, 400);
    }

    // Fetch the correct price from the database
    let price = 0;
    let receiverId = null;

    if (entity_type === 'task') {
      const { data, error } = await auth.adminClient.from('tasks').select('budget, user_id').eq('id', entity_id).single();
      if (error || !data) throw new Error("Task not found");
      price = Number(data.budget);
      receiverId = data.user_id; // Usually tasks are funded to an escrow implicitly, but receiver is usually the one performing
      // If task is being funded for tender, there is no specific receiver yet other than the task itself. Let's use payer's id for now as the receiver of the initial escrow hold is the platform/themselves until release.
      receiverId = auth.user.id;
    } else if (entity_type === 'booking') {
      const { data, error } = await auth.adminClient.from('bookings').select('price, provider_id').eq('id', entity_id).single();
      if (error || !data) throw new Error("Booking not found");
      price = Number(data.price);
      receiverId = data.provider_id;
    } else if (entity_type === 'direct_offer') {
      const { data, error } = await auth.adminClient.from('direct_offers').select('price, freelancer_id').eq('id', entity_id).single();
      if (error || !data) throw new Error("Direct offer not found");
      price = Number(data.price);
      receiverId = data.freelancer_id;
    }

    if (price <= 0) {
      return jsonResponse({ error: "Invalid price for entity" }, 400);
    }

    // Hardcode fee_rate_locked to 0 for now as per minimal viable. Can be fetched from platform_settings.
    let feeRateLocked = 0;

    const idempotencyKey = crypto.randomUUID();
    
    // Insert intent into payment_intents
    const { data: intent, error: intentError } = await auth.adminClient.from('payment_intents').insert({
      entity_type,
      entity_id,
      payer_id: auth.user.id,
      receiver_id: receiverId,
      gross_amount: price,
      fee_rate_locked: feeRateLocked,
      idempotency_key: idempotencyKey,
      status: 'created'
    }).select('id').single();

    if (intentError || !intent) {
      throw new Error(`Failed to create intent: ${intentError?.message}`);
    }

    const intentId = intent.id;

    // Keep customer-facing return URLs sanitized; internal IDs stay in
    // additionalInfo and server logs for webhook/recovery correlation.
    const baseFinishUrl = resolveQiCardFinishUrl(req, success_url || null) || "https://sline.app/?payment_return=1";
    const correlationId = entity_type === "booking"
      ? buildCorrelationId(entity_id, "create")
      : `intent:${intentId}`;
    const finishParams: Record<string, string> = { payment_return: "1" };
    const finishPaymentUrl = withQueryParams(baseFinishUrl, finishParams);

    // Build additionalInfo for QiCard — webhook expects booking_id for booking flow
    const additionalInfo: Record<string, unknown> = {
      intent_id: intentId,
      entity_id,
      entity_type,
      payer_id: auth.user.id,
      correlation_id: correlationId,
    };
    if (entity_type === "booking") {
      additionalInfo.booking_id = entity_id;
      additionalInfo.client_id = auth.user.id;
    } else if (entity_type === "direct_offer") {
      additionalInfo.offer_id = entity_id;
    } else if (entity_type === "task") {
      additionalInfo.request_id = entity_id;
    }

    // Build the QiCard gateway intent
    const paymentRequestId = crypto.randomUUID();
    additionalInfo.payment_request_id = paymentRequestId;
    const payment = await qicardCreatePayment({
      requestId: paymentRequestId,
      amount: price,
      currency: "IQD",
      description: `Payment for ${entity_type} ${entity_id}`,
      finishPaymentUrl,
      additionalInfo,
    });

    if (!payment.formUrl) {
      throw new Error("Failed to get checkout URL from gateway");
    }

    // Update intent with gateway ID
    await auth.adminClient.from('payment_intents').update({
      gateway_intent_id: payment.paymentId,
      status: 'gateway_processing'
    }).eq('id', intentId);

    // For booking: persist payment context on booking so qicard_payment_recovery can work
    if (entity_type === "booking") {
      const expiresAt = new Date(
        Date.now() + BOOKING_PAYMENT_EXPIRY_MINUTES * 60 * 1000,
      ).toISOString();
      const { error: linkError } = await auth.adminClient
        .from("bookings")
        .update({
          payment_request_id: paymentRequestId,
          payment_gateway_id: payment.paymentId,
          payment_correlation_id: correlationId,
          payment_expires_at: expiresAt,
        })
        .eq("id", entity_id);

      if (linkError) {
        await recordBookingAudit(auth.adminClient, {
          bookingId: entity_id,
          eventType: "payment_create",
          correlationId,
          actorUserId: auth.user.id,
          outcome: "rejected",
          payload: {
            stage: "persist_payment_context",
            payment_request_id: paymentRequestId,
            payment_gateway_id: payment.paymentId,
            error: linkError.message,
          },
        });
        throw new Error(linkError.message || "BOOKING_PAYMENT_CONTEXT_PERSIST_FAILED");
      }

      await recordBookingAudit(auth.adminClient, {
        bookingId: entity_id,
        eventType: "payment_create",
        correlationId,
        actorUserId: auth.user.id,
        outcome: "accepted",
        payload: {
          payment_request_id: paymentRequestId,
          payment_gateway_id: payment.paymentId,
          amount: price,
          expires_at: expiresAt,
        },
      });
    }

    return jsonResponse({
      intent_id: intentId,
      checkout_url: payment.formUrl
    });

  } catch (err: any) {
    console.error("create_payment_intent error:", err);
    return jsonResponse({ error: err.message || "Internal server error" }, 500);
  }
});
