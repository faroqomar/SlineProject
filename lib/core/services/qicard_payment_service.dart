import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/demo_payment_service.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_service.dart';

/// Booking remediation version of the QiCard service.
///
/// Privileged gateway operations now live behind Supabase edge functions.
/// Legacy direct-client QiCard endpoints are intentionally disabled.
class QiCardPaymentService implements PaymentService {
  QiCardPaymentService({DemoPaymentService? fallbackService})
    : _fallbackService = fallbackService ?? DemoPaymentService();

  final DemoPaymentService _fallbackService;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<void> initialize() async {
    AppLogger.i('QiCardPaymentService initialized', tag: 'Payment');
    await _fallbackService.initialize();
  }

  @override
  Future<String> processPayment({
    required double amount,
    required String currency,
    required String description,
  }) {
    AppLogger.w(
      'Direct processPayment is disabled for QiCard. Falling back to demo implementation.',
      tag: 'Payment',
    );
    return _fallbackService.processPayment(
      amount: amount,
      currency: currency,
      description: description,
    );
  }

  @override
  Future<PaymentInitResult> initiatePayment({
    required double amount,
    required String currency,
    required String bookingId,
    required String clientId,
    String? description,
  }) async {
    AppLogger.w(
      'Direct initiatePayment was called for booking=$bookingId; server-backed booking flow is required.',
      tag: 'Payment',
    );
    return const PaymentInitResult(
      error:
          'Direct QiCard client initiation is disabled. Use the server-backed booking payment flow.',
      errorCode: 'SERVER_FLOW_REQUIRED',
    );
  }

  @override
  Future<bool> triggerPaymentSuccessRecovery({
    required String bookingId,
    required String paymentId,
    required String requestId,
    required double amount,
    required String currency,
    required String clientId,
  }) async {
    AppLogger.w(
      'Legacy triggerPaymentSuccessRecovery was called for booking=$bookingId and is disabled.',
      tag: 'Payment',
    );
    return false;
  }

  @override
  Future<RefundResult> refundPayment({
    required String paymentId,
    required double amount,
    required String currency,
    String? reason,
  }) async {
    AppLogger.w(
      'Direct refundPayment was called for payment=$paymentId; server-backed booking refund flow is required.',
      tag: 'Payment',
    );
    return const RefundResult(
      error:
          'Direct QiCard client refunds are disabled. Use the server-backed booking refund flow.',
      errorCode: 'SERVER_FLOW_REQUIRED',
    );
  }

  @override
  Future<CancelResult> cancelPayment({
    required String paymentId,
    required String reason,
  }) async {
    AppLogger.w(
      'Direct cancelPayment was called for payment=$paymentId; server-backed booking refund flow is required.',
      tag: 'Payment',
    );
    return const CancelResult(
      error:
          'Direct QiCard client cancel is disabled. Use the server-backed booking refund flow.',
      errorCode: 'SERVER_FLOW_REQUIRED',
    );
  }

  @override
  Future<PaymentStatusResult> getPaymentStatus({
    required String paymentId,
  }) async {
    AppLogger.w(
      'Direct getPaymentStatus was called for payment=$paymentId; server recovery is required instead.',
      tag: 'Payment',
    );
    return const PaymentStatusResult(
      error:
          'Direct QiCard client status checks are disabled. Use server recovery instead.',
      errorCode: 'SERVER_FLOW_REQUIRED',
    );
  }

