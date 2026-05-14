// @ts-nocheck
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  corsPreflightResponse,
  createAdminClient,
  jsonResponse,
  qicardGetPaymentStatus,
  requireAuthenticatedUser,
  submitDirectOfferGatewayEscrow,
} from "../_shared/booking_payment.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return corsPreflightResponse();
  }

  if (req.method !== "POST") {
    return jsonResponse({ code: "METHOD_NOT_ALLOWED", message: "Method not allowed" }, 405);
  }

  const auth = await requireAuthenticatedUser(req);
  if (auth.error) return auth.error;

  try {
    const body = await req.json();
    const offerId = String(body.offer_id || "").trim();
    const paymentRequestId = String(body.payment_request_id || "").trim();

    if (!offerId) {
      return jsonResponse(
        { code: "MISSING_OFFER_ID", message: "offer_id is required" },
        400,
      );
    }

    if (!paymentRequestId) {
      return jsonResponse(
        { code: "MISSING_PAYMENT_REQUEST_ID", message: "payment_request_id is required for recovery" },
        400,
      );
    }

    const { data: offer, error: offerError } = await auth.adminClient
      .from("direct_offers")
      .select("id, client_id, status, payment_status, price")
      .eq("id", offerId)
      .single();

    if (offerError || !offer) {
      return jsonResponse(
        { code: "OFFER_NOT_FOUND", message: offerError?.message || "Offer not found" },
        404,
      );
    }

    if (offer.client_id !== auth.user.id) {
      return jsonResponse(
        { code: "FORBIDDEN", message: "Only the client of this offer can recover payment" },
        403,
      );
    }

    if (offer.status === "active" && offer.payment_status === "held") {
      return jsonResponse({
        ok: true,
        recovered: false,
        message: "Offer already paid (idempotent)",
      });
    }

    if (offer.status !== "accepted" || offer.payment_status !== "unpaid") {
      return jsonResponse(
        { code: "INVALID_STATE", message: "Offer must be accepted and unpaid to recover" },
        400,
      );
    }

    const statusResult = await qicardGetPaymentStatus({
      paymentRequestId,
    });

    if (statusResult.status !== "SUCCESS") {
      return jsonResponse(
        {
          code: "PAYMENT_NOT_SUCCESS",
          message: `Payment status is ${statusResult.status}, cannot recover`,
        },
        400,
      );
    }

    const paymentId =
      (statusResult.raw?.paymentId as string) ||
      (statusResult.raw?.payment_id as string) ||
      paymentRequestId;
    const correlationId = `direct_offer:${offerId}:create`;

    await submitDirectOfferGatewayEscrow(auth.adminClient, {
      offerId,
      paymentId,
      requestId: paymentRequestId,
      amount: statusResult.amount,
      currency: statusResult.currency,
      timestamp: statusResult.createdAt,
      correlationId,
    });

    return jsonResponse({
      ok: true,
      recovered: true,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (
      message.includes("Gateway escrow not allowed") ||
      message.includes("must be accepted and unpaid")
    ) {
      return jsonResponse({
        ok: true,
        recovered: false,
        message: "Offer already updated (webhook or previous recovery)",
      });
    }
    console.error("Direct offer payment recovery error:", error);
    return jsonResponse(
      { code: "RECOVERY_FAILED", message },
      500,
    );
  }
});
