import 'dart:async';
import 'dart:io'; // exit, Platform

import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemNavigator
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 项目内部依赖
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/modal/dialog/modal_dialog_config.dart';
import 'package:flutter_app/ui/modal/dialog/radix_modal.dart';
import 'package:flutter_app/utils/events/event_bus.dart';
import 'package:flutter_app/utils/events/global_events.dart';
import '../../theme/design_tokens.g.dart';
import '../providers/socket_provider.dart';

class GlobalHandler extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalHandler({super.key, required this.child});

  @override
  ConsumerState<GlobalHandler> createState() => _GlobalHandlerState();
}

class _GlobalHandlerState extends ConsumerState<GlobalHandler> {
  // 定义订阅变量，分别管理不同的流
  StreamSubscription? _eventBusSub;
  StreamSubscription? _notificationSub; // 监听明确通知 (如 group_success)
  StreamSubscription? _updateSub;       // 监听数据更新 (如 status 变更为 2)

  @override
  void initState() {
    super.initState();

    // 1. 监听本地 EventBus (处理封号等)
    _eventBusSub = EventBus().stream.listen((event) {
      _handleGlobalEvent(event);
    });

    // 2. 监听 Socket 全局通知
    // 使用 addPostFrameCallback 确保 Context 安全
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSocketListener();
    });
  }

  void _setupSocketListener() {
    final socketService = ref.read(socketServiceProvider);

    // ----------------------------------------------------------------
    // 监听 A: 明确的 Notification (后端直接发送 group_success 事件)
    // ----------------------------------------------------------------
    _notificationSub = socketService.notificationStream.listen((notification) {
      debugPrint('🔔 [GlobalHandler] Recv Notification: ${notification.title}');
      if (!mounted) return;

      if (notification.isSuccess) {
        _showSuccessToast(notification.title, notification.message);
      } else {
        _showErrorToast(notification.title, notification.message);
      }
    });

    // ----------------------------------------------------------------
    // 监听 B: 数据 Update (后端发送 group_update 事件)
    // 🔥 核心补充：当收到 group_update 且状态变成 2 (满员) 时，也弹窗
    // ----------------------------------------------------------------
    _updateSub = socketService.groupUpdateStream.listen((data) {
      if (!mounted) return;

      try {
        final int status = data['status'] ?? 0;
        final bool isFull = data['isFull'] ?? false;

        // 如果状态变成 2 (满员/成功) 或者 isFull 为 true
        if (status == 2 || isFull) {
          debugPrint('🔔 [GlobalHandler] 监测到团满员(Update流)，触发弹窗！');
          _showSuccessToast(
            'group_lobby.status_success'.tr(), // Key: 拼团成功
            'group_lobby.msg_group_full'.tr(), // Key: 团已满，正在计算结果...
          );
        }
      } catch (e) {
        debugPrint('❌ [GlobalHandler] 解析 Update 失败: $e');
      }
    });
  }

  @override
  void dispose() {
    _eventBusSub?.cancel();
    _notificationSub?.cancel();
    _updateSub?.cancel();
    super.dispose();
  }

  // ============================================================
  // 🟢 🟡 Socket 弹窗逻辑 (使用 BotToast)
  // ============================================================

  void _showSuccessToast(String title, String msg) {
    // 简单的去重逻辑：防止短时间内连续弹相同的窗（可选）
    BotToast.showSimpleNotification(
      title: title,
      subTitle: msg,
      duration: const Duration(seconds: 4),
      align: const Alignment(0, -0.8), // 顶部显示
      backgroundColor: const Color(0xFF52C41A), // 成功绿
      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      subTitleStyle: const TextStyle(color: Colors.white),
      borderRadius: 12.0,
      hideCloseButton: true,
    );
  }

  void _showErrorToast(String title, String msg) {
    BotToast.showSimpleNotification(
      title: title,
      subTitle: msg,
      duration: const Duration(seconds: 4),
      align: const Alignment(0, -0.8),
      backgroundColor: Colors.orange, // 警告色
      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      subTitleStyle: const TextStyle(color: Colors.white),
      borderRadius: 12.0,
      hideCloseButton: true,
    );
  }

  // ============================================================
  // 🔒 EventBus 逻辑 (封号处理)
  // ============================================================

  void _handleGlobalEvent(GlobalEvent event) {
    if (!mounted) return;

    switch (event.type) {
      case GlobalEventType.deviceBanned:
        _showLockDialog();
        break;
      default:
        break;
    }
  }

  void _showLockDialog() {
    RadixModal.show(
      config: ModalDialogConfig(showCloseButton: false),
      clickBgToClose: false,
      builder: (context, close) {
        return PopScope(
          canPop: false,
          child: Container(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_person_rounded, size: 48.w, color: context.textPrimary900),
                SizedBox(height: 16.h),
                Text(
                  'security.device_banned_title'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: context.textLg, fontWeight: FontWeight.w700, color: context.textPrimary900),
                ),
                SizedBox(height: 8.h),
                Text(
                  'security.device_banned_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: context.textSm, color: context.textSecondary700),
                ),
                SizedBox(height: 24.h),
                Button(
                  onPressed: () {}, // TODO: 客服
                  child: Text('security.btn_contact_support'.tr()),
                ),
                SizedBox(height: 12.h),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (Platform.isAndroid) {
                      try {
                        SystemNavigator.pop();
                      } catch (e) {
                        exit(0);
                      }
                    } else {
                      exit(0);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 24.w),
                    child: Text(
                      'security.btn_exit_app'.tr(),
                      style: TextStyle(fontSize: context.textSm, fontWeight: FontWeight.w600, color: context.textSecondary700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      confirmText: '',
      cancelText: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    // 这里不需要再包 BotToastInit 了，因为 MyApp 里已经包在最外层了
    return widget.child;
  }
}