import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:blurhash/blurhash.dart' as bh;
import 'package:image/image.dart' as img;

class BlurHashService {
  /// 外部调用的唯一入口：自动处理多线程
  static Future<String> create(Uint8List bytes) async {
    return compute(_generateBlurHashWorker, bytes);
  }
  /// 内部 Worker：必须是顶层函数或静态函数
  static Future<String> _generateBlurHashWorker(Uint8List bytes) async {
    try {
      final rawImage = img.decodeImage(bytes);
      if (rawImage == null) return "";

      // 1. 缩放图片 (32x32)
      final smallerImage = img.copyResize(rawImage, width: 32, height: 32);

      // 2. 获取 RGBA 字节流
      final rgbaBytes = smallerImage.getBytes();

      // 3. 核心修正：只传 3 个参数
      // 参数 1: rgba 字节流
      // 参数 2: X轴分量 (4)
      // 参数 3: Y轴分量 (3)
      // 注意：该库内部会根据 rgbaBytes.length 自动识别宽高
      return bh.BlurHash.encode(
        rgbaBytes,
        4,
        3,
      );
    } catch (e) {
      debugPrint("❌ [BlurHashService] 最终尝试失败: $e");
      return "";
    }
  }
}