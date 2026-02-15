import 'dart:ui' as ui; // [新增] 用于图片处理
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // [新增] 用于截图边界处理
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:flutter_app/utils/media/media_exporter.dart';

// [修改] 改为 StatefulWidget
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
  // [新增] 1. 定义截图边界 Key
  final GlobalKey _qrRepaintKey = GlobalKey();

  // [新增] 2. 截图核心逻辑
  Future<Uint8List?> _capturePng() async {
    try {
      RenderRepaintBoundary? boundary = _qrRepaintKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // pixelRatio: 3.0 保证生成高清大图
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Capture error: $e");
      return null;
    }
  }

  // [新增] 3. 处理保存
  Future<void> _handleSave() async {
    RadixToast.showLoading(message: "Saving...");
    final bytes = await _capturePng();

    if (bytes != null) {
      final success = await MediaExporter.saveImageBytes(context, bytes);
      RadixToast.hide();
      if (success) {
        RadixToast.success("Saved to Photos");
      } else {
        RadixToast.error("Failed to save");
      }
    } else {
      RadixToast.hide();
      RadixToast.error("Capture failed");
    }
  }

  // [新增] 4. 处理分享
  Future<void> _handleShare() async {
    final bytes = await _capturePng();
    if (bytes != null) {
      await MediaExporter.shareImageBytes(
        context,
        bytes,
        filename: 'group_qr_${widget.groupId}.png',
        subject: 'Join Group: ${widget.groupName}',
        text: 'Scan this QR code to join my group!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = "luckyapp://group/join?id=${widget.groupId}";

    return BaseScaffold(
      title: "Group QR Code",
      backgroundColor: context.bgSecondary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // [修改] 5. 使用 RepaintBoundary 包裹卡片
            RepaintBoundary(
              key: _qrRepaintKey,
              child: Container(
                width: 300.w,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white, // 建议强制白色背景，保证保存后二维码清晰可读
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 群信息头部
                    Row(
                      children: [
                        Container(
                          width: 50.r,
                          height: 50.r,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            color: context.bgSecondary,
                            image: widget.groupAvatar != null
                                ? DecorationImage(
                              image: NetworkImage(
                                UrlResolver.resolveImage(context, widget.groupAvatar),
                              ),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            widget.groupName,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: context.textSecondary700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // 二维码主体
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 220.w,
                      backgroundColor: Colors.white,
                      embeddedImage: widget.groupAvatar != null
                          ? NetworkImage(UrlResolver.resolveImage(context, widget.groupAvatar))
                          : null,
                      embeddedImageStyle: QrEmbeddedImageStyle(
                        size: Size(40.w, 40.w),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "Scan to join group",
                      style: TextStyle(
                        color: context.textSecondary700,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 40.h),

            // [修改] 6. 底部双按钮 (分享 + 保存)
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