import 'package:web/web.dart' as web;

/// Clears payment_return, offer_id, payment_request_id etc. from the current URL
/// so we don't re-trigger recovery on refresh. Uses package:web (not dart:html).
void clearPaymentReturnParamsFromUrl() {
  final path = web.window.location.pathname;
  final clean = (path.isEmpty) ? '/' : path;
  web.window.history.replaceState(null, '', clean);
}