  @override
  Future<PaymentIntentResult> createPaymentIntent({
    required String entityType,
    required String entityId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      AppLogger.i(
        'Creating hardned payment intent for $entityType $entityId',
        tag: 'Payment',
        json: {
          'entity_type': entityType,
          'entity_id': entityId,
          'success_url': successUrl,
          'cancel_url': cancelUrl,
        },
      );

      final response = await _client.functions.invoke(
        'create_payment_intent',
        body: {
          'entity_type': entityType,
          'entity_id': entityId,
          'success_url': successUrl,
          'cancel_url': cancelUrl,
        },
      );

      final data = _asMap(response.data);
      final error = _extractError(data) ?? _extractErrorFromPayload(data);

      if (error != null) {
        AppLogger.w('Intent creation rejected', tag: 'Payment', error: error);
        return PaymentIntentResult(error: error, errorCode: 'INTENT_REJECTED');
      }

      final intentId = data?['intent_id'] as String?;
      final checkoutUrl = data?['checkout_url'] as String?;

      if (intentId == null || checkoutUrl == null) {
        return const PaymentIntentResult(
          error: 'Invalid intent payload',
          errorCode: 'INVALID_PAYLOAD',
        );
      }

      return PaymentIntentResult(intentId: intentId, checkoutUrl: checkoutUrl);
    } catch (e, st) {
      AppLogger.e(
        'createPaymentIntent failed',
        tag: 'Payment',
        error: e,
        stackTrace: st,
      );
      return const PaymentIntentResult(
        error: 'Failed to communicate with payment gateway.',
        errorCode: 'INTENT_CRASH',
      );
    }
  }

  @override
  Stream<String> streamPaymentIntentStatus(String intentId) {
    AppLogger.i(
      'Subscribing to realtime updates for intent=$intentId',
      tag: 'Payment',
    );
    return _client
        .from('payment_intents')
        .stream(primaryKey: ['id'])
        .eq('id', intentId)
        .map((rows) {
          if (rows.isEmpty) return 'created';
          return rows.first['status'] as String? ?? 'created';
        });
  }

  @override
  Future<QiCardCreatePaymentResult> createPaymentForBooking({
    required String taskId,
    String? note,
    String? packageId,
    Map<String, dynamic>? requirements,
    String? finishUrl,
    String? requestCorrelationId,
  }) async {
    try {
      AppLogger.i(
        'Creating booking payment task=$taskId package=${packageId ?? 'none'}',
        tag: 'Payment',
        json: <String, dynamic>{
          'task_id': taskId,
          'package_id': packageId,
          'has_note': note != null && note.trim().isNotEmpty,
          'finish_url': finishUrl,
          'requirements_keys': (requirements ?? const <String, dynamic>{}).keys
              .toList(),
          'request_correlation_id': requestCorrelationId,
        },
      );
      final response = await _client.functions.invoke(
        'qicard_payment_create',
        body: <String, dynamic>{
          'task_id': taskId,
          'note': note,
          'package_id': packageId,
          'requirements': requirements ?? const <String, dynamic>{},
          'finish_url': finishUrl,
          'request_correlation_id': requestCorrelationId,
        },
      );

      final data = _asMap(response.data);
      final serviceError = _extractError(data);
      final responseRequestCorrelationId =
          data?['request_correlation_id'] as String? ?? requestCorrelationId;
      if (serviceError != null) {
        AppLogger.w(
          'Booking payment create was rejected by the server for task=$taskId',
          tag: 'Payment',
          error: serviceError,
          json: _safePayloadSummary(data),
        );
        return QiCardCreatePaymentResult(
          requestCorrelationId: responseRequestCorrelationId,
          error: serviceError,
          errorCode: 'BOOKING_PAYMENT_CREATE_FAILED',
        );
      }

      if (data == null) {
        AppLogger.w(
          'Booking payment create returned no payload for task=$taskId',
          tag: 'Payment',
        );
        return QiCardCreatePaymentResult(
          requestCorrelationId: responseRequestCorrelationId,
          error: 'Booking payment could not be created.',
          errorCode: 'BOOKING_PAYMENT_CREATE_FAILED',
        );
      }

      final result = QiCardCreatePaymentResult(
        bookingId: data['booking_id'] as String?,
        paymentRequestId: data['payment_request_id'] as String?,
        formUrl: data['form_url'] as String?,
        amount: (data['amount'] as num?)?.toDouble(),
        providerId: data['provider_id'] as String?,
        expiresAt: _parseDate(data['expires_at']),
        correlationId: data['correlation_id'] as String?,
        requestCorrelationId: responseRequestCorrelationId,
      );

      if (!result.isSuccess) {
        AppLogger.w(
          'Booking payment create returned an incomplete payload for task=$taskId',
          tag: 'Payment',
          json: _safePayloadSummary(data),
        );
        return QiCardCreatePaymentResult(
          requestCorrelationId: responseRequestCorrelationId,
          error: 'Booking payment could not be created.',
          errorCode: 'BOOKING_PAYMENT_CREATE_FAILED',
        );
      }

      AppLogger.i(
        'Booking payment created booking=${result.bookingId} correlation=${result.correlationId}',
        tag: 'Payment',
      );
      return result;
    } catch (e, st) {
      AppLogger.e(
        'createPaymentForBooking failed',
        tag: 'Payment',
        error: e,
        stackTrace: st,
      );
      return QiCardCreatePaymentResult(
        requestCorrelationId: requestCorrelationId,
        error: 'Cannot start booking payment right now.',
        errorCode: 'BOOKING_PAYMENT_CREATE_FAILED',
      );
    }
  }

