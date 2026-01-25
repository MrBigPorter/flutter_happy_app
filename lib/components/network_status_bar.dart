import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/providers/network_status_provider.dart';

class NetworkStatusBar extends ConsumerWidget {
  const NetworkStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStatus = ref.watch(networkStatusProvider);

    // 默认为在线 (不显示)
    final bool isOffline = asyncStatus.valueOrNull == NetworkStatus.offline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isOffline ? 40.h : 0, // 断网显示 40高度，平时 0
      color: const Color(0xFFFF3B30), // iOS 风格警告红
      width: double.infinity,
      child: isOffline
          ? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: Colors.white,
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            "No Internet Connection",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      )
          : const SizedBox.shrink(),
    );
  }
}