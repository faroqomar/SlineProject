import 'package:sline_app/core/models/payment_return_args.dart';

const String kQiCardFinishUrl = String.fromEnvironment(
  'QICARD_FINISH_URL',
  defaultValue: 'https://sline.app/payment/success',
);

Set<String> buildQiCardCallbackHosts({String? finishUrl}) {
  final hosts = <String>{'sline.app'};
  final configuredHost = Uri.tryParse(
    finishUrl ?? kQiCardFinishUrl,
  )?.host.toLowerCase();

  if (configuredHost != null && configuredHost.isNotEmpty) {
    hosts.add(configuredHost);
  }

  return hosts;
}

bool isWebPaymentCallbackUri(Uri uri, {Set<String>? callbackHosts}) {
  final hosts = callbackHosts ?? buildQiCardCallbackHosts();
  final host = uri.host.toLowerCase();
  if (!hosts.contains(host)) {
    return false;
  }

  final isTrustedScheme =
      uri.scheme == 'https' ||
      (uri.scheme == 'http' && (host == 'localhost' || host == '127.0.0.1'));
  if (!isTrustedScheme) {
    return false;
  }

  final path = uri.path.toLowerCase();
  if (!path.contains('/payment/')) {
    return false;
  }

  return path.contains('/success') ||
      path.contains('/failure') ||
      path.contains('/cancel') ||
      path.contains('/error') ||
      path.contains('/finish') ||
      uri.queryParameters.containsKey('status');
}

PaymentReturnArgs? parsePaymentReturnArgs(
  Uri uri, {
  Set<String>? callbackHosts,
}) {
  if (!isWebPaymentCallbackUri(uri, callbackHosts: callbackHosts)) {
    return null;
  }

  final path = uri.path.toLowerCase();
  final explicitStatus = uri.queryParameters['status']?.trim();
  final inferredStatus = explicitStatus?.isNotEmpty == true
      ? explicitStatus!
      : path.contains('/success')
      ? 'SUCCESS'
      : path.contains('/cancel')
      ? 'CANCELED'
      : path.contains('/failure') || path.contains('/error')
      ? 'FAILED'
      : 'UNKNOWN';

  return PaymentReturnArgs(
    status: inferredStatus,
    bookingId: uri.queryParameters['booking_id'],
    correlationId: uri.queryParameters['correlation_id'],
    paymentId: uri.queryParameters['payment_id'],
    rawUri: uri,
  );
}
