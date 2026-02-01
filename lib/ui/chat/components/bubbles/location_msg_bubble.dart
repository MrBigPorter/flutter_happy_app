import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/utils/url_resolver.dart';
import 'package:flutter_app/ui/chat/services/media/map_launcher_service.dart';

import '../../../../core/store/auth/auth_provider.dart';

class LocationMsgBubble extends ConsumerWidget {
  final ChatUiModel message;

  const LocationMsgBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听 Token，但允许为空 (String?)
    final String? token = ref.watch(authProvider.select((s) => s.accessToken));

    final double? lat = message.latitude;
    final double? lng = message.longitude;
    final String address = message.address ?? "Unknown Address";
    final String? title = message.locationTitle;

    final double bubbleWidth = 0.65.sw;

    final timeStr = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(message.createdAt),
    );

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => _handleOpenMap(context, lat, lng, title, address),
        child: Container(
          width: bubbleWidth,
          decoration: BoxDecoration(
            color: context.bgSecondary,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.borderPrimary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // === 优化后的地图预览 ===
              _buildMapPreview(context, lat, lng, bubbleWidth, token!),

              // 地址信息
              Padding(
                padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 4.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null && title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: context.textPrimary900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    SizedBox(height: 2.h),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: context.textSecondary700,
                        height: 1.2,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: _buildTimeTag(context, timeStr),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建地图预览 (包含 4 种状态：本地、网络、无Token、错误)
  Widget _buildMapPreview(BuildContext context, double? lat, double? lng, double width, String token) {
    // 固定高度，防止布局抖动
    final double imageHeight = 120.h;

    // 状态 1: 数据缺失，显示默认灰块
    if (lat == null || lng == null) {
      return _buildPlaceholder(width, height: imageHeight, icon: Icons.location_off);
    }

    final String? localPath = message.resolvedThumbPath;

    // 状态 2: 优先检查本地文件
    if (localPath != null && localPath.isNotEmpty && !localPath.startsWith('http')) {
      final file = File(localPath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(11.r)),
          //  修复点 1：用 SizedBox 强制约束尺寸，防止 RenderBox 报错
          child: SizedBox(
            width: width,
            height: imageHeight,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(width, height: imageHeight),
            ),
          ),
        );
      }
    }

    // 状态 3: Token 缺失
    if (token.isEmpty) {
      return _buildPlaceholder(width, height: imageHeight, icon: Icons.lock_clock);
    }

    // 状态 4: 正常网络请求
    final String mapUrl = UrlResolver.getStaticMapUrl(lat, lng);

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(11.r)),
      // 修复点 2：CachedNetworkImage 也包一层 SizedBox
      child: SizedBox(
        width: width,
        height: imageHeight,
        child: CachedNetworkImage(
          imageUrl: mapUrl,
          httpHeaders: {
            "Authorization": "Bearer $token",
          },
          fit: BoxFit.cover, // 这里的 fit 才能在 SizedBox 里生效

          // 优化：加载中显示转圈
          placeholder: (context, url) => Container(
            color: context.bgSecondary,
            child: const Center(
              child: CupertinoActivityIndicator(),
            ),
          ),

          // 优化：加载失败
          errorWidget: (context, url, error) => _buildPlaceholder(width, height: imageHeight, icon: Icons.map_outlined),
        ),
      ),
    );
  }

  /// 统一的占位组件 (记得更新这个方法的签名，接收 height)
  Widget _buildPlaceholder(double width, {required double height, IconData icon = Icons.map}) {
    return Container(
      width: width,
      height: height, // 使用传入的高度
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(11.r)),
      ),
      child: Center(
        child: Icon(icon, color: Colors.grey, size: 32.sp),
      ),
    );
  }


  Widget _buildTimeTag(BuildContext context, String time) {
    return Container(
      margin: EdgeInsets.only(top: 4.h, bottom: 2.h),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        time,
        style: TextStyle(
          color: context.textSecondary700,
          fontSize: 9.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _handleOpenMap(BuildContext context, double? lat, double? lng, String? title, String address) {
    if (lat == null || lng == null) return;

    MapLauncherService.openMap(
      context,
      lat: lat,
      lng: lng,
      title: title ?? "Location",
      address: address,
    );
  }
}