import 'package:flutter/material.dart';
import 'package:flutter_app/theme/index.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'deposit_result_page.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String url;
  final String orderNo;

  const PaymentWebViewPage({
    super.key,
    required this.url,
    required this.orderNo
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  // 1. 定义进度状态
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _goToResult(), // 手动关闭也去查单
        ),
      ),
      // 2. 使用 Stack 叠加进度条
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              useHybridComposition: true, // Android 键盘适配关键
              javaScriptEnabled: true,
              // iOS 允许滑动返回，体验更好
              allowsBackForwardNavigationGestures: true,
            ),

            // 3. 监听加载进度
            onProgressChanged: (controller, progress) {
              setState(() {
                _progress = progress / 100;
              });
            },

            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url!;
              final urlString = uri.toString();
              final scheme = uri.scheme;

              // --- A. 拦截业务回调 (成功/失败) ---
              // 包含判断逻辑 (Compatible with localhost/http/https)
              if (urlString.contains('/wallet/recharge/success')) {
                _goToResult();
                return NavigationActionPolicy.CANCEL;
              }

              if (urlString.contains('/wallet/recharge/failure')) {
                Navigator.pop(context); // 失败直接关闭
                return NavigationActionPolicy.CANCEL;
              }

              // --- B. 拦截第三方 App (Deep Link) ---
              // 逻辑优化：排除掉所有“网页”相关的协议，剩下的默认都当做 App 唤起请求
              // 这样以后接入新的钱包（如 shopeepay://）也不用改代码
              final isWebScheme = ["http", "https", "file", "chrome", "data", "javascript", "about"].contains(scheme);

              if (!isWebScheme) {
                try {
                  if (await canLaunchUrl(uri)) {
                    // mode: externalApplication 是唤起其他 App 的关键
                    await launchUrl(uri, mode: LaunchMode.externalApplication);

                    // 这里通常不需要关闭 WebView，因为用户可能付完钱还要跳回来
                    return NavigationActionPolicy.CANCEL;
                  }
                } catch (e) {
                  print("无法唤起 App: $e");
                }
                // 如果唤起失败（比如用户没装 App），是否要允许加载？
                // 通常 Deep Link 在 WebView 里加载会报错，所以 CANCEL 比较稳妥
                return NavigationActionPolicy.CANCEL;
              }

              // --- C. 普通网页 (http/https) ---
              return NavigationActionPolicy.ALLOW;
            },
          ),

          // 4. 进度条组件 (加载完自动消失)
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              color: context.utilityBrand500,
              backgroundColor: Colors.transparent,
              minHeight: 2, // 细一点比较优雅
            ),
        ],
      ),
    );
  }

  void _goToResult() {
    // 使用 pushReplacement 销毁当前的 WebView，防止用户点返回键又回到支付页
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DepositResultPage(orderNo: widget.orderNo)),
    );
  }
}