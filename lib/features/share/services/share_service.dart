import 'package:flutter/cupertino.dart';
import 'package:flutter_app/features/share/models/share_data.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service class for sharing content via various platforms.
/// Provides methods to share via native dialog, WhatsApp, Telegram, Twitter, and Facebook.
/// Each method constructs the appropriate share URL and attempts to launch it.
/// If the platform-specific share fails, it falls back to the native share dialog.
/// Also includes a method to open the native share dialog or a custom share sheet as a fallback.
/// Usage:
/// ```dart
/// await ShareService.shareWhatsApp(shareData);
/// ```
/// where `shareData` is an instance of `ShareData`.
/// Note: Ensure that the required packages (`share_plus` and `url_launcher`) are added to `pubspec.yaml`.
/// Example:
/// ```dart
/// dependencies:
///  share_plus: ^4.0.0
///  url_launcher: ^6.0.20
///  ```
class ShareService {
  /// Shares data using the native share dialog.
  static Future<ShareResult> shareNative(BuildContext ctx, ShareData d) async {
    final box = ctx.findRenderObject() as RenderBox?;
    final origin = box!.localToGlobal(Offset.zero) & box.size;  // Get the position and size of the widget for ipad popover

    return  SharePlus.instance.share(
      ShareParams(
        text: d.combined, // Combine text and URL for sharing, or uri: Uri.parse(d.url),
        subject: d.title, // Optional subject
        sharePositionOrigin: origin, // Position for iPad popover
        downloadFallbackEnabled: true // Enable download fallback for web
      ),
    );
  }

  static Future<ShareResult> shareFiles(
      BuildContext ctx, List<XFile> files, String? text, String? subject, List<String>? fileNameOverrides
      ){
    final box = ctx.findRenderObject() as RenderBox?;
    final origin = box!.localToGlobal(Offset.zero) & box.size;  // Get the position and size of the widget for ipad popover
    return SharePlus.instance.share(
      ShareParams(
        files: files,
        text: text,
        subject: subject,
        sharePositionOrigin: origin,
        fileNameOverrides: fileNameOverrides,
        downloadFallbackEnabled: true
      ),
    );
  }

  /// Shares content via WhatsApp by opening the WhatsApp share URL.
  static Future<void> shareWhatsApp(ShareData d) async {
    final whatsappUrl = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(d.combined)}');
    if(await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      await SharePlus.instance.share(
        ShareParams(
          text: d.combined,
          downloadFallbackEnabled: true
        ),
      );
    }
  }

  /// Shares content via Telegram by opening the Telegram share URL.
  static Future<void> shareTelegram(ShareData d) async {
    final telegramUrl = Uri.parse('tg://msg_url?url=${Uri.encodeComponent(d.url)}&text=${Uri.encodeComponent(d.text ?? '')}');
    if(await canLaunchUrl(telegramUrl)) {
      await launchUrl(telegramUrl, mode: LaunchMode.externalApplication);
    } else {
      await SharePlus.instance.share(
        ShareParams(
          text: d.combined,
          downloadFallbackEnabled: true
        ),
      );
    }
  }

  /// Shares content via Twitter by opening the Twitter share URL in a browser.
  static Future<void> shareTwitter(ShareData d) async {
    final twitterUrl = Uri.parse('https://twitter.com/intent/tweet?text=${Uri.encodeComponent(d.text ?? '')}&url=${Uri.encodeComponent(d.url)}');
    if(await canLaunchUrl(twitterUrl)) {
      await launchUrl(twitterUrl, mode: LaunchMode.externalApplication);
    } else {
      await SharePlus.instance.share(
        ShareParams(
          text: d.combined,
          downloadFallbackEnabled: true
        ),
      );
    }
  }

  /// Shares content via Facebook by opening the Facebook share URL in a browser.
  static Future<void> shareFacebook(ShareData d) async {
    final facebookUrl = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(d.url)}');
    if(await canLaunchUrl(facebookUrl)) {
      await launchUrl(facebookUrl, mode: LaunchMode.externalApplication);
    } else {
      await SharePlus.instance.share(
        ShareParams(
          text: d.combined,
          downloadFallbackEnabled: true
        ),
      );
    }
  }

  /// Attempts to open the native share dialog, and falls back to a custom share sheet if it fails.
  static Future<void> openSystemOrSheet(ShareData d, Future<void> Function()? openSheet) async {
    // Try to open the native share dialog first
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: d.combined,
          subject: d.title,
          downloadFallbackEnabled: true
        ),
      );
    } catch (e) {
      print('Failed to open native share dialog: $e');
      // If it fails, open the custom share sheet if provided
      if(openSheet != null) {
        await openSheet();
      }
    }
  }
}