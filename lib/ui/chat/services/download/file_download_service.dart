import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'web_download_helper.dart';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/utils/asset/asset_manager.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/core/network/http_adapter/http_adapter_factory.dart';

final fileDownloadServiceProvider = Provider((ref) => FileDownloadService());

class FileDownloadService {
  late final Dio _dio;

  FileDownloadService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 30),
    ));

    final adapter = getNativeAdapter();
    if (adapter != null) {
      _dio.httpClientAdapter = adapter;
    }
  }

  Future<String?> downloadOrOpen(
      ChatUiModel message, {
        Function(int, int)? onProgress,
        CancelToken? cancelToken,
      }) async {
    final rawContent = message.content;
    if (rawContent == '[File]') return null;

    final String fullUrl = UrlResolver.resolveFile(rawContent);

    if (fullUrl.isEmpty) return null;

    // --- Web Strategy ---
    if (kIsWeb) {
      // 🚀 核心改动：调用被隔离的安全方法！
      downloadFileWeb(fullUrl, fileName: message.fileName);
      return null;
    }

    // --- Native Strategy ---
    try {
      final dir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${dir.path}/chat_files');
      if (!saveDir.existsSync()) {
        await saveDir.create(recursive: true);
      }

      final String fileName = message.fileName ??
          message.meta?['fileName'] ??
          "file_${message.id}.bin";
      final String savePath = "${saveDir.path}/$fileName";

      if (File(savePath).existsSync()) {
        if (await File(savePath).length() > 0) {
          return savePath;
        }
      }

      await _dio.download(
        fullUrl,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );

      await LocalDatabaseService().updateMessage(message.id, {
        'localPath': savePath
      });

      return savePath;

    } catch (e) {
      rethrow;
    }
  }

  Future<void> openLocalFile(String path) async {
    if (kIsWeb) {
      // 🚀 核心改动
      downloadFileWeb(path);
      return;
    }

    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      if (result.type != ResultType.noAppToOpen) {
        throw "Could not open file: ${result.message}";
      }
    }
  }

  Future<String?> checkLocalFile(String? rawPath) async {
    if (rawPath == null) return null;

    if (kIsWeb) {
      if (rawPath.startsWith('blob:') || rawPath.startsWith('http')) return rawPath;
      return null;
    }

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