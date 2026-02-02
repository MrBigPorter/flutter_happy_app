import 'dart:io';
import 'dart:typed_data'; // 🔥 引入这个用于 Uint8List

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/api/http_client.dart'; // 确保引入 Http 类
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/utils/url_resolver.dart';
import 'package:flutter_app/ui/chat/services/media/map_launcher_service.dart';

import '../../../../core/store/auth/auth_provider.dart';

//  1. 改动：从 ConsumerWidget 改为 ConsumerStatefulWidget
// 只有有状态组件才能缓存 Future，防止 build 循环重绘
class LocationMsgBubble extends ConsumerStatefulWidget {
  final ChatUiModel message;

  const LocationMsgBubble({super.key, required this.message});

  @override
  ConsumerState<LocationMsgBubble> createState() => _LocationMsgBubbleState();
}

//  2. 改动：混入 AutomaticKeepAliveClientMixin
// 这能保证列表滚动出屏幕外再滚回来时，图片不会重新加载，进一步节省流量
class _LocationMsgBubbleState extends ConsumerState<LocationMsgBubble> with AutomaticKeepAliveClientMixin {

  //  3. 新增：定义一个变量来缓存 Web 端的请求任务
  // 一旦赋值，除非组件销毁，否则不会再次执行网络请求
  Future<Uint8List?>? _mapSnapshotFuture;

  @override
  bool get wantKeepAlive => true; // 保持状态不被回收

  ///  Web 端获取图片二进制数据的辅助方法 (移到了 State 内部)
  Future<Uint8List?> _webFetchMapImage(String url, String token) async {
    if (token.isEmpty) return null;
    try {
      // 使用 rawDio (跳过全局拦截器，防止它去解析 JSON)
      final response = await Http.rawDio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes, // 告诉它我要二进制
          headers: {
            "Authorization": "Bearer $token", // 手动带 Token
          },
        ),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      }
    } catch (e) {
      debugPrint("Web Map Load Error: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ⚠️ KeepAlive 必须调用

    // 监听 Token
    final String? token = ref.watch(authProvider.select((s) => s.accessToken));

    final double? lat = widget.message.latitude;
    final double? lng = widget.message.longitude;
    final String address = widget.message.address ?? "Unknown Address";
    final String? title = widget.message.locationTitle;

    //  4. 关键逻辑：懒加载初始化 Future
    // 条件：是Web端 + 还没请求过(_mapSnapshotFuture为空) + 有经纬度 + 有Token
    if (kIsWeb &&
        _mapSnapshotFuture == null &&
        lat != null &&
        lng != null &&
        token != null &&
        token.isNotEmpty) {
      final String mapUrl = UrlResolver.getStaticMapUrl(lat, lng);
      // 将请求赋给变量，下次 build 时直接用这个变量，不会再次发起请求
      _mapSnapshotFuture = _webFetchMapImage(mapUrl, token);
    }

    final double bubbleWidth = 0.65.sw;

    final timeStr = DateFormat(
      'HH:mm',
    ).format(DateTime.fromMillisecondsSinceEpoch(widget.message.createdAt));

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
              // 地图预览
              _buildMapPreview(context, lat, lng, bubbleWidth, token ?? ""),

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

  /// 构建地图预览
  Widget _buildMapPreview(
      BuildContext context,
      double? lat,
      double? lng,
      double width,
      String token,
      ) {
    final double imageHeight = 120.h;

    // 状态 1: 数据缺失
    if (lat == null || lng == null) {
      return _buildPlaceholder(
        width,
        height: imageHeight,
        icon: Icons.location_off,
      );
    }

    // 状态 2: Web 端逻辑
    if (kIsWeb) {
      //  5. 改动：FutureBuilder 使用缓存的 _mapSnapshotFuture
      // 这里的 future 不再是函数调用，而是一个固定的变量
      return ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(11.r)),
        child: SizedBox(
          width: width,
          height: imageHeight,
          child: FutureBuilder<Uint8List?>(
            future: _mapSnapshotFuture, //  正确用法
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  color: context.bgSecondary,
                  child: const Center(child: CupertinoActivityIndicator()),
                );
              }
              if (snapshot.hasData && snapshot.data != null) {
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true, // 防止重新加载时闪烁
                );
              }
              // 加载失败或无数据
              return _buildPlaceholder(width, height: imageHeight, icon: Icons.map_outlined);
            },
          ),
        ),
      );
    }

    // 状态 3: Native 端逻辑 (保持不变)
    final String? localPath = widget.message.resolvedThumbPath; // 注意用了 widget.message

    // 优先检查本地文件
    if (localPath != null &&
        localPath.isNotEmpty &&
        !localPath.startsWith('http')) {
      final file = File(localPath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(11.r)),
          child: SizedBox(
            width: width,
            height: imageHeight,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _buildPlaceholder(width, height: imageHeight),
            ),
          ),
        );
      }
    }

    // Token 缺失检查
    if (token.isEmpty) {
      return _buildPlaceholder(
        width,
        height: imageHeight,
        icon: Icons.lock_clock,
      );
    }

    // 正常网络请求 (Native)
    final String mapUrl = UrlResolver.getStaticMapUrl(lat, lng);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(11.r)),
      child: SizedBox(
        width: width,
        height: imageHeight,
        child: CachedNetworkImage(
          imageUrl: mapUrl,
          httpHeaders: {"Authorization": "Bearer $token"},
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: context.bgSecondary,
            child: const Center(child: CupertinoActivityIndicator()),
          ),
          errorWidget: (context, url, error) => _buildPlaceholder(
            width,
            height: imageHeight,
            icon: Icons.map_outlined,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(
      double width, {
        required double height,
        IconData icon = Icons.map,
      }) {
    return Container(
      width: width,
      height: height,
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

  void _handleOpenMap(
      BuildContext context,
      double? lat,
      double? lng,
      String? title,
      String address,
      ) {
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