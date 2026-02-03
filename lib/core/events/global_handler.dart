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
import '../../app/routes/app_router.dart';
import '../../theme/design_tokens.g.dart';
import '../../ui/chat/providers/contact_provider.dart';
import '../../ui/toast/radix_toast.dart';
import '../providers/socket_provider.dart';
import '../services/socket/session_manager.dart';
import '../services/socket/socket_service.dart';

//  修改标注 1: 引入逻辑分层文件
part 'global_handler_socket.dart';
part 'global_handler_ui.dart';

class GlobalHandler extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalHandler({super.key, required this.child});

  @override
  ConsumerState<GlobalHandler> createState() => _GlobalHandlerState();
}

class _GlobalHandlerState extends ConsumerState<GlobalHandler> {
  // ----------------------------------------------------------------
  //  状态变量 (由各 Part 共享)
  // ----------------------------------------------------------------
  StreamSubscription? _eventBusSub;
  StreamSubscription? _notificationSub;
  StreamSubscription? _updateSub;
  StreamSubscription? _contactApplySub;
  StreamSubscription? _contactAcceptSub;

  DateTime? _lastToastTime;
  String? _lastToastKey;

  @override
  void initState() {
    super.initState();

    // 监听本地 EventBus
    _eventBusSub = EventBus().stream.listen((event) => _handleGlobalEvent(event));

    // 启动 Session 管理
    ref.read(sessionManagerProvider);

    Future.microtask(() {
      final service = ref.read(socketServiceProvider);
      _subscribeToSocket(service);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 监听 Provider 变化，自动重连
    ref.listen<SocketService>(socketServiceProvider, (previous, next) {
      debugPrint(' [GlobalHandler] SocketService updated, re-subscribing...');
      _subscribeToSocket(next);
    });

    return widget.child;
  }

  @override
  void dispose() {
    _eventBusSub?.cancel();
    _cancelSocketSubscriptions();
    super.dispose();
  }
}