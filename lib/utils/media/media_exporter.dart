import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/features/share/services/share_service.dart';

import 'package:flutter_app/features/share/widgets/save_poster_stub.dart'
if (dart.library.html) 'package:flutter_app/features/share/widgets/save_poster_web.dart';

class MediaExporter {
  /// 统一保存入口：兼容本地路径/网络路径，兼容 App/Web
  static Future<bool> saveImage(BuildContext context, String source) async {
    if (kIsWeb) {
      // 1. Web 端：触发浏览器下载
      final url = UrlResolver.resolveImage(context, source);
      await downloadImageOnWeb(Uint8List(0), imageUrl: url);
      return true;
    }

    try {
      // 2. Mobile 端：获取物理路径
      final String runtimePath = AssetManager.getRuntimePath(source);
      final file = File(runtimePath);

      // 3. 权限检查（使用 Gal 插件，与 SharePost 保持一致）
      if (!await Gal.hasAccess()) {
        final ok = await Gal.requestAccess();
        if (!ok) return false;
      }

      // 4. 执行保存
      if (await file.exists()) {
        await Gal.putImage(runtimePath); // 直接存文件路径
      } else {
        // 如果本地文件丢了，可以从网络重新下载再存，或者提示失败
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 3. 保存内存图片到相册
  static Future<bool> saveImageBytes(BuildContext context, Uint8List bytes) async {
    if (kIsWeb) {
      await downloadImageOnWeb(bytes);
      return true;
    }

    try {
      if (!await Gal.hasAccess()) {
        final ok = await Gal.requestAccess();
        if (!ok) return false;
      }
      // 直接保存二进制数据
      await Gal.putImageBytes(bytes);
      return true;
    } catch (e) {
      debugPrint("Save bytes error: $e");
      return false;
    }
  }

  /// 4. [修改] 分享内存图片 (通用化)
  static Future<void> shareImageBytes(
      BuildContext context,
      Uint8List bytes, {
        String filename = 'shared_image.png', // 默认文件名
        String? subject, // 邮件/系统分享标题
        String? text,    // 分享文案
      }) async {
    try {
      // 将内存数据包装成 XFile
      final file = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: filename,
      );

      // 调用现有的 ShareService
      await ShareService.shareFiles(
        context,
        [file],
        subject: subject,
        text: text,
      );
    } catch (e) {
      debugPrint("Share bytes error: $e");
    }
  }

  /// 统一分享入口：分享物理文件
  static Future<void> shareImage(BuildContext context, String source) async {
    if (kIsWeb) {
      // Web 端分享通常是复制链接或触发下载
      final url = UrlResolver.resolveImage(context, source);
      await downloadImageOnWeb(Uint8List(0), imageUrl: url);
      return;
    }

    final String runtimePath = AssetManager.getRuntimePath(source);
    if (File(runtimePath).existsSync()) {
      // 调用你现有的 ShareService
      await ShareService.shareFiles(context, [XFile(runtimePath)]);
    }
  }
}