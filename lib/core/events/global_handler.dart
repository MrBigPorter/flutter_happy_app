import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/providers/fcm_service_provider.dart';
import 'package:flutter_app/ui/chat/services/network/offline_queue_manager.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/modal/dialog/modal_dialog_config.dart';
import 'package:flutter_app/ui/modal/dialog/radix_modal.dart';
import 'package:flutter_app/utils/events/event_bus.dart';
import 'package:flutter_app/utils/events/global_events.dart';
import '../../app/routes/app_router.dart';
import '../../main.dart';
import '../../theme/design_tokens.g.dart';
import '../../ui/chat/call/call_page.dart';
import '../../ui/chat/handlers/global_chat_handler.dart';
import '../../ui/chat/models/call_state_model.dart';
import '../../ui/chat/providers/call_controller.dart';
import '../../ui/chat/providers/contact_provider.dart';
import '../../ui/chat/providers/global_unread_provider.dart';
import '../../ui/toast/radix_toast.dart';
import '../constants/socket_events.dart';
import '../providers/socket_provider.dart';
import '../services/socket/session_manager.dart';
import '../services/socket/socket_service.dart';
import '../store/user_store.dart';

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
  StreamSubscription? _groupEventSub;

  DateTime? _lastToastTime;
  String? _lastToastKey;

  SocketService? _cachedSocketService;

  @override
  void initState() {
    super.initState();

    // 监听本地 EventBus
    _eventBusSub = EventBus().stream.listen((event) => _handleGlobalEvent(event));

    //fcm init
    ref.read(fcmServiceProvider);

    // 启动 Session 管理
    ref.read(sessionManagerProvider);

    Future.microtask(() {
      final service = ref.read(socketServiceProvider);
      _subscribeToSocket(service);
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_){
      OfflineQueueManager().init(ProviderScope.containerOf(context));
      debugPrint(' [GlobalHandler] OfflineQueueManager initialized.');
    });
  }

  @override
  Widget build(BuildContext context) {

    // 只要 GlobalHandler 活着，这两个 Provider 就会一直工作
    // 1. 负责收消息存库
    ref.watch(globalChatHandlerProvider);
    // 2. 负责更新红点
    ref.watch(globalUnreadProvider);

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