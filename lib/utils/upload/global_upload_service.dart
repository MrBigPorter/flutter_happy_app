import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // 用于 kIsWeb
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // 引入 XFile
import 'package:mime/mime.dart';

import 'package:flutter_app/common.dart';
import 'upload_types.dart';
import 'image_utils.dart';

class GlobalUploadService {
  static final Dio _s3Dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(minutes: 5),
  ));

  // ===========================================================================
  // ☁️ 1. S3 通用文件上传 (支持 Web & Mobile)
  // ===========================================================================
  Future<String> uploadFile({
    required XFile file, // 🔥 改动点：参数改为 XFile
    required UploadModule module,
    required Function(double) onProgress,
    CancelToken? cancelToken,
  }) async {
    XFile fileToUpload = file;
    String? tempCompressedPath; // 用于手机端清理临时文件

    onProgress(0.01);

    try {
      // --- A. 压缩逻辑 (仅 Mobile) ---
      // Web 端压缩稍微复杂，为了稳健，Web 端暂传原图；Mobile 端继续压缩
      if (!kIsWeb) {
        final lowerPath = file.path.toLowerCase();
        final isImage = lowerPath.endsWith(".jpg") ||
            lowerPath.endsWith(".jpeg") ||
            lowerPath.endsWith(".png") ||
            lowerPath.endsWith(".heic");

        if (isImage) {
          // compressImage 返回的是 String 路径
          final compressedPath = await ImageUtils.compressImage(file.path);
          if (compressedPath != null) {
            tempCompressedPath = compressedPath;
            fileToUpload = XFile(compressedPath); // 包装回 XFile
          }
        }
      }

      // --- B. 准备参数 ---
      String fileName = fileToUpload.name;

      // MimeType 获取
      String mimeType = fileToUpload.mimeType ?? "image/jpeg";
      // 如果名字为空，或者只是 'blob' (Web常见情况)，手动生成一个
      if (fileName.trim().isEmpty || fileName == 'blob') {
        final suffix = mimeType.split('/').last; // image/png -> png
        fileName = "img_${DateTime.now().millisecondsSinceEpoch}.$suffix";
      }

      final fileSize = await fileToUpload.length();

      // --- C. 申请凭证 ---
      final urlRes = await Http.post(module.apiPath, data: {
        "fileName": fileName,
        "fileType": mimeType,
        if (module == UploadModule.common) "common": "",
      });

      final String uploadUrl = urlRes['url'];
      //  变量 2：返回给 UI 的短链接 (CDN 链接)
      // 这个是上传成功后，我们要拿到的结果
      String finalResultUrl = urlRes['cdnUrl'];
      if (finalResultUrl.isEmpty) {
        // 兜底：如果后端没返回，自己拼
        finalResultUrl = "https://img.joyminis.com/${urlRes['key']}";
      }

      // --- D. 执行上传 (Web兼容) ---
      //  核心区分：Web 用 Bytes，Mobile 用 Stream
      dynamic uploadData;
      if (kIsWeb) {
        uploadData = await fileToUpload.readAsBytes();
      } else {
        uploadData = fileToUpload.openRead();
      }

      try {
        await _s3Dio.put(
          uploadUrl,
          data: uploadData,
          cancelToken: cancelToken,
          options: Options(headers: {
            "Content-Type": mimeType,
            "Content-Length": fileSize,
          }),
          onSendProgress: (count, total) {
            if (total <= 0) return;
            double uploadP = count / total;
            double totalP = 0.25 + (uploadP * 0.75);
            onProgress(totalP.clamp(0.0, 1.0));
          },
        );
        return finalResultUrl;
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) throw Exception("Upload cancelled");
        final s3Error = e.response?.data?.toString() ?? e.message;
        throw Exception("S3 Transmission Error: $s3Error");
      }
    } catch (e) {
      throw Exception("${module.name} upload failed: $e");
    } finally {
      // --- E. 清理临时文件 (仅 Mobile) ---
      if (!kIsWeb && tempCompressedPath != null) {
        try {
          final f = File(tempCompressedPath);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
  }

  // ===========================================================================
  // 📷 2. OCR 扫描上传 (支持 Web & Mobile)
  // ===========================================================================
  Future<KycOcrResult> uploadOcrScan({
    required XFile file, //  改动点：统一只接收 XFile
    required UploadModule module,
    required Function(double) onProgress,
    CancelToken? cancelToken,
    bool enableImageCompress = true,
  }) async {
    String? tempCompressedPath;
    XFile fileToSend = file;

    onProgress(0.01);

    try {
      // A. 压缩 (仅 Mobile)
      if (!kIsWeb && enableImageCompress) {
        final lowerPath = file.path.toLowerCase();
        if (lowerPath.endsWith(".jpg") || lowerPath.endsWith(".png")) {
          final cPath = await ImageUtils.compressImage(file.path);
          if (cPath != null) {
            tempCompressedPath = cPath;
            fileToSend = XFile(cPath);
          }
        }
      }

      late MultipartFile mf;
      final fileName = fileToSend.name;

      // B. 构建 MultipartFile (跨平台)
      if (kIsWeb) {
        // Web: 必须读成 bytes 上传
        final bytes = await fileToSend.readAsBytes();
        final mime = lookupMimeType(fileName, headerBytes: bytes) ?? "application/octet-stream";
        mf = MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType.parse(mime),
        );
      } else {
        // Mobile: 直接传路径，效率高
        final mime = lookupMimeType(fileToSend.path) ?? "application/octet-stream";
        mf = await MultipartFile.fromFile(
          fileToSend.path,
          filename: fileName,
          contentType: DioMediaType.parse(mime),
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

      // 处理返回结果 (保持你原有的逻辑)
      final dynamic raw = (resp is Response) ? resp.data : resp;
      final map = (raw as Map).cast<String, dynamic>();
      final dynamic dataAny = map['data'] ?? map;
      final data = (dataAny as Map).cast<String, dynamic>();

      final code = map['code'];
      if (code != null && code != 10000) {
        throw Exception("OCR failed: $code");
      }

      return KycOcrResult.fromJson(data);

    } catch (e) {
      throw Exception("ocr-scan upload failed: $e");
    } finally {
      // 清理
      if (!kIsWeb && tempCompressedPath != null) {
        try { File(tempCompressedPath).delete(); } catch (_) {}
      }
    }
  }

  // ===========================================================================
  // 🆔 3. KYC 提交 (支持 Web & Mobile)
  // ===========================================================================
  Future<dynamic> submitKyc({
    required XFile frontImage, // 🔥 改动点：传 XFile
    required XFile? backImage, // 🔥 改动点：传 XFile
    required Map<String, dynamic> bodyData,
  }) async {
    final Map<String, dynamic> map = Map.from(bodyData);

    // 辅助函数：将 XFile 转为 MultipartFile
    Future<MultipartFile> xFileToMultipart(XFile f) async {
      if (kIsWeb) {
        final bytes = await f.readAsBytes();
        final mime = lookupMimeType(f.name, headerBytes: bytes) ?? "image/jpeg";
        return MultipartFile.fromBytes(
            bytes,
            filename: f.name,
            contentType: DioMediaType.parse(mime)
        );
      } else {
        final mime = lookupMimeType(f.path) ?? "image/jpeg";
        return MultipartFile.fromFile(
            f.path,
            filename: f.name,
            contentType: DioMediaType.parse(mime)
        );
      }
    }

    map['idCardFront'] = await xFileToMultipart(frontImage);

    if (backImage != null) {
      map['idCardBack'] = await xFileToMultipart(backImage);
    }

    final form = FormData.fromMap(map);
    return Http.post('/api/v1/kyc/submit', data: form);
  }
}

// Provider
final uploadServiceProvider = Provider<GlobalUploadService>((ref) {
  return GlobalUploadService();
});