import 'dart:async';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// 假设你的 ShareData 在这里引入
import 'package:flutter_app/features/share/models/share_data.dart';

class ShareService {

  // ==========================================
  // 1. 内部辅助方法 (Private Helpers)
  // ==========================================

  /// 下载图片作为预览图，增加 3秒 超时，防止分享卡死
  static Future<XFile?> _ensurePreviewThumbnail(ShareData d) async {
    if (d.previewThumbnail != null) return d.previewThumbnail;
    if (d.imageUrl == null || d.imageUrl!.isEmpty) return null;

    try {
      //  优化：增加 timeout，如果 3秒 下不来就算了，直接弹出分享框，不要让用户等
      final resp = await http.get(Uri.parse(d.imageUrl!))
          .timeout(const Duration(seconds: 3));

      if (resp.statusCode == 200) {
        return XFile.fromData(
          resp.bodyBytes,
          name: 'preview_thumbnail.jpg', // 建议给个后缀
          mimeType: resp.headers['content-type'] ?? 'image/jpeg',
        );
      }
    } catch (e) {
      debugPrint('ShareService: Download thumbnail failed or timed out: $e');
    }
    return null;
  }

  /// 获取 iPad 分享弹出的锚点位置
  ///  优化：增加空安全检查，防止崩溃
  static Rect? _getShareOrigin(BuildContext ctx) {
    try {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        return box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (e) {
      debugPrint('ShareService: Cannot find render object for share origin: $e');
    }
    return null; // 如果获取失败，SharePlus 会尝试居中显示或使用默认位置
  }

  ///  优化：提取公共的社交软件跳转逻辑
  static Future<void> _launchSocialIntent({
    required String urlScheme,
    required ShareData fallbackData,
  }) async {
    final uri = Uri.parse(urlScheme);

    // 尝试打开 App (WhatsApp, TG 等)
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // 失败则降级为系统原生分享
      await SharePlus.instance.share(
        ShareParams(
            text: fallbackData.combined,
            downloadFallbackEnabled: true
        ),
      );
    }
  }

  // ==========================================
  // 2. 公开方法 (Public APIs)
  // ==========================================

  static Future<ShareResult> shareNative(BuildContext ctx, ShareData d) async {
    final origin = _getShareOrigin(ctx);
    final thumbnail = await _ensurePreviewThumbnail(d);

    return SharePlus.instance.share(
      ShareParams(
        text: d.combined, // 确保这里是 "文案 + 空格 + 链接"
        subject: d.title,
        sharePositionOrigin: origin,
        downloadFallbackEnabled: true,
        previewThumbnail: thumbnail,
      ),
    );
  }

  static Future<ShareResult> shareFiles(
      BuildContext ctx,
      List<XFile> files, {
        String? text,
        String? subject,
      }) {
    final origin = _getShareOrigin(ctx);

    return SharePlus.instance.share(
      ShareParams(
        files: files,
        text: text,
        subject: subject,
        sharePositionOrigin: origin,
        downloadFallbackEnabled: true,
      ),
    );
  }

  /// WhatsApp: 需要对参数进行编码
  static Future<void> shareWhatsApp(ShareData d) async {
    // WhatsApp 同时支持文本和链接拼接
    final text = Uri.encodeComponent(d.combined);
    await _launchSocialIntent(
      urlScheme: 'whatsapp://send?text=$text',
      fallbackData: d,
    );
  }

  /// Telegram: 支持 url 和 text 参数
  static Future<void> shareTelegram(ShareData d) async {
    final url = Uri.encodeComponent(d.url);
    final text = Uri.encodeComponent(d.text ?? '');
    await _launchSocialIntent(
      urlScheme: 'tg://msg_url?url=$url&text=$text',
      fallbackData: d,
    );
  }

  /// Twitter/X: 推荐使用 intent URL
  static Future<void> shareTwitter(ShareData d) async {
    final text = Uri.encodeComponent(d.text ?? '');
    final url = Uri.encodeComponent(d.url);
    await _launchSocialIntent(
      urlScheme: 'https://twitter.com/intent/tweet?text=$text&url=$url',
      fallbackData: d,
    );
  }

  /// Facebook: 极其特殊，基本只认 u 参数
  static Future<void> shareFacebook(ShareData d) async {
    final url = Uri.encodeComponent(d.url);
    // FB 很多时候忽略 text，只抓取 url 的 OpenGraph 信息
    await _launchSocialIntent(
      urlScheme: 'https://www.facebook.com/sharer/sharer.php?u=$url',
      fallbackData: d,
    );
  }

  /// 智能分享入口：尝试原生分享，失败则调用自定义 Sheet
  static Future<void> openSystemOrSheet(
      ShareData d,
      Future<void> Function()? openSheet,
      ) async {
    // 1. Web 平台直接弹自定义 Sheet (原生分享在 Web 上体验不一致)
    if (kIsWeb && openSheet != null) {
      await openSheet();
      return;
    }

    try {
      final thumbnail = await _ensurePreviewThumbnail(d);

      await SharePlus.instance.share(
        ShareParams(
          text: d.combined,
          subject: d.title,
          previewThumbnail: thumbnail,
          downloadFallbackEnabled: true,
        ),
      );
    } catch (e) {
      debugPrint('ShareService: Native share failed ($e), falling back to custom sheet.');
      if (openSheet != null) {
        await openSheet();
      }
    }
  }
}