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
typedef AckResponse = ({
  bool success,
  String? message,
  Map<String, dynamic>? data,
});

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

  GlobalNotification({
    required this.isSuccess,
    required this.title,
    required this.message,
    this.originalData,
  });
}

abstract class _SocketBase {
  IO.Socket? _socket;

  IO.Socket? get socket => _socket;

  bool get isConnected => _socket != null && _socket!.connected;

  final _syncController = StreamController<void>.broadcast();
  // Broadcast a signal every time the underlying IO.Socket successfully connects
  // (including auto-reconnects and fresh connections after re-login).
  final _connectController = StreamController<void>.broadcast();

  Stream<void> get onSyncNeeded => _syncController.stream;

  /// Fires whenever the socket transitions to the "connected" state.
  /// Subscribers (e.g. GlobalHandler) should re-register direct socket listeners
  /// each time this fires, because a new IO.Socket instance may have been created.
  Stream<void> get onConnected => _connectController.stream;

  void triggerSync() {
    if (!_syncController.isClosed) _syncController.add(null);
  }

  void dispose() {
    _syncController.close();
    _connectController.close();
  }
}

mixin SocketDispatcherMixin on _SocketBase {
  void _handleDispatch(dynamic payload) {
    if (payload == null || payload is! Map) return;

    final String type = payload['type']?.toString() ?? 'unknown';
    final dynamic data = payload['data'];
    if (kDebugMode) {
      debugPrint(" [SocketService] 底层分发中心收到信号: type=$type, data=$data");
    }

    switch (type) {
      // base events
      case SocketEvents.chatMessage:
        _onChatMessage(data);
        break;
      case SocketEvents.conversationRead:
        _onReadReceipt(data);
        break;
      case SocketEvents.messageRecall:
        _onMessageRecall(data);
        break;
      case SocketEvents.conversationUpdated:
        _onConversationUpdated(data);
        break;
      // contact events
      case SocketEvents.contactApply:
        _onContactApply(data);
        break;
      case SocketEvents.contactAccept:
        _onContactAccept(data);
        break;

      // group events are treated as notifications or business events, not chat events
      case SocketEvents.memberKicked:
      case SocketEvents.memberMuted:
      case SocketEvents.ownerTransferred:
      case SocketEvents.memberRoleUpdated:
      case SocketEvents.memberJoined:
      case SocketEvents.conversationAdded:
      case SocketEvents.memberLeft:
      case SocketEvents.groupDisbanded:
      case SocketEvents.groupInfoUpdated:
      case SocketEvents.groupApplyNew:
      case SocketEvents.groupApplyResult:
      case SocketEvents.groupRequestHandled:
        _onGroupEvent(type, data);
        break;

      // business/system notifications
      case SocketEvents.groupSuccess:
      case SocketEvents.groupFailed:
        _onGroupNotification(type, data);
        break;
      case SocketEvents.groupUpdate:
      case SocketEvents.walletChange:
      case SocketEvents.luckyDrawTicketIssued:
        _onBusinessEvent(type, data);
        break;

      // AI customer service events
      case SocketEvents.aiToken:
      case SocketEvents.aiStep:
      case SocketEvents.aiDone:
      case SocketEvents.aiError:
      case SocketEvents.aiTransfer:
        _onAiEvent(type, data);
        break;

      default:
        debugPrint(" [SocketService] Unhandled event type: $type, data: $data");

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

  void _onAiEvent(String type, dynamic data);

  void _onContactAccept(dynamic data);

  void _onGroupEvent(String type, dynamic data);
}

class SocketService extends _SocketBase
    with
        SocketDispatcherMixin,
        SocketChatMixin,
        SocketContactMixin,
        SocketNotificationMixin,
        SocketLobbyMixin {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  SocketService._internal();

  TokenRefreshCallback? onTokenRefreshRequest;
  TokenRefreshCallback? _tokenRefresher;
  bool _isInitializing = false;

  //  新增：自己维护当前已连接的 Token 账本
  String? _currentToken;

  Future<void> init({
    required String token,
    TokenRefreshCallback? onTokenRefresh,
  }) async {
    debugPrint('🔌 [SocketService] init() called with token: ${token.substring(0, 10)}...');
    
    // 检查是否已经在初始化中
    if (_isInitializing) {
      debugPrint('🔌 [SocketService] Already initializing, skipping duplicate call');
      return;
    }
    
    _tokenRefresher =
        onTokenRefresh ?? onTokenRefreshRequest ?? _defaultTokenRefresher;
    _isInitializing = true;

    try {
      debugPrint('🔌 [SocketService] Validating token...');
      final validToken = await _ensureValidToken(token);
      if (validToken == null) {
        debugPrint('🔌 [SocketService] Token validation failed, aborting init');
        _isInitializing = false;
        return;
      }
      debugPrint('🔌 [SocketService] Token validated: ${validToken.substring(0, 10)}...');

      // 检查是否已经使用相同的Token连接
      if (_socket != null && _socket!.connected && _currentToken == validToken) {
        debugPrint("🔌 [SocketService] Already connected with same token, skipping");
        _isInitializing = false;
        return;
      }

      // 检查是否有旧的连接需要断开
      if (_socket != null) {
        debugPrint('🔌 [SocketService] Disconnecting previous socket...');
        try {
          _socket!.disconnect();
          _socket!.dispose();
        } catch (e) {
          debugPrint('🔌 [SocketService] Error disconnecting old socket: $e');
        }
        _socket = null;
      }

      // 更新当前Token
      _currentToken = validToken;

      final socketUrl = '${AppConfig.apiBaseUrl}/events';
      debugPrint('🔌 [SocketService] Connecting to: $socketUrl');
      
      // 创建新的Socket连接
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling']) // 添加polling作为备选
            .disableAutoConnect()
            .setQuery(<String, dynamic>{'token': validToken.toString()})
            .setReconnectionAttempts(10) // 增加重连尝试次数
            .setReconnectionDelay(1000) // 重连延迟1秒
            .setReconnectionDelayMax(5000) // 最大重连延迟5秒
            .setTimeout(20000) // 连接超时20秒
            .setAuth(<String, dynamic>{'token': validToken})
            .build(),
      );

      // 设置事件监听器
      _socket!.onConnect((_) {
        debugPrint('✅ [SocketService] Connected successfully to server');
        // Fix 1: Release the init lock so future init() calls (re-login / token
        // refresh) are not blocked by the guard at the top of init().
        _isInitializing = false;
        // Fix 2: Broadcast the connected event so GlobalHandler can (re-)register
        // direct socket listeners (e.g. call_invite) on the live socket instance.
        if (!_connectController.isClosed) _connectController.add(null);
        triggerSync();
      });
      
      _socket!.onDisconnect((reason) {
        debugPrint('❌ [SocketService] Disconnected from server: $reason');
        _currentToken = null; // 断开时清除Token
      });
      
      _socket!.onConnectError((data) {
        // Fix 1: Also release the lock on connection failure so the next
        // init() call (e.g. after a token refresh) is not silently skipped.
        _isInitializing = false;
        debugPrint('⚠️ [SocketService] Connection error: $data');
      });
      
      _socket!.onError((data) {
        debugPrint('⚠️ [SocketService] Socket error: $data');
      });
      
      _socket!.onReconnect((attempt) {
        debugPrint('🔄 [SocketService] Reconnecting (attempt $attempt)...');
      });
      
      _socket!.onReconnectAttempt((attempt) {
        debugPrint('🔄 [SocketService] Reconnection attempt $attempt');
      });
      
      _socket!.onReconnectError((error) {
        debugPrint('❌ [SocketService] Reconnection error: $error');
      });
      
      _socket!.onReconnectFailed((_) {
        debugPrint('❌ [SocketService] Reconnection failed after all attempts');
      });
      
      _socket!.on(SocketEvents.dispatch, (data) {
        debugPrint('📨 [SocketService] Received dispatch event');
        _handleDispatch(data);
      });
      
      debugPrint('🔌 [SocketService] Starting connection...');
      _socket!.connect();
      
      // 添加连接超时检查
      Future.delayed(const Duration(seconds: 10), () {
        if (_socket != null && !_socket!.connected && !_socket!.disconnected) {
          debugPrint('⏰ [SocketService] Connection timeout after 10 seconds');
          // 可以在这里触发重连或显示错误
        }
      });
      
    } catch (e, stackTrace) {
      debugPrint('❌ [SocketService] init() failed: $e');
      debugPrint('❌ [SocketService] Stack trace: $stackTrace');
      // 确保在异常情况下也重置初始化状态
      _isInitializing = false;
      rethrow;
    } finally {
      // 注意：这里不能重置_isInitializing，因为连接过程是异步的
      // 我们会在连接成功或失败的事件中处理状态重置
      debugPrint('🔌 [SocketService] init() setup completed');
    }
  }

  Future<String?> _ensureValidToken(String token) async {
    debugPrint('🔑 [SocketService] Validating token: ${token.substring(0, 10)}...');
    if (token.isEmpty) {
      debugPrint('🔑 [SocketService] Token is empty');
      return null;
    }

    // 检查Token格式和过期状态
    bool isInvalid = false;
    String? validationError;
    
    try {
      // 首先检查Token格式（基本的JWT格式检查）
      final parts = token.split('.');
      if (parts.length != 3) {
        validationError = 'Invalid JWT format';
        isInvalid = true;
      } else if (JwtDecoder.isExpired(token)) {
        validationError = 'Token expired';
        isInvalid = true;
      }
    } catch (e) {
      debugPrint("🔑 [SocketService] Token parsing error: $e");
      validationError = 'Token parsing error: $e';
      isInvalid = true;
    }

    if (isInvalid) {
      debugPrint("🔑 [SocketService] Token invalid ($validationError), attempting refresh...");
      try {
        final refreshedToken = await _tokenRefresher?.call();
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          debugPrint("🔑 [SocketService] Token refresh successful: ${refreshedToken.substring(0, 10)}...");
          return refreshedToken;
        } else {
          debugPrint("🔑 [SocketService] Token refresh failed or returned empty token");
          return null;
        }
      } catch (e, stackTrace) {
        debugPrint("🔑 [SocketService] Token refresh error: $e");
        debugPrint("🔑 [SocketService] Stack trace: $stackTrace");
        return null;
      }
    }

    debugPrint('🔑 [SocketService] Token is valid');
    return token;
  }

  Future<String?> _defaultTokenRefresher() async {
    debugPrint('🔄 [SocketService] Default token refresher called');
    try {
      final success = await Http.tryRefreshToken(Http.rawDio);
      if (success) {
        final newToken = await Http.getToken();
        debugPrint('🔄 [SocketService] Token refresh successful: ${newToken?.substring(0, 10)}...');
        return newToken;
      } else {
        debugPrint('🔄 [SocketService] Token refresh failed');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('🔄 [SocketService] Token refresh error: $e');
      debugPrint('🔄 [SocketService] Stack trace: $stackTrace');
      return null;
    }
  }

  void disconnect() {
    _socket?.dispose();
    _currentToken = null; //  记得彻底断开时撕毁账本
    _socket = null;
  }
}
