import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 用于触感反馈
import 'fcm_payload.dart';

class FcmUiFactory {
  /// 架构点：对外暴露唯一的展示接口
  static void showNotification(FcmPayload payload, {VoidCallback? onTap}) {
    BotToast.showCustomNotification(
      duration: const Duration(seconds: 5), // 稍微延长显示时间，增加可读性
      toastBuilder: (cancelFunc) {
        return _buildAdvancedNotificationCard(
          payload: payload,
          onTap: () {
            cancelFunc();
            if (onTap != null) onTap();
          },
          onDismiss: cancelFunc,
        );
      },
    );
  }

  /// 内部 UI 构建：采用解耦的布局结构，增强扩展性
  static Widget _buildAdvancedNotificationCard({
    required FcmPayload payload,
    required VoidCallback onTap,
    required VoidCallback onDismiss,
  }) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final themeColor = _getThemeColor(payload.type);

      return Card(
        margin: const EdgeInsets.only(top: 10, left: 12, right: 12),
        elevation: 12,
        shadowColor: themeColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        // 适配暗黑模式的背景
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact(); // 增加轻微触感反馈
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. 左侧动态 Icon 区域
                _buildLeadingIcon(payload.type, themeColor),
                const SizedBox(width: 12),

                // 2. 中间文本信息区域 (Flexible 布局防止溢出)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payload.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payload.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 3. 右侧物理关闭按钮 (解决用户只想关闭不跳转的需求)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: isDark ? Colors.white38 : Colors.black26,
                  onPressed: onDismiss,
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// 根据业务类型返回不同的图标和背景
  static Widget _buildLeadingIcon(FcmType type, Color themeColor) {
    IconData iconData;
    switch (type) {
      case FcmType.groupDetail:
        iconData = Icons.group_work_rounded;
        break;
      case FcmType.chat:
        iconData = Icons.chat_bubble_rounded;
        break;
      case FcmType.system:
        iconData = Icons.campaign_rounded;
        break;
      default:
        iconData = Icons.notifications_active_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: themeColor, size: 22),
    );
  }

  /// 颜色策略：区分业务紧急程度
  static Color _getThemeColor(FcmType type) {
    switch (type) {
      case FcmType.groupDetail:
        return Colors.deepOrangeAccent;
      case FcmType.system:
        return Colors.blueAccent;
      case FcmType.chat:
        return Colors.greenAccent[700]!;
      default:
        return Colors.blueGrey;
    }
  }
}