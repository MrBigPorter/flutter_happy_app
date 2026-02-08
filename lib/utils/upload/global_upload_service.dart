import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart'; //  必须引入这个包 (如果没有请在 pubspec.yaml 添加 mime: ^1.0.0)

import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/network/http_adapter/http_adapter_factory.dart';
import 'upload_types.dart';
import 'image_utils.dart';

class GlobalUploadService {
  static final Dio _s3Dio = _createS3Dio();

  static Dio _createS3Dio() {
    final dio = Dio(BaseOptions(
      // 1. 连接超时 (30秒足够)
      connectTimeout: const Duration(seconds: 30),

      // 2. 发送超时 (上传大文件必须长！建议 20-30 分钟)
      // 这是指发送数据的过程，如果你传 500MB 视频，15秒肯定不够
      sendTimeout: const Duration(minutes: 30),

      // 3. 接收超时 (等待服务器响应的时间)
      // 上传完成后，S3/后端 处理可能需要几秒
      receiveTimeout: const Duration(minutes: 30),
    ));

    //  Safe Adapter Assignment
    final adapter = getNativeAdapter();
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
    }
    return dio;
  }

  Future<String> uploadFile({
    required XFile file,
    required UploadModule module,
    required Function(double) onProgress,
    CancelToken? cancelToken,
  }) async {
    XFile fileToUpload = file;
    String? tempCompressedPath;

    onProgress(0.01);

    try {
      // Mobile 图片压缩逻辑 (仅对图片生效)
      if (!kIsWeb) {
        final lowerPath = file.path.toLowerCase();
        final isImage = lowerPath.endsWith(".jpg") ||
            lowerPath.endsWith(".jpeg") ||
            lowerPath.endsWith(".png") ||
            lowerPath.endsWith(".heic");

        if (isImage) {
          final compressedPath = await ImageUtils.compressImage(file.path);
          if (compressedPath != null) {
            tempCompressedPath = compressedPath;
            fileToUpload = XFile(compressedPath);
          }
        }
      }

      String fileName = fileToUpload.name;

      //  核心修复区：强制纠正视频类型
      String mimeType = "application/octet-stream";

      // 1. 优先尝试自动识别
      if (fileToUpload.mimeType != null && fileToUpload.mimeType!.isNotEmpty) {
        mimeType = fileToUpload.mimeType!;
      } else {
        mimeType = lookupMimeType(fileName) ??
            lookupMimeType(fileToUpload.path) ??
            "application/octet-stream";
      }

      // 2.  强制修正：如果后缀是 mp4，必须是 video/mp4
      // 这一步是为了防止 lookupMimeType 识别失败 fallback 成 image/jpeg
      if (fileName.toLowerCase().endsWith(".mp4")) {
        mimeType = "video/mp4";
      } else if (fileName.toLowerCase().endsWith(".jpg") || fileName.toLowerCase().endsWith(".jpeg")) {
        if (mimeType == "application/octet-stream") mimeType = "image/jpeg";
      }

      // 如果名字太乱，重新生成一个带正确后缀的名字
      if (fileName.trim().isEmpty || fileName == 'blob') {
        final suffix = extensionFromMime(mimeType);
        fileName = "file_${DateTime.now().millisecondsSinceEpoch}.$suffix";
      }

      final fileSize = await fileToUpload.length();

      // 申请凭证
      final urlRes = await Http.post(module.apiPath, data: {
        "fileName": fileName,
        "fileType": mimeType, // 告诉后端
        if (module == UploadModule.common) "common": "",
      });

      final String uploadUrl = urlRes['url'];
      final String finalResultKey = urlRes['key'];

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
          options: Options(
              contentType: mimeType, // 告诉 S3/R2
              headers: {
                "Content-Length": fileSize,
              }
          ),
          onSendProgress: (count, total) {
            if (total <= 0) return;
            double p = count / total;
            onProgress((0.25 + (p * 0.75)).clamp(0.0, 1.0));
          },
        );
        return finalResultKey;

      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) throw Exception("Cancelled");
        final s3Error = e.response?.data?.toString() ?? e.message;
        throw Exception("S3 Error: $s3Error");
      }
    } catch (e) {
      throw Exception("Upload failed: $e");
    } finally {
      if (!kIsWeb && tempCompressedPath != null) {
        try { File(tempCompressedPath).delete(); } catch (_) {}
      }
    }
  }

  // ... 必须保留原来的 uploadOcrScan 和 submitKyc 代码，防止报错 ...
  Future<KycOcrResult> uploadOcrScan({
    required XFile file,
    required UploadModule module,
    required Function(double) onProgress,
    CancelToken? cancelToken,
    bool enableImageCompress = true,
  }) async {
    String? tempCompressedPath;
    XFile fileToSend = file;
    onProgress(0.01);
    try {
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
      if (kIsWeb) {
        final bytes = await fileToSend.readAsBytes();
        final mime = lookupMimeType(fileName, headerBytes: bytes) ?? "application/octet-stream";
        mf = MultipartFile.fromBytes(bytes, filename: fileName, contentType: DioMediaType.parse(mime));
      } else {
        final mime = lookupMimeType(fileToSend.path) ?? "application/octet-stream";
        mf = await MultipartFile.fromFile(fileToSend.path, filename: fileName, contentType: DioMediaType.parse(mime));
      }
      final form = FormData.fromMap({"file": mf});
      final resp = await Http.post(module.apiPath, data: form, cancelToken: cancelToken, options: Options(sendTimeout: const Duration(minutes: 2)));
      final dynamic raw = (resp is Response) ? resp.data : resp;
      final map = (raw as Map).cast<String, dynamic>();
      final dynamic dataAny = map['data'] ?? map;
      final data = (dataAny as Map).cast<String, dynamic>();
      return KycOcrResult.fromJson(data);
    } catch (e) {
      throw Exception("ocr failed: $e");
    } finally {
      if (!kIsWeb && tempCompressedPath != null) try { File(tempCompressedPath).delete(); } catch (_) {}
    }
  }

  Future<dynamic> submitKyc({
    required XFile frontImage,
    required XFile? backImage,
    required Map<String, dynamic> bodyData,
  }) async {
    final Map<String, dynamic> map = Map.from(bodyData);
    Future<MultipartFile> xFileToMultipart(XFile f) async {
      if (kIsWeb) {
        final bytes = await f.readAsBytes();
        final mime = lookupMimeType(f.name, headerBytes: bytes) ?? "image/jpeg";
        return MultipartFile.fromBytes(bytes, filename: f.name, contentType: DioMediaType.parse(mime));
      } else {
        final mime = lookupMimeType(f.path) ?? "image/jpeg";
        return MultipartFile.fromFile(f.path, filename: f.name, contentType: DioMediaType.parse(mime));
      }
    }
    map['idCardFront'] = await xFileToMultipart(frontImage);
    if (backImage != null) map['idCardBack'] = await xFileToMultipart(backImage);
    final form = FormData.fromMap(map);
    return Http.post('/api/v1/kyc/submit', data: form);
  }
}

final uploadServiceProvider = Provider<GlobalUploadService>((ref) {
  return GlobalUploadService();
});