import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Mobile 端原生压缩

//  使用 universal_html 解决跨平台编译问题
// 它在 Web 端是真实的 html 库，在 Mobile 端是 mock 类，不会报错
import 'package:universal_html/html.dart' as html;

class ImageCompressionService {

  // ===========================================================================
  // 1. 上传专用压缩 (保持高清 1920p，体积适中)
  // 用于 ChatActionService 的 sendImage
  // ===========================================================================
  static Future<XFile> compressForUpload(XFile file) async {
    try {
      final int size = await file.length();
      // 如果文件本身小于 500KB，直接返回原图，不折腾
      if (size < 500 * 1024) {
        return file;
      }

      if (kIsWeb) {
        // Web 端：使用 Canvas 硬件加速 (不卡顿)
        return await _compressWebCanvas(file, quality: 0.8, maxWidth: 1920);
      } else {
        // Mobile 端：使用 Native 底层压缩 (最快)
        return await _compressMobile(file, 1920, 80);
      }
    } catch (e) {
      debugPrint(" [Upload Compress] Failed: $e");
      return file; // 失败时兜底返回原图
    }
  }

  // ===========================================================================
  // 2. 缩略图专用 (极致压缩 200px，用于 DB 预览)
  // 用于 Pipeline 的 ImageProcessStep
  // ===========================================================================
  static Future<Uint8List> getTinyThumbnail(XFile file) async {
    try {
      if (kIsWeb) {
        // Web 端：Canvas 生成 200px 小图，毫秒级
        final XFile tinyFile = await _compressWebCanvas(file, quality: 0.5, maxWidth: 200);
        return await tinyFile.readAsBytes();
      } else {
        // Mobile 端：生成小缩略图 (这里复用 Native 压缩，性能更好)
        final XFile tinyFile = await _compressMobile(file, 200, 50);
        return await tinyFile.readAsBytes();
      }
    } catch (e) {
      debugPrint(" [Tiny Thumb] Failed: $e");
      return Uint8List(0);
    }
  }

  // ---------------------------------------------------------------------------
  //  Web 端核心：使用 HTML5 Canvas 加速 (解决卡顿的关键)
  // ---------------------------------------------------------------------------
  static Future<XFile> _compressWebCanvas(XFile file, {double quality = 0.8, int maxWidth = 1920}) async {
    final Completer<XFile> completer = Completer();

    try {
      // 1. 读取 Blob
      final bytes = await file.readAsBytes();
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // 2. 创建 HTML Image 元素
      final img = html.ImageElement();
      img.src = url;

      await img.onLoad.first; // 等待浏览器解码

      // 3. 计算尺寸 (✅ 修复点：处理 int? 可空类型，如果为 null 则默认为 0)
      int w = img.naturalWidth ?? 0;
      int h = img.naturalHeight ?? 0;

      // 如果获取不到尺寸，说明图片有问题，直接返回原图
      if (w == 0 || h == 0) {
        html.Url.revokeObjectUrl(url);
        completer.complete(file);
        return completer.future;
      }

      if (w > maxWidth || h > maxWidth) {
        final double ratio = w > h ? (maxWidth / w) : (maxWidth / h);
        w = (w * ratio).round();
        h = (h * ratio).round();
      }

      // 4. 利用 Canvas 绘图 (硬件加速)
      final canvas = html.CanvasElement(width: w, height: h);
      final ctx = canvas.context2D;

      // 高质量缩放算法
      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = 'high';
      ctx.drawImageScaled(img, 0, 0, w, h);

      // 5. 导出为 Blob (image/jpeg)
      canvas.toBlob('image/jpeg', quality).then((blob) {
        html.Url.revokeObjectUrl(url);

        // 6. 转回 XFile
        final reader = html.FileReader();
        reader.readAsArrayBuffer(blob);
        reader.onLoadEnd.listen((e) {
          final Uint8List resultBytes = reader.result as Uint8List;
          completer.complete(XFile.fromData(
            resultBytes,
            name: file.name.replaceAll(RegExp(r'\.[^.]+$'), '.jpg'), // 强制改后缀
            mimeType: 'image/jpeg',
          ));
        });
      }).catchError((e) {
        completer.complete(file);
      });

    } catch (e) {
      debugPrint("Web Canvas error: $e");
      completer.complete(file); // 失败返原图
    }

    return completer.future;
  }

  // ---------------------------------------------------------------------------
  // 📱 Mobile 端逻辑 (FlutterImageCompress)
  // ---------------------------------------------------------------------------
  static Future<XFile> _compressMobile(XFile file, int minWidth, int quality) async {
    final String filePath = file.path;
    final int lastIndex = filePath.lastIndexOf(RegExp(r'.jp|.pn|.heic', caseSensitive: false));
    final String split = lastIndex != -1 ? filePath.substring(0, lastIndex) : filePath;
    final String outPath = "${split}_opt_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      outPath,
      minWidth: minWidth,
      minHeight: minWidth,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    return result ?? file;
  }
}