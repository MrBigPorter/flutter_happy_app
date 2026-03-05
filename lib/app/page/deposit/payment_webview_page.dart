import 'dart:async';
import 'dart:js_interop'; // Required for WASM JS conversions
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// Optimization 1: Use package:web to support both mobile compilation and WASM
import 'package:web/web.dart' as web;

import 'deposit_result_page.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String url;
  final String orderNo;

  const PaymentWebViewPage({
    super.key,
    required this.url,
    required this.orderNo,
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  InAppWebViewController? _webViewController;
  double _progress = 0;
  final String _pageTitle = "Payment";

  // Use web.Window for WASM compatibility
  web.Window? _popupWindow;
  Timer? _checkTimer;

  // Optimization 2: Message listener using package:web EventStream
  StreamSubscription<web.MessageEvent>? _messageSubscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Release resources
    _checkTimer?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }

  /// Web specific: Monitor payment window status and messages
  void _startWebCheck() {
    _checkTimer?.cancel();
    _messageSubscription?.cancel();

    // A. Listen for postMessage (signal returned from the payment success page)
    _messageSubscription = web.window.onMessage.listen((web.MessageEvent event) {
      // Use dartify() to convert JSAny? to a Dart object safely in WASM
      final data = event.data?.dartify();

      // 'payment_success' is the string defined in your success.html
      if (data == 'payment_success') {
        _messageSubscription?.cancel();
        _checkTimer?.cancel();
        _popupWindow?.close();
        _goToResult();
      }
    });

    // B. Fallback: Check if the window was manually closed by the user
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_popupWindow != null && _popupWindow!.closed) {
        timer.cancel();
        _goToResult();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebLayout();

    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              useShouldOverrideUrlLoading: true,
              // Use Pixel 7 UA to bypass certain risk controls
              userAgent: "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36",
            ),
            onWebViewCreated: (controller) => _webViewController = controller,
            onProgressChanged: (_, p) => setState(() => _progress = p / 100),
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final urlString = navigationAction.request.url.toString();
              // Mobile interception logic
              if (urlString.contains('wallet/recharge/success')) {
                _goToResult();
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_progress < 1.0) LinearProgressIndicator(value: _progress),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Completing Payment")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              "Waiting for payment to complete...",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Payment window opened in a new tab",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              onPressed: _openWebPayment,
              label: const Text("Re-open Payment Window"),
            ),
            TextButton(
              onPressed: () => _goToResult(),
              child: const Text("I have paid, check status now"),
            ),
          ],
        ),
      ),
    );
  }

  void _openWebPayment() {
    // Open in a new tab/window and maintain the reference
    _popupWindow = web.window.open(widget.url, '_blank');
    _startWebCheck();
  }

  void _goToResult() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DepositResultPage(orderNo: widget.orderNo)),
    );
  }
}