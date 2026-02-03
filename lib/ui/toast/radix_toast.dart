import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 假设你用了 screenutil

/// RadixToast - 使用 BotToast 重构，支持顶部显示
class RadixToast {

  // 保持原有私有方法签名不变
  static void _show(
      String message, {
        required Color backgroundColor,
        required Color textColor,
        // 虽然 BotToast 不用 ToastGravity，但为了兼容你的旧代码调用，保留此参数
        // 我们在内部将其转换为 Alignment
        dynamic gravity,
      }) {
    // 移除旧的 toast (可选，防止堆叠)
    BotToast.cleanAll();

    // 使用 showCustomText 可以完全自定义样式，完美复刻你原来的配色
    BotToast.showCustomText(
      duration: const Duration(seconds: 2),
      onlyOne: true, // 保持同一时间只显示一个
      clickClose: true,
      align: Alignment(0, -0.85), // 对应 Gravity.TOP，0是中间，-1是顶部，-0.85留出状态栏距离
      toastBuilder: (_) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w), // 左右边距
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24.r), // 圆角
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // 宽度自适应内容
            children: [
              // 如果需要图标可以加在这里，为了保持原样，只放文字
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp, // 根据需要调整
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none, // 防止没有 Material 父级时出现双下划线
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 保持原有接口不变 - Success
  static void success(String message) {
    _show(
      message,
      backgroundColor: const Color(0xFF4CAF50), // Green
      textColor: const Color(0xFFFFFFFF), // White
    );
  }

  // 保持原有接口不变 - Error
  static void error(String message) {
    _show(
      message,
      backgroundColor: const Color(0xFFF44336), // Red
      textColor: const Color(0xFFFFFFFF), // White
    );
  }

  // 保持原有接口不变 - Info
  static void info(String message) {
    _show(
      message,
      backgroundColor: const Color(0xFF2196F3), // Blue
      textColor: const Color(0xFFFFFFFF), // White
    );
  }
}