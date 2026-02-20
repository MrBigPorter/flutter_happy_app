part of 'global_handler.dart';

extension GlobalHandlerSocketExtension on _GlobalHandlerState {
  // 【核心修改点 1】：重构 CallKit 监听逻辑，适配新的 onAction 接口
  void _initCallKitListener() {
    // 🟢 核心改动 1：加上第一个参数 'GlobalHandler' 作为唯一身份标识
    CallKitService.instance.onAction('GlobalHandler', (event) async {

      // 🟢 核心改动 2：防丧尸护盾！页面被安卓销毁时直接拦截，防止报 ref disposed 错误
      if (!mounted) {
        debugPrint("🛡️ [TRACE-UI] 检测到页面已销毁，拦截丧尸回调！");
        return;
      }

      final String sessionId = event.data?['id']?.toString() ?? '';

      switch (event.action) {
        case 'answerCall':
          debugPrint("📍 [TRACE-1] CallKit 触发 answerCall! sessionId: $sessionId");

          if (_isAcceptingCall) return;
          _isAcceptingCall = true;

          try {
            Map<String, dynamic> metadata = {};
            if (event.data?['extra'] != null) {
              metadata = (event.data!['extra'] as Map).cast<String, dynamic>();
            }

            final stateMachine = ref.read(callStateMachineProvider.notifier);
            final callState = ref.read(callStateMachineProvider);

            // 🛡️ 核心护盾：只有当状态机里【真的没有 SDP】时，才允许用 metadata 恢复
            // 绝对禁止在 Ringing 状态下覆盖已有的完整 SDP！
            if (callState.remoteSdp == null || callState.remoteSdp!.isEmpty) {

              // 🟢 终极修复：优先从内存保险箱中取 SDP，完美绕过原生层的截断！
              final cachedInvite = CallDispatcher.instance.currentInvite;
              if (cachedInvite != null && cachedInvite.sessionId == sessionId) {
                debugPrint("📍 [TRACE-UI] 从内存保险箱完美恢复信令数据！SDP 完好无损！");
                stateMachine.onIncomingInvite(cachedInvite);
              } else if (metadata.isNotEmpty) {
                debugPrint("📍 [TRACE-UI] 尝试从 CallKit 元数据恢复...");
                stateMachine.onIncomingInvite(CallEvent.fromMap(metadata));
              }

            }

            debugPrint("📍 [TRACE-4] 统一指挥状态机去执行 WebRTC 接听...");
            stateMachine.acceptCall();

            // 执行 UI 跳转逻辑
            final String realTargetId = metadata['senderId']?.toString() ?? callState.targetId ?? "unknown";
            final String realTargetName = metadata['senderName']?.toString() ?? callState.targetName ?? "User";
            final bool isVideoCall = (metadata['mediaType'] != null) ? metadata['mediaType'] == 'video' : callState.isVideoMode;
            final String? realAvatar = metadata['senderAvatar']?.toString();

            // 🟢 终极修复 1：轮询等待 Flutter 引擎和 Navigator 准备就绪 (最长等待 5 秒)
            int retryCount = 0;
            Timer.periodic(const Duration(milliseconds: 500), (timer) {
              retryCount++;
              final navigator = NavHub.key.currentState;

              if (navigator != null) {
                timer.cancel(); // 拿到句柄，立刻停止轮询
                debugPrint("📍 [TRACE-UI] NavHub 存活 (耗时: ${retryCount * 0.5}s)，压入 CallPage...");
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => CallPage(
                      targetId: realTargetId,
                      targetName: realTargetName,
                      isVideo: isVideoCall,
                      targetAvatar: realAvatar,
                    ),
                  ),
                );
              } else if (retryCount >= 10) {
                // 如果 5 秒后还没起来，说明被系统彻底物理死锁了
                timer.cancel();
                debugPrint("❌ [TRACE-ERR] 致命错误：等了 5 秒 NavHub 还是空！");
                // 此时建议给个兜底的 Toast 提示
              }
            });

          } catch (e) {
            debugPrint("📍 [TRACE-ERR] 接听流程崩溃: $e");
          } finally {
            Future.delayed(const Duration(seconds: 3), () => _isAcceptingCall = false);
          }
          break;

      // B. 用户点了系统界面的【挂断/拒绝】
        case 'endCall':
          debugPrint("📍 [TRACE-CallKit] 收到系统挂断指令");
          if (_isDecliningCall) return;
          _isDecliningCall = true;

          final stateMachine = ref.read(callStateMachineProvider.notifier);
          final currentState = ref.read(callStateMachineProvider);

          // 如果状态机正在通话且 Session 一致，执行标准挂断
          if (currentState.status != CallStatus.idle && currentState.sessionId == sessionId) {
            stateMachine.hangUp(emitEvent: true);
          } else {
            // 否则，仅仅是通知服务器本端已拒绝
            if (event.data?['extra'] != null) {
              final metadata = (event.data!['extra'] as Map).cast<String, dynamic>();
              final targetId = metadata['senderId']?.toString();
              if (targetId != null) {
                ref.read(socketServiceProvider).socket?.emit(SocketEvents.callEnd, {
                  'sessionId': sessionId,
                  'targetId': targetId,
                  'reason': 'decline'
                });
              }
            }
            stateMachine.hangUp(emitEvent: false);
          }
          Future.delayed(const Duration(seconds: 3), () => _isDecliningCall = false);
          break;

      // C. 处理其他可能的动作（如静音）
        case 'setMuted':
          ref.read(callStateMachineProvider.notifier).toggleMute();
          break;
      }
    });
  }

  void _subscribeToSocket(SocketService service) {
    _cachedSocketService = service;
    _cancelSocketSubscriptions();
    // 【核心修改点 2】：确保初始化监听
    _initCallKitListener();

    service.socket?.on(SocketEvents.callInvite, (data) async {
      if (!mounted) return;
      if (data is Map) data['type'] = SocketEvents.callInvite;
      await CallDispatcher.instance.dispatch(
        data,
        onNotify: (event) {
          ref.read(callStateMachineProvider.notifier).onIncomingInvite(event);
        },
      );
    });

    service.socket?.on(SocketEvents.callEnd, (data) async {
      if (!mounted) return;
      if (data is Map) data['type'] = SocketEvents.callEnd;
      await CallDispatcher.instance.dispatch(
        data,
        onNotify: (event) {
          ref.read(callStateMachineProvider.notifier).hangUp(emitEvent: false);
        },
      );
    });

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