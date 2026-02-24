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
  static const String _terminalId = String.fromEnvironment(
    'QICARD_TERMINAL_ID',
    defaultValue: '',
  );
  static const String _username = String.fromEnvironment(
    'QICARD_USERNAME',
    defaultValue: '',
  );
  static const String _password = String.fromEnvironment(
    'QICARD_PASSWORD',
    defaultValue: '',
  );
  static const String _notificationUrl = String.fromEnvironment(
    'QICARD_NOTIFICATION_URL',
    defaultValue: '',
  );
  static const String _finishPaymentUrl = String.fromEnvironment(
    'QICARD_FINISH_URL',
    defaultValue: '',
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
        error:
            'QICARD_FINISH_URL must be a valid https URL for QiCard create-payment.',
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
    switch (code) {
      case '27':
        return 'Payment service is temporarily unavailable. Please retry.';
      case '12':
        return 'Payment reference was not found. Please retry checkout.';
      case '21':
        return 'Invalid payment details. Please review and try again.';
      case '403':
        return 'QiCard rejected credentials or terminal settings. Verify username/password/terminal ID and callback URL.';
      default:
        return fallbackMessage ??
            'Payment could not be started. Please try again.';
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
    } catch (e) {
      return false;
    }
  }
}
