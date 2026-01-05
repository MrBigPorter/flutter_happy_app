import 'package:flutter/material.dart';
import 'package:flutter_app/theme/index.dart'; // 你的主题
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
  InAppWebViewController? _webViewController;
  double _progress = 0;
  String _pageTitle = "Payment"; // 动态标题
  bool _canGoBack = false; // 是否可后退
  bool _isError = false; // 是否加载出错

  @override
  Widget build(BuildContext context) {
    // 1. PopScope: 拦截安卓物理返回键
    return PopScope(
      canPop: false, // 接管返回逻辑
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _pageTitle,
            style: const TextStyle(fontSize: 16), // 标题小一点，防止太长
          ),
          centerTitle: true,
          // 2. 双按钮导航栏：左边是关闭，如果能后退显示后退
          leadingWidth: 80, // 加宽以容纳两个按钮
          leading: Row(
            children: [
              // 关闭按钮 (总是显示)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _showExitDialog(), // 防止误触，弹窗确认
              ),
              // 后退按钮 (只有网页能后退时才显示)
              if (_canGoBack)
                Expanded( // 避免溢出
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    onPressed: () => _webViewController?.goBack(),
                  ),
                ),
            ],
          ),
          actions: [
            // 刷新按钮 (万一卡住)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _webViewController?.reload(),
            ),
          ],
        ),
        body: Stack(
          children: [
            _isError
                ? _buildErrorView() // 3. 错误页面兜底
                : InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                useHybridComposition: true, // Android 必开
                javaScriptEnabled: true,
                allowsBackForwardNavigationGestures: true, // iOS 滑动返回
              ),

              onWebViewCreated: (controller) {
                _webViewController = controller;
              },

              // 监听标题变化
              onTitleChanged: (controller, title) {
                if (title != null && title.isNotEmpty) {
                  setState(() => _pageTitle = title);
                }
              },

              // 监听进度
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },

              // 监听历史记录变化 (控制后退按钮显隐)
              onUpdateVisitedHistory: (controller, url, androidIsReload) async {
                final canGoBack = await controller.canGoBack();
                setState(() {
                  _canGoBack = canGoBack;
                });
              },

              // 监听加载错误 (断网等)
              onReceivedError: (controller, request, error) {
                // 忽略特定的 cancel 错误 (比如拦截 deep link 导致的)
                if (error.type != WebResourceErrorType.CANCELLED) {
                  setState(() => _isError = true);
                }
              },

              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url!;
                final urlString = uri.toString();
                final scheme = uri.scheme;

                // --- A. 业务回调 ---
                if (urlString.contains('/wallet/recharge/success')) {
                  _goToResult();
                  return NavigationActionPolicy.CANCEL;
                }
                if (urlString.contains('/wallet/recharge/failure')) {
                  Navigator.pop(context);
                  return NavigationActionPolicy.CANCEL;
                }

                // --- B. 第三方 App (Deep Link) ---
                final isWebScheme = ["http", "https", "file", "about"].contains(scheme);
                if (!isWebScheme) {
                  try {
                    // Android 上有时 canLaunchUrl 会返回 false 但其实能打开 (package visibility 限制)
                    // 所以可以直接 try launch
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    return NavigationActionPolicy.CANCEL;
                  } catch (e) {
                    print("App launch failed: $e");
                  }
                  return NavigationActionPolicy.CANCEL;
                }

                return NavigationActionPolicy.ALLOW;
              },
            ),

            // 4. 进度条 (带淡出动画)
            if (_progress < 1.0 && !_isError)
              LinearProgressIndicator(
                value: _progress,
                color: context.utilityBrand500,
                backgroundColor: Colors.transparent,
                minHeight: 3,
              ),
          ],
        ),
      ),
    );
  }

  // 构建错误页面
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Connection Failed", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() => _isError = false);
              _webViewController?.reload();
            },
            child: const Text("Retry"),
          )
        ],
      ),
    );
  }

  // 处理后退逻辑
  Future<void> _handleBackNavigation() async {
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      _webViewController!.goBack(); // 网页后退
    } else {
      _showExitDialog(); // 已经是第一页了，询问是否退出
    }
  }

  // 退出确认弹窗 (防止误触)
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Payment?"),
        content: const Text("Are you sure you want to cancel the deposit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // 关弹窗
            child: const Text("Continue Paying"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 关弹窗
              _goToResult(); // 关页面，去查单
            },
            child: const Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _goToResult() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DepositResultPage(orderNo: widget.orderNo)),
    );
  }
}