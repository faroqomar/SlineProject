import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

/// Sets [WebViewPlatform.instance] for web so in-app WebView works.
void initWebViewPlatform() {
  WebViewPlatform.instance = WebWebViewPlatform();
}
