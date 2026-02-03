part of 'socket_service.dart';

mixin SocketContactMixin on _SocketBase, SocketDispatcherMixin {
  final _contactApplyController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get contactApplyStream => _contactApplyController.stream;

  final _contactAcceptController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get contactAcceptStream => _contactAcceptController.stream;

  @override
  void _onContactApply(dynamic data) {
    if (data != null && !_contactApplyController.isClosed) {
      _contactApplyController.add(Map<String, dynamic>.from(data));
    }
  }

  @override
  void _onContactAccept(dynamic data) {
    if (data != null && !_contactAcceptController.isClosed) {
      _contactAcceptController.add(Map<String, dynamic>.from(data));
      triggerSync(); // ✅ 收到好友同意后，自动触发同步信号刷新联系人列表
    }
  }
}