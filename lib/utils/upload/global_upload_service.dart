import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_app/common.dart';
import 'upload_types.dart'; // 定义 UploadModule 枚举的地方
import 'image_utils.dart';  // 下面第3步提供的工具类

class GlobalUploadService {
  // 1. 创建一个干净、长超时的 Dio 实例专供 S3 使用
  // sendTimeout 设为 5 分钟，防止大文件在弱网下上传失败
  static final Dio _s3Dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(minutes: 5),
  ));

  Future<String> uploadFile({
    required String filePath,
    required UploadModule module,
    required Function(double) onProgress,
    CancelToken? cancelToken,
  }) async {
    String? compressedPath;

    // 显式初始化进度，让 UI 知道开始了
    onProgress(0.01);

    try {
      // --- 1. 图片智能预处理 ---
      final lowerPath = filePath.toLowerCase();
      final isImage = lowerPath.endsWith(".jpg") ||
          lowerPath.endsWith(".jpeg") ||
          lowerPath.endsWith(".png") ||
          lowerPath.endsWith(".heic");

      if (isImage) {
        // 调用压缩工具 (建议确保 ImageUtils 内部在 Isolate 中运行)
        compressedPath = await ImageUtils.compressImage(filePath);
      }

      // 确定最终上传的文件路径 (有压缩用压缩的，没压缩用原图)
      final finalPath = compressedPath ?? filePath;
      final file = File(finalPath);

      if (!await file.exists()) throw Exception("File not found: $finalPath");

      final fileName = p.basename(finalPath);
      // MimeType 兜底逻辑
      final mimeType = lookupMimeType(finalPath) ??
          (lowerPath.endsWith(".png") ? "image/png" : "image/jpeg");
      final fileSize = await file.length();

      // --- 2. 申请上传凭证 (0% - 25% 阶段，UI 层假进度在跑) ---
      // 使用你业务封装的 Http 类，带 Token 去找后端拿 URL
      final urlRes = await Http.post(module.apiPath, data: {
        "fileName": fileName,
        "fileType": mimeType,
        if (module == UploadModule.common) "common": "",
      });

      final String uploadUrl = urlRes['url'];
      final String s3Key = urlRes['key'];

      // --- 3. 执行 S3 直传 (25% - 100% 阶段) ---
      try {
        await _s3Dio.put(
          uploadUrl,
          data: file.openRead(), //  流式上传，内存占用极低
          cancelToken: cancelToken,
          options: Options(headers: {
            "Content-Type": mimeType,
            "Content-Length": fileSize,
          }),
          onSendProgress: (count, total) {
            if (total <= 0) return;

            // 将 S3 物理上传进度 (0-1) 映射到总进度 (0.25-1.0)
            double uploadP = count / total;
            double totalP = 0.25 + (uploadP * 0.75);

            onProgress(totalP.clamp(0.0, 1.0));
          },
        );

        return s3Key;
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) throw Exception("Upload cancelled");
        // 抓取 S3 返回的具体 XML 报错
        final s3Error = e.response?.data?.toString() ?? e.message;
        throw Exception("S3 Transmission Error: $s3Error");
      }
    } catch (e) {
      throw Exception("${module.name} upload failed: $e");
    } finally {
      // --- 4. 自动清理垃圾 ---
      // 只有当生成了临时压缩文件，且它不是原文件时，才删除
      if (compressedPath != null && compressedPath != filePath) {
        try {
          final tempFile = File(compressedPath);
          if (await tempFile.exists()) {
            await tempFile.delete();
            debugPrint(" Cleaned up temp file: $compressedPath");
          }
        } catch (cleanupError) {
          debugPrint(" Failed to clean up temp file: $cleanupError");
        }
      }
    }
  }
}