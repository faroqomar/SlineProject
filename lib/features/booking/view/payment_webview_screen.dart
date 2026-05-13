import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sline_app/core/config/payment_runtime_config.dart';
import 'package:sline_app/core/services/crash_reporting_service.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/features/booking/models/payment_return_args.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.initialUrl,
    this.callbackHosts = const {'sline.app'},
    this.expectedBookingId,
    this.expectedCorrelationId,
    this.expectedOfferId,
    this.expectedRequestId,
    this.paymentIntentId,
    this.paymentIntentStatusStream,
  });

  final String initialUrl;
  final Set<String> callbackHosts;
  final String? expectedBookingId;
  final String? expectedCorrelationId;

  /// For direct-offer payments: callback URL may include offer_id.
  final String? expectedOfferId;

  /// For tender (task_request) payments: callback URL may include request_id.
  final String? expectedRequestId;

  /// When set with [paymentIntentStatusStream], webview pops on realtime succeeded/failed.
  final String? paymentIntentId;

  /// Realtime stream for payment_intents.status; when status is succeeded/failed, pop with result.
  final Stream<String>? paymentIntentStatusStream;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _loadError;
  bool _hasPopped = false;
  bool _isDisposed = false;
  StreamSubscription<String>? _intentStatusSubscription;

  /// On web, WebView platform does not implement NavigationDelegate; use external browser + manual completion.
  bool _useWebFallback = false;

  void _popWithResult(PaymentReturnArgs result) {
    if (!mounted || _hasPopped || _isDisposed) return;
    _hasPopped = true;
    Navigator.of(context).pop(result);
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  bool _isTrustedCallbackHost(Uri? uri) {
    if (uri == null) return false;
    return widget.callbackHosts.contains(uri.host.toLowerCase());
  }

  bool _matchesExpectedCallback(Uri? uri) {
    if (uri == null) return false;
    final matchesBooking =
        widget.expectedBookingId == null ||
        uri.queryParameters['booking_id'] == widget.expectedBookingId;
    final matchesCorrelation =
        widget.expectedCorrelationId == null ||
        uri.queryParameters['correlation_id'] == widget.expectedCorrelationId;
    final matchesOffer =
        widget.expectedOfferId == null ||
        uri.queryParameters['offer_id'] == widget.expectedOfferId;
    final matchesRequest =
        widget.expectedRequestId == null ||
        uri.queryParameters['request_id'] == widget.expectedRequestId;
    return matchesBooking &&
        matchesCorrelation &&
        matchesOffer &&
        matchesRequest;
  }

  bool _isTrustedWebCallback(Uri? uri) {
    if (uri == null || !_isTrustedCallbackHost(uri)) return false;
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1');
  }

  String _schemeKind(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'https' || scheme == 'http') return scheme;
    if (scheme == 'sline') return 'app_scheme';
    return scheme.isEmpty ? 'missing' : 'other';
  }

  String _paymentPathKind(Uri uri) {
    final path = uri.path.toLowerCase();
    if (uri.scheme == 'sline' && uri.host == 'payment') return 'app_payment';
    if (path.contains('/payment/success') ||
        (path.endsWith('/success') && path.contains('payment'))) {
      return 'payment_success';
    }
    if (path.contains('/payment/failure') ||
        path.contains('/payment/cancel') ||
        path.contains('/payment/error')) {
      return 'payment_failure';
    }
    if (path.contains('finish')) return 'payment_finish';
    if (path.isEmpty || path == '/') return 'root';
    return 'other';
  }

  Map<String, dynamic> _paymentUrlFacts(Uri? uri) {
    if (uri == null) return const {'url_state': 'unparsed'};
    // Payment URLs can include gateway structure, so logs record only
    // non-identifying classifications and query-key presence.
    return <String, dynamic>{
      'url_state': 'parsed',
      'scheme_kind': _schemeKind(uri),
      'path_kind': _paymentPathKind(uri),
      'trusted_callback_host': _isTrustedCallbackHost(uri),
      'trusted_web_callback': _isTrustedWebCallback(uri),
      'has_status': uri.queryParameters.containsKey('status'),
      'has_booking': uri.queryParameters['booking_id'] != null,
      'has_correlation': uri.queryParameters['correlation_id'] != null,
      'has_payment_reference': uri.queryParameters['payment_id'] != null,
      'has_offer': uri.queryParameters['offer_id'] != null,
      'has_request': uri.queryParameters['request_id'] != null,
    };
  }

  String _paymentUrlCode(Uri? uri, String fallback) {
    if (uri == null) return fallback;
    return 'PAYMENT_URL_${_schemeKind(uri).toUpperCase()}_'
        '${_paymentPathKind(uri).toUpperCase()}';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _intentStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    AppLogger.i(
      'Opening payment webview',
      tag: 'Payment',
      json: <String, dynamic>{
        'initial_url_facts': _paymentUrlFacts(Uri.tryParse(widget.initialUrl)),
        'has_expected_booking': widget.expectedBookingId != null,
        'has_expected_correlation': widget.expectedCorrelationId != null,
        'has_expected_offer': widget.expectedOfferId != null,
        'has_payment_intent': widget.paymentIntentId != null,
        'callback_host_count': widget.callbackHosts.length,
      },
    );

    if (widget.paymentIntentStatusStream != null) {
      _intentStatusSubscription = widget.paymentIntentStatusStream!.listen((
        status,
      ) {
        if (_hasPopped || _isDisposed) return;
        AppLogger.i(
          'Payment intent realtime status in webview: $status',
          tag: 'Payment',
          json: <String, dynamic>{
            'has_intent': widget.paymentIntentId != null,
            'status': status,
          },
        );
        if (status == 'succeeded' || status == 'failed') {
          _intentStatusSubscription?.cancel();
          _popWithResult(
            PaymentReturnArgs(
              paymentId: null,
              correlationId: widget.expectedCorrelationId,
              status: status == 'succeeded' ? 'SUCCESS' : 'FAILED',
              rawUri: Uri.parse('sline://payment_sync?status=$status'),
            ),
          );
        }
      });
    }

    if (kIsWeb) {
      _useWebFallback = true;
      _isLoading = false;
      return;
    }

    _controller = WebViewController();
    _controller!.setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller!.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          final pageUri = Uri.tryParse(url);
          AppLogger.d(
            'Payment webview page started',
            tag: 'Payment',
            json: _paymentUrlFacts(pageUri),
          );
          _safeSetState(() {
            _isLoading = true;
            _loadError = null;
          });
        },
        onPageFinished: (url) {
          final pageUri = Uri.tryParse(url);
          AppLogger.d(
            'Payment webview page finished',
            tag: 'Payment',
            json: _paymentUrlFacts(pageUri),
          );
          _safeSetState(() {
            _isLoading = false;
          });
        },
        onWebResourceError: (error) {
          final normalizedCode = 'WEBVIEW_${error.errorCode}';
          AppLogger.e(
            'Payment webview resource error',
            tag: 'Payment',
            error: normalizedCode,
            json: <String, dynamic>{
              'description': error.description,
              'error_type': error.errorType.toString(),
            },
          );
          unawaited(
            CrashReportingService.instance.recordError(
              error,
              StackTrace.current,
              reason: normalizedCode,
            ),
          );
          _safeSetState(() {
            _isLoading = false;
            _loadError = 'Payment page could not load.';
          });
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          final isTrustedHost = _isTrustedCallbackHost(uri);
          final isTrustedCallbackHost = _isTrustedWebCallback(uri);
          final matchesExpectedCallback = _matchesExpectedCallback(uri);
          final paymentReturn = uri == null
              ? null
              : parsePaymentReturnArgs(
                  uri,
                  callbackHosts: widget.callbackHosts,
                );

          // App scheme deep link: sline://payment/finish?status=...
          final isAppSchemeFinish =
              uri != null &&
              uri.scheme == 'sline' &&
              uri.host == 'payment' &&
              uri.path.contains('finish');

          // HTTPS finish URLs with status parameter
          final isHttpsFinishWithStatus =
              uri != null &&
              (uri.scheme == 'https' || uri.scheme == 'http') &&
              isTrustedCallbackHost &&
              uri.path.contains('finish') &&
              uri.queryParameters.containsKey('status');

          // QiCard success return paths stay classified before logging.
          // Or any URL containing /payment/success in the path
          final isPaymentSuccessUrl =
              uri != null &&
              (uri.scheme == 'https' || uri.scheme == 'http') &&
              isTrustedCallbackHost &&
              (uri.path.contains('/payment/success') ||
                  uri.path.endsWith('/success') &&
                      uri.path.contains('payment'));

          // QiCard failure/cancel URLs
          final isPaymentFailureUrl =
              uri != null &&
              (uri.scheme == 'https' || uri.scheme == 'http') &&
              isTrustedCallbackHost &&
              (uri.path.contains('/payment/failure') ||
                  uri.path.contains('/payment/cancel') ||
                  uri.path.contains('/payment/error'));

          if (uri != null &&
              isTrustedHost &&
              !isTrustedCallbackHost &&
              uri.scheme != 'sline') {
            AppLogger.w(
              'Rejected insecure payment callback URL',
              tag: 'Payment',
              error: _paymentUrlCode(uri, 'UNKNOWN_CALLBACK_URL'),
              json: _paymentUrlFacts(uri),
            );
            return NavigationDecision.prevent;
          }

          if (isAppSchemeFinish || isHttpsFinishWithStatus) {
            if (!matchesExpectedCallback) {
              AppLogger.w(
                'Rejected payment finish callback due to booking/correlation mismatch',
                tag: 'Payment',
                error: _paymentUrlCode(uri, 'UNKNOWN_CALLBACK_URL'),
                json: _paymentUrlFacts(uri),
              );
              return NavigationDecision.prevent;
            }
            final status = (uri.queryParameters['status'] ?? 'UNKNOWN')
                .toUpperCase();
            final paymentId = uri.queryParameters['payment_id'];
            AppLogger.i(
              'Accepted payment finish callback status=$status',
              tag: 'Payment',
              json: <String, dynamic>{
                'has_booking': uri.queryParameters['booking_id'] != null,
                'has_correlation':
                    uri.queryParameters['correlation_id'] != null,
                'has_payment_reference': paymentId != null,
              },
            );
            _popWithResult(
              PaymentReturnArgs(
                status: status,
                paymentId: paymentId,
                bookingId: uri.queryParameters['booking_id'],
                correlationId: uri.queryParameters['correlation_id'],
                rawUri: uri,
              ),
            );
            return NavigationDecision.prevent;
          }

          if (paymentReturn != null) {
            if (!matchesExpectedCallback) {
              AppLogger.w(
                'Rejected payment callback due to booking/correlation mismatch',
                tag: 'Payment',
                error: _paymentUrlCode(uri, 'UNKNOWN_CALLBACK_URL'),
                json: _paymentUrlFacts(uri),
              );
              return NavigationDecision.prevent;
            }

            if (paymentReturn.isFailure) {
              AppLogger.w(
                'Accepted payment failure callback status=${paymentReturn.normalizedStatus}',
                tag: 'Payment',
                error: _paymentUrlCode(uri, 'UNKNOWN_CALLBACK_URL'),
                json: _paymentUrlFacts(uri),
              );
            } else {
              AppLogger.i(
                'Accepted payment callback status=${paymentReturn.normalizedStatus}',
                tag: 'Payment',
                json: <String, dynamic>{
                  'has_booking': paymentReturn.bookingId != null,
                  'has_correlation': paymentReturn.correlationId != null,
                  'has_payment_reference': paymentReturn.paymentId != null,
                },
              );
            }
            _popWithResult(paymentReturn);
            return NavigationDecision.prevent;
          }

          // Handle QiCard success return URL
          if (isPaymentSuccessUrl) {
            if (!matchesExpectedCallback) {
              AppLogger.w(
                'Rejected payment success callback due to booking/correlation mismatch',
                tag: 'Payment',
                error: _paymentUrlCode(uri, 'UNKNOWN_CALLBACK_URL'),
                json: _paymentUrlFacts(uri),
              );
              return NavigationDecision.prevent;
            }
            AppLogger.i(
              'Accepted payment success callback',
              tag: 'Payment',
              json: <String, dynamic>{
                'has_booking': uri.queryParameters['booking_id'] != null,
                'has_correlation':
                    uri.queryParameters['correlation_id'] != null,
                'has_payment_reference':
                    uri.queryParameters['payment_id'] != null,
              },
            );
            _popWithResult(
              PaymentReturnArgs(
                status: 'SUCCESS',
                paymentId: uri.queryParameters['payment_id'],
                bookingId: uri.queryParameters['booking_id'],
                correlationId: uri.queryParameters['correlation_id'],
                rawUri: uri,
              ),
            );
            return NavigationDecision.prevent;
          }

          // Handle QiCard failure/cancel return URL
          if (isPaymentFailureUrl) {
            if (!matchesExpectedCallback) {
              AppLogger.w(
                'Rejected payment failure callback due to booking/correlation mismatch',
                tag: 'Payment',
                error: _paymentUrlCode(uri, 'UNKNOWN_CALLBACK_URL'),
                json: _paymentUrlFacts(uri),
              );
              return NavigationDecision.prevent;
            }
            final status =
                uri.queryParameters['status']?.toUpperCase() ??
                (uri.path.contains('cancel') ? 'CANCELED' : 'FAILED');
            AppLogger.w(
              'Accepted payment failure callback status=$status',
              tag: 'Payment',
              error: _paymentUrlCode(uri, 'UNKNOWN_CALLBACK_URL'),
              json: _paymentUrlFacts(uri),
            );
            _popWithResult(
              PaymentReturnArgs(
                status: status,
                paymentId: uri.queryParameters['payment_id'],
                bookingId: uri.queryParameters['booking_id'],
                correlationId: uri.queryParameters['correlation_id'],
                rawUri: uri,
              ),
            );
            return NavigationDecision.prevent;
          }

          return NavigationDecision.navigate;
        },
      ),
    );
    _controller!.loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _handleBackNavigation() async {
    if (_isDisposed) return;
    if (_useWebFallback) {
      _popWithResult(
        PaymentReturnArgs(status: 'CANCELED', rawUri: Uri.parse('about:blank')),
      );
      return;
    }

    try {
      if (await _controller!.canGoBack()) {
        await _controller!.goBack();
        return;
      }
    } on Exception catch (_) {
      // Controller might be disposed, fall through to pop
    }

    // Check current URL before returning CANCELED
    // If user is on a success/receipt page, return SUCCESS instead
    try {
      final currentUrl = await _controller!.currentUrl();
      final uri = currentUrl != null ? Uri.tryParse(currentUrl) : null;

      if (uri != null) {
        final paymentReturn = parsePaymentReturnArgs(
          uri,
          callbackHosts: widget.callbackHosts,
        );
        final currentPath = uri.path.toLowerCase();
        final isTrustedCallback = _isTrustedWebCallback(uri);
        final matchesExpectedCallback = _matchesExpectedCallback(uri);

        if (paymentReturn != null &&
            matchesExpectedCallback &&
            isTrustedCallback) {
          AppLogger.i(
            'Back navigation resolved to payment callback status=${paymentReturn.normalizedStatus}',
            tag: 'Payment',
            json: <String, dynamic>{
              'has_booking': paymentReturn.bookingId != null,
              'has_correlation': paymentReturn.correlationId != null,
              'has_payment_reference': paymentReturn.paymentId != null,
            },
          );
          _popWithResult(paymentReturn);
          return;
        }

        // Check if we're on a success/receipt page
        final isOnSuccessPage =
            isTrustedCallback &&
            matchesExpectedCallback &&
            (currentPath.contains('/payment/success') ||
                (currentPath.contains('finish') &&
                    uri.queryParameters.containsKey('status')));

        // Check if we're on a failure/cancel page
        final isOnFailurePage =
            isTrustedCallback &&
            matchesExpectedCallback &&
            (currentPath.contains('/payment/failure') ||
                currentPath.contains('/payment/cancel') ||
                currentPath.contains('/payment/error'));

        if (isOnSuccessPage) {
          AppLogger.i(
            'Back navigation resolved to payment success page',
            tag: 'Payment',
            json: <String, dynamic>{
              'has_booking': uri.queryParameters['booking_id'] != null,
              'has_correlation': uri.queryParameters['correlation_id'] != null,
            },
          );
          _popWithResult(
            PaymentReturnArgs(
              status: 'SUCCESS',
              bookingId: uri.queryParameters['booking_id'],
              correlationId: uri.queryParameters['correlation_id'],
              rawUri: uri,
            ),
          );
          return;
        }

        if (isOnFailurePage) {
          final status = currentPath.contains('cancel') ? 'CANCELED' : 'FAILED';
          AppLogger.w(
            'Back navigation resolved to payment failure page status=$status',
            tag: 'Payment',
            error: _paymentUrlCode(uri, 'UNKNOWN_CURRENT_URL'),
            json: _paymentUrlFacts(uri),
          );
          _popWithResult(
            PaymentReturnArgs(
              status: status,
              bookingId: uri.queryParameters['booking_id'],
              correlationId: uri.queryParameters['correlation_id'],
              rawUri: uri,
            ),
          );
          return;
        }
      }
    } on Exception catch (e, st) {
      AppLogger.w(
        'Failed to inspect payment webview URL during back navigation',
        tag: 'Payment',
        error: e.runtimeType.toString(),
      );
      unawaited(
        CrashReportingService.instance.recordError(
          e,
          st,
          reason: 'payment_webview_back_navigation_inspection_failed',
        ),
      );
    }

    AppLogger.i(
      'Payment webview closed without callback; returning canceled',
      tag: 'Payment',
    );
    _popWithResult(
      PaymentReturnArgs(status: 'CANCELED', rawUri: Uri.parse('about:blank')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete Payment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _handleBackNavigation();
            },
          ),
        ),
        body: _useWebFallback
            ? _buildWebFallbackBody(context)
            : _buildWebViewBody(context),
      ),
    );
  }

  Widget _buildWebFallbackBody(BuildContext context) {
    final uri = Uri.tryParse(widget.initialUrl);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppDimens.p16),
            Icon(
              Icons.open_in_browser,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppDimens.p16),
            Text(
              'Payment in browser',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.p8),
            Text(
              "You'll leave this page to pay securely. After payment you'll be brought back here and your payment will be completed automatically.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.p24),
            FilledButton.icon(
              onPressed: uri != null
                  ? () async {
                      final messenger = ScaffoldMessenger.of(context);
                      // Open in same tab so QiCard redirect back lands here with payment_return=1&request_id&payment_request_id and dashboard runs recovery
                      final launched = await launchUrl(
                        uri,
                        webOnlyWindowName: '_self',
                      );
                      if (!launched) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Could not open payment link'),
                          ),
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.payment),
              label: const Text('Open payment page'),
            ),
            const SizedBox(height: AppDimens.p12),
            FilledButton.tonalIcon(
              onPressed: () {
                AppLogger.i(
                  'Web fallback: user completed payment',
                  tag: 'Payment',
                );
                _popWithResult(
                  PaymentReturnArgs(
                    status: 'SUCCESS',
                    rawUri: uri ?? Uri.parse('about:blank'),
                    bookingId: widget.expectedBookingId,
                    correlationId: widget.expectedCorrelationId,
                    offerId: widget.expectedOfferId,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("I've completed payment"),
            ),
            const SizedBox(height: AppDimens.p8),
            TextButton(
              onPressed: _handleBackNavigation,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebViewBody(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_isLoading)
          Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        if (_loadError != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: colorScheme.danger),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load payment page.\n$_loadError',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      if (_isDisposed) return;
                      _safeSetState(() {
                        _isLoading = true;
                        _loadError = null;
                      });
                      _controller?.reload();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
