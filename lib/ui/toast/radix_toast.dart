import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// RadixToast - 统一全局通知组件
/// 支持：成功、错误、警告、信息、加载中
class RadixToast {

  // ----------------------------------------------------------------
  // 核心私有展示方法 (支持高级 UI 样式)
  // ----------------------------------------------------------------

  static void _show({
    required String message,
    String? title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    // 移除旧的通知，确保不堆叠
    BotToast.cleanAll();

    BotToast.showCustomNotification(
      duration: duration,
      onlyOne: true,
      toastBuilder: (cancelFunc) {
        return _NotificationCard(
          title: title,
          message: message,
          icon: icon,
          iconColor: iconColor,
          iconBgColor: iconBgColor,
          onTap: () => cancelFunc(),
        );
      },
    );
  }

  // ----------------------------------------------------------------
  // 常用静态接口
  // ----------------------------------------------------------------

  ///  成功 - 绿色风格
  static void success(String message, {String? title}) {
    _show(
      message: message,
      title: title ?? "Success",
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF52C41A),
      iconBgColor: const Color(0xFFF6FFED),
    );
  }

  ///  错误 - 红色风格
  static void error(String message, {String? title}) {
    _show(
      message: message,
      title: title ?? "Error",
      icon: Icons.error_rounded,
      iconColor: const Color(0xFFF5222D),
      iconBgColor: const Color(0xFFFFF1F0),
    );
  }

  /// ️ 警告 - 橙色风格 (新增常用)
  static void warning(String message, {String? title}) {
    _show(
      message: message,
      title: title ?? "Warning",
      icon: Icons.warning_rounded,
      iconColor: const Color(0xFFFAAD14),
      iconBgColor: const Color(0xFFFFFBE6),
    );
  }

  ///  信息 - 蓝色风格
  static void info(String message, {String? title}) {
    _show(
      message: message,
      title: title ?? "Information",
      icon: Icons.info_rounded,
      iconColor: const Color(0xFF1890FF),
      iconBgColor: const Color(0xFFE6F7FF),
    );
  }

  ///  全局 Loading (新增常用)
  /// 用于网络请求等需要阻塞交互的场景
  static void showLoading({String? message}) {
    BotToast.showCustomLoading(
      clickClose: false,
      allowClick: false,
      backButtonBehavior: BackButtonBehavior.ignore,
      toastBuilder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF333333).withOpacity(0.9), // 深灰色背景
            borderRadius: BorderRadius.circular(12), // 圆角
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Colors.white), // 白色转圈
                ),
              ),
              if (message != null && message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  /// 关闭所有通知/Loading
  static void hide() {
    BotToast.closeAllLoading();
    BotToast.cleanAll();
  }
}

// ----------------------------------------------------------------
//  私有 UI 组件：现代卡片样式 (Shopee 风格)
// ----------------------------------------------------------------

class _NotificationCard extends StatelessWidget {
  final String? title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _NotificationCard({
    this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  // 左侧状态图标
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 22.sp),
                  ),
                  SizedBox(width: 12.w),
                  // 中间文字内容
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        SizedBox(height: 2.h),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF666666),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // 右侧关闭提示或箭头
                  Icon(Icons.close, size: 16.sp, color: Colors.grey[300]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}