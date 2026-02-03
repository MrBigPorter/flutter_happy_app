part of 'socket_service.dart';

mixin SocketNotificationMixin on _SocketBase, SocketDispatcherMixin {
  final _notificationController = StreamController<GlobalNotification>.broadcast();
  Stream<GlobalNotification> get notificationStream => _notificationController.stream;

  final _businessEventController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get groupUpdateStream => _businessEventController.stream
      .where((e) => e['type'] == SocketEvents.groupUpdate)
      .map((e) => Map<String, dynamic>.from(e['data']));

  @override
  void _onGroupNotification(String type, dynamic data) {
    final payload = data ?? {};
    _notificationController.add(GlobalNotification(
      isSuccess: type == SocketEvents.groupSuccess,
      title: payload['title'] ?? (type == SocketEvents.groupSuccess ? 'Success' : 'Failed'),
      message: payload['message'] ?? '',
      originalData: payload,
    ));
  }

  @override
  void _onBusinessEvent(String type, dynamic data) {
    if (!_businessEventController.isClosed) {
      _businessEventController.add({
        'type': type,
        'data': data ?? {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
}