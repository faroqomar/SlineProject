import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sline_app/core/config/payment_runtime_config.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/booking/models/payment_return_args.dart';

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.initialUrl,
    this.callbackHosts = const {'sline.app'},
    this.expectedBookingId,
    this.expectedCorrelationId,
  });

  final String initialUrl;
  final Set<String> callbackHosts;
  final String? expectedBookingId;
  final String? expectedCorrelationId;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _loadError;
  bool _hasPopped = false;
  bool _isDisposed = false;

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
    return matchesBooking && matchesCorrelation;
  }

  bool _isTrustedWebCallback(Uri? uri) {
    if (uri == null || !_isTrustedCallbackHost(uri)) return false;
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1');
  }

  String? _describeUri(Uri? uri) {
    if (uri == null) return null;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port${uri.path}';
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    AppLogger.i(
      'Opening payment webview',
      tag: 'QiCard',
      json: <String, dynamic>{
        'initial_url': _describeUri(Uri.tryParse(widget.initialUrl)),
        'expected_booking_id': widget.expectedBookingId,
        'expected_correlation_id': widget.expectedCorrelationId,
        'callback_hosts': widget.callbackHosts.toList(),
      },
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            AppLogger.d(
              'Payment webview page started: ${_describeUri(Uri.tryParse(url))}',
              tag: 'QiCard',
            );
            _safeSetState(() {
              _isLoading = true;
              _loadError = null;
            });
          },
          onPageFinished: (url) {
            AppLogger.d(
              'Payment webview page finished: ${_describeUri(Uri.tryParse(url))}',
              tag: 'QiCard',
            );
            _safeSetState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            AppLogger.e(
              'Payment webview resource error',
              tag: 'QiCard',
              error: '${error.errorCode}: ${error.description}',
            );
            _safeSetState(() {
              _isLoading = false;
              _loadError = error.description;
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

            // QiCard success return URL: https://sline.app/payment/success
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
                tag: 'QiCard',
                error: _describeUri(uri) ?? 'UNKNOWN_CALLBACK_URL',
              );
              return NavigationDecision.prevent;
            }

            if (isAppSchemeFinish || isHttpsFinishWithStatus) {
              if (!matchesExpectedCallback) {
                AppLogger.w(
                  'Rejected payment finish callback due to booking/correlation mismatch',
                  tag: 'QiCard',
                  error: _describeUri(uri) ?? 'UNKNOWN_CALLBACK_URL',
                );
                return NavigationDecision.prevent;
              }
              final status = (uri.queryParameters['status'] ?? 'UNKNOWN')
                  .toUpperCase();
              final paymentId = uri.queryParameters['payment_id'];
              AppLogger.i(
                'Accepted payment finish callback status=$status',
                tag: 'QiCard',
                json: <String, dynamic>{
                  'booking_id': uri.queryParameters['booking_id'],
                  'correlation_id': uri.queryParameters['correlation_id'],
                  'payment_id': paymentId,
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
                  tag: 'QiCard',
                  error: _describeUri(uri) ?? 'UNKNOWN_CALLBACK_URL',
                );
                return NavigationDecision.prevent;
              }

              if (paymentReturn.isFailure) {
                AppLogger.w(
                  'Accepted payment failure callback status=${paymentReturn.normalizedStatus}',
                  tag: 'QiCard',
                  error: _describeUri(uri) ?? 'UNKNOWN_CALLBACK_URL',
                );
              } else {
                AppLogger.i(
                  'Accepted payment callback status=${paymentReturn.normalizedStatus}',
                  tag: 'QiCard',
                  json: <String, dynamic>{
                    'booking_id': paymentReturn.bookingId,
                    'correlation_id': paymentReturn.correlationId,
                    'payment_id': paymentReturn.paymentId,
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
                  tag: 'QiCard',
                  error: _describeUri(uri) ?? 'UNKNOWN_CALLBACK_URL',
                );
                return NavigationDecision.prevent;
              }
              AppLogger.i(
                'Accepted payment success callback',
                tag: 'QiCard',
                json: <String, dynamic>{
                  'booking_id': uri.queryParameters['booking_id'],
                  'correlation_id': uri.queryParameters['correlation_id'],
                  'payment_id': uri.queryParameters['payment_id'],
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
                  tag: 'QiCard',
                  error: _describeUri(uri) ?? 'UNKNOWN_CALLBACK_URL',
                );
                return NavigationDecision.prevent;
              }
              final status =
                  uri.queryParameters['status']?.toUpperCase() ??
                  (uri.path.contains('cancel') ? 'CANCELED' : 'FAILED');
              AppLogger.w(
                'Accepted payment failure callback status=$status',
                tag: 'QiCard',
                error: _describeUri(uri) ?? 'UNKNOWN_CALLBACK_URL',
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
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _handleBackNavigation() async {
    // Prevent any navigation if already disposed
    if (_isDisposed) return;

    try {
      if (await _controller.canGoBack()) {
        await _controller.goBack();
        return;
      }
    } catch (e) {
      // Controller might be disposed, fall through to pop
    }

    // Check current URL before returning CANCELED
    // If user is on a success/receipt page, return SUCCESS instead
    try {
      final currentUrl = await _controller.currentUrl();
      final uri = currentUrl != null ? Uri.tryParse(currentUrl) : null;

      if (uri != null) {
        final currentPath = uri.path.toLowerCase();
        final isTrustedCallback = _isTrustedWebCallback(uri);
        final matchesExpectedCallback = _matchesExpectedCallback(uri);

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
            tag: 'QiCard',
            json: <String, dynamic>{
              'booking_id': uri.queryParameters['booking_id'],
              'correlation_id': uri.queryParameters['correlation_id'],
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
            tag: 'QiCard',
            error: _describeUri(uri) ?? 'UNKNOWN_CURRENT_URL',
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
    } catch (e) {
      AppLogger.w(
        'Failed to inspect payment webview URL during back navigation',
        tag: 'QiCard',
        error: e,
      );
    }

    AppLogger.i(
      'Payment webview closed without callback; returning canceled',
      tag: 'QiCard',
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
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Center(child: CircularProgressIndicator(color: AppColors.teal)),
            if (_loadError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.lightRed),
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
                          _controller.reload();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
