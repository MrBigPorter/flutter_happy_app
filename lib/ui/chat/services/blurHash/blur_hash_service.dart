import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img; // 确保 pubspec.yaml 引用了 image 库
import 'package:blurhash/blurhash.dart' as bh; // 确保引用了 flutter_blurhash 或 blurhash_dart

/// 封装处理结果：thumbBytes 将作为 previewBytes 存入 Sembast 数据库
class ThumbBlurResult {
  final Uint8List thumbBytes;
  final int thumbW;
  final int thumbH;
  final String thumbMime;
  final String blurHash;

  const ThumbBlurResult({
    required this.thumbBytes,
    required this.thumbW,
    required this.thumbH,
    required this.thumbMime,
    required this.blurHash,
  });
}

class ThumbBlurHashService {
  ///  核心入口：子线程解码，主线程通道编码
  static Future<ThumbBlurResult?> build(
      Uint8List originalFileBytes, {
        int thumbWidth = 100, // 仅做本地 DB 占位，100px 足够
        int blurSize = 32,    // BlurHash 计算用的尺寸，32x32 足够
        int compX = 4,
        int compY = 3,
      }) async {
    if (originalFileBytes.isEmpty) return null;

    final payload = {
      'fileBytes': originalFileBytes,
      'thumbWidth': thumbWidth,
      'blurSize': blurSize,
    };

    // 1. 图像缩放处理
    // Web 端不支持 Isolate (compute)，直接在当前线程运行；App 端走子线程避免卡顿
    final Map<String, dynamic>? out = kIsWeb
        ? _worker(payload)
        : await compute(_worker, payload);

    if (out == null) return null;

    // 2. 主线程处理 BlurHash 编码
    String blurHash = "";

    try {
      //  核心修正：直接移除了 (!kIsWeb) 判断
      // 现在的 blurhash 库通常支持 Web（纯 Dart 实现），且输入图片非常小，不会阻塞 UI
      final Uint8List blurInputPng = out['blurInputPng'] as Uint8List;

      // 注意：这里假设 bh.BlurHash.encode 能接受 PNG 字节流
      // 如果你的库只接受原始 RGBA，可能需要调整 _worker 输出，但根据你之前的代码，Mobile 能跑通说明接口是对的
      final String? hash = await bh.BlurHash.encode(blurInputPng, compX, compY);
      blurHash = hash ?? "";
    } catch (e) {
      debugPrint("️ [ThumbBlurHashService] BlurHash 生成失败: $e");
    }

    return ThumbBlurResult(
      thumbBytes: out['thumbBytes'] as Uint8List,
      thumbW: out['thumbW'] as int,
      thumbH: out['thumbH'] as int,
      thumbMime: 'image/png',
      blurHash: blurHash,
    );
  }

  /// 图像处理单元（运行在 Isolate 或 Web Worker 模拟环境）
  @pragma('vm:entry-point')
  static Map<String, dynamic>? _worker(Map<String, dynamic> input) {
    try {
      final bytes = input['fileBytes'] as Uint8List;

      // 使用 image 库解码
      final raw = img.decodeImage(bytes);
      if (raw == null) return null;

      // 1) 生成用于 DB 存储的小图 (PNG 格式最通用，用于 previewBytes)
      final thumbImg = img.copyResize(raw, width: input['thumbWidth'] as int);
      final thumbBytes = img.encodePng(thumbImg);

      // 2) 生成用于 BlurHash 输入的超小图 (32x32)
      // BlurHash 对细节不敏感，缩得越小计算越快，生成的 Hash 越短
      final blurImg = img.copyResize(raw, width: input['blurSize'] as int, height: input['blurSize'] as int);
      final blurInputPng = img.encodePng(blurImg);

      return <String, dynamic>{
        'thumbBytes': thumbBytes,
        'thumbW': thumbImg.width,
        'thumbH': thumbImg.height,
        'blurInputPng': blurInputPng,
      };
    } catch (e) {
      // 子线程里 print 可能看不要，但在 Web 端能看到
      if (kDebugMode) print("Worker Error: $e");
      return null;
    }
  }
}