// @ts-nocheck
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  corsPreflightResponse,
  jsonResponse,
  qicardGetPaymentStatus,
  requireAuthenticatedUser,
  submitTenderGatewayEscrow,
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
    const requestId = String(body.request_id || "").trim();
    const paymentRequestId = String(body.payment_request_id || "").trim();

    if (!requestId) {
      return jsonResponse(
        { code: "MISSING_REQUEST_ID", message: "request_id is required" },
        400,
      );
    }

    if (!paymentRequestId) {
      return jsonResponse(
        { code: "MISSING_PAYMENT_REQUEST_ID", message: "payment_request_id is required for recovery" },
        400,
      );
    }

    const { data: taskRequest, error: trError } = await auth.adminClient
      .from("task_requests")
      .select("id, task_id, status, payment_status")
      .eq("id", requestId)
      .single();

    if (trError || !taskRequest) {
      return jsonResponse(
        { code: "TASK_REQUEST_NOT_FOUND", message: trError?.message || "Task request not found" },
        404,
      );
    }

    const { data: task, error: taskError } = await auth.adminClient
      .from("tasks")
      .select("id, owner_id")
      .eq("id", taskRequest.task_id)
      .single();

    if (taskError || !task) {
      return jsonResponse(
        { code: "TASK_NOT_FOUND", message: taskError?.message || "Task not found" },
        404,
      );
    }

    if (task.owner_id !== auth.user.id) {
      return jsonResponse(
        { code: "FORBIDDEN", message: "Only the task owner (client) can recover payment" },
        403,
      );
    }

    if (taskRequest.payment_status === "held") {
      return jsonResponse({
        ok: true,
        recovered: false,
        message: "Tender already paid (idempotent)",
      });
    }

    if (taskRequest.status !== "accepted" || taskRequest.payment_status !== "unpaid") {
      return jsonResponse(
        { code: "INVALID_STATE", message: "Tender must be awarded and unpaid to recover" },
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
    const correlationId = `tender:${requestId}:create`;

    await submitTenderGatewayEscrow(auth.adminClient, {
      requestId,
      paymentId,
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
      message.includes("must be awarded and unpaid")
    ) {
      return jsonResponse({
        ok: true,
        recovered: false,
        message: "Tender already updated (webhook or previous recovery)",
      });
    }
    console.error("Tender payment recovery error:", error);
    return jsonResponse(
      { code: "RECOVERY_FAILED", message },
      500,
    );
  }
});