  @override
  Future<QiCardRecoveryResult> recoverBookingPayment({
    required String bookingId,
  }) async {
    try {
      AppLogger.i(
        'Recovering booking payment state for booking=$bookingId',
        tag: 'Payment',
      );
      final response = await _client.functions.invoke(
        'qicard_payment_recovery',
        body: <String, dynamic>{'booking_id': bookingId},
      );

      final data = _asMap(response.data);
      final serviceError = _extractError(data);
      if (serviceError != null) {
        AppLogger.w(
          'Booking recovery was rejected for booking=$bookingId',
          tag: 'Payment',
          error: serviceError,
          json: _safePayloadSummary(data),
        );
        return QiCardRecoveryResult(
          error: serviceError,
          errorCode: 'BOOKING_PAYMENT_RECOVERY_FAILED',
        );
      }

      if (data == null) {
        AppLogger.w(
          'Booking recovery returned no payload for booking=$bookingId',
          tag: 'Payment',
        );
        return QiCardRecoveryResult(
          error: 'Booking recovery failed.',
          errorCode: 'BOOKING_PAYMENT_RECOVERY_FAILED',
        );
      }

      final result = QiCardRecoveryResult(
        bookingId: data['booking_id'] as String?,
        bookingStatus: data['booking_status'] as String?,
        paymentStatus: data['payment_status'] as String?,
        recoveryResult: data['recovery_result'] as String?,
        correlationId: data['correlation_id'] as String?,
      );

      if (!result.isSuccess) {
        AppLogger.w(
          'Booking recovery returned an incomplete payload for booking=$bookingId',
          tag: 'Payment',
          json: _safePayloadSummary(data),
        );
        return const QiCardRecoveryResult(
          error: 'Booking recovery failed.',
          errorCode: 'BOOKING_PAYMENT_RECOVERY_FAILED',
        );
      }

      AppLogger.i(
        'Booking recovery finished booking=$bookingId status=${result.paymentStatus} outcome=${result.recoveryResult}',
        tag: 'Payment',
      );
      return result;
    } catch (e, st) {
      AppLogger.e(
        'recoverBookingPayment failed',
        tag: 'Payment',
        error: e,
        stackTrace: st,
      );
      return const QiCardRecoveryResult(
        error: 'Cannot recover booking payment right now.',
        errorCode: 'BOOKING_PAYMENT_RECOVERY_FAILED',
      );
    }
  }

