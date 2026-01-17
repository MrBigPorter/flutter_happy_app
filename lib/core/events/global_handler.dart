import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/modal/dialog/modal_dialog_config.dart';
import 'package:flutter_app/ui/modal/dialog/radix_modal.dart';
import 'package:flutter_app/utils/events/event_bus.dart';
import 'package:flutter_app/utils/events/global_events.dart';
import '../../theme/design_tokens.g.dart';
import '../providers/socket_provider.dart';
import '../services/session_manager.dart';
import '../services/socket_service.dart';
// 必须引入这个以识别类型

class GlobalHandler extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalHandler({super.key, required this.child});

  @override
  ConsumerState<GlobalHandler> createState() => _GlobalHandlerState();
}

class _GlobalHandlerState extends ConsumerState<GlobalHandler> {
  StreamSubscription? _eventBusSub;

  // Socket 相关的订阅
  StreamSubscription? _notificationSub;
  StreamSubscription? _updateSub;

  // 去重变量
  DateTime? _lastToastTime;
  String? _lastToastKey;

  @override
  void initState() {
    super.initState();

    // 1. 监听本地 EventBus
    _eventBusSub = EventBus().stream.listen((event) {
      _handleGlobalEvent(event);
    });

    //  只要这一句话，SessionManager 就开始在后台干活了！
    ref.read(sessionManagerProvider);

    Future.microtask(() {
      final service = ref.read(socketServiceProvider);
      _subscribeToSocket(service);
    });
  }

  //  核心修复 1：监听 Provider 变化，自动重连订阅
  @override
  Widget build(BuildContext context) {
    // 只要 socketServiceProvider 发生变化（比如 Token 刷新导致 Service 重建）
    // 这个回调就会执行，我们立刻把订阅切换到新的 Service 上
    ref.listen<SocketService>(socketServiceProvider, (previous, next) {
      debugPrint('🔄 [GlobalHandler] SocketService 实例更新，重新订阅流...');
      _subscribeToSocket(next);
    });

    return widget.child;
  }

  // ----------------------------------------------------------------
  // 🔌 统一的订阅逻辑 (核心修复 2：封装订阅与取消)
  // ----------------------------------------------------------------
  void _subscribeToSocket(SocketService service) {
    // A. 先取消旧的订阅 (防止重复监听)
    _notificationSub?.cancel();
    _updateSub?.cancel();

    debugPrint('🎧 [GlobalHandler] 已连接到最新的 SocketService');

    // B. 监听 Notification 流
    _notificationSub = service.notificationStream.listen((notification) {
      if (!mounted) return;
      if (notification.isSuccess) {
        _showSuccessToast(notification.title, notification.message);
      } else {
        _showErrorToast(notification.title, notification.message);
      }
    });

    // C. 监听 Update 流
    _updateSub = service.groupUpdateStream.listen((data) {
      if (!mounted) return;
      try {
        final int status = data['status'] ?? 0;
        final bool isFull = data['isFull'] ?? false;

        // 只有在明确满员时才触发
        if (status == 2 || isFull) {
          _showSuccessToast(
            'group_lobby.status_success'.tr(),
            'group_lobby.msg_group_full'.tr(),
          );
        }
      } catch (e) {
        // ignore error
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
  // 🟢 🟡 弹窗逻辑 (核心修复 3：补全去重代码)
  // ============================================================

  void _showSuccessToast(String title, String msg) {
    final String key = '$title|$msg';
    final DateTime now = DateTime.now();

    //  去重判断：内容相同 且 2秒内
    if (_lastToastKey == key &&
        _lastToastTime != null &&
        now.difference(_lastToastTime!) < const Duration(seconds: 2)) {
      debugPrint('🚫 [GlobalHandler] 拦截重复弹窗: $title');
      return;
    }

    _lastToastKey = key;
    _lastToastTime = now;

    BotToast.showSimpleNotification(
      title: title,
      subTitle: msg,
      duration: const Duration(seconds: 4),
      align: const Alignment(0, -0.8),
      backgroundColor: const Color(0xFF52C41A),
      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      subTitleStyle: const TextStyle(color: Colors.white),
      borderRadius: 12.0,
      hideCloseButton: true,
    );
  }

  void _showErrorToast(String title, String msg) {
    final String key = '$title|$msg';
    final DateTime now = DateTime.now();

    // 失败弹窗同样去重
    if (_lastToastKey == key &&
        _lastToastTime != null &&
        now.difference(_lastToastTime!) < const Duration(seconds: 2)) {
      return;
    }

    _lastToastKey = key;
    _lastToastTime = now;

    BotToast.showSimpleNotification(
      title: title,
      subTitle: msg,
      duration: const Duration(seconds: 4),
      align: const Alignment(0, -0.8),
      backgroundColor: Colors.orange,
      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      subTitleStyle: const TextStyle(color: Colors.white),
      borderRadius: 12.0,
      hideCloseButton: true,
    );
  }

  // ============================================================
  // 🔒 EventBus 逻辑
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
                Text('security.device_banned_title'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: context.textLg, fontWeight: FontWeight.w700, color: context.textPrimary900)),
                SizedBox(height: 8.h),
                Text('security.device_banned_desc'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: context.textSm, color: context.textSecondary700)),
                SizedBox(height: 24.h),
                Button(onPressed: () {}, child: Text('security.btn_contact_support'.tr())),
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: () => Platform.isAndroid ? SystemNavigator.pop() : exit(0),
                  child: Padding(padding: EdgeInsets.symmetric(vertical: 8.h), child: Text('security.btn_exit_app'.tr())),
                ),
              ],
            ),
          ),
        );
      },
      confirmText: '', cancelText: '',
    );
  }
}