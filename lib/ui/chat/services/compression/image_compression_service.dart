import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img; // 仅移动端使用
// Web 环境兼容处理
import 'package:flutter_app/ui/chat/widgets/web_image_utils.dart' if (dart.library.js) 'dart:html' as html;

class ImageCompressionService {
  /// 核心入口：获取极致压缩的预览图 (用于 v3.0 previewBytes)

  static Future<Uint8List> getTinyThumbnail(XFile file) async {
    if (kIsWeb) {
      return _compressForWeb(file);
    } else {
      return _compressForMobile(file);
    }
  }

  ///  Web 端：利用浏览器 Canvas 硬件加速
  static Future<Uint8List> _compressForWeb(XFile file) async {
    // Web 端不使用 Isolate，因为 JS 环境下 Canvas 性能远超纯 Dart 库
    final bytes = await file.readAsBytes();
    final String blobUrl = html.Url.createObjectUrlFromBlob(html.Blob([bytes]));
    final html.ImageElement imageElement = html.ImageElement(src: blobUrl);

    await imageElement.onLoad.first;
    // 设定微缩图尺寸 (Max 200px)
    int width = imageElement.naturalWidth;
    int height = imageElement.naturalHeight;
    const int thumbSize = 200;

    if (width > height) {
      height = (height * (thumbSize / width)).round();
      width = thumbSize;
    } else {
      width = (width * (thumbSize / height)).round();
      height = thumbSize;
    }
    final html.CanvasElement canvas = html.CanvasElement(
        width: width, height: height);
    canvas.context2D.drawImageScaled(imageElement, 0, 0, width, height);
    // 导出压缩后的 DataURL
    final String dataUrl = canvas.toDataUrl('image/jpeg', 0.7);
    // 清理 URL 对象
    html.Url.revokeObjectUrl(blobUrl);
    // 提取 Uint8List
    return Uint8List.fromList(Uri
        .parse(dataUrl)
        .data!
        .contentAsBytes());
  }

  ///  移动端：调用 compute (Isolate) 避免 UI 卡顿
  static Future<Uint8List> _compressForMobile(XFile file) async {
    final Uint8List originalBytes = await file.readAsBytes();
    return compute(_isolateCompressLogic, originalBytes);
  }
/// 独立子线程逻辑
  static Uint8List _isolateCompressLogic(Uint8List bytes) {
    final img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      return bytes; // 解码失败，返回原图
    }
    // 缩放至微缩尺寸
    final img.Image thumbnail = img.copyResize(image, width: 200);
    // 极致压缩，目标 <50KB
    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 50));
  }
}