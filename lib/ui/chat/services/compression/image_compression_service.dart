import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:universal_html/html.dart' as html;

class ImageCompressionService {
  // 1. 上传压缩
  static Future<XFile> compressForUpload(XFile file) async {
    try {
      final int size = await file.length();
      if (size < 500 * 1024) return file;
      if (kIsWeb) {
        return await _compressWebCanvas(file, quality: 0.8, maxWidth: 1920);
      } else {
        return await _compressMobile(file, 1920, 80);
      }
    } catch (e) {
      return file;
    }
  }

  // 2. 缩略图生成
  static Future<Uint8List> getTinyThumbnail(XFile file) async {
    try {
      if (kIsWeb) {
        final XFile tinyFile = await _compressWebCanvas(file, quality: 0.5, maxWidth: 200);
        return await tinyFile.readAsBytes();
      } else {
        final XFile tinyFile = await _compressMobile(file, 200, 50);
        return await tinyFile.readAsBytes();
      }
    } catch (e) {
      return Uint8List(0);
    }
  }

  // 🔥🔥🔥 核心修复：captureWebVideoFrame 🔥🔥🔥
  // 增加了 (video as dynamic) 强转，解决 iOS 编译报错
  static Future<Uint8List?> captureWebVideoFrame(String blobUrl) async {
    if (!kIsWeb) return null;
    final completer = Completer<Uint8List?>();
    try {
      final video = html.VideoElement()..src = blobUrl..crossOrigin = 'anonymous'..muted = true;

      video.onLoadedData.listen((_) async {
        // ⚠️ 关键修改：强转 dynamic，骗过编译器
        final int vW = (video as dynamic).videoWidth;
        final int vH = (video as dynamic).videoHeight;

        final canvas = html.CanvasElement(width: vW ~/ 2, height: vH ~/ 2);
        canvas.context2D.drawImageScaled(video, 0, 0, canvas.width!, canvas.height!);

        final blob = await canvas.toBlob('image/jpeg', 0.7);
        final reader = html.FileReader()..readAsArrayBuffer(blob);
        reader.onLoadEnd.listen((_) => completer.complete(reader.result as Uint8List?));
      });

      video.onError.listen((_) => completer.complete(null));
      video.load();
    } catch (e) { completer.complete(null); }
    return completer.future.timeout(const Duration(seconds: 5), onTimeout: () => null);
  }

  // 4. Web Canvas 图片压缩 (保持原样，加了 Blob URL 修复)
  static Future<XFile> _compressWebCanvas(XFile file, {double quality = 0.8, int maxWidth = 1920}) async {
    final Completer<XFile> completer = Completer();
    try {
      final bytes = await file.readAsBytes();
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final img = html.ImageElement()..src = url;
      await img.onLoad.first;

      int w = img.naturalWidth ?? 0;
      int h = img.naturalHeight ?? 0;
      if (w == 0 || h == 0) {
        html.Url.revokeObjectUrl(url);
        return file;
      }

      if (w > maxWidth || h > maxWidth) {
        final double ratio = w > h ? (maxWidth / w) : (maxWidth / h);
        w = (w * ratio).round(); h = (h * ratio).round();
      }

      final canvas = html.CanvasElement(width: w, height: h);
      canvas.context2D..imageSmoothingEnabled = true..imageSmoothingQuality = 'high'..drawImageScaled(img, 0, 0, w, h);

      canvas.toBlob('image/jpeg', quality).then((blob) {
        html.Url.revokeObjectUrl(url);

        // 生成新的 Blob URL 传给 XFile，防止 UI 读不到路径
        final newUrl = html.Url.createObjectUrlFromBlob(blob);

        completer.complete(XFile(
            newUrl,
            name: file.name.replaceAll(RegExp(r'\.[^.]+$'), '.jpg'),
            mimeType: 'image/jpeg'
        ));
      });
    } catch (e) {
      completer.complete(file);
    }
    return completer.future;
  }

  static Future<XFile> _compressMobile(XFile file, int minWidth, int quality) async {
    final String filePath = file.path;
    final String outPath = "${filePath.split('.').first}_opt_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final result = await FlutterImageCompress.compressAndGetFile(filePath, outPath, minWidth: minWidth, minHeight: minWidth, quality: quality, format: CompressFormat.jpeg);
    return result ?? file;
  }
}