part of 'global_handler.dart';

extension GlobalHandlerSocketExtension on _GlobalHandlerState {

  // 初始化 CallKit 监听 (处理系统来电界面的接听/挂断点击)
  void _initCallKitListener() {
    CallKitService.instance.initListener(
      // A. 用户点了系统界面的【接听】
      onAccept: (sessionId) async {
        debugPrint(" [CallKit] 用户点击接听，开始捞取系统资料... sessionId: $sessionId");

        final List<dynamic>? calls = await FlutterCallkitIncoming.activeCalls();
        Map<String, dynamic> metadata = {};

        if (calls != null && calls.isNotEmpty) {
          final call = calls.firstWhere((c) => c['id'] == sessionId, orElse: () => null);
          if (call != null && call['extra'] != null) {
            metadata = (call['extra'] as Map).cast<String, dynamic>();
            debugPrint(" [CallKit] 成功找回资料隧道数据: $metadata");
          }
        }

        if (NavHub.key.currentState?.mounted ?? false) {
          final stateMachine = ref.read(callStateMachineProvider.notifier);
          final callState = ref.read(callStateMachineProvider);

          if (metadata.isNotEmpty && callState.status == CallStatus.idle) {
            stateMachine.onIncomingInvite(CallEvent.fromMap(metadata));
          }

          stateMachine.acceptCall();

          //  核心修复：优先从 metadata 拿真实的 isVideo 状态，如果为空再退回到 state
          final String realTargetId = metadata['senderId']?.toString() ?? callState.targetId ?? "unknown";
          final String realTargetName = metadata['senderName']?.toString() ?? callState.targetName ?? "User";
          final bool isVideoCall = (metadata['mediaType'] != null)
              ? metadata['mediaType'] == 'video'
              : callState.isVideoMode;

          NavHub.key.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (_) => CallPage(
                targetId: realTargetId,
                targetName: realTargetName,
                isVideo: isVideoCall, //  使用准确的变量
              ),
            ),
          );
        }
      },

      // B. 用户点了系统界面的【挂断】
      onDecline: (sessionId) {
        debugPrint(" [CallKit] User declined call");
        //  核心替换 2：交给状态机去物理清场
        ref.read(callStateMachineProvider.notifier).hangUp();
      },
    );
  }

  void _subscribeToSocket(SocketService service) {
    _cachedSocketService = service;
    _cancelSocketSubscriptions();
    _initCallKitListener();

    // 1. 监听来电信令 (SocketEvents.callInvite)
    service.socket?.on(SocketEvents.callInvite, (data) async {
      if (!mounted) return;
      debugPrint(' [GlobalHandler] 收到 Socket 呼叫信令，交由 Dispatcher 审查...');
      // 没有任何废话，直接扔给海关安检口！
      await CallDispatcher.instance.dispatch(data);
    });

    // 2. 监听对方挂断 (SocketEvents.callEnd)
    service.socket?.on(SocketEvents.callEnd, (data) async {
      if (!mounted) return;
      // 同样没有废话，扔给 Dispatcher 去物理拉黑和清场！
      await CallDispatcher.instance.dispatch(data);
    });

    debugPrint('🔌 [GlobalHandler] Socket Subscriptions Active');


    _contactApplySub = service.contactApplyStream.listen((data) {
      if (!mounted) return;
      _showContactApplyNotification(data);
    });

    _contactAcceptSub = service.contactAcceptStream.listen((data) {
      if (!mounted) return;
      _showSuccessToast("Friend Added", "You are now friends!");
      ref.invalidate(contactListProvider);
    });

    _groupEventSub = service.groupEventStream.listen((event) {
      if (!mounted) return;
      final payload = event.payload;
      switch (event.type) {
        case SocketEvents.groupApplyNew:
          _showSuccessToast("New Group Request", "${payload.nickname ?? 'Someone'} wants to join the group");
          break;
        case SocketEvents.groupApplyResult:
          final groupName = payload.groupName ?? 'Group';
          if (payload.approved == true) {
            _showSuccessToast("Application Approved", "You have joined $groupName");
          } else {
            _showErrorToast("Application Rejected", "Your request to join $groupName was rejected");
          }
          break;
        case SocketEvents.memberKicked:
          final myId = ref.read(userProvider)?.id;
          if (payload.targetId == myId) {
            _showErrorToast("Removed", "You were removed from the group");
          }
          break;
      }
    });

    _notificationSub = service.notificationStream.listen((notification) {
      if (!mounted) return;
      if (notification.isSuccess) {
        _showSuccessToast(notification.title, notification.message);
      } else {
        _showErrorToast(notification.title, notification.message);
      }
    });

    _updateSub = service.groupUpdateStream.listen((data) {
      if (!mounted) return;
      _processGroupUpdate(data);
    });
  }

  void _processGroupUpdate(Map<String, dynamic> data) {
    try {
      final int status = data['status'] ?? 0;
      if (status == 2 || (data['isFull'] ?? false)) {
        _showSuccessToast('group_lobby.status_success'.tr(), 'group_lobby.msg_group_full'.tr());
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
    _cachedSocketService?.socket?.off(SocketEvents.callEnd);
  }
}