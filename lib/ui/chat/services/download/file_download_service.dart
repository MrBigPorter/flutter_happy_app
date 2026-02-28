import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

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
    // 1. Initialize BaseOptions with standardized timeouts
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 30),
    ));

    // 2. Platform-Specific Adapter Configuration:
    // Safely assign the NativeAdapter only if it is not null (Native platforms).
    final adapter = getNativeAdapter();
    if (adapter != null) {
      _dio.httpClientAdapter = adapter;
    }
  }

  /// Main Entry Point: Downloads or opens the specified file message.
  Future<String?> downloadOrOpen(
      ChatUiModel message, {
        Function(int, int)? onProgress,
        CancelToken? cancelToken,
      }) async {
    final rawContent = message.content;
    if (rawContent == '[File]') return null;

    // Resolve the full URL using UrlResolver to handle relative paths and domains.
    final String fullUrl = UrlResolver.resolveFile(rawContent);

    if (fullUrl.isEmpty) return null;

    // --- Web Strategy: Trigger Browser-Native Download ---
    if (kIsWeb) {
      _downloadWeb(fullUrl, fileName: message.fileName);
      return null; // Web platforms do not use local path concepts.
    }

    // --- Native Strategy: Download to Application Sandbox ---
    try {
      // 1. Prepare storage directory
      final dir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${dir.path}/chat_files');
      if (!saveDir.existsSync()) {
        await saveDir.create(recursive: true);
      }

      // 2. Prepare destination filename
      final String fileName = message.fileName ??
          message.meta?['fileName'] ??
          "file_${message.id}.bin";
      final String savePath = "${saveDir.path}/$fileName";

      // 3. Cache Check: Return existing path if file is valid and non-empty
      if (File(savePath).existsSync()) {
        if (await File(savePath).length() > 0) {
          return savePath;
        }
      }

      // 4. Execute Download via Dio
      await _dio.download(
        fullUrl,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );

      // 5. Update local database with the new local file path
      await LocalDatabaseService().updateMessage(message.id, {
        'localPath': savePath
      });

      return savePath;

    } catch (e) {
      rethrow;
    }
  }

  /// Handles Web platform file downloads by creating a virtual anchor element.
  void _downloadWeb(String url, {String? fileName}) {
    final anchor = html.AnchorElement(href: url);

    // Open in a new tab for Blobs or PDFs to prevent immediate UI navigation.
    anchor.target = '_blank';

    // Set the 'download' attribute to force the browser to treat the response as a file.
    String finalName = fileName ?? '';

    if (finalName.isEmpty) {
      if (url.startsWith('http')) {
        finalName = url.split('/').last;
      }
      if (finalName.isEmpty || finalName.contains('?')) {
        finalName = "download_file.pdf";
      }
    }

    anchor.download = finalName;
    anchor.click();
  }

  /// Opens a local file using system-default applications (Native platforms).
  Future<void> openLocalFile(String path) async {
    if (kIsWeb) {
      _downloadWeb(path);
      return;
    }

    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      if (result.type != ResultType.noAppToOpen) {
        throw "Could not open file: ${result.message}";
      }
    }
  }

  /// Checks if the local file exists at the given path.
  Future<String?> checkLocalFile(String? rawPath) async {
    if (rawPath == null) return null;

    // Web: Treat Blobs and HTTP URLs as existing resources.
    if (kIsWeb) {
      if (rawPath.startsWith('blob:') || rawPath.startsWith('http')) return rawPath;
      return null;
    }

    // Native: Physical file system verification.
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