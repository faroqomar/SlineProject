import 'package:sline_app/core/models/payment_return_args.dart';

const String kQiCardFinishUrl = String.fromEnvironment(
  'QICARD_FINISH_URL',
  defaultValue: 'https://sline.app/?payment_return=1',
);

Set<String> buildQiCardCallbackHosts({String? finishUrl}) {
  final hosts = <String>{};
  final configuredHost = Uri.tryParse(
    finishUrl ?? kQiCardFinishUrl,
  )?.host.toLowerCase();

  if (configuredHost != null && configuredHost.isNotEmpty) {
    hosts.add(configuredHost);
  }

  if (hosts.isEmpty) {
    hosts.add('sline.app');
  }

  return hosts;
}

String buildQiCardFinishUrlForRuntime({
  Uri? runtimeUri,
  String? fallbackFinishUrl,
}) {
  final runtimeCandidate = runtimeUri ?? Uri.base;
  if (_isTrustedRuntimeFinishUri(runtimeCandidate)) {
    return _normalizeRuntimeFinishUri(runtimeCandidate).toString();
  }

  final fallbackCandidate = Uri.tryParse(fallbackFinishUrl ?? kQiCardFinishUrl);
  if (fallbackCandidate != null &&
      _isTrustedRuntimeFinishUri(fallbackCandidate)) {
    return _normalizeRuntimeFinishUri(fallbackCandidate).toString();
  }

  return kQiCardFinishUrl;
}

bool _isTrustedRuntimeFinishUri(Uri uri) {
  if (uri.host.isEmpty) {
    return false;
  }

  if (uri.scheme == 'https') {
    return true;
  }

  return uri.scheme == 'http' &&
      (uri.host == 'localhost' || uri.host == '127.0.0.1');
}

Uri _normalizeRuntimeFinishUri(Uri uri) {
  return uri.replace(
    queryParameters: const <String, String>{'payment_return': '1'},
    fragment: null,
  );
}

bool isWebPaymentCallbackUri(Uri uri, {Set<String>? callbackHosts}) {
  final hosts = callbackHosts ?? buildQiCardCallbackHosts();
  final host = uri.host.toLowerCase();
  final hostAllowed =
      hosts.contains(host) || (host == 'localhost' || host == '127.0.0.1');
  if (!hostAllowed) {
    return false;
  }

  final isTrustedScheme =
      uri.scheme == 'https' ||
      (uri.scheme == 'http' && (host == 'localhost' || host == '127.0.0.1'));
  if (!isTrustedScheme) {
    return false;
  }

  final path = uri.path.toLowerCase();
  final query = uri.queryParameters;
  final hasPaymentPath = path.contains('/payment/');
  final hasRootPaymentSignal =
      query['payment_return'] == '1' ||
      query.containsKey('status') ||
      query.containsKey('payment_id') ||
      (query.containsKey('booking_id') &&
          (query.containsKey('correlation_id') ||
              query['payment_return'] == '1')) ||
      (query.containsKey('request_id') &&
          query.containsKey('payment_request_id'));

  if (!hasPaymentPath && !hasRootPaymentSignal) {
    return false;
  }

  return path.contains('/success') ||
      path.contains('/failure') ||
      path.contains('/cancel') ||
      path.contains('/error') ||
      path.contains('/finish') ||
      hasRootPaymentSignal;
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
  final inferredStatus = explicitStatus?.isNotEmpty ?? false
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
    offerId: uri.queryParameters['offer_id'],
    requestId: uri.queryParameters['request_id'],
    paymentRequestId: uri.queryParameters['payment_request_id'],
    rawUri: uri,
  );
}

bool shouldResumePendingWebPayment({
  required Uri currentUri,
  required DateTime startedAt,
  Set<String>? callbackHosts,
  String? expectedReturnUrl,
  Duration maxAge = const Duration(minutes: 45),
}) {
  if (!_isTrustedRuntimeFinishUri(currentUri)) {
    return false;
  }

  if (DateTime.now().toUtc().difference(startedAt.toUtc()) > maxAge) {
    return false;
  }

  final expectedUri = Uri.tryParse(expectedReturnUrl ?? '');
  if (expectedUri != null && _isTrustedRuntimeFinishUri(expectedUri)) {
    final currentPath = currentUri.path.isEmpty ? '/' : currentUri.path;
    final expectedPath = expectedUri.path.isEmpty ? '/' : expectedUri.path;
    return currentUri.host.toLowerCase() == expectedUri.host.toLowerCase() &&
        currentPath == expectedPath;
  }

  final hosts = callbackHosts ?? const <String>{};
  if (hosts.isEmpty) {
    return false;
  }

  return hosts.contains(currentUri.host.toLowerCase());
}
