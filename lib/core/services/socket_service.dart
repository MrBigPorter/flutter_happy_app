import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/constants/socket_events.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../api/env.dart';
import '../api/http_client.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

// 定义 Token 刷新函数的签名
typedef TokenRefreshCallback = Future<String?> Function();
typedef AckResponse = ({bool success, String? message, Map<String, dynamic>? data});

class SocketException implements Exception {
  final String message;
  SocketException(this.message);
  @override
  String toString() => 'SocketException: $message';
}

// ==========================================
// 🧩 Mixin 1: 聊天能力
// ==========================================
mixin SocketChatMixin on _SocketBase {
  final _chatMessageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatMessageStream => _chatMessageController.stream;

  final _conversationListUpdateController = StreamController<SocketMessage>.broadcast();
  Stream<SocketMessage> get conversationListUpdateStream => _conversationListUpdateController.stream;

  //  新增：已读回执流
  final _readStatusController = StreamController<SocketReadEvent>.broadcast();
  Stream<SocketReadEvent> get readStatusStream => _readStatusController.stream;

  // 新增：recall 事件流
  final _recallEventController = StreamController<SocketRecallEvent>.broadcast();
  Stream<SocketRecallEvent> get recallEventStream => _recallEventController.stream;

  // 监听聊天相关事件
  void _setupChatListeners(IO.Socket socket) {
    // 监听聊天消息
    socket.on(SocketEvents.chatMessage, (data) {
      if (data == null) return;

      final mapData = Map<String, dynamic>.from(data);

      // 1. 发给详情页 (详情页自己处理容错)
      if (!_chatMessageController.isClosed) {
        _chatMessageController.add(mapData);
      }

      // 2. 发给列表页 (需要转换模型，容易报错，所以要加 try-catch)
      if(!_conversationListUpdateController.isClosed){
        try {
          final message = SocketMessage.fromJson(mapData);
          _conversationListUpdateController.add(message);
        } catch (e) {
          debugPrint("[Socket] 解析消息失败，跳过列表更新: $e");
          // 这里捕获异常，保证 Socket 连接不会受影响，
          // 仅仅是这条消息在列表里显示不出来而已，不影响大局。
        }
      }
    });

    // 监听已读回执
    socket.on(SocketEvents.conversationRead, (data) {
      if( data == null ) return;
      try{
        final event = SocketReadEvent.fromJson(Map<String, dynamic>.from(data));
        if(!_readStatusController.isClosed){
          _readStatusController.add(event);
        }
      }catch(e){
        debugPrint("[Socket] 解析已读回执失败，跳过: $e");
        return;
      }
    });

    // 监听消息撤回事件
    socket.on(SocketEvents.messageRecall, (data){
      if(data == null) return;
      try{
        final event = SocketRecallEvent.fromJson(Map<String, dynamic>.from(data));
        if(!_recallEventController.isClosed){
          _recallEventController.add(event);
        }
      }catch(e){
        debugPrint("[Socket] 解析消息撤回事件失败，跳过: $e");
        return;
      }
    });

  }

  Future<AckResponse> sendMessage({
    required String conversationId,
    required String content,
    required int type,
    required String tempId,
  }) {
    if (!isConnected) return Future.error(SocketException('Socket disconnected'));
    final completer = Completer<AckResponse>();

    socket!.emitWithAck(SocketEvents.sendMessage, {
      'conversationId': conversationId,
      'content': content,
      'type': type,
      'tempId': tempId,
    }, ack: (response) {
      if (response != null && response['status'] == 'ok') {
        completer.complete((
        success: true,
        message: null,
        data: Map<String, dynamic>.from(response['data'])
        ));
      } else {
        completer.complete((
        success: false,
        message: response is String ? response : 'Send failed',
        data: null
        ));
      }
    });

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => (success: false, message: 'Send timeout', data: null),
    );
  }

  void joinChatRoom(String conversationId) =>
      socket?.emit(SocketEvents.joinChat, {'conversationId': conversationId});

  void leaveChatRoom(String conversationId) =>
      socket?.emit(SocketEvents.leaveChat, {'conversationId': conversationId});
}

// ==========================================
// 🧩 Mixin 2: 通用通知与业务事件 (含 Group Update)
// ==========================================
mixin SocketNotificationMixin on _SocketBase {
  // 全局弹窗通知流
  final _notificationController = StreamController<GlobalNotification>.broadcast();
  Stream<GlobalNotification> get notificationStream => _notificationController.stream;

  // 业务数据流 (统一入口)
  final _businessEventController = StreamController<Map<String, dynamic>>.broadcast();

  //  [修复] 专门暴露给 GroupLobbyPage 使用的流
  Stream<Map<String, dynamic>> get groupUpdateStream => _businessEventController.stream
      .where((e) => e['type'] == 'group_update')
      .map((e) => Map<String, dynamic>.from(e['data']));

  void _setupNotificationListeners(IO.Socket socket) {
    socket.on('server_push', (data) {
      if (data == null) return;
      _handlePush(data);
    });
  }

  void _handlePush(dynamic data) {
    final typeStr = data['type'] ?? 'unknown';
    final payload = data['payload'] ?? {};

    // 调试日志
    // debugPrint('🔔 [Socket] Push: $typeStr');

    switch (typeStr) {
      case 'group_success':
      case 'group_failed':
        _notificationController.add(GlobalNotification(
          isSuccess: typeStr == 'group_success',
          title: payload['title'] ?? (typeStr == 'group_success' ? 'Success' : 'Failed'),
          message: payload['message'] ?? '',
          originalData: payload,
        ));
        break;

      case 'group_update':
      case 'wallet_change':
      // 分发到业务流
        if (!_businessEventController.isClosed) {
          _businessEventController.add({
            'type': typeStr,
            'data': payload,
            'timestamp': DateTime.now().millisecondsSinceEpoch
          });
        }
        break;
    }
  }
}

