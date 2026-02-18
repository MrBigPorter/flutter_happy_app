part of 'global_handler.dart';


extension GlobalHandlerSocketExtension on _GlobalHandlerState {

  // [新增] 初始化 CallKit 监听 (处理系统来电界面的接听/挂断点击)
  void _initCallKitListener() {
    CallKitService.instance.initListener(
      // A. 用户点了系统界面的【接听】
      onAccept: (sessionId) {
        debugPrint("📞 [CallKit] User accepted call: $sessionId");

        // 确保 UI 挂载
        if (NavHub.key.currentState?.mounted ?? false) {
          final controller = ref.read(callControllerProvider.notifier);

          // 1. 告诉 Controller 用户接了 (这会触发 accept 信令)
          controller.acceptCall();

          // 2. 导航到通话界面
          // 注意：此时 Controller 状态已变，CallPage 会自动渲染 Connected 状态
          // 这里的参数最好在 incomingCall 时存入 Controller，或者后端带过来
          NavHub.key.currentState?.push(
            MaterialPageRoute(
              builder: (_) => const CallPage(
                targetId: "unknown", // 暂时占位，接通后通常会走 info 查询
                targetName: "Connecting...",
                isVideo: true, // 最好从 Controller 或缓存中获取
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

      // 获取当前状态
      final currentStatus = ref.read(callControllerProvider).status;
      // 如果已经在通话或拨号中，直接无视或自动拒绝
      if (currentStatus != CallStatus.idle && currentStatus != CallStatus.ended) {
        debugPrint(' [GlobalHandler] Received call invite but already in call: $currentStatus');
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