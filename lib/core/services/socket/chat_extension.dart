part of 'socket_service.dart';



mixin SocketChatMixin on _SocketBase, SocketDispatcherMixin {
  final _chatMessageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatMessageStream => _chatMessageController.stream;

  final _conversationListUpdateController = StreamController<SocketMessage>.broadcast();
  Stream<SocketMessage> get conversationListUpdateStream => _conversationListUpdateController.stream;

  final _readStatusController = StreamController<SocketReadEvent>.broadcast();
  Stream<SocketReadEvent> get readStatusStream => _readStatusController.stream;

  final _recallEventController = StreamController<SocketRecallEvent>.broadcast();
  Stream<SocketRecallEvent> get recallEventStream => _recallEventController.stream;

  final _conversationUpdateStream = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get conversationUpdateStream => _conversationUpdateStream.stream;

  // group events are handled in SocketNotificationMixin as business events, so no need to handle them here\
  final _groupEventController = StreamController<SocketGroupEvent>.broadcast();
  Stream<SocketGroupEvent> get groupEventStream => _groupEventController.stream;

  @override
  void _onChatMessage(dynamic data) {
    if (data == null) return;
    final mapData = Map<String, dynamic>.from(data);
    if (!_chatMessageController.isClosed) _chatMessageController.add(mapData);
    if (!_conversationListUpdateController.isClosed) {
      try { _conversationListUpdateController.add(SocketMessage.fromJson(mapData)); } catch (e) { debugPrint("Parse error: $e"); }
    }
  }

  @override
  void _onReadReceipt(dynamic data) {
    try {
      final event = SocketReadEvent.fromJson(Map<String, dynamic>.from(data));
      if (!_readStatusController.isClosed) _readStatusController.add(event);
    } catch (_) {}
  }

  @override
  void _onMessageRecall(dynamic data) {
    try {
      final event = SocketRecallEvent.fromJson(Map<String, dynamic>.from(data));
      if (!_recallEventController.isClosed) _recallEventController.add(event);
    } catch (_) {}
  }

  @override
  void _onConversationUpdated(dynamic data) {
    if (data != null && !_conversationUpdateStream.isClosed) {
      _conversationUpdateStream.add(Map<String, dynamic>.from(data));
    }
  }

  @override
  void _onGroupEvent(String type, dynamic data) {
    if(data != null && !_groupEventController.isClosed){
      try{
        final mapData = Map<String, dynamic>.from(data);
        _groupEventController.add(SocketGroupEvent.fromJson(type, mapData));
        debugPrint("Received group event: type=$type, data=$mapData");
      }catch(e){
        debugPrint("Failed to parse group event: $e");
      }
    }
  }

  Future<AckResponse> sendMessage({required String conversationId, required String content, required int type, required String tempId}) {
    if (!isConnected) return Future.error(SocketException('Disconnected'));
    final completer = Completer<AckResponse>();
    socket!.emitWithAck(SocketEvents.sendMessage, {'conversationId': conversationId, 'content': content, 'type': type, 'tempId': tempId}, ack: (res) {
      if (res != null && res['status'] == 'ok') {
        completer.complete((success: true, message: null, data: Map<String, dynamic>.from(res['data'])));
      } else {
        completer.complete((success: false, message: 'Failed', data: null));
      }
    });
    return completer.future.timeout(const Duration(seconds: 10), onTimeout: () => (success: false, message: 'Timeout', data: null));
  }

  void joinChatRoom(String id) => socket?.emit(SocketEvents.joinChat, {'conversationId': id});
  void leaveChatRoom(String id) => socket?.emit(SocketEvents.leaveChat, {'conversationId': id});
}