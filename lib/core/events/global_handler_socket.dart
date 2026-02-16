part of 'global_handler.dart';

//  修改标注 3: 专注于“信号接收与路由”
extension GlobalHandlerSocketExtension on _GlobalHandlerState {
  void _subscribeToSocket(SocketService service) {
    _cancelSocketSubscriptions();

    service.socket?.on(SocketEvents.callInvite, (data) {
      if (!mounted) return;
      // 获取当前状态
      final currentStatus = ref.read(callControllerProvider).status;
      // 如果已经在通话或拨号中，直接无视或自动拒绝
      if (currentStatus != CallStatus.idle && currentStatus != CallStatus.ended) {
        debugPrint(' [GlobalHandler] Received call invite but already in call: $currentStatus');
        // 可选：发送一个 busy 信号给对方
        return;
      }

      debugPrint(' [GlobalHandler] Received call invite: $data');
      // 1. 获取 Controller 并初始化被叫状态
      // 这一步会将状态改为 ringing，并保存 sessionId
      ref.read(callControllerProvider.notifier).incomingCall(data);

      // 2. 导航到通话界面
      // 注意：这里使用 context 需要确保 GlobalHandler 在 MaterialApp 下面
      NavHub.key.currentState?.push(
        MaterialPageRoute(
          builder: (_) => CallPage(
            targetId: data['senderId'], // 对方 ID
            targetName: "Incoming Call...", // 暂时显示，可以在 CallPage 里再去查用户信息
            isVideo: data['mediaType'] == 'video', // 判断是视频还是语音
          ),
        ),
      );
    });

    debugPrint(' [GlobalHandler] Socket Subscriptions Active');

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

    // ========================================================
    // [新增] 5. 群组事件监听 (只负责弹窗，不负责业务逻辑)
    // ========================================================
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

    // 3. 通用业务通知
    _notificationSub = service.notificationStream.listen((notification) {
      if (!mounted) return;
      if (notification.isSuccess) {
        _showSuccessToast(notification.title, notification.message);
      } else {
        _showErrorToast(notification.title, notification.message);
      }
    });

    // 4. 拼团/更新通知
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

    //  [新增] 记得销毁监听，防止内存泄漏
    // 这里的 service 需要通过 ref 获取，因为这个方法里没有传 service
    // 或者你可以把 socket 存个引用，或者直接通过 ref 读取
    ref.read(socketServiceProvider).socket?.off(SocketEvents.callInvite);
  }
}