  @override
  Future<BookingRefundResult> declineAndRefundBooking({
    required String bookingId,
    required String reason,
  }) async {
    try {
      AppLogger.i(
        'Requesting booking refund for booking=$bookingId',
        tag: 'Payment',
      );
      final response = await _client.functions.invoke(
        'booking_decline_refund',
        body: <String, dynamic>{'booking_id': bookingId, 'reason': reason},
      );

      final data = _asMap(response.data);
      final serviceError = _extractError(data);
      if (serviceError != null) {
        AppLogger.w(
          'Booking refund was rejected for booking=$bookingId',
          tag: 'Payment',
          error: serviceError,
          json: _safePayloadSummary(data),
        );
        return BookingRefundResult(
          error: serviceError,
          errorCode: 'BOOKING_REFUND_FAILED',
        );
      }

      if (data == null) {
        AppLogger.w(
          'Booking refund returned no payload for booking=$bookingId',
          tag: 'Payment',
        );
        return BookingRefundResult(
          error: 'Booking refund failed.',
          errorCode: 'BOOKING_REFUND_FAILED',
        );
      }

      final result = BookingRefundResult(
        bookingId: data['booking_id'] as String?,
        bookingStatus: data['booking_status'] as String?,
        paymentStatus: data['payment_status'] as String?,
        refundResult: data['refund_result'] as String?,
        correlationId: data['correlation_id'] as String?,
      );

      if (!result.isSuccess) {
        AppLogger.w(
          'Booking refund returned an incomplete payload for booking=$bookingId',
          tag: 'Payment',
          json: _safePayloadSummary(data),
        );
        return const BookingRefundResult(
          error: 'Booking refund failed.',
          errorCode: 'BOOKING_REFUND_FAILED',
        );
      }

      AppLogger.i(
        'Booking refund finished booking=$bookingId status=${result.paymentStatus} outcome=${result.refundResult}',
        tag: 'Payment',
      );
      return result;
    } catch (e, st) {
      AppLogger.e(
        'declineAndRefundBooking failed',
        tag: 'Payment',
        error: e,
        stackTrace: st,
      );
      return const BookingRefundResult(
        error: 'Cannot refund booking right now.',
        errorCode: 'BOOKING_REFUND_FAILED',
      );
    }
  }

  @override
  Future<QiCardDirectOfferPaymentResult> createPaymentForDirectOffer({
    required String offerId,
    required double amount,
    String? finishUrl,
    String? requestCorrelationId,
  }) async {
    try {
      AppLogger.i(
        'Creating direct offer payment offer=$offerId amount=$amount',
        tag: 'Payment',
      );
      final response = await _client.functions.invoke(
        'qicard_payment_create_direct_offer',
        body: <String, dynamic>{
          'offer_id': offerId,
          'amount': amount,
          'finish_url': finishUrl,
          'request_correlation_id': requestCorrelationId,
        },
      );

      final data = _asMap(response.data);
      final serviceError =
          _extractError(data) ?? _extractErrorFromPayload(data);
      if (serviceError != null) {
        AppLogger.w(
          'Direct offer payment create rejected for offer=$offerId',
          tag: 'Payment',
          error: serviceError,
          json: _safePayloadSummary(data),
        );
        return QiCardDirectOfferPaymentResult(
          offerId: offerId,
          error: serviceError,
          errorCode: 'DIRECT_OFFER_PAYMENT_CREATE_FAILED',
        );
      }

      if (data == null) {
        AppLogger.w(
          'Direct offer payment create returned no payload for offer=$offerId',
          tag: 'Payment',
        );
        return QiCardDirectOfferPaymentResult(
          offerId: offerId,
          error: 'Payment could not be created.',
          errorCode: 'DIRECT_OFFER_PAYMENT_CREATE_FAILED',
        );
      }

      final payloadError = _extractErrorFromPayload(data);
      final result = QiCardDirectOfferPaymentResult(
        offerId: data['offer_id'] as String? ?? offerId,
        formUrl: data['form_url'] as String?,
        correlationId: data['correlation_id'] as String?,
        paymentRequestId: data['payment_request_id'] as String?,
        amount: (data['amount'] as num?)?.toDouble(),
        error: payloadError,
        errorCode: 'DIRECT_OFFER_PAYMENT_CREATE_FAILED',
      );

      if (!result.isSuccess) {
        AppLogger.w(
          'Direct offer payment create returned incomplete or error payload for offer=$offerId',
          tag: 'Payment',
          json: _safePayloadSummary(data),
        );
        return QiCardDirectOfferPaymentResult(
          offerId: offerId,
          error:
              payloadError ?? result.error ?? 'Payment could not be created.',
          errorCode: result.errorCode ?? 'DIRECT_OFFER_PAYMENT_CREATE_FAILED',
        );
      }

      AppLogger.i(
        'Direct offer payment created offer=$offerId correlation=${result.correlationId}',
        tag: 'Payment',
      );
      return result;
    } catch (e, st) {
      AppLogger.e(
        'createPaymentForDirectOffer failed',
        tag: 'Payment',
        error: e,
        stackTrace: st,
      );
      return QiCardDirectOfferPaymentResult(
        offerId: offerId,
        error: 'Cannot start payment right now.',
        errorCode: 'DIRECT_OFFER_PAYMENT_CREATE_FAILED',
      );
    }
  }

