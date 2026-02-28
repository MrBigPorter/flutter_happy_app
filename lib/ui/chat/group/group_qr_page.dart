import 'dart:ui' as ui;
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:flutter_app/utils/media/media_exporter.dart';

class GroupQrPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupAvatar;

  const GroupQrPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupAvatar,
  });

  @override
  State<GroupQrPage> createState() => _GroupQrPageState();
}

class _GroupQrPageState extends State<GroupQrPage> {
  final GlobalKey _qrRepaintKey = GlobalKey();

  /// Core logic for capturing the widget as a PNG image
  Future<Uint8List?> _capturePng() async {
    try {
      RenderRepaintBoundary? boundary = _qrRepaintKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return null;

      // Lower pixel ratio on Web to prevent Canvas memory overflow
      final ratio = kIsWeb ? 1.5 : 3.0;

      ui.Image image = await boundary.toImage(pixelRatio: ratio);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("[GroupQrPage] Capture error: $e");
      // Handle Web-specific CORS "Tainted canvas" errors
      if (kIsWeb && e.toString().contains("Tainted")) {
        RadixToast.error("Security Error: Image CORS issue");
      }
      return null;
    }
  }

  /// Handles the process of saving the QR code to the device local storage
  Future<void> _handleSave() async {
    RadixToast.showLoading(message: "Saving...");
    try {
      final bytes = await _capturePng();
      if (bytes != null) {
        final success = await MediaExporter.saveImageBytes(context, bytes);
        RadixToast.hide();
        if (success) {
          RadixToast.success(kIsWeb ? "Image Downloaded" : "Saved to Photos");
        } else {
          RadixToast.error("Failed to save");
        }
      } else {
        RadixToast.hide();
        RadixToast.error("Generation failed");
      }
    } catch (e) {
      RadixToast.hide();
    }
  }

  /// Handles the process of sharing the generated QR code image
  Future<void> _handleShare() async {
    RadixToast.showLoading(message: "Preparing...");
    try {
      final bytes = await _capturePng();
      RadixToast.hide();

      if (bytes != null && mounted) {
        await MediaExporter.shareImageBytes(
          context,
          bytes,
          filename: 'group_qr_${widget.groupId}.png',
          subject: 'Join Group: ${widget.groupName}',
          text: 'Scan this QR code to join my group!',
        );
      }
    } catch (e) {
      RadixToast.hide();
      RadixToast.error("Share failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = "luckyapp://group/join?id=${widget.groupId}";
    final avatarUrl = widget.groupAvatar != null
        ? UrlResolver.resolveImage(context, widget.groupAvatar!)
        : null;

    // Hide central logo on Web if CORS is not configured to avoid "Tainted canvas" capture errors
    final showLogo = avatarUrl != null && !kIsWeb;

    return BaseScaffold(
      title: "Group QR Code",
      backgroundColor: context.bgSecondary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Screenshot capture area
            RepaintBoundary(
              key: _qrRepaintKey,
              child: Container(
                width: 300.w,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Info Section
                    Row(
                      children: [
                        Container(
                          width: 50.r,
                          height: 50.r,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            color: context.bgSecondary,
                            image: avatarUrl != null
                                ? DecorationImage(
                                image: CachedNetworkImageProvider(avatarUrl),
                                fit: BoxFit.cover)
                                : null,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            widget.groupName,
                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Layered rendering optimization to avoid blocking QR generation
                    SizedBox(
                      width: 220.w,
                      height: 220.w,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Bottom Layer: Pure QR code (Instant rendering)
                          QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 220.w,
                            backgroundColor: Colors.white,
                            errorStateBuilder: (cxt, err) => Center(child: Text("Error")),
                          ),

                          // Top Layer: Logo (Asynchronous loading with white border)
                          if (showLogo)
                            Container(
                              width: 48.w,
                              height: 48.w,
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6.r),
                                child: CachedNetworkImage(
                                  imageUrl: avatarUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                                  errorWidget: (context, url, error) => Icon(Icons.error),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12.h),
                    Text("Scan to join group", style: TextStyle(color: context.textSecondary700)),
                  ],
                ),
              ),
            ),

            SizedBox(height: 40.h),

            // Bottom Action Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Row(
                children: [
                  Expanded(
                    child: Button(
                      onPressed: _handleShare,
                      variant: ButtonVariant.secondary,
                      trailing: Icon(Icons.share, size: 18.r, color: context.textPrimary900),
                      child: Text("Share"),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Button(
                      onPressed: _handleSave,
                      variant: ButtonVariant.primary,
                      trailing: Icon(Icons.download, size: 18.r, color: Colors.white),
                      child: Text("Save"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}