// ==========================================
// 🧩 Mixin 3: 拼团大厅能力 (Lobby Capability)  [新增]
// ==========================================
mixin SocketLobbyMixin on _SocketBase {
  /// 加入大厅 (订阅实时更新)
  void joinLobby() {
    if (isConnected) {
      socket!.emit(SocketEvents.joinLobby);
      debugPrint('🏟️ [Socket] Joined Lobby');
    }
  }

  /// 离开大厅 (取消订阅)
  void leaveLobby() {
    if (isConnected) {
      socket!.emit(SocketEvents.leaveLobby);
      debugPrint('👋 [Socket] Left Lobby');
    }
  }
}

// ==========================================
// 🧱 基类：连接管理
// ==========================================
abstract class _SocketBase {
  IO.Socket? _socket;
  IO.Socket? get socket => _socket;
  bool get isConnected => _socket != null && _socket!.connected;

  //  [修复] 重连信号流
  final _syncController = StreamController<void>.broadcast();
  Stream<void> get onSyncNeeded => _syncController.stream;

  // 供子类/Mixin 调用
  void triggerSync() {
    if (!_syncController.isClosed) _syncController.add(null);
  }

  void dispose() {
    _syncController.close();
  }
}

// ==========================================
// 🚀 主服务类 (The Service)
// ==========================================
class SocketService extends _SocketBase
    with SocketChatMixin, SocketNotificationMixin, SocketLobbyMixin {

  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  TokenRefreshCallback? onTokenRefreshRequest;
  TokenRefreshCallback? _tokenRefresher;

  // 1. 新增：初始化互斥锁
  bool _isInitializing = false;

  Future<void> init({required String token, TokenRefreshCallback? onTokenRefresh}) async {

    // 2. 新增：第一道防线：如果正在初始化，直接打回！
    if (_isInitializing) {
      debugPrint(
          '⏳ [Socket] Initialization already in progress, skipping duplicate call.');
      return;
    }

    _tokenRefresher = onTokenRefresh ?? onTokenRefreshRequest ?? _defaultTokenRefresher;

    // 3. 新增：第二道防线：加锁
    _isInitializing = true;

   try{
     final validToken = await _ensureValidToken(token);
     if (validToken == null) return;

     // 新增：如果 Token 没变且已连接，直接返回，不折腾
     if(_socket != null && _socket!.connected){
       final currentToken = _socket!.io.options?['query']?['token'];
       if(currentToken == validToken){
         debugPrint('🔒 [Socket] Token 未变，保持现有连接');
         return;
       }
     }

     // 只有 Token 变了，或者断开了，才执行下面的 disconnect 和重连
     disconnect();

     final socketUrl = '${Env.apiBaseEffective}/events';
     debugPrint('🔌 [Socket] Connecting to $socketUrl');

     _socket = IO.io(
       socketUrl,
       IO.OptionBuilder()
           .setTransports(['websocket'])
           .disableAutoConnect()
           .setQuery({'token': validToken})
           .setReconnectionAttempts(5)
           .setReconnectionDelay(2000)
           .setAuth({'token': validToken})
           .build(),
     );

     // 挂载监听器
     _setupCommonListeners();
     _setupChatListeners(_socket!);
     _setupNotificationListeners(_socket!);

     _socket!.connect();
   }catch(e){
      debugPrint('❌ [Socket] Initialization error: $e');
   } finally {
      // 4. 解锁
      _isInitializing = false;
   }
  }

  void _setupCommonListeners() {
    _socket!.onConnect((_) {
      debugPrint('✅ [Socket] Connected: ${_socket!.id}');
      //  连接成功时，触发 Sync 信号
      triggerSync();
    });

    _socket!.onDisconnect((r) => debugPrint('❌ [Socket] Disconnected: $r'));
  }

  Future<String?> _ensureValidToken(String token) async {
    try {
      // 1. 简单判空
      if(token.isEmpty){
        debugPrint("❌ [Socket] Token 为空，取消连接！");
        return null;
      }

      if (JwtDecoder.isExpired(token) ||
          JwtDecoder.getRemainingTime(token).inSeconds < 60) {
        debugPrint("⚠️ [Socket] Token 已过期，尝试刷新...");
        final newToken = await _tokenRefresher?.call();
        if (newToken == null) {
          debugPrint("❌ [Socket] Token 刷新失败，无法建立连接！");
        } else {
          debugPrint("✅ [Socket] Token 刷新成功！");
        }
        return newToken;
      }
      return token;
    } catch (e) {
      //  之前这里可能吞掉了报错
      debugPrint("❌ [Socket] Token 校验异常: $e");
      return null;
    }
  }

  Future<String?> _defaultTokenRefresher() async {
    final success = await Http.tryRefreshToken(Http.rawDio);
    return success ? await Http.getToken() : null;
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }

  @override
  void dispose() {
    disconnect();
    // 单例模式下不要关闭 StreamController，除非你确定要彻底销毁 App
    // super.dispose();
  }
}

class GlobalNotification {
  final bool isSuccess;
  final String title;
  final String message;
  final dynamic originalData;

  GlobalNotification({
    required this.isSuccess,
    required this.title,
    required this.message,
    this.originalData,
  });
}