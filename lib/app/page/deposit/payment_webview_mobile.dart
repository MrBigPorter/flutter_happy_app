import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'deposit_result_page.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String url;
  final String orderNo;
  const PaymentWebViewPage({super.key, required this.url, required this.orderNo});
  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewMobileState();
}

class _PaymentWebViewMobileState extends State<PaymentWebViewPage> {
  InAppWebViewController? _webViewController;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true, domStorageEnabled: true, useShouldOverrideUrlLoading: true,
              userAgent: "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36",
            ),
            onWebViewCreated: (controller) => _webViewController = controller,
            onProgressChanged: (_, p) => setState(() => _progress = p / 100),
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              if (navigationAction.request.url.toString().contains('wallet/recharge/success')) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => DepositResultPage(orderNo: widget.orderNo)));
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
}