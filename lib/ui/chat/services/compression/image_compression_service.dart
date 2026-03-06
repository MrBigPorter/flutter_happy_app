import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// 条件导入！
import 'image_compression_stub.dart' if (dart.library.js_interop) 'image_compression_web.dart';

class ImageCompressionService {
  static Future<XFile> compressForUpload(XFile file) async {
    try {
      final int size = await file.length();
      if (size < 500 * 1024) return file;

      if (kIsWeb) {
        return await compressWebCanvasImpl(file, quality: 0.8, maxWidth: 1920);
      } else {
        return await _compressMobile(file, 1920, 80);
      }
    } catch (e) { return file; }
  }

  static Future<Uint8List> getTinyThumbnail(XFile file) async {
    try {
      if (kIsWeb) {
        final XFile tinyFile = await compressWebCanvasImpl(file, quality: 0.5, maxWidth: 200);
        return await tinyFile.readAsBytes();
      } else {
        final XFile tinyFile = await _compressMobile(file, 200, 50);
        return await tinyFile.readAsBytes();
      }
    } catch (e) { return Uint8List(0); }
  }

  static Future<Uint8List?> captureWebVideoFrame(String blobUrl) async {
    return await captureWebVideoFrameImpl(blobUrl);
  }

  static Future<XFile> _compressMobile(XFile file, int minWidth, int quality) async {
    final String filePath = file.path;
    final String outPath = "${filePath.split('.').first}_opt_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final result = await FlutterImageCompress.compressAndGetFile(
        filePath, outPath, minWidth: minWidth, minHeight: minWidth, quality: quality, format: CompressFormat.jpeg);
    return result ?? file;
  }
}