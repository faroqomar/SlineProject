// @ts-nocheck
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  buildCorrelationId,
  corsPreflightResponse,
  createBookingNotification,
  fetchBooking,
  isTerminalRefundStatus,
  jsonResponse,
  qicardRefundPayment,
  recordBookingAudit,
  requireAuthenticatedUser,
} from "../_shared/booking_payment.ts";

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
    const reason =
      typeof body.reason === "string" && body.reason.trim().length > 0
        ? body.reason.trim()
        : "Booking declined";

    if (!bookingId) {
      return jsonResponse({ error: "booking_id is required" }, 400);
    }

    const booking = await fetchBooking(auth.adminClient, bookingId);
    const correlationId = buildCorrelationId(bookingId, "refund");
    const isClient = booking.client_id === auth.user.id;
    const isProvider = booking.provider_id === auth.user.id;

    if (!isClient && !isProvider) {
      return jsonResponse({ error: "Forbidden" }, 403);
    }

    if (
      booking.status === "refunded" ||
      booking.payment_status === "refunded"
    ) {
      return jsonResponse({
        booking_id: bookingId,
        booking_status: booking.status,
        payment_status: booking.payment_status,
        refund_result: "already_refunded",
        correlation_id: correlationId,
      });
    }

    if (booking.payment_status === "unpaid") {
      const nextStatus = isClient ? "canceled" : "canceled";
      await auth.adminClient
        .from("bookings")
        .update({ status: nextStatus })
        .eq("id", bookingId);

      await recordBookingAudit(auth.adminClient, {
        bookingId,
        eventType: "booking_cancel_unpaid",
        correlationId,
        actorUserId: auth.user.id,
        outcome: "accepted",
        payload: { reason },
      });

      const refreshedBooking = await fetchBooking(auth.adminClient, bookingId);
      await createBookingNotification(auth.adminClient, {
        userId: isClient ? booking.provider_id : booking.client_id,
        bookingId,
        title: "Booking Updated",
        message: "A booking was canceled before payment was captured.",
        metadata: {
          booking_id: bookingId,
          status: refreshedBooking.status,
          payment_status: refreshedBooking.payment_status,
        },
      });
      return jsonResponse({
        booking_id: bookingId,
        booking_status: refreshedBooking.status,
        payment_status: refreshedBooking.payment_status,
        refund_result: "canceled_unpaid",
        correlation_id: correlationId,
      });
    }

    if (!isProvider) {
      return jsonResponse(
        { error: "Only the provider can decline a held booking." },
        403,
      );
    }

    if (!booking.payment_gateway_id) {
      return jsonResponse(
        { error: "Missing payment gateway id for held booking." },
        409,
      );
    }

    const refund = await qicardRefundPayment({
      paymentId: booking.payment_gateway_id,
      amount: Number(booking.price || 0),
      currency: "IQD",
      reason,
    });

    if (!isTerminalRefundStatus(refund.status)) {
      await recordBookingAudit(auth.adminClient, {
        bookingId,
        eventType: "booking_decline_refund",
        correlationId,
        actorUserId: auth.user.id,
        outcome: "pending",
        payload: {
          refund_id: refund.refundId,
          refund_status: refund.status,
          reason,
        },
      });
      return jsonResponse(
        {
          error: "Refund was accepted by the gateway but not finalized yet.",
          refund_status: refund.status,
          correlation_id: correlationId,
        },
        409,
      );
    }

    const { data: refundedBooking, error } = await auth.adminClient.rpc(
      "rpc_finalize_booking_refund",
      {
        p_booking_id: bookingId,
        p_reason: reason,
        p_correlation_id: correlationId,
      },
    );

    if (error || !refundedBooking) {
      return jsonResponse(
        { error: error?.message || "REFUND_FINALIZE_FAILED" },
        500,
      );
    }

    await recordBookingAudit(auth.adminClient, {
      bookingId,
      eventType: "booking_decline_refund",
      correlationId,
      actorUserId: auth.user.id,
      outcome: "accepted",
      payload: {
        refund_id: refund.refundId,
        refund_status: refund.status,
        reason,
      },
    });

    await createBookingNotification(auth.adminClient, {
      userId: booking.client_id,
      bookingId,
      title: "Booking Refunded",
      message: "A held booking was declined and refunded.",
      metadata: {
        booking_id: bookingId,
        status: refundedBooking.status,
        payment_status: refundedBooking.payment_status,
      },
    });

    return jsonResponse({
      booking_id: refundedBooking.id,
      booking_status: refundedBooking.status,
      payment_status: refundedBooking.payment_status,
      refund_result: refund.status || "REFUNDED",
      correlation_id: correlationId,
    });
  } catch (error) {
    console.error("Refund processing error:", error);
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ error: message }, 500);
  }
});
