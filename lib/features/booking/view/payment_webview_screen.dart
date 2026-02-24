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

  void _popWithResult(PaymentWebViewResult result) {
    if (!mounted || _hasPopped) return;
    _hasPopped = true;
    Navigator.of(context).pop(result);
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _loadError = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _loadError = error.description;
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final isAppSchemeFinish =
                uri != null &&
                uri.scheme == 'sline' &&
                uri.host == 'payment' &&
                uri.path.contains('finish');
            final isHttpsFinish =
                uri != null &&
                (uri.scheme == 'https' || uri.scheme == 'http') &&
                uri.path.contains('finish') &&
                uri.queryParameters.containsKey('status');
            if (isAppSchemeFinish || isHttpsFinish) {
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
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _handleBackNavigation() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
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
                          setState(() {
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
