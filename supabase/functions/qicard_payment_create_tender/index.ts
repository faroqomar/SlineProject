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

  let requestCorrelationId = `tender_create:${crypto.randomUUID()}`;

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

    const requestId = String(body.request_id || "").trim();
    const amount = Number(body.amount);
    const currency =
      typeof body.currency === "string" && body.currency.trim().length > 0
        ? body.currency.trim()
        : "IQD";
    const requestedFinishUrl =
      typeof body.finish_url === "string" && body.finish_url.trim().length > 0
        ? body.finish_url.trim()
        : null;

    if (!requestId) {
      return jsonResponse(
        { code: "MISSING_REQUEST_ID", message: "request_id is required", request_correlation_id: requestCorrelationId },
        400,
      );
    }

    if (!Number.isFinite(amount) || amount <= 0) {
      return jsonResponse(
        { code: "INVALID_AMOUNT", message: "amount must be a positive number", request_correlation_id: requestCorrelationId },
        400,
      );
    }

    const { data: taskRequest, error: trError } = await auth.adminClient
      .from("task_requests")
      .select("id, task_id, freelancer_id, status, payment_status, price, payment_deadline")
      .eq("id", requestId)
      .single();

    if (trError || !taskRequest) {
      return jsonResponse(
        { code: "TASK_REQUEST_NOT_FOUND", message: trError?.message || "Task request not found", request_correlation_id: requestCorrelationId },
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
        { code: "TASK_NOT_FOUND", message: taskError?.message || "Task not found", request_correlation_id: requestCorrelationId },
        404,
      );
    }

    if (task.owner_id !== auth.user.id) {
      return jsonResponse(
        { code: "FORBIDDEN", message: "Only the task owner (client) can create payment for this tender", request_correlation_id: requestCorrelationId },
        403,
      );
    }

    if (taskRequest.status !== "accepted" || taskRequest.payment_status !== "unpaid") {
      return jsonResponse(
        { code: "INVALID_STATE", message: "Tender must be awarded and unpaid to pay", request_correlation_id: requestCorrelationId },
        400,
      );
    }

    const paymentDeadline = taskRequest.payment_deadline
      ? new Date(taskRequest.payment_deadline).getTime()
      : null;
    if (paymentDeadline != null && Date.now() > paymentDeadline) {
      return jsonResponse(
        { code: "PAYMENT_DEADLINE_EXPIRED", message: "Payment deadline has passed", request_correlation_id: requestCorrelationId },
        400,
      );
    }

    const correlationId = `tender:${requestId}:create`;
    const paymentRequestId = crypto.randomUUID();
    const finishPaymentUrl = withQueryParams(
      resolveQiCardFinishUrl(req, requestedFinishUrl ?? QICARD_FINISH_URL),
      {
        request_id: requestId,
        correlation_id: correlationId,
        payment_request_id: paymentRequestId,
      },
    );

    const payment = await qicardCreatePayment({
      requestId: paymentRequestId,
      amount,
      currency,
      description: `SLine tender payment ${requestId}`,
      finishPaymentUrl,
      additionalInfo: {
        request_id: requestId,
        client_id: auth.user.id,
        correlation_id: correlationId,
      },
    });

    if (!payment.formUrl) {
      throw new Error("QICARD_FORM_URL_MISSING");
    }

    return jsonResponse({
      request_id: requestId,
      form_url: payment.formUrl,
      correlation_id: correlationId,
      payment_request_id: paymentRequestId,
      amount,
      currency,
      request_correlation_id: requestCorrelationId,
    });
  } catch (error) {
    console.error("Tender payment create error:", {
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
