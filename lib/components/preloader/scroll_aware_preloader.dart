import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';
import '../../utils/media/url_resolver.dart';
import '../../utils/metrics/preload_metrics.dart';

class ScrollAwarePreloader extends StatefulWidget {
  final Widget child;
  final List<ChatUiModel> items;
  final double itemAverageHeight;
  final int preloadWindow;
  final double? predictWidth;

  const ScrollAwarePreloader({
    super.key,
    required this.child,
    required this.items,
    this.itemAverageHeight = 300.0,
    this.preloadWindow = 15,
    this.predictWidth,
  });

  @override
  State<ScrollAwarePreloader> createState() => _ScrollAwarePreloaderState();
}

class _ScrollAwarePreloaderState extends State<ScrollAwarePreloader> {
  final Set<String> _warmedUpIds = {};
  double _lastProcessedPixels = 0;
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
    // 只要动了就触发，越灵敏越好
    if (notification is ScrollUpdateNotification || notification is ScrollEndNotification) {
      if ((notification.metrics.pixels - _lastProcessedPixels).abs() < 10) return false;
      _lastProcessedPixels = notification.metrics.pixels;
      _schedulePreload(notification.metrics);
    }
    return false;
  }

  void _schedulePreload(ScrollMetrics metrics) {
    if (widget.items.isEmpty) return;

    int estimatedIndex = (metrics.pixels / widget.itemAverageHeight).floor();
    // 回看 5 个，防止估算误差导致漏图
    int startIndex = (estimatedIndex - 5).clamp(0, widget.items.length);
    int endIndex = (startIndex + widget.preloadWindow).clamp(0, widget.items.length);

    if (startIndex == _lastStartIndex && endIndex == _lastEndIndex) return;
    _lastStartIndex = startIndex;
    _lastEndIndex = endIndex;

    for (int i = startIndex; i < endIndex; i++) {
      _dispatchPrecacheTask(widget.items[i]);
    }
  }

  void _dispatchPrecacheTask(ChatUiModel item) {
    if (_warmedUpIds.contains(item.id)) return;
    if (item.type != MessageType.image && item.type != MessageType.video) return;

    // if (_activePreloadCount >= _maxConcurrentPreloads) return;

    String? resPath = item.type == MessageType.image ? item.content : item.meta?['thumb'];
    if (resPath == null || resPath.isEmpty) return;

    ImageProvider? provider;
    String? trackUrl;

    try {
      if (item.localPath != null && AssetManager.existsSync(item.localPath!)) {
        provider = FileImage(File(AssetManager.getRuntimePath(item.localPath!)));
      }

      if (provider == null) {
        final double targetWidth = widget.predictWidth ?? 240.0;
        // 这里的 fit 必须和 UI 一致
        final String fullUrl = UrlResolver.resolveImage(
          context,
          resPath,
          logicalWidth: targetWidth,
          fit: BoxFit.cover,
        );
        if (fullUrl.startsWith('http')) {
          provider = CachedNetworkImageProvider(fullUrl);
          trackUrl = fullUrl;
        }
      }

      if (provider != null) {
        _warmedUpIds.add(item.id);

        // 登记，防止 Metrics 误报漏图
        if (trackUrl != null) {
          PreloadMetrics.markAsPreloaded(trackUrl);
        }

        // 直接发起下载，不计数，不等待
        precacheImage(provider, context).catchError((e) {
          _warmedUpIds.remove(item.id); // 失败允许重试
        });
      }
    } catch (e) {}
  }
}