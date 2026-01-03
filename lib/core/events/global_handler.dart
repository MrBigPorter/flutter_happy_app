import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemNavigator
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/modal/dialog/modal_dialog_config.dart';
import 'package:flutter_app/ui/modal/dialog/radix_modal.dart';
import 'package:flutter_app/utils/events/event_bus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io'; //  必须加这个，为了用 exit(0) 和 Platform
import 'package:flutter/services.dart'; // 为了用 SystemNavigator

import '../../theme/design_tokens.g.dart';
import '../../utils/events/global_events.dart';

class GlobalHandler extends StatefulWidget {
  final Widget child;
  const GlobalHandler({super.key, required this.child});

  @override
  State<GlobalHandler> createState() => _GlobalHandlerState();
}

class _GlobalHandlerState extends State<GlobalHandler> {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = EventBus().stream.listen((event) {
      _handleGlobalEvent(event);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

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
      // 配置：不显示右上角关闭按钮
      config: ModalDialogConfig(
        showCloseButton: false,
      ),
      // 配置：点击背景不关闭
      clickBgToClose: false,
      builder: (context, close) {
        // 使用 PopScope 拦截物理返回键 (Android Back Button)
        return PopScope(
          canPop: false, //  禁止通过返回键关闭
          child: Container(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon 增加视觉警示
                Icon(
                    Icons.lock_person_rounded,
                    size: 48.w,
                    color: context.textPrimary900
                ),
                SizedBox(height: 16.h),

                // 标题 Title
                Text(
                  'security.device_banned_title'.tr(), // ✅ Key: Device Access Restricted
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.textLg,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary900,
                  ),
                ),
                SizedBox(height: 8.h),

                // 描述 Description
                Text(
                  'security.device_banned_desc'.tr(), // ✅ Key: We detected unusual activity...
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.textSm,
                    color: context.textSecondary700,
                  ),
                ),
                SizedBox(height: 24.h),

                // 按钮 1: 联系客服 (Primary Action)
                Button(
                  onPressed: () {
                    // TODO: 跳转客服逻辑
                    // launchUrl(Uri.parse("https://support.example.com"));
                  },
                  child: Text('security.btn_contact_support'.tr()), //  Key: Contact Support
                ),

                SizedBox(height: 12.h),

                // 按钮 2: 退出应用 (Secondary Action)
                GestureDetector(
                  behavior: HitTestBehavior.opaque, //  扩大点击区域，防止点不中
                  onTap: () {
                    //  Android: 尝试优雅退出
                    if (Platform.isAndroid) {
                      try {
                        SystemNavigator.pop();
                      } catch (e) {
                        // 如果失败，直接强杀
                        exit(0);
                      }
                    }
                    //  iOS: 必须强杀 (SystemNavigator 在 iOS 通常没反应)
                    else {
                      exit(0);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 24.w), // 增加触摸面积
                    child: Text(
                      'security.btn_exit_app'.tr(),
                      style: TextStyle(
                        fontSize: context.textSm,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondary700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      confirmText: '', // 不显示确认按钮
      cancelText: '', // 不显示取消按钮
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}