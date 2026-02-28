// @ts-nocheck
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  BOOKING_PAYMENT_EXPIRY_MINUTES,
  buildCorrelationId,
  corsPreflightResponse,
  fetchBooking,
  jsonResponse,
  qicardCreatePayment,
  QICARD_FINISH_URL,
  recordBookingAudit,
  requireAuthenticatedUser,
  withQueryParams,
} from "../_shared/bookin_payment.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return corsPreflightResponse();
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const auth = await requireAuthenticatedUser(req);
  if (auth.error) return auth.error;

  try {
    const body = await req.json();
    const taskId = String(body.task_id || "");
    const note = typeof body.note === "string" ? body.note : null;
    const packageId = typeof body.package_id === "string" ? body.package_id : null;
    const requirements =
      body.requirements && typeof body.requirements === "object"
        ? body.requirements
        : {};

    if (!taskId) {
      return jsonResponse({ error: "task_id is required" }, 400);
    }

    const { data: booking, error } = await auth.userClient.rpc(
      "rpc_create_booking_draft_validated",
      {
        p_task_id: taskId,
        p_note: note,
        p_package_id: packageId,
        p_requirements: requirements,
      },
    );

    if (error || !booking) {
      return jsonResponse(
        { error: error?.message || "BOOKING_DRAFT_CREATE_FAILED" },
        400,
      );
    }

    const bookingId = String(booking.id);
    const correlationId = buildCorrelationId(bookingId, "create");
    const paymentRequestId = crypto.randomUUID();
    const finishPaymentUrl = withQueryParams(QICARD_FINISH_URL, {
      booking_id: bookingId,
      correlation_id: correlationId,
    });
    const amount = Number(booking.price || 0);
    const expiresAt = new Date(
      Date.now() + BOOKING_PAYMENT_EXPIRY_MINUTES * 60 * 1000,
    ).toISOString();

    const payment = await qicardCreatePayment({
      requestId: paymentRequestId,
      amount,
      currency: "IQD",
      description: `SLine booking ${bookingId}`,
      finishPaymentUrl,
      additionalInfo: {
        booking_id: bookingId,
        client_id: auth.user.id,
        correlation_id: correlationId,
      },
    });

    if (!payment.formUrl) {
      throw new Error("QICARD_FORM_URL_MISSING");
    }

    const { data: linkedBooking, error: linkError } = await auth.adminClient
      .from("bookings")
      .update({
        payment_request_id: paymentRequestId,
        payment_gateway_id: payment.paymentId,
        payment_correlation_id: correlationId,
        payment_expires_at: expiresAt,
      })
      .eq("id", bookingId)
      .select("id")
      .single();

    if (linkError || !linkedBooking) {
      await recordBookingAudit(auth.adminClient, {
        bookingId,
        eventType: "payment_create",
        correlationId,
        actorUserId: auth.user.id,
        outcome: "rejected",
        payload: {
          stage: "persist_payment_context",
          payment_request_id: paymentRequestId,
          payment_gateway_id: payment.paymentId,
          error: linkError?.message || "BOOKING_PAYMENT_CONTEXT_PERSIST_FAILED",
        },
      });
      throw new Error(linkError?.message || "BOOKING_PAYMENT_CONTEXT_PERSIST_FAILED");
    }

    await recordBookingAudit(auth.adminClient, {
      bookingId,
      eventType: "payment_create",
      correlationId,
      actorUserId: auth.user.id,
      outcome: "accepted",
      payload: {
        payment_request_id: paymentRequestId,
        payment_gateway_id: payment.paymentId,
        amount,
        expires_at: expiresAt,
      },
    });

    const refreshedBooking = await fetchBooking(auth.adminClient, bookingId);

    return jsonResponse({
      booking_id: bookingId,
      payment_request_id: paymentRequestId,
      form_url: payment.formUrl,
      amount,
      provider_id: refreshedBooking.provider_id,
      expires_at: expiresAt,
      correlation_id: correlationId,
    });
  } catch (error) {
    console.error("Payment create error:", error);
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ error: message }, 500);
  }
});
