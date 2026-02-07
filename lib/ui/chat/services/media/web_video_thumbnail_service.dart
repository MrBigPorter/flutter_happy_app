import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart'; // 必须引入，用于 kIsWeb

class WebVideoThumbnailService {
  static Future<Uint8List?> extractJpegThumb(
      Uint8List videoBytes, {
        double atSeconds = 0.1,
        int maxWidth = 320,
        double quality = 0.85,
      }) async {
    // 1. 物理隔绝：非 Web 环境直接返回 null，防止运行时错误
    if (!kIsWeb) return null;

    final completer = Completer<Uint8List?>();
    String? blobUrl;

    try {
      final blob = html.Blob([videoBytes]);
      blobUrl = html.Url.createObjectUrlFromBlob(blob);

      final video = html.VideoElement()
        ..src = blobUrl
        ..crossOrigin = 'anonymous'
        ..muted = true
        ..preload = 'metadata'; // 只加载元数据即可获取尺寸

      // 必须设置 currentTime 才能截取非黑屏帧
      video.currentTime = atSeconds;

      await video.onLoadedData.first;

      // 等待 seek 完成
      if (video.currentTime != atSeconds) {
        await video.onSeeked.first;
      }

      // 🔥🔥🔥 核心修复点：强转 dynamic 绕过 iOS 编译检查 🔥🔥🔥
      // universal_html 的 Mock 类没有 videoWidth，所以必须骗过编译器
      final int vW = (video as dynamic).videoWidth;
      final int vH = (video as dynamic).videoHeight;

      if (vW == 0 || vH == 0) {
        throw Exception("Video dimensions are zero");
      }

      // 计算缩放比例
      int targetW = vW;
      int targetH = vH;
      if (targetW > maxWidth) {
        final double ratio = maxWidth / targetW;
        targetW = maxWidth;
        targetH = (vH * ratio).round();
      }

      final canvas = html.CanvasElement(width: targetW, height: targetH);
      canvas.context2D.drawImageScaled(video, 0, 0, targetW, targetH);

      final outBlob = await canvas.toBlob('image/jpeg', quality);
      final reader = html.FileReader();
      reader.readAsArrayBuffer(outBlob);
      reader.onLoadEnd.listen((_) {
        completer.complete(reader.result as Uint8List?);
      });

    } catch (e) {
      debugPrint("WebThumb error: $e");
      completer.complete(null);
    } finally {
      if (blobUrl != null) {
        html.Url.revokeObjectUrl(blobUrl);
      }
    }

    return completer.future;
  }
}