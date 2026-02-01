import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_app/utils/asset/asset_manager.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';

final fileDownloadServiceProvider = Provider((ref) => FileDownloadService());

class FileDownloadService {
  final Dio _dio = Dio();

  /// 核心入口：下载或打开文件
  /// [onProgress]: 下载进度回调 (received, total)
  /// [cancelToken]: 用于取消下载
  Future<String?> downloadOrOpen(
      ChatUiModel message, {
        Function(int, int)? onProgress,
        CancelToken? cancelToken,
      }) async {
    final remoteUrl = message.content;
    if (remoteUrl == '[File]' || !remoteUrl.startsWith('http')) return null;

    // === 1. Web 端策略：直接打开，不下载到本地 ===
    if (kIsWeb) {
      final uri = Uri.parse(remoteUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return null; // Web 端不返回本地路径
    }

    // === 2. Native 端策略：下载到沙盒 ===
    try {
      // 2.1 准备目录
      final dir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${dir.path}/chat_files');
      if (!saveDir.existsSync()) {
        await saveDir.create(recursive: true);
      }

      // 2.2 准备文件名
      final String fileName = message.fileName ??
          message.meta?['fileName'] ??
          "file_${message.id}.bin";
      final String savePath = "${saveDir.path}/$fileName";

      // 2.3 检查是否已存在 (断点续传的基础，这里简单处理为已存在直接返回)
      if (File(savePath).existsSync()) {
        return savePath;
      }

      // 2.4 开始下载
      await _dio.download(
        remoteUrl,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );

      // 2.5 下载成功，回写数据库
      // 这样下次进 App 就不用再下了
      await LocalDatabaseService().updateMessage(message.id, {
        'localPath': savePath
      });

      return savePath;

    } catch (e) {
      // 可以在这里统一处理 Toast 报错
      rethrow;
    }
  }

  /// 仅仅打开本地文件 (Native Only)
  Future<void> openLocalFile(String path) async {
    if (kIsWeb) return;

    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw "Open file failed: ${result.message}";
    }
  }

  /// 检查文件是否存在
  Future<String?> checkLocalFile(String? rawPath) async {
    if (rawPath == null) return null;

    // Web: 只要是 blob 或 http 开头，就算“存在”
    if (kIsWeb) {
      if (rawPath.startsWith('blob:') || rawPath.startsWith('http')) return rawPath;
      return null;
    }

    // Native: 真正的文件检查
    String? resolvedPath;
    if (rawPath.startsWith('/') || rawPath.contains(Platform.pathSeparator)) {
      resolvedPath = rawPath;
    } else {
      resolvedPath = await AssetManager.getFullPath(rawPath, MessageType.file);
    }

    if (resolvedPath != null && File(resolvedPath).existsSync()) {
      return resolvedPath;
    }
    return null;
  }
}