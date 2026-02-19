part of 'global_handler.dart';


extension GlobalHandlerSocketExtension on _GlobalHandlerState {

  // [新增] 初始化 CallKit 监听 (处理系统来电界面的接听/挂断点击)
  void _initCallKitListener() {
    CallKitService.instance.initListener(
      // A. 用户点了系统界面的【接听】
      onAccept: (sessionId) async {
        debugPrint(" [CallKit] 用户点击接听，开始捞取系统资料... sessionId: $sessionId");

        // 1. 【核心逻辑】从系统的 CallKit 库里捞回你在 bootstrap 时塞进去的 extra 资料
        final List<dynamic>? calls = await FlutterCallkitIncoming.activeCalls();
        Map<String, dynamic> metadata = {};

        if (calls != null && calls.isNotEmpty) {
          // 找到当前 ID 对应的那个通话
          final call = calls.firstWhere((c) => c['id'] == sessionId, orElse: () => null);
          if (call != null && call['extra'] != null) {
            // 重点：使用 .cast 解决你日志里那个该死的类型报错 '_Map<Object?, Object?>'
            metadata = (call['extra'] as Map).cast<String, dynamic>();
            debugPrint(" [CallKit] 成功找回资料隧道数据: $metadata");
          }
        }

        if (NavHub.key.currentState?.mounted ?? false) {
          final controller = ref.read(callControllerProvider.notifier);
          final callState = ref.read(callControllerProvider);

          // 2. 【自愈逻辑】如果当前控制器是空的（冷启动），用 metadata 强制喂饱它
          if (metadata.isNotEmpty) {
            await controller.incomingCall(metadata);
          }

          // 3. 执行接听协议流程
          controller.acceptCall();

          // 4. 【精准跳转】不再用 unknown 占位，直接从 metadata 拿真实数据
          final String realTargetId = metadata['senderId']?.toString() ?? controller.targetId ?? "unknown";
          final String realTargetName = metadata['senderName']?.toString() ?? controller.targetName ?? "User";

          NavHub.key.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (_) => CallPage(
                targetId: realTargetId,
                targetName: realTargetName,
                isVideo: callState.isVideoMode,
              ),
            ),
          );
        }
      },

