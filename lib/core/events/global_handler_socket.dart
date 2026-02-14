part of 'global_handler.dart';

//  修改标注 3: 专注于“信号接收与路由”
extension GlobalHandlerSocketExtension on _GlobalHandlerState {

  void _subscribeToSocket(SocketService service) {
    _cancelSocketSubscriptions();

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
        _showSuccessToast('group_lobby.status_success'.tr(), 'group_lobby.msg_group_full'.tr());
      }
    } catch (_) {}
  }

  void _cancelSocketSubscriptions() {
    _notificationSub?.cancel();
    _updateSub?.cancel();
    _contactApplySub?.cancel();
    _contactAcceptSub?.cancel();
  }
}