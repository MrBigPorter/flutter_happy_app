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
//  1. 引入 UrlResolver
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/core/network/http_adapter/http_adapter_factory.dart';

final fileDownloadServiceProvider = Provider((ref) => FileDownloadService());

class FileDownloadService {
  // 1. 改为 late final，允许在构造函数里初始化
  late final Dio _dio;

  FileDownloadService() {
    // 2. 初始化 BaseOptions
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 30),
    ));

    // 3.  核心修复：安全赋值
    // getNativeAdapter() 在 Web 端返回 null，在 Native 端返回 NativeAdapter
    // 只有不为 null 时才赋值，千万不要加 "!"
    final adapter = getNativeAdapter();
    if (adapter != null) {
      _dio.httpClientAdapter = adapter;
    }
  }

  /// 核心入口：下载或打开文件
  Future<String?> downloadOrOpen(
      ChatUiModel message, {
        Function(int, int)? onProgress,
        CancelToken? cancelToken,
      }) async {
    final rawContent = message.content;
    if (rawContent == '[File]') return null;

    //  2. 核心修改：使用 UrlResolver 获取完整链接
    // 它会自动处理 relative path, domain, https 等问题
    final String fullUrl = UrlResolver.resolveFile(rawContent);

    if (fullUrl.isEmpty) return null;

    // === 1. Web 端策略：触发浏览器下载 ===
    if (kIsWeb) {
      _downloadWeb(fullUrl, fileName: message.fileName);
      return null; // Web 端没有本地路径的概念
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

      // 2.3 检查是否已存在 (断点续传/缓存命中)
      if (File(savePath).existsSync()) {
        // 如果文件存在且大小不为0，直接返回
        if (await File(savePath).length() > 0) {
          return savePath;
        }
      }

      // 2.4 开始下载
      //  3. 这里传入 fullUrl，确保 Dio 能请求到完整地址
      await _dio.download(
        fullUrl,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );

      // 2.5 下载成功，回写数据库
      await LocalDatabaseService().updateMessage(message.id, {
        'localPath': savePath
      });

      return savePath;

    } catch (e) {
      rethrow;
    }
  }

  /// 专门处理 Web 端的下载
  void _downloadWeb(String url, {String? fileName}) {
    // 创建一个隐藏的 <a> 标签
    final anchor = html.AnchorElement(href: url);

    // 1. 只要是 Blob 或者是 PDF，不要让浏览器直接在当前也打开，尝试新标签页
    anchor.target = '_blank';

    // 2.  核心修复：强制设置 download 属性
    // 只要设置了这个属性，浏览器就会把响应当成文件下载，而不会试图去渲染它（导致显示乱码）
    String finalName = fileName ?? '';

    // 如果没有传文件名，尝试从 URL 截取，或者给个默认名
    if (finalName.isEmpty) {
      if (url.startsWith('http')) {
        finalName = url.split('/').last;
      }
      // 兜底：如果是 blob 且没名字，给个默认名，防止浏览器乱猜
      if (finalName.isEmpty || finalName.contains('?')) {
        finalName = "download_file.pdf";
      }
    }

    // 赋值 download 属性 -> 这就是告诉浏览器："别废话，给我存成文件！"
    anchor.download = finalName;

    anchor.click();
  }

  /// 打开本地文件 (Native)
  Future<void> openLocalFile(String path) async {
    if (kIsWeb) {
      // Web 端如果有 localPath (通常是 blob)，也用同样的方式打开
      _downloadWeb(path);
      return;
    }

    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      // 忽略 "file not found" 之类的常见错误提示，或者根据需求 throw
      if (result.type != ResultType.noAppToOpen) {
        throw "无法打开文件: ${result.message}";
      }
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