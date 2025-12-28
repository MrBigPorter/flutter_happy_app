import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/models/kyc.dart';
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

  /// 后端 multipart 上传（用于你这个 ocr-scan 接口，不走 S3）
  /// 对应后端：
  /// @UseInterceptors(FileInterceptor('file'))
  /// => 字段名必须是 "file"
  ///
  /// 支持：
  /// - Native/桌面：filePath
  /// - Web：bytes + fileName
  Future<KycOcrResult> uploadOcrScan({
    String? filePath,
    Uint8List? bytes,
    String? fileName, // bytes 模式必填
    required UploadModule module,
    required Function(double) onProgress,
    CancelToken? cancelToken,
    bool enableImageCompress = true,
  }) async {
    String? compressedPath;

    // 显式初始化进度
    onProgress(0.01);

    final hasPath = filePath != null && filePath.isNotEmpty;
    final hasBytes = bytes != null && bytes.isNotEmpty;

    if (!hasPath && !hasBytes) {
      throw Exception("uploadOcrScan: must provide either filePath or bytes");
    }
    if (hasBytes && (fileName == null || fileName.isEmpty)) {
      throw Exception("uploadOcrScan: bytes mode requires fileName");
    }

    try {
      late final MultipartFile mf;

      if (hasPath) {
        // 可选压缩：OCR 场景通常是身份证照片，压一下省流量更稳
        final lowerPath = filePath!.toLowerCase();
        final isImage = lowerPath.endsWith(".jpg") ||
            lowerPath.endsWith(".jpeg") ||
            lowerPath.endsWith(".png") ||
            lowerPath.endsWith(".heic");

        if (isImage && enableImageCompress) {
          compressedPath = await ImageUtils.compressImage(filePath!);
        }

        final finalPath = compressedPath ?? filePath!;
        final file = File(finalPath);
        if (!await file.exists()) throw Exception("File not found: $finalPath");

        final finalName = p.basename(finalPath);
        final finalMime =
            lookupMimeType(finalPath) ?? "application/octet-stream";

        mf = await MultipartFile.fromFile(
          finalPath,
          filename: finalName,
          contentType: DioMediaType.parse(finalMime),
        );
      } else {
        final finalName = fileName!;
        final finalMime = lookupMimeType(finalName, headerBytes: bytes) ??
            "application/octet-stream";

        mf = MultipartFile.fromBytes(
          bytes!,
          filename: finalName,
          contentType: DioMediaType.parse(finalMime),
        );
      }

      final form = FormData.fromMap({"file": mf});

      final resp = await Http.post(
        module.apiPath,
        data: form,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (total <= 0) return;
          onProgress((sent / total).clamp(0.0, 1.0));
        },
        options: Options(sendTimeout: const Duration(minutes: 2)),
      );


      //  兼容：Http.post 可能返回 Map，也可能返回 Dio Response
      final dynamic raw = (resp is Response) ? resp.data : resp;

      if (raw is! Map) {
        throw Exception("Invalid OCR response type: ${raw.runtimeType}");
      }

      final map = raw.cast<String, dynamic>();

      //  兼容两种后端返回：
      // 1) 包装结构：{code,message,tid,data:{...}}
      // 2) 直接 data：{type,typeText,country,...}
      final dynamic dataAny = map['data'] ?? map;

      if (dataAny is! Map) {
        throw Exception("Invalid OCR data type: ${dataAny.runtimeType}");
      }

      final data = dataAny.cast<String, dynamic>();


      //  如果后端有 code，顺便校验一下
      final code = map['code'];
      if (code != null && code != 10000) {
        throw Exception("OCR failed: code=$code, message=${map['message']}");
      }

      return KycOcrResult.fromJson(data);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) throw Exception("Upload cancelled");

      final msg = e.response?.data?.toString() ?? e.message;

      // 429：Throttle
      // 423/409：你分布式锁/幂等冲突可能会用到（看你实现）
      throw Exception("OCR Scan Failed: $msg");
    } catch (e) {
      throw Exception("ocr-scan upload failed: $e");
    } finally {
      // 清理压缩临时文件
      if (compressedPath != null && compressedPath != filePath) {
        try {
          final tempFile = File(compressedPath);
          if (await tempFile.exists()) {
            await tempFile.delete();
            debugPrint(" Cleaned up temp file: $compressedPath");
          }
        } catch (cleanupError) {
          debugPrint("Failed to clean up temp file: $cleanupError");
        }
      }
    }
  }

  /// 提交 KYC 实名认证资料
  /// @param frontPath 身份证正面照片路径
  /// @param backPath 身份证反面照片路径（可选）
  /// @param bodyData 其他表单字段数据
  /// @return 后端响应结果
  Future<dynamic> submitKyc({
    required String frontPath,
    required String? backPath,
    required Map<String, dynamic> bodyData,
}) async{
    final Map<String,dynamic> map = Map.from(bodyData);

    map['idCardFront'] = await MultipartFile.fromFile(
      frontPath,
      filename: p.basename(frontPath),
      contentType: DioMediaType.parse(
        lookupMimeType(frontPath) ?? "image/jpeg",
      ),
    );

    if(backPath != null){
      map['idCardBack'] = await MultipartFile.fromFile(
        backPath,
        filename: p.basename(backPath),
        contentType: DioMediaType.parse(
          lookupMimeType(backPath) ?? "image/jpeg",
        ),
      );
    }

    final form = FormData.fromMap(map);
    return Http.post(
      '/api/v1/kyc/submit',
      data: form,
    );
  }



}