  @override
  Future<QiCardTenderPaymentResult> createPaymentForTenderOffer({
    required String requestId,
    required double amount,
    String currency = 'IQD',
    String? description,
    String? finishUrl,
    String? requestCorrelationId,
  }) async {
    try {
      AppLogger.i(
        'Creating tender payment request=$requestId amount=$amount',
        tag: 'Payment',
      );
      final response = await _client.functions.invoke(
        'qicard_payment_create_tender',
        body: <String, dynamic>{
          'request_id': requestId,
          'amount': amount,
          'currency': currency,
          'description': description,
          'finish_url': finishUrl,
          'request_correlation_id': requestCorrelationId,
        },
      );

      final data = _asMap(response.data);
      final serviceError =
          _extractError(data) ?? _extractErrorFromPayload(data);
      if (serviceError != null) {
        AppLogger.w(
          'Tender payment create rejected for request=$requestId',
          tag: 'Payment',
          error: serviceError,
          json: _safePayloadSummary(data),
        );
        return QiCardTenderPaymentResult(
          requestId: requestId,
          error: serviceError,
          errorCode: 'TENDER_PAYMENT_CREATE_FAILED',
        );
      }

      if (data == null) {
        AppLogger.w(
          'Tender payment create returned no payload for request=$requestId',
          tag: 'Payment',
        );
        return QiCardTenderPaymentResult(
          requestId: requestId,
          error: 'Payment could not be created.',
          errorCode: 'TENDER_PAYMENT_CREATE_FAILED',
        );
      }

      final payloadError = _extractErrorFromPayload(data);
      final result = QiCardTenderPaymentResult(
        requestId: data['request_id'] as String? ?? requestId,
        formUrl: data['form_url'] as String?,
        correlationId: data['correlation_id'] as String?,
        paymentRequestId: data['payment_request_id'] as String?,
        amount: (data['amount'] as num?)?.toDouble(),
        error: payloadError,
        errorCode: 'TENDER_PAYMENT_CREATE_FAILED',
      );

      if (!result.isSuccess) {
        AppLogger.w(
          'Tender payment create returned incomplete or error payload for request=$requestId',
          tag: 'Payment',
          json: _safePayloadSummary(data),
        );
        return QiCardTenderPaymentResult(
          requestId: requestId,
          error:
              payloadError ?? result.error ?? 'Payment could not be created.',
          errorCode: result.errorCode ?? 'TENDER_PAYMENT_CREATE_FAILED',
        );
      }

      AppLogger.i(
        'Tender payment created request=$requestId correlation=${result.correlationId}',
        tag: 'Payment',
      );
      return result;
    } catch (e, st) {
      AppLogger.e(
        'createPaymentForTenderOffer failed',
        tag: 'Payment',
        error: e,
        stackTrace: st,
      );
      return QiCardTenderPaymentResult(
        requestId: requestId,
        error: 'Cannot start payment right now.',
        errorCode: 'TENDER_PAYMENT_CREATE_FAILED',
      );
    }
  }

