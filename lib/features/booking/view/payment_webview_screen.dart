import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sline_app/core/theme/app_colors.dart';

class PaymentWebViewResult {
  const PaymentWebViewResult({
    required this.status,
    this.paymentId,
    this.rawUri,
  });

  final String status;
  final String? paymentId;
  final Uri? rawUri;
}

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key, required this.initialUrl});

  final String initialUrl;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _loadError;
  bool _hasPopped = false;
  bool _isDisposed = false;

  void _popWithResult(PaymentWebViewResult result) {
    if (!mounted || _hasPopped || _isDisposed) return;
    _hasPopped = true;
    Navigator.of(context).pop(result);
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            _safeSetState(() {
              _isLoading = true;
              _loadError = null;
            });
          },
          onPageFinished: (_) {
            _safeSetState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            _safeSetState(() {
              _isLoading = false;
              _loadError = error.description;
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);

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
                uri.path.contains('finish') &&
                uri.queryParameters.containsKey('status');

            // QiCard success return URL: https://sline.app/payment/success
            // Or any URL containing /payment/success in the path
            final isPaymentSuccessUrl =
                uri != null &&
                (uri.scheme == 'https' || uri.scheme == 'http') &&
                (uri.path.contains('/payment/success') ||
                 uri.path.endsWith('/success') && uri.path.contains('payment'));

            // QiCard failure/cancel URLs
            final isPaymentFailureUrl =
                uri != null &&
                (uri.scheme == 'https' || uri.scheme == 'http') &&
                (uri.path.contains('/payment/failure') ||
                 uri.path.contains('/payment/cancel') ||
                 uri.path.contains('/payment/error'));

            if (isAppSchemeFinish || isHttpsFinishWithStatus) {
              final status = (uri.queryParameters['status'] ?? 'UNKNOWN')
                  .toUpperCase();
              final paymentId = uri.queryParameters['payment_id'];
              _popWithResult(
                PaymentWebViewResult(
                  status: status,
                  paymentId: paymentId,
                  rawUri: uri,
                ),
              );
              return NavigationDecision.prevent;
            }

            // Handle QiCard success return URL
            if (isPaymentSuccessUrl) {
              _popWithResult(
                PaymentWebViewResult(
                  status: 'SUCCESS',
                  paymentId: uri.queryParameters['payment_id'],
                  rawUri: uri,
                ),
              );
              return NavigationDecision.prevent;
            }

            // Handle QiCard failure/cancel return URL
            if (isPaymentFailureUrl) {
              final status = uri.queryParameters['status']?.toUpperCase() ??
                  (uri.path.contains('cancel') ? 'CANCELED' : 'FAILED');
              _popWithResult(
                PaymentWebViewResult(
                  status: status,
                  paymentId: uri.queryParameters['payment_id'],
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
        final currentUrlStr = currentUrl?.toLowerCase() ?? '';

        // Check if we're on a success/receipt page
        final isOnSuccessPage =
            currentPath.contains('/payment/success') ||
            currentPath.contains('/receipt') ||
            currentPath.contains('/processed') ||
            (currentUrlStr.contains('qi') && currentPath.contains('success'));

        // Check if we're on a failure/cancel page
        final isOnFailurePage =
            currentPath.contains('/payment/failure') ||
            currentPath.contains('/payment/cancel') ||
            currentPath.contains('/payment/error') ||
            currentPath.contains('/404');

        if (isOnSuccessPage) {
          _popWithResult(const PaymentWebViewResult(status: 'SUCCESS'));
          return;
        }

        if (isOnFailurePage) {
          final status = currentPath.contains('cancel') ? 'CANCELED' : 'FAILED';
          _popWithResult(PaymentWebViewResult(status: status));
          return;
        }
      }
    } catch (e) {
      // Fallback to CANCELED if we can't determine status
    }

    _popWithResult(const PaymentWebViewResult(status: 'CANCELED'));
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
