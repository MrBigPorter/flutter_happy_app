import 'package:flutter/material.dart';

/// 安全加载 deferred 模块的包装器。
///
/// - [loadLibrary]：Dart 自动为 `deferred as` 库生成的下载函数
/// - [builder]：chunk 下载完成后构建实际页面的回调
/// - [skeletonBuilder]：可选，chunk 加载期间显示的骨架屏替代默认 loading spinner
///
/// 当提供 [skeletonBuilder] 时，chunk 下载期间显示骨架屏，下载完成后
/// 通过 AnimatedOpacity 淡入实际页面，实现平滑过渡。
/// 支持加载失败重试。
class DeferredPage extends StatefulWidget {
  const DeferredPage({
    required this.loadLibrary,
    required this.builder,
    this.skeletonBuilder,
    super.key,
  });

  /// 调用 deferred 库的 loadLibrary()，下载对应 JS chunk
  final Future<void> Function() loadLibrary;

  /// chunk 加载完成后构建实际页面
  final Widget Function() builder;

  /// 可选：chunk 加载期间显示的骨架屏
  /// 不提供时回退到 CircularProgressIndicator
  final Widget Function()? skeletonBuilder;

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

    // Loading state: show skeleton (if provided) or default spinner
    if (!_loaded) {
      if (widget.skeletonBuilder != null) {
        return widget.skeletonBuilder!();
      }
      return const Center(child: CircularProgressIndicator());
    }

    // Chunk loaded: fade in the real page
    return _FadeIn(
      key: ValueKey(_loaded),
      child: widget.builder(),
    );
  }
}

/// 淡入包装器 — 子组件挂载时执行一次 fade-in 动画（300ms）
class _FadeIn extends StatefulWidget {
  const _FadeIn({super.key, required this.child});
  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}
