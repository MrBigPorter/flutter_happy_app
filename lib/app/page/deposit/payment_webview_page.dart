import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'deposit_result_page.dart';

// 优化 1：使用 universal_html 解决移动端编译报错问题
import 'package:universal_html/html.dart' as html;

class PaymentWebViewPage extends StatefulWidget {
  final String url;
  final String orderNo;

  const PaymentWebViewPage({super.key, required this.url, required this.orderNo});

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  InAppWebViewController? _webViewController;
  double _progress = 0;
  String _pageTitle = "Payment";
  html.WindowBase? _popupWindow;
  Timer? _checkTimer;
  StreamSubscription? _messageSubscription; // 优化 2：消息监听器

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _messageSubscription?.cancel(); // 释放资源
    super.dispose();
  }

  // Web 端专用：监听支付窗口状态和消息
  void _startWebCheck() {
    _checkTimer?.cancel();
    _messageSubscription?.cancel();

    // A. 监听 postMessage (支付成功页传回的信号)
    _messageSubscription = html.window.onMessage.listen((event) {
      print("Received message from payment window: ${event.data}");
      // 这里的 'payment_success' 是你 success.html 里定义的字符串
      if (event.data == 'payment_success') {
        _messageSubscription?.cancel();
        _checkTimer?.cancel();
        _popupWindow?.close();
        _goToResult();
      }
    });

    // B. 兜底：监听窗口是否被手动关闭
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_popupWindow != null && _popupWindow!.closed == true) {
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
              // 使用 Pixel 7 UA 避开部分风控
              userAgent: "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36",
            ),
            onWebViewCreated: (controller) => _webViewController = controller,
            onProgressChanged: (_, p) => setState(() => _progress = p / 100),
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final urlString = navigationAction.request.url.toString();
              // 移动端拦截逻辑
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
            const Text("Waiting for payment to complete...",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("Payment window opened in a new tab",
                style: TextStyle(color: Colors.grey)),
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
    // 使用 window.open 保持引用
    html.window.location.href = widget.url;
    _startWebCheck();
  }

  void _goToResult() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DepositResultPage(orderNo: widget.orderNo)),
    );
  }
}