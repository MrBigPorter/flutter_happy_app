import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/features/share/models/share_data.dart';
import 'package:http/http.dart' as httpClient;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';


/// function: Service for sharing content via various platforms and methods.
/// description: Provides methods to share content using native share dialogs,
///              as well as specific platforms like WhatsApp, Telegram, Twitter, and Facebook.
///              It also handles preview thumbnails for shared content.
/// depends_on:
///   - share_plus: ^6.3.0 use system share dialog
///   - url_launcher: ^6.1.7 to open URLs for specific platform sharing
///           - http: ^0.13.5 for downloading preview thumbnails
///           xfile: use to handle file data for sharing
class ShareService {
  /// Ensures that a preview thumbnail is available for sharing.
  /// If a preview thumbnail is already provided in the ShareData, it is returned.
  /// If not, and if an imageUrl is provided, it attempts to download the image
  static Future<XFile?> _ensurePreviewThumbnail(ShareData d) async {
    // If preview thumbnail is already provided, use it
    if (d.previewThumbnail != null) {
      return d.previewThumbnail;
    }

    // If imageUrl is not provided, return null
    if (d.imageUrl == null || d.imageUrl!.isEmpty) {
      return null;
    }

    try {
      final resp = await httpClient.get(Uri.parse(d.imageUrl!));
      if (resp.statusCode != 200) {
        return null;
      }
      return XFile.fromData(
        resp.bodyBytes,
        name: 'preview_thumbnail',
        mimeType: resp.headers['content-type'],
      );
    } catch (_) {
      return null;
    }
  }

  /// Shares data using the native share dialog.
  static Future<ShareResult> shareNative(BuildContext ctx, ShareData d) async {
    final box = ctx.findRenderObject() as RenderBox?;
    final origin =
        box!.localToGlobal(Offset.zero) &
        box.size; // Get the position and size of the widget for ipad popover

    final thumbnail = await _ensurePreviewThumbnail(d);

    return SharePlus.instance.share(
      ShareParams(
        text: d.combined,
        // Combine text and URL for sharing, or uri: Uri.parse(d.url),
        subject: d.title,
        // Optional subject
        sharePositionOrigin: origin,
        // Position for iPad popover
        downloadFallbackEnabled: true,
        // Enable download fallback for web
        previewThumbnail: thumbnail,
      ),
    );
  }

  static Future<ShareResult> shareFiles(
    BuildContext ctx,
    List<XFile> files,
    String? text,
    String? subject,
    List<String>? fileNameOverrides,
  ) {
    final box = ctx.findRenderObject() as RenderBox?;
    final origin =
        box!.localToGlobal(Offset.zero) &
        box.size; // Get the position and size of the widget for ipad popover
    return SharePlus.instance.share(
      ShareParams(
        files: files,
        text: text,
        subject: subject,
        sharePositionOrigin: origin,
        fileNameOverrides: fileNameOverrides,
        downloadFallbackEnabled: true,
      ),
    );
  }

  /// Shares content via WhatsApp by opening the WhatsApp share URL.
  static Future<void> shareWhatsApp(ShareData d) async {
    final whatsappUrl = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(d.combined)}',
    );
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      await SharePlus.instance.share(
        ShareParams(text: d.combined, downloadFallbackEnabled: true),
      );
    }
  }

  /// Shares content via Telegram by opening the Telegram share URL.
  static Future<void> shareTelegram(ShareData d) async {
    final telegramUrl = Uri.parse(
      'tg://msg_url?url=${Uri.encodeComponent(d.url)}&text=${Uri.encodeComponent(d.text ?? '')}',
    );
    if (await canLaunchUrl(telegramUrl)) {
      await launchUrl(telegramUrl, mode: LaunchMode.externalApplication);
    } else {
      await SharePlus.instance.share(
        ShareParams(text: d.combined, downloadFallbackEnabled: true),
      );
    }
  }

  /// Shares content via Twitter by opening the Twitter share URL in a browser.
  static Future<void> shareTwitter(ShareData d) async {
    final twitterUrl = Uri.parse(
      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(d.text ?? '')}&url=${Uri.encodeComponent(d.url)}',
    );
    if (await canLaunchUrl(twitterUrl)) {
      await launchUrl(twitterUrl, mode: LaunchMode.externalApplication);
    } else {
      await SharePlus.instance.share(
        ShareParams(text: d.combined, downloadFallbackEnabled: true),
      );
    }
  }

  /// Shares content via Facebook by opening the Facebook share URL in a browser.
  static Future<void> shareFacebook(ShareData d) async {
    final facebookUrl = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(d.url)}',
    );
    if (await canLaunchUrl(facebookUrl)) {
      await launchUrl(facebookUrl, mode: LaunchMode.externalApplication);
    } else {
      await SharePlus.instance.share(
        ShareParams(text: d.combined, downloadFallbackEnabled: true),
      );
    }
  }

  /// Attempts to open the native share dialog, and falls back to a custom share sheet if it fails.
  static Future<void> openSystemOrSheet(
    ShareData d,
    Future<void> Function()? openSheet,
  ) async {
    // Try to open the native share dialog first
    try {

      if( kIsWeb && openSheet != null){
        // On web, directly open the custom share sheet if provided
        await openSheet();
        return;

      }
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
      // If it fails, open the custom share sheet if provided
      if (openSheet != null) {
        await openSheet();
      }
    }
  }
}