      // B. 用户点了系统界面的【挂断】
      onDecline: (sessionId) {
        debugPrint(" [CallKit] User declined call");
        ref.read(callControllerProvider.notifier).hangUp();
      },
    );
  }

  void _subscribeToSocket(SocketService service) {
    // 缓存 service 引用
    _cachedSocketService = service;

    _cancelSocketSubscriptions();

    // [新增] 1. 启动 CallKit 监听
    _initCallKitListener();

    // [修改] 2. 监听来电信令 (SocketEvents.callInvite)
    service.socket?.on(SocketEvents.callInvite, (data) async {
      if (!mounted) return;

      // 终极修复：前台线程检查全局时间锁
      final prefs = await SharedPreferences.getInstance();
      final int lockTime = prefs.getInt('global_call_lock') ?? 0;
      final int now = DateTime.now().millisecondsSinceEpoch;

      if (now - lockTime < 5000) {
        debugPrint("️ [GlobalHandler] 全局冷却期生效！拦截重复的 Socket invite 信号！");
        return;
      }

      // 允许接通了，赶紧上锁！
      await prefs.setInt('global_call_lock', now);

      final currentStatus = ref.read(callControllerProvider).status;
      if (currentStatus != CallStatus.idle && currentStatus != CallStatus.ended) {
        debugPrint(' 拦截无效呼叫：状态=$currentStatus');
        return;
      }

      debugPrint(' [GlobalHandler] Received call invite: $data');

      // A. 初始化 Controller 并初始化被叫状态 (设置为 Ringing)
      await ref.read(callControllerProvider.notifier).incomingCall(data);

      // [修改] B. 不再直接 Navigator.push，而是显示系统原生来电界面！
      final senderName = data['senderName'] ?? "Incoming Call";
      final avatar = data['senderAvatar'] ?? "https://via.placeholder.com/150";

      // C. 唤起原生界面 (Android/iOS)
      await CallKitService.instance.showIncomingCall(
        uuid: data['sessionId'],
        name: senderName,
        avatar: avatar,
        isVideo: data['mediaType'] == 'video',
      );
    });

    // [新增] 3. 监听对方挂断 (SocketEvents.callEnd)
    // 对方挂了，我们要把 CallKit 的系统界面也关掉，否则它会一直响
    service.socket?.on(SocketEvents.callEnd, (data) {
      if (data['sessionId'] != null) {
        CallKitService.instance.endCall(data['sessionId']);

       //  核心修复：必须触发 hangUp，否则 Flutter 的 CallPage 永远不会消失！
        ref.read(callControllerProvider.notifier).hangUp(emitEvent: false);
      }
    });

    debugPrint(' [GlobalHandler] Socket Subscriptions Active');

    // ----------------------------------------------------------------
    // 下面的逻辑保持不变
    // ----------------------------------------------------------------

    // 1. 联系人申请
    _contactApplySub = service.contactApplyStream.listen((data) {
      if (!mounted) return;
      _showContactApplyNotification(data); //  转交给 UI 逻辑
    });

    // 2. 联系人接受
    _contactAcceptSub = service.contactAcceptStream.listen((data) {
      if (!mounted) return;
      _showSuccessToast("Friend Added", "You are now friends!");
      ref.invalidate(contactListProvider);
    });

    // 3. 群组事件监听
    _groupEventSub = service.groupEventStream.listen((event) {
      if (!mounted) return;

      final payload = event.payload;

      switch (event.type) {
      // A. 管理员收到新申请
        case SocketEvents.groupApplyNew:
          _showSuccessToast(
            "New Group Request",
            "${payload.nickname ?? 'Someone'} wants to join the group",
          );
          break;

      // B. 申请人收到结果
        case SocketEvents.groupApplyResult:
          final groupName = payload.groupName ?? 'Group';
          if (payload.approved == true) {
            _showSuccessToast(
              "Application Approved",
              "You have joined $groupName",
            );
          } else {
            _showErrorToast(
              "Application Rejected",
              "Your request to join $groupName was rejected",
            );
          }
          break;

      // C. 成员被踢 (给自己弹个提示)
        case SocketEvents.memberKicked:
          final myId = ref.read(userProvider)?.id;
          if (payload.targetId == myId) {
            _showErrorToast("Removed", "You were removed from the group");
          }
          break;
      }
    });

    // 4. 通用业务通知
    _notificationSub = service.notificationStream.listen((notification) {
      if (!mounted) return;
      if (notification.isSuccess) {
        _showSuccessToast(notification.title, notification.message);
      } else {
        _showErrorToast(notification.title, notification.message);
      }
    });

    // 5. 拼团/更新通知
    _updateSub = service.groupUpdateStream.listen((data) {
      if (!mounted) return;
      _processGroupUpdate(data);
    });
  }

  void _processGroupUpdate(Map<String, dynamic> data) {
    try {
      final int status = data['status'] ?? 0;
      if (status == 2 || (data['isFull'] ?? false)) {
        _showSuccessToast(
          'group_lobby.status_success'.tr(),
          'group_lobby.msg_group_full'.tr(),
        );
      }
    } catch (_) {}
  }

  void _cancelSocketSubscriptions() {
    _notificationSub?.cancel();
    _updateSub?.cancel();
    _contactApplySub?.cancel();
    _contactAcceptSub?.cancel();
    _groupEventSub?.cancel();

    _cachedSocketService?.socket?.off(SocketEvents.callInvite);

    // [新增] 记得移除 callEnd 监听，防止重复
    _cachedSocketService?.socket?.off(SocketEvents.callEnd);
  }
}