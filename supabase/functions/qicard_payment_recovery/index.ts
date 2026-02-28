// @ts-nocheck
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  buildCorrelationId,
  corsPreflightResponse,
  createBookingNotification,
  fetchBooking,
  jsonResponse,
  qicardGetPaymentStatus,
  recordBookingAudit,
  requireAuthenticatedUser,
  submitGatewayEscrowHold,
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
    const bookingId = String(body.booking_id || "");
    if (!bookingId) {
      return jsonResponse({ error: "booking_id is required" }, 400);
    }

    const booking = await fetchBooking(auth.adminClient, bookingId);
    if (booking.client_id !== auth.user.id) {
      return jsonResponse({ error: "Forbidden" }, 403);
    }

    const correlationId = buildCorrelationId(bookingId, "recover");

    if (booking.payment_status === "held") {
      await recordBookingAudit(auth.adminClient, {
        bookingId,
        eventType: "payment_recovery",
        correlationId,
        actorUserId: auth.user.id,
        outcome: "noop",
        payload: { reason: "already_held" },
      });
      return jsonResponse({
        booking_id: bookingId,
        booking_status: booking.status,
        payment_status: booking.payment_status,
        recovery_result: "already_held",
        correlation_id: correlationId,
      });
    }

    if (!booking.payment_gateway_id) {
      await recordBookingAudit(auth.adminClient, {
        bookingId,
        eventType: "payment_recovery",
        correlationId,
        actorUserId: auth.user.id,
        outcome: "noop",
        payload: { reason: "missing_payment_gateway_id" },
      });
      return jsonResponse({
        booking_id: bookingId,
        booking_status: booking.status,
        payment_status: booking.payment_status,
        recovery_result: "missing_payment_context",
        correlation_id: correlationId,
      });
    }

    const paymentStatus = await qicardGetPaymentStatus(booking.payment_gateway_id);
    if (!["SUCCESS", "COMPLETED"].includes(paymentStatus.status)) {
      await recordBookingAudit(auth.adminClient, {
        bookingId,
        eventType: "payment_recovery",
        correlationId,
        actorUserId: auth.user.id,
        outcome: "noop",
        payload: {
          reason: "payment_not_held",
          gateway_status: paymentStatus.status,
        },
      });
      return jsonResponse({
        booking_id: bookingId,
        booking_status: booking.status,
        payment_status: booking.payment_status,
        recovery_result: "no_action",
        correlation_id: correlationId,
      });
    }

    const escrowResult = await submitGatewayEscrowHold(auth.adminClient, {
      bookingId,
      paymentId: booking.payment_gateway_id,
      requestId: booking.payment_request_id || paymentStatus.requestId,
      amount: Number(booking.price || paymentStatus.amount || 0),
      currency: paymentStatus.currency || "IQD",
      timestamp: paymentStatus.createdAt,
      correlationId,
    });

    await recordBookingAudit(auth.adminClient, {
      bookingId,
      eventType: "payment_recovery",
      correlationId,
      actorUserId: auth.user.id,
      outcome: escrowResult.replayed ? "replayed" : "accepted",
      payload: {
        gateway_status: paymentStatus.status,
        journal_entry_id: escrowResult.journalEntryId,
      },
    });

    const refreshedBooking = await fetchBooking(auth.adminClient, bookingId);
    if (!escrowResult.replayed) {
      await createBookingNotification(auth.adminClient, {
        userId: refreshedBooking.provider_id,
        bookingId,
        title: "Booking Payment Secured",
        message: "Payment was secured for a booking request.",
        metadata: {
          booking_id: bookingId,
          status: refreshedBooking.status,
          payment_status: refreshedBooking.payment_status,
        },
      });
    }

    return jsonResponse({
      booking_id: bookingId,
      booking_status: refreshedBooking.status,
      payment_status: refreshedBooking.payment_status,
      recovery_result: escrowResult.replayed ? "idempotent_replay" : "hold_recorded",
      correlation_id: correlationId,
    });
  } catch (error) {
    console.error("Payment recovery error:", error);
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ error: message }, 500);
  }
});