  @override
  Future<QiCardTenderRecoveryResult> recoverTenderPaymentAfterCallback({
    required String requestId,
    required String paymentRequestId,
  }) async {
    try {
      AppLogger.i(
        'Recovering tender payment request=$requestId paymentRequestId=$paymentRequestId',
        tag: 'Payment',
      );
      final response = await _client.functions.invoke(
        'qicard_payment_recovery_tender',
        body: <String, dynamic>{
          'request_id': requestId,
          'payment_request_id': paymentRequestId,
        },
      );

      final data = _asMap(response.data);
      final serviceError =
          _extractError(data) ?? _extractErrorFromPayload(data);
      if (serviceError != null) {
        AppLogger.w(
          'Tender recovery rejected for request=$requestId',
          tag: 'Payment',
          error: serviceError,
          json: _safePayloadSummary(data),
        );
        return QiCardTenderRecoveryResult(
          error: serviceError,
          errorCode: 'TENDER_RECOVERY_FAILED',
        );
      }

      if (data == null) {
        return QiCardTenderRecoveryResult(
          error: 'Recovery failed.',
          errorCode: 'TENDER_RECOVERY_FAILED',
        );
      }

      final ok = data['ok'] as bool? ?? false;
      final recovered = data['recovered'] as bool? ?? false;
      return QiCardTenderRecoveryResult(
        ok: ok,
        recovered: recovered,
        message: data['message'] as String?,
      );
    } catch (e, st) {
      AppLogger.e(
        'recoverTenderPaymentAfterCallback failed',
        tag: 'Payment',
        error: e,
        stackTrace: st,
      );
      final baseMessage = 'Cannot recover payment right now.';
      final detail = kDebugMode ? ' (${e.toString()})' : '';
      return QiCardTenderRecoveryResult(
        error: '$baseMessage$detail',
        errorCode: 'TENDER_RECOVERY_FAILED',
      );
    }
  }

  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  Map<String, dynamic> _safePayloadSummary(Map<String, dynamic>? data) {
    final normalizedError = _normalizeErrorValue(data?['error']);
    return <String, dynamic>{
      'keys': data?.keys.toList() ?? const <String>[],
      'booking_id': data?['booking_id'],
      'correlation_id': data?['correlation_id'],
      'request_correlation_id': data?['request_correlation_id'],
      'payment_status': data?['payment_status'],
      'recovery_result': data?['recovery_result'],
      'refund_result': data?['refund_result'],
      'error': normalizedError,
    };
  }

  String? _extractError(Map<String, dynamic>? data) {
    return _normalizeErrorValue(data?['error']);
  }

  /// Top-level code/message (e.g. edge function error response).
  String? _extractErrorFromPayload(Map<String, dynamic>? data) {
    if (data == null) return null;
    final msg = data['message'];
    final code = data['code'];
    if (msg is String && msg.isNotEmpty) {
      return code is String && code.isNotEmpty ? '$code: $msg' : msg;
    }
    if (code is String && code.isNotEmpty) return code;
    return null;
  }

  String? _normalizeErrorValue(dynamic error) {
    if (error is String && error.isNotEmpty) return error;
    if (error is Map) {
      final message = error['message'];
      final code = error['code'];
      if (code is String && message is String && code.isNotEmpty) {
        return '$code: $message';
      }
      if (message is String && message.isNotEmpty) return message;
      if (code is String && code.isNotEmpty) return code;
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
