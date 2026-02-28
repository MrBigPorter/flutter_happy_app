import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_ui_model.dart';
import '../../photo_preview_page.dart';
import '../../../img/app_image.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';

class ImageMsgBubble extends StatelessWidget {
  final ChatUiModel message;

  const ImageMsgBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // Fixed width for the image bubble in the chat list
    const double bubbleWidth = 240;
    final Map<String, dynamic> meta = message.meta ?? {};

    // Calculate aspect ratio: prevents list jumping by reserving space before image loads
    final double w = (meta['w'] ?? meta['width'] ?? 1.0).toDouble();
    final double h = (meta['h'] ?? meta['height'] ?? 1.0).toDouble();
    final double aspectRatio = (w / h).clamp(0.5, 2.0); // Clamping ratio to avoid excessively long images

    final timeStr = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(message.createdAt),
    );

    // Logic: Prioritize localPath; AppImage handles fallbacks automatically if the file is missing
    final source = message.localPath ?? message.content;

    return GestureDetector(
      onTap: () => _openPreview(context, source),
      child: Container(
        width: bubbleWidth,
        height: bubbleWidth / aspectRatio,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Image Display
              Hero(
                tag: 'img_${message.id}',
                child: AppCachedImage(
                  source,
                  width: bubbleWidth, // Explicit width for the Preloader
                  height: bubbleWidth / aspectRatio, // Explicit height
                  fit: BoxFit.cover,

                  // Passing metadata to prevent flickering and provide placeholders
                  previewBytes: message.previewBytes,
                  metadata: meta,

                  enablePreview: false, // Preview is handled manually by the outer GestureDetector
                ),
              ),

              // Sending state: Loading overlay
              if (message.status == MessageStatus.sending)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                ),

              // Failure state: Error icon overlay
              if (message.status == MessageStatus.failed)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Icon(Icons.error_outline, color: Colors.red, size: 30),
                    ),
                  ),
                ),

              // Timestamp tag (Bottom right)
              Positioned(
                right: 6, bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    timeStr,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPreview(BuildContext context, String source) {
    // Resolve remote URL as fallback in case the local path is inaccessible during preview
    final remoteUrl = UrlResolver.resolveImage(context, message.content);

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => PhotoPreviewPage(
          heroTag: 'img_${message.id}',
          imageSource: source, // Pass current source to ensure Hero animation continuity
          cachedThumbnailUrl: remoteUrl, // Provide the actual remote address to the preview page
          previewBytes: message.previewBytes, // Pass in-memory small image for blurred transition
          metadata: message.meta,
        ),
      ),
    );
  }
}