import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/config/app_config.dart';
import 'package:flutter_app/core/constants/socket_events.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

import '../../api/http_client.dart';

//  标注：使用 part 引用拆分出的业务模块
part 'chat_extension.dart';
part 'contact_extension.dart';
part 'notification_extension.dart';
part 'lobby_extension.dart';

typedef TokenRefreshCallback = Future<String?> Function();
typedef AckResponse = ({bool success, String? message, Map<String, dynamic>? data});

class SocketException implements Exception {
  final String message;
  SocketException(this.message);
  @override
  String toString() => 'SocketException: $message';
}

class GlobalNotification {
  final bool isSuccess;
  final String title;
  final String message;
  final dynamic originalData;

  GlobalNotification({required this.isSuccess, required this.title, required this.message, this.originalData});
}

abstract class _SocketBase {
  IO.Socket? _socket;
  IO.Socket? get socket => _socket;
  bool get isConnected => _socket != null && _socket!.connected;

  final _syncController = StreamController<void>.broadcast();
  Stream<void> get onSyncNeeded => _syncController.stream;

  void triggerSync() {
    if (!_syncController.isClosed) _syncController.add(null);
  }

  void dispose() {
    _syncController.close();
  }
}

mixin SocketDispatcherMixin on _SocketBase {
  void _handleDispatch(dynamic payload) {
    if (payload == null || payload is! Map) return;

    final String type = payload['type']?.toString() ?? 'unknown';
    final dynamic data = payload['data'];
    if(kDebugMode){
      debugPrint(" [SocketService] 分发中心收到信号: type=$type, data=$data");
    }

    switch (type) {
      // base events
      case SocketEvents.chatMessage: _onChatMessage(data); break;
      case SocketEvents.conversationRead: _onReadReceipt(data); break;
      case SocketEvents.messageRecall: _onMessageRecall(data); break;
      case SocketEvents.conversationUpdated: _onConversationUpdated(data); break;
      // contact events
      case SocketEvents.contactApply: _onContactApply(data); break;
      case SocketEvents.contactAccept: _onContactAccept(data); break;

      // group events are treated as notifications or business events, not chat events
      case SocketEvents.memberKicked:
      case SocketEvents.memberMuted:
      case SocketEvents.ownerTransferred:
      case SocketEvents.memberRoleUpdated:
      case SocketEvents.memberJoined:
      case SocketEvents.memberLeft:
      case SocketEvents.groupDisbanded:
      case SocketEvents.groupInfoUpdated:
      _onGroupEvent(type, data);
      break;

      // business/system notifications
      case SocketEvents.groupSuccess:
      case SocketEvents.groupFailed: _onGroupNotification(type, data); break;
      case SocketEvents.groupUpdate:
      case SocketEvents.walletChange: _onBusinessEvent(type, data); break;
      default: debugPrint(" [Socket] Unknown type: $type");
    }
  }

  // 抽象方法由各 Part Mixin 实现
  void _onChatMessage(dynamic data);
  void _onReadReceipt(dynamic data);
  void _onMessageRecall(dynamic data);
  void _onConversationUpdated(dynamic data);
  void _onGroupNotification(String type, dynamic data);
  void _onBusinessEvent(String type, dynamic data);
  void _onContactApply(dynamic data);
  void _onContactAccept(dynamic data);
  void _onGroupEvent(String type, dynamic data);
}

class SocketService extends _SocketBase
    with SocketDispatcherMixin, SocketChatMixin, SocketContactMixin, SocketNotificationMixin, SocketLobbyMixin {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  TokenRefreshCallback? onTokenRefreshRequest;
  TokenRefreshCallback? _tokenRefresher;
  bool _isInitializing = false;

  Future<void> init({required String token, TokenRefreshCallback? onTokenRefresh}) async {
    if (_isInitializing) return;
    _tokenRefresher = onTokenRefresh ?? onTokenRefreshRequest ?? _defaultTokenRefresher;
    _isInitializing = true;

    try {
      final validToken = await _ensureValidToken(token);
      if (validToken == null) return;

      if (_socket != null && _socket!.connected) {
        if (_socket!.io.options?['query']?['token'] == validToken) return;
      }

      disconnect();
      _socket = IO.io('${AppConfig.apiBaseUrl}/events', IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
      // 修复：强制 Map 类型并确保值被正确处理
          .setQuery(<String, dynamic>{'token': validToken.toString()})
          .setReconnectionAttempts(5)
          .setAuth(<String, dynamic>{'token': validToken})
          .build());

      _socket!.onConnect((_) { debugPrint(' [Socket] Connected'); triggerSync(); });
      _socket!.onDisconnect((r) => debugPrint(' [Socket] Disconnected: $r'));
      _socket!.on(SocketEvents.dispatch, (data) => _handleDispatch(data));
      _socket!.connect();
    } finally { _isInitializing = false; }
  }

  Future<String?> _ensureValidToken(String token) async {
    if (token.isEmpty) return null;

    //  核心修改：把 JwtDecoder 包裹在 try-catch 中
    // 无论是格式错、类型错、还是过期，统统视为“Token不可用”
    bool isInvalid = false;
    try {
      if (JwtDecoder.isExpired(token)) {
        isInvalid = true;
      }
    } catch (e) {
      debugPrint("[Socket] Token 解析异常 (可能是旧缓存格式错误): $e");
      // 只要解析报错，就认为它是坏的，必须刷新
      isInvalid = true;
    }

    if (isInvalid) {
      debugPrint(" [Socket] Token 无效或过期，尝试刷新...");
      return await _tokenRefresher?.call();
    }

    return token;
  }

  Future<String?> _defaultTokenRefresher() async {
    final success = await Http.tryRefreshToken(Http.rawDio);
    return success ? await Http.getToken() : null;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}