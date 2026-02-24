import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/demo_payment_service.dart';
import 'package:sline_app/core/services/payment_service.dart';

/// Feature-flag target for QiCard integration.
///
/// Phase 0/1 only wires the provider selection and rollback gate.
/// The full create-payment + WebView flow is introduced in later phases.
class QiCardPaymentService implements PaymentService {
  QiCardPaymentService({DemoPaymentService? fallbackService})
    : _fallbackService = fallbackService ?? DemoPaymentService();

  final DemoPaymentService _fallbackService;
  static const _uuid = Uuid();

  static const String _apiBaseUrl = String.fromEnvironment(
    'QICARD_API_BASE_URL',
    defaultValue: 'https://uat-sandbox-3ds-api.qi.iq/api/v1',
  );
  // Test credentials - replace with production values via --dart-define
  static const String _terminalId = String.fromEnvironment(
    'QICARD_TERMINAL_ID',
    defaultValue: '237984',
  );
  static const String _username = String.fromEnvironment(
    'QICARD_USERNAME',
    defaultValue: 'paymentgatewaytest',
  );
  static const String _password = String.fromEnvironment(
    'QICARD_PASSWORD',
    defaultValue: 'WHaNFE5C3qlChqNbAzH4',
  );
  static const String _notificationUrl = String.fromEnvironment(
    'QICARD_NOTIFICATION_URL',
    defaultValue: 'https://isddrknbjsgaantjojhm.supabase.co/functions/v1/qicard_webhook_handler',
  );
  static const String _finishPaymentUrl = String.fromEnvironment(
    'QICARD_FINISH_URL',
    defaultValue: 'https://sline.app/payment/success',
  );
  static const String _supabaseFunctionsBaseUrl = String.fromEnvironment(
    'SUPABASE_FUNCTIONS_BASE_URL',
    defaultValue: 'https://isddrknbjsgaantjojhm.supabase.co/functions/v1',
  );

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
  }) async {
    // Keep checkout stable while backend/webhook work lands in Phase 0/1.
    AppLogger.w(
      'QiCard service is in fallback mode during Phase 0/1. '
      'Routing to DemoPaymentService.',
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
    final missingConfig = <String>[
      if (_username.isEmpty) 'QICARD_USERNAME',
      if (_password.isEmpty) 'QICARD_PASSWORD',
      if (_terminalId.isEmpty) 'QICARD_TERMINAL_ID',
      if (_notificationUrl.isEmpty) 'QICARD_NOTIFICATION_URL',
    ];
    if (missingConfig.isNotEmpty) {
      return PaymentInitResult(
        error:
            'QiCard configuration missing: ${missingConfig.join(', ')}. '
            'Run with matching --dart-define values.',
        errorCode: 'QICARD_CONFIG_MISSING',
      );
    }

    final notificationUri = Uri.tryParse(_notificationUrl);
    final invalidNotificationUrl =
        notificationUri == null ||
        (notificationUri.scheme != 'https' &&
            notificationUri.scheme != 'http') ||
        _notificationUrl.contains('YOUR_NOTIFICATION_URL');
    if (invalidNotificationUrl) {
      return const PaymentInitResult(
        error:
            'QICARD_NOTIFICATION_URL must be a real https webhook URL (not placeholder).',
        errorCode: 'QICARD_NOTIFICATION_URL_INVALID',
      );
    }

    final finishUri = Uri.tryParse(_finishPaymentUrl);
    final invalidFinishUrl =
        finishUri == null ||
        (finishUri.scheme != 'https' && finishUri.scheme != 'http');
    if (invalidFinishUrl) {
      return const PaymentInitResult(
        error: 'QICARD_FINISH_URL must be a valid https URL for QiCard create-payment.',
        errorCode: 'QICARD_FINISH_URL_INVALID',
      );
    }

    final requestId = _uuid.v4();
    final uri = Uri.parse('$_apiBaseUrl/payment');
    final authToken = base64Encode(utf8.encode('$_username:$_password'));

    final payload = <String, dynamic>{
      'requestId': requestId,
      'amount': double.parse(amount.toStringAsFixed(3)),
      'currency': currency,
      'finishPaymentUrl': _finishPaymentUrl,
      'notificationUrl': _notificationUrl,
      'description': description ?? 'SLine booking payment',
      'additionalInfo': <String, dynamic>{
        'booking_id': bookingId,
        'client_id': clientId,
      },
    };

    try {
      AppLogger.i(
        'Initiating QiCard payment requestId=$requestId',
        tag: 'QiCard',
      );

      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Basic $authToken',
          'X-Terminal-Id': _terminalId,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final parsedError = _extractQiCardError(response.body);
        return PaymentInitResult(
          error: _mapQiCardError(
            code: parsedError['code'],
            fallbackMessage: parsedError['message'],
          ),
          errorCode: parsedError['code'],
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final formUrl = data['formUrl'] as String?;
      final paymentId = data['paymentId'] as String?;

      if (formUrl == null || formUrl.isEmpty) {
        return const PaymentInitResult(
          error: 'Payment could not be started. Please try again.',
        );
      }

      AppLogger.i(
        'QiCard form URL received paymentId=$paymentId requestId=$requestId',
        tag: 'QiCard',
      );

      return PaymentInitResult(
        formUrl: formUrl,
        paymentId: paymentId,
        requestId: requestId,
      );
    } catch (e, st) {
      AppLogger.e(
        'QiCard initiatePayment failed',
        tag: 'QiCard',
        error: e,
        stackTrace: st,
      );
      return const PaymentInitResult(
        error: 'Cannot reach payment provider. Please try again.',
      );
    }
  }

  Map<String, String?> _extractQiCardError(String rawBody) {
    try {
      final body = jsonDecode(rawBody) as Map<String, dynamic>;
      final nestedError = body['error'];
      if (nestedError is Map<String, dynamic>) {
        return {
          'code': nestedError['code']?.toString(),
          'message': nestedError['description']?.toString(),
        };
      }
      return {
        'code': body['code']?.toString(),
        'message': body['message']?.toString(),
      };
    } catch (_) {
      return {'code': null, 'message': null};
    }
  }

  String _mapQiCardError({String? code, String? fallbackMessage}) {
    if ((fallbackMessage ?? '').toLowerCase().contains('finishpaymenturl')) {
      return 'QiCard rejected finish URL. Use https://... for QICARD_FINISH_URL.';
    }

    // Complete QiCard error code mapping (1-35 per documentation)
    switch (code) {
      // System errors (1-10)
      case '1':
        return 'System error. Please try again later.';
      case '2':
        return 'Payment service temporarily unavailable. Please retry.';
      case '3':
        return 'Payment gateway error. Please contact support.';
      case '4':
        return 'Merchant configuration error. Please contact support.';
      case '5':
        return 'Invalid request format. Please contact support.';
      case '6':
        return 'Required parameter missing. Please contact support.';
      case '7':
        return 'Invalid parameter value. Please check your details.';
      case '8':
        return 'Duplicate request detected. Please wait a moment.';
      case '9':
        return 'Request timeout. Please try again.';
      case '10':
        return 'Service busy. Please try again later.';

      // Authentication/Authorization errors (11-20)
      case '11':
        return 'Authentication failed. Invalid credentials.';
      case '12':
        return 'Payment reference was not found. Please retry checkout.';
      case '13':
        return 'Access denied. Invalid merchant or terminal.';
      case '14':
        return 'Terminal not active. Please contact support.';
      case '15':
        return 'Merchant account suspended. Please contact support.';
      case '16':
        return 'Invalid IP address. Please contact support.';
      case '17':
        return 'Session expired. Please restart the payment process.';
      case '18':
        return 'Invalid signature. Security check failed.';
      case '19':
        return 'Token expired. Please restart the payment process.';
      case '20':
        return 'Maximum attempts exceeded. Please try again later.';

      // Payment processing errors (21-30)
      case '21':
        return 'Invalid payment details. Please review and try again.';
      case '22':
        return 'Card expired. Please use a different card.';
      case '23':
        return 'Card declined. Please use a different card or contact your bank.';
      case '24':
        return 'Insufficient funds. Please use a different card or payment method.';
      case '25':
        return 'Transaction limit exceeded. Please contact your bank.';
      case '26':
        return 'Invalid CVV. Please check and try again.';
      case '27':
        return 'Payment service is temporarily unavailable. Please retry.';
      case '28':
        return '3D Secure authentication failed. Please contact your bank.';
      case '29':
        return 'Issuer declined. Please contact your bank.';
      case '30':
        return 'Suspected fraud. Transaction blocked for security.';

      // Refund/Cancellation errors (31-35)
      case '31':
        return 'Payment already refunded. Cannot process duplicate refund.';
      case '32':
        return 'Refund amount exceeds original payment amount.';
      case '33':
        return 'Payment cannot be cancelled. Already processed.';
      case '34':
        return 'Refund period expired. Please contact support.';
      case '35':
        return 'Partial refund not supported for this payment.';

      // HTTP status codes
      case '400':
        return 'Invalid request. Please check your payment details.';
      case '401':
        return 'Authentication failed. Please check your credentials.';
      case '403':
        return 'QiCard rejected credentials or terminal settings. Verify username/password/terminal ID and callback URL.';
      case '404':
        return 'Payment service endpoint not found. Please contact support.';
      case '500':
        return 'Internal server error at payment provider. Please try again.';
      case '503':
        return 'Payment service temporarily unavailable. Please retry.';

      default:
        return fallbackMessage ?? 'Payment could not be started. Please try again.';
    }
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
    final recoveryUri = Uri.parse(
      '$_supabaseFunctionsBaseUrl/qicard_webhook_handler',
    );
    final payload = <String, dynamic>{
      'requestId': requestId,
      'paymentId': paymentId,
      'status': 'SUCCESS',
      'amount': double.parse(amount.toStringAsFixed(3)),
      'currency': currency,
      'creationDate': DateTime.now().toUtc().toIso8601String(),
      'additionalInfo': <String, dynamic>{
        'booking_id': bookingId,
        'client_id': clientId,
      },
    };

    try {
      final response = await http.post(
        recoveryUri,
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return response.statusCode == 200;
    } catch (e, st) {
      AppLogger.e(
        'QiCard triggerPaymentSuccessRecovery failed',
        tag: 'QiCard',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  @override
  Future<RefundResult> refundPayment({
    required String paymentId,
    required double amount,
    required String currency,
    String? reason,
  }) async {
    final missingConfig = <String>[
      if (_username.isEmpty) 'QICARD_USERNAME',
      if (_password.isEmpty) 'QICARD_PASSWORD',
      if (_terminalId.isEmpty) 'QICARD_TERMINAL_ID',
    ];

    if (missingConfig.isNotEmpty) {
      return RefundResult(
        error: 'QiCard configuration missing: ${missingConfig.join(', ')}.',
        errorCode: 'QICARD_CONFIG_MISSING',
      );
    }

    final refundRequestId = _uuid.v4();
    final uri = Uri.parse('$_apiBaseUrl/payment/$paymentId/refund');
    final authToken = base64Encode(utf8.encode('$_username:$_password'));

    final payload = <String, dynamic>{
      'requestId': refundRequestId,
      'amount': double.parse(amount.toStringAsFixed(3)),
      'currency': currency,
      if (reason != null && reason.isNotEmpty) 'description': reason,
    };

    try {
      AppLogger.i(
        'Initiating QiCard refund paymentId=$paymentId requestId=$refundRequestId',
        tag: 'QiCard',
      );

      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Basic $authToken',
          'X-Terminal-Id': _terminalId,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final parsedError = _extractQiCardError(response.body);
        return RefundResult(
          error: _mapQiCardError(
            code: parsedError['code'],
            fallbackMessage: parsedError['message'],
          ),
          errorCode: parsedError['code'],
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final refundId = data['refundId'] as String? ?? data['paymentId'] as String?;
      final status = data['status'] as String? ?? 'PENDING';

      AppLogger.i(
        'QiCard refund initiated refundId=$refundId paymentId=$paymentId',
        tag: 'QiCard',
      );

      return RefundResult(
        refundId: refundId,
        amount: amount,
        currency: currency,
        status: status,
      );
    } catch (e, st) {
      AppLogger.e(
        'QiCard refundPayment failed',
        tag: 'QiCard',
        error: e,
        stackTrace: st,
      );
      return const RefundResult(
        error: 'Cannot process refund. Please try again or contact support.',
        errorCode: 'REFUND_FAILED',
      );
    }
  }

  @override
  Future<CancelResult> cancelPayment({
    required String paymentId,
    required String reason,
  }) async {
    final missingConfig = <String>[
      if (_username.isEmpty) 'QICARD_USERNAME',
      if (_password.isEmpty) 'QICARD_PASSWORD',
      if (_terminalId.isEmpty) 'QICARD_TERMINAL_ID',
    ];

    if (missingConfig.isNotEmpty) {
      return CancelResult(
        error: 'QiCard configuration missing: ${missingConfig.join(', ')}.',
        errorCode: 'QICARD_CONFIG_MISSING',
      );
    }

    final cancelRequestId = _uuid.v4();
    final uri = Uri.parse('$_apiBaseUrl/payment/$paymentId/cancel');
    final authToken = base64Encode(utf8.encode('$_username:$_password'));

    final payload = <String, dynamic>{
      'requestId': cancelRequestId,
      if (reason.isNotEmpty) 'description': reason,
    };

    try {
      AppLogger.i(
        'Initiating QiCard cancel paymentId=$paymentId requestId=$cancelRequestId',
        tag: 'QiCard',
      );

      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Basic $authToken',
          'X-Terminal-Id': _terminalId,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final parsedError = _extractQiCardError(response.body);
        return CancelResult(
          error: _mapQiCardError(
            code: parsedError['code'],
            fallbackMessage: parsedError['message'],
          ),
          errorCode: parsedError['code'],
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final cancelId = data['cancelId'] as String? ?? data['paymentId'] as String?;
      final status = data['status'] as String? ?? 'CANCELLED';

      AppLogger.i(
        'QiCard payment cancelled cancelId=$cancelId paymentId=$paymentId',
        tag: 'QiCard',
      );

      return CancelResult(
        cancelId: cancelId,
        status: status,
      );
    } catch (e, st) {
      AppLogger.e(
        'QiCard cancelPayment failed',
        tag: 'QiCard',
        error: e,
        stackTrace: st,
      );
      return const CancelResult(
        error: 'Cannot cancel payment. Please try again or contact support.',
        errorCode: 'CANCEL_FAILED',
      );
    }
  }

  @override
  Future<PaymentStatusResult> getPaymentStatus({
    required String paymentId,
  }) async {
    final missingConfig = <String>[
      if (_username.isEmpty) 'QICARD_USERNAME',
      if (_password.isEmpty) 'QICARD_PASSWORD',
      if (_terminalId.isEmpty) 'QICARD_TERMINAL_ID',
    ];

    if (missingConfig.isNotEmpty) {
      return PaymentStatusResult(
        error: 'QiCard configuration missing: ${missingConfig.join(', ')}.',
        errorCode: 'QICARD_CONFIG_MISSING',
      );
    }

    final statusRequestId = _uuid.v4();
    final uri = Uri.parse('$_apiBaseUrl/payment/$paymentId/status');
    final authToken = base64Encode(utf8.encode('$_username:$_password'));

    try {
      AppLogger.i(
        'Checking QiCard payment status paymentId=$paymentId requestId=$statusRequestId',
        tag: 'QiCard',
      );

      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Basic $authToken',
          'X-Terminal-Id': _terminalId,
          'X-Request-Id': statusRequestId,
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final parsedError = _extractQiCardError(response.body);
        return PaymentStatusResult(
          error: _mapQiCardError(
            code: parsedError['code'],
            fallbackMessage: parsedError['message'],
          ),
          errorCode: parsedError['code'],
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      final amount = (data['amount'] as num?)?.toDouble();
      final currency = data['currency'] as String?;
      final createdAtStr = data['createdDate'] as String? ?? data['creationDate'] as String?;

      AppLogger.i(
        'QiCard payment status retrieved paymentId=$paymentId status=$status',
        tag: 'QiCard',
      );

      return PaymentStatusResult(
        paymentId: paymentId,
        status: status?.toUpperCase(),
        amount: amount,
        currency: currency,
        createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
      );
    } catch (e, st) {
      AppLogger.e(
        'QiCard getPaymentStatus failed',
        tag: 'QiCard',
        error: e,
        stackTrace: st,
      );
      return PaymentStatusResult(
        error: 'Cannot retrieve payment status. Please try again.',
        errorCode: 'STATUS_CHECK_FAILED',
      );
    }
  }
}
