import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/api/http_client.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/ui/chat/services/media/map_launcher_service.dart';

import '../../../../core/store/auth/auth_provider.dart';

class LocationMsgBubble extends ConsumerStatefulWidget {
  final ChatUiModel message;

  const LocationMsgBubble({super.key, required this.message});

  @override
  ConsumerState<LocationMsgBubble> createState() => _LocationMsgBubbleState();
}

// AutomaticKeepAliveClientMixin ensures the map snapshot is preserved when
// scrolling out of view, reducing redundant network requests.
class _LocationMsgBubbleState extends ConsumerState<LocationMsgBubble> with AutomaticKeepAliveClientMixin {

  // Cache the Future for Web platform requests to prevent re-fetching during widget rebuilds.
  Future<Uint8List?>? _mapSnapshotFuture;

  @override
  bool get wantKeepAlive => true;

  /// Helper method for fetching raw image bytes on Web platform.
  Future<Uint8List?> _webFetchMapImage(String url, String token) async {
    if (token.isEmpty) return null;
    try {
      // Use rawDio to skip global interceptors and handle binary response type directly.
      final response = await Http.rawDio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      }
    } catch (e) {
      debugPrint("[LocationBubble] Web Map Load Error: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final String? token = ref.watch(authProvider.select((s) => s.accessToken));

    final double? lat = widget.message.latitude;
    final double? lng = widget.message.longitude;
    final String address = widget.message.address ?? "Unknown Address";
    final String? title = widget.message.locationTitle;

    // Lazy-load initialization for Web map snapshot.
    if (kIsWeb &&
        _mapSnapshotFuture == null &&
        lat != null &&
        lng != null &&
        token != null &&
        token.isNotEmpty) {
      final String mapUrl = UrlResolver.getStaticMapUrl(lat, lng);
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
              // Map Preview Section
              _buildMapPreview(context, lat, lng, bubbleWidth, token ?? ""),

              // Address and Title Information
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

  /// Builds the map snapshot preview area.
  Widget _buildMapPreview(
      BuildContext context,
      double? lat,
      double? lng,
      double width,
      String token,
      ) {
    final double imageHeight = 120.h;

    // State 1: Incomplete location data
    if (lat == null || lng == null) {
      return _buildPlaceholder(
        width,
        height: imageHeight,
        icon: Icons.location_off,
      );
    }

    // State 2: Web platform specific rendering
    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(11.r)),
        child: SizedBox(
          width: width,
          height: imageHeight,
          child: FutureBuilder<Uint8List?>(
            future: _mapSnapshotFuture,
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
                  gaplessPlayback: true,
                );
              }
              return _buildPlaceholder(width, height: imageHeight, icon: Icons.map_outlined);
            },
          ),
        ),
      );
    }

    // State 3: Native platform logic with local caching
    final String? localPath = widget.message.resolvedThumbPath;

    // Prioritize local file existence for faster rendering and offline support
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

    // Security check for missing authorization token
    if (token.isEmpty) {
      return _buildPlaceholder(
        width,
        height: imageHeight,
        icon: Icons.lock_clock,
      );
    }

    // Standard remote map snapshot request for Native
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