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
  Future<QiCardCreatePaymentResult> createPaymentForBooking({
    required String taskId,
    String? note,
    String? packageId,
    Map<String, dynamic>? requirements,
  }) async {
    try {
      AppLogger.i(
        'Creating booking payment task=$taskId package=${packageId ?? 'none'}',
        tag: 'QiCard',
        json: <String, dynamic>{
          'task_id': taskId,
          'package_id': packageId,
          'has_note': note != null && note.trim().isNotEmpty,
          'requirements_keys': (requirements ?? const <String, dynamic>{}).keys
              .toList(),
        },
      );
      final response = await _client.functions.invoke(
        'qicard_payment_create',
        body: <String, dynamic>{
          'task_id': taskId,
          'note': note,
          'package_id': packageId,
          'requirements': requirements ?? const <String, dynamic>{},
        },
      );

      final data = _asMap(response.data);
      final serviceError = _extractError(data);
      if (serviceError != null) {
        AppLogger.w(
          'Booking payment create was rejected by the server for task=$taskId',
          tag: 'QiCard',
          error: serviceError,
          json: _safePayloadSummary(data),
        );
        return QiCardCreatePaymentResult(
          error: serviceError,
          errorCode: 'BOOKING_PAYMENT_CREATE_FAILED',
        );
      }

      if (data == null) {
        AppLogger.w(
          'Booking payment create returned no payload for task=$taskId',
          tag: 'QiCard',
        );
        return QiCardCreatePaymentResult(
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
      );

      if (!result.isSuccess) {
        AppLogger.w(
          'Booking payment create returned an incomplete payload for task=$taskId',
          tag: 'QiCard',
          json: _safePayloadSummary(data),
        );
        return const QiCardCreatePaymentResult(
          error: 'Booking payment could not be created.',
          errorCode: 'BOOKING_PAYMENT_CREATE_FAILED',
        );
      }

      AppLogger.i(
        'Booking payment created booking=${result.bookingId} correlation=${result.correlationId}',
        tag: 'QiCard',
      );
      return result;
    } catch (e, st) {
      AppLogger.e(
        'createPaymentForBooking failed',
        tag: 'QiCard',
        error: e,
        stackTrace: st,
      );
      return const QiCardCreatePaymentResult(
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
        tag: 'QiCard',
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
          tag: 'QiCard',
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
          tag: 'QiCard',
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
          tag: 'QiCard',
          json: _safePayloadSummary(data),
        );
        return const QiCardRecoveryResult(
          error: 'Booking recovery failed.',
          errorCode: 'BOOKING_PAYMENT_RECOVERY_FAILED',
        );
      }

      AppLogger.i(
        'Booking recovery finished booking=$bookingId status=${result.paymentStatus} outcome=${result.recoveryResult}',
        tag: 'QiCard',
      );
      return result;
    } catch (e, st) {
      AppLogger.e(
        'recoverBookingPayment failed',
        tag: 'QiCard',
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
        tag: 'QiCard',
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
          tag: 'QiCard',
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
          tag: 'QiCard',
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
          tag: 'QiCard',
          json: _safePayloadSummary(data),
        );
        return const BookingRefundResult(
          error: 'Booking refund failed.',
          errorCode: 'BOOKING_REFUND_FAILED',
        );
      }

      AppLogger.i(
        'Booking refund finished booking=$bookingId status=${result.paymentStatus} outcome=${result.refundResult}',
        tag: 'QiCard',
      );
      return result;
    } catch (e, st) {
      AppLogger.e(
        'declineAndRefundBooking failed',
        tag: 'QiCard',
        error: e,
        stackTrace: st,
      );
      return const BookingRefundResult(
        error: 'Cannot refund booking right now.',
        errorCode: 'BOOKING_REFUND_FAILED',
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
    return <String, dynamic>{
      'keys': data?.keys.toList() ?? const <String>[],
      'booking_id': data?['booking_id'],
      'correlation_id': data?['correlation_id'],
      'payment_status': data?['payment_status'],
      'recovery_result': data?['recovery_result'],
      'refund_result': data?['refund_result'],
      'error': data?['error'],
    };
  }

  String? _extractError(Map<String, dynamic>? data) {
    final error = data?['error'];
    if (error is String && error.isNotEmpty) return error;
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
