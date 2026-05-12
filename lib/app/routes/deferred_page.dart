import 'package:flutter/material.dart';

/// 安全加载 deferred 模块的包装器。
///
/// - [loadLibrary]：Dart 自动为 `deferred as` 库生成的下载函数
/// - [builder]：chunk 下载完成后构建实际页面的回调
///
/// Chunk 下载完成前显示 loading indicator，下载完成后自动渲染实际页面。
/// 支持加载失败重试。
class DeferredPage extends StatefulWidget {
  const DeferredPage({
    required this.loadLibrary,
    required this.builder,
    super.key,
  });

  /// 调用 deferred 库的 loadLibrary()，下载对应 JS chunk
  final Future<void> Function() loadLibrary;

  /// chunk 加载完成后构建实际页面
  final Widget Function() builder;

  @override
  State<DeferredPage> createState() => _DeferredPageState();
}

class _DeferredPageState extends State<DeferredPage> {
  bool _loaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadChunk();
  }

  Future<void> _loadChunk() async {
    try {
      await widget.loadLibrary();
      if (mounted) setState(() => _loaded = true);
    } catch (e) {
      debugPrint('DeferredPage: chunk 加载失败: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('页面加载失败'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _hasError = false;
                setState(() {});
                _loadChunk();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return widget.builder();
  }
}
