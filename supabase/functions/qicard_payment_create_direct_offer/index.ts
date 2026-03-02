// @ts-nocheck
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  corsPreflightResponse,
  jsonResponse,
  qicardCreatePayment,
  QICARD_FINISH_URL,
  requireAuthenticatedUser,
  resolveQiCardFinishUrl,
  withQueryParams,
} from "../_shared/bookin_payment.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return corsPreflightResponse();
  }

  if (req.method !== "POST") {
    return jsonResponse({ code: "METHOD_NOT_ALLOWED", message: "Method not allowed" }, 405);
  }

  const auth = await requireAuthenticatedUser(req);
  if (auth.error) return auth.error;

  let requestCorrelationId = `direct_offer_create:${crypto.randomUUID()}`;

  try {
    const body = await req.json();
    const providedRequestCorrelationId =
      typeof body.request_correlation_id === "string" &&
        body.request_correlation_id.trim().length > 0
        ? body.request_correlation_id.trim()
        : null;
    if (providedRequestCorrelationId) {
      requestCorrelationId = providedRequestCorrelationId;
    }

    const offerId = String(body.offer_id || "").trim();
    const amount = Number(body.amount);
    const requestedFinishUrl =
      typeof body.finish_url === "string" && body.finish_url.trim().length > 0
        ? body.finish_url.trim()
        : null;

    if (!offerId) {
      return jsonResponse(
        { code: "MISSING_OFFER_ID", message: "offer_id is required", request_correlation_id: requestCorrelationId },
        400,
      );
    }

    if (!Number.isFinite(amount) || amount <= 0) {
      return jsonResponse(
        { code: "INVALID_AMOUNT", message: "amount must be a positive number", request_correlation_id: requestCorrelationId },
        400,
      );
    }

    const { data: offer, error: offerError } = await auth.adminClient
      .from("direct_offers")
      .select("id, client_id, freelancer_id, status, payment_status, price")
      .eq("id", offerId)
      .single();

    if (offerError || !offer) {
      return jsonResponse(
        { code: "OFFER_NOT_FOUND", message: offerError?.message || "Offer not found", request_correlation_id: requestCorrelationId },
        404,
      );
    }

    if (offer.client_id !== auth.user.id) {
      return jsonResponse(
        { code: "FORBIDDEN", message: "Only the client of this offer can create payment", request_correlation_id: requestCorrelationId },
        403,
      );
    }

    if (offer.status !== "accepted" || offer.payment_status !== "unpaid") {
      return jsonResponse(
        { code: "INVALID_STATE", message: "Offer must be accepted and unpaid to pay", request_correlation_id: requestCorrelationId },
        400,
      );
    }

    const correlationId = `direct_offer:${offerId}:create`;
    const paymentRequestId = crypto.randomUUID();
    const finishPaymentUrl = withQueryParams(
      resolveQiCardFinishUrl(req, requestedFinishUrl ?? QICARD_FINISH_URL),
      {
        offer_id: offerId,
        correlation_id: correlationId,
        payment_request_id: paymentRequestId,
      },
    );

    const payment = await qicardCreatePayment({
      requestId: paymentRequestId,
      amount,
      currency: "IQD",
      description: `SLine direct offer ${offerId}`,
      finishPaymentUrl,
      additionalInfo: {
        offer_id: offerId,
        client_id: auth.user.id,
        correlation_id: correlationId,
      },
    });

    if (!payment.formUrl) {
      throw new Error("QICARD_FORM_URL_MISSING");
    }

    return jsonResponse({
      offer_id: offerId,
      form_url: payment.formUrl,
      correlation_id: correlationId,
      payment_request_id: paymentRequestId,
      amount,
      request_correlation_id: requestCorrelationId,
    });
  } catch (error) {
    console.error("Direct offer payment create error:", {
      request_correlation_id: requestCorrelationId,
      error,
    });
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse(
      { code: "PAYMENT_CREATE_FAILED", message, request_correlation_id: requestCorrelationId },
      500,
    );
  }
});
