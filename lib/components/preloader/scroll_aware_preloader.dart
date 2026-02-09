import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';
import '../../utils/media/url_resolver.dart';

/// 🏎️ [Architecture Component] 滚动感知资源预热器 (Final Optimized Version)
///
/// **核心能力**:
/// 1. **智能错峰**: 只在滚动停止或慢速滚动时下载，不抢占 UI 渲染资源。
/// 2. **参数对齐**: 通过 predictWidth 确保预热 URL 与 UI 渲染 URL 完全一致，命中缓存。
/// 3. **去重与防抖**: 防止重复下载同一张图，防止同一范围重复计算。
class ScrollAwarePreloader extends StatefulWidget {
  final Widget child;
  final List<ChatUiModel> items;
  final double itemAverageHeight;
  final int preloadWindow;

  /// 预测图片宽度 (逻辑像素)
  /// 🔥 必须传入！必须与 ChatBubble 里的 AppCachedImage width 一致！
  final double? predictWidth;

  const ScrollAwarePreloader({
    super.key,
    required this.child,
    required this.items,
    this.itemAverageHeight = 150.0,
    this.preloadWindow = 8, // 建议稍微调大一点，给网络更多缓冲
    this.predictWidth,
  });

  @override
  State<ScrollAwarePreloader> createState() => _ScrollAwarePreloaderState();
}

class _ScrollAwarePreloaderState extends State<ScrollAwarePreloader> {
  // 💾 已预热 ID 池 (防止单次生命周期内重复下载)
  final Set<String> _warmedUpIds = {};

  // 📏 滚动节流记录
  double _lastProcessedPixels = 0;

  // 🔒 范围锁 (防止同一位置重复触发循环)
  int _lastStartIndex = -1;
  int _lastEndIndex = -1;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollMetric,
      child: widget.child,
    );
  }

  bool _handleScrollMetric(ScrollNotification notification) {
    // 1. [Circuit Breaker] 速度熔断
    // 保护机制：如果用户疯狂甩动列表 (>80px/ms)，停止预热，全力保 FPS
    if (notification is ScrollUpdateNotification) {
      if ((notification.scrollDelta ?? 0).abs() > 80) {
        // print("🛑 [Preloader] Velocity protection. Too fast.");
        return false;
      }
    }

    // 2. [Trigger Logic] 触发时机
    // 仅在 "滑动更新" 或 "滑动停止" 时尝试计算
    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {

      // 3. [Throttling] 像素节流
      // 只有滚动超过一定距离 (50px) 才重新计算，避免每帧都算
      if ((notification.metrics.pixels - _lastProcessedPixels).abs() < 50) {
        return false;
      }

      // 4. [Execution] 执行调度
      _lastProcessedPixels = notification.metrics.pixels;
      _schedulePreload(notification.metrics);
    }

    return false; // 允许事件继续冒泡给上层 (如下拉刷新)
  }

  void _schedulePreload(ScrollMetrics metrics) {
    if (widget.items.isEmpty) return;

    // A. 估算当前索引
    // 使用 floor 向下取整
    int firstVisibleIndex = (metrics.pixels / widget.itemAverageHeight).floor();

    // B. 安全钳制 (Safety Clamp)
    // 防止因估算高度偏差导致索引越界
    if (firstVisibleIndex >= widget.items.length) {
      firstVisibleIndex = widget.items.length - 1;
    }
    if (firstVisibleIndex < 0) firstVisibleIndex = 0;

    // C. 计算预热范围
    final int startIndex = firstVisibleIndex;
    final int endIndex = (startIndex + widget.preloadWindow).clamp(0, widget.items.length);

    // 基础校验
    if (startIndex >= endIndex) return;

    // 🔥🔥🔥 核心优化：范围锁 (Range Lock) 🔥🔥🔥
    // 如果计算出的范围和上次完全一样，直接跳过！
    // 解决日志刷屏和 CPU 重复空转的问题。
    if (startIndex == _lastStartIndex && endIndex == _lastEndIndex) {
      return;
    }

    // 更新锁状态
    _lastStartIndex = startIndex;
    _lastEndIndex = endIndex;

     print("✅ [Preloader] Range: $startIndex -> $endIndex (Total: ${widget.items.length})");

    // D. 提交任务
    for (int i = startIndex; i < endIndex; i++) {
      _dispatchPrecacheTask(widget.items[i]);
    }
  }

  // 🚦 并发控制：当前正在下载的数量
  int _activePreloadCount = 0;
  // 🚦 最大并发建议设为 3，HTTP/2 下也不建议给太多，防止抢占主 UI 带宽
  static const int _maxConcurrentPreloads = 3;

  void _dispatchPrecacheTask(ChatUiModel item) {
    if (_warmedUpIds.contains(item.id)) return;

    // 🔥 1. 并发熔断：如果后台已经在下载 3 张了，后续的就等下一波滚动再试
    // 这能确保这 3 张图能以最快速度下完，而不是 10 张图一起拖慢。
    if (_activePreloadCount >= _maxConcurrentPreloads) return;

    String? resourcePath;
    if (item.type == MessageType.image) {
      resourcePath = item.content;
    } else if (item.type == MessageType.video) {
      resourcePath = item.meta?['thumb'];
    }

    if (resourcePath == null || resourcePath.isEmpty) return;

    ImageProvider? provider;
    bool isLocal = false;

    try {
      if (item.localPath != null && AssetManager.existsSync(item.localPath!)) {
        provider = FileImage(File(AssetManager.getRuntimePath(item.localPath!)));
        isLocal = true;
      }

      if (provider == null) {
        // 🔥 2. 核心修复：强制默认宽度对齐
        // 必须确保这里的逻辑和你的 ImageMsgBubble 里的 width: 240.0 配合 predictWidth 完全一致
        final double targetWidth = widget.predictWidth ?? 240.0;

        final String fullUrl = UrlResolver.resolveImage(
          context,
          resourcePath,
          logicalWidth: targetWidth,
        );

        if (fullUrl.startsWith('http')) {
          provider = CachedNetworkImageProvider(fullUrl);
          isLocal = false;
        }
      }

      if (provider != null) {
        _warmedUpIds.add(item.id);
        _activePreloadCount++; // 占用坑位

        final stopwatch = Stopwatch()..start();

        precacheImage(provider, context).then((_) {
          _activePreloadCount--; // 释放坑位
          stopwatch.stop();
          final int cost = stopwatch.elapsedMilliseconds;

          // 📊 智能日志
          String icon = isLocal ? "📂" : (cost < 15 ? "🧠" : (cost < 100 ? "💾" : "☁️"));
          String label = isLocal ? "Local" : (cost < 15 ? "Memory" : (cost < 100 ? "Disk" : "Net"));

          print("$icon [Preloader] $label | ${cost}ms | ID: ${item.id}");
        }).catchError((e) {
          _activePreloadCount--;
          _warmedUpIds.remove(item.id); // 失败了允许重试
        });
      }
    } catch (e) {}
  }
}