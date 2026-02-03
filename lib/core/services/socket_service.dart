import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/config/app_config.dart';
import 'package:flutter_app/core/constants/socket_events.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../api/http_client.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

// Signature definition for Token Refresh
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

// ==========================================
//  Base: Connection Management
// ==========================================
abstract class _SocketBase {
  IO.Socket? _socket;

  IO.Socket? get socket => _socket;

  bool get isConnected => _socket != null && _socket!.connected;

  // Reconnection signal stream
  final _syncController = StreamController<void>.broadcast();

  Stream<void> get onSyncNeeded => _syncController.stream;

  void triggerSync() {
    if (!_syncController.isClosed) _syncController.add(null);
  }

  void dispose() {
    _syncController.close();
  }
}

// ==========================================
// ⚙ Mixin: Central Dispatcher [NEW]
// ==========================================
mixin SocketDispatcherMixin on _SocketBase {
  /// Handles the unified 'dispatch' event
  void _handleDispatch(dynamic payload) {
    if (payload == null || payload is! Map) return;

    // Expected format: { "type": "chat_message", "data": {...} }
    final String type = payload['type']?.toString() ?? 'unknown';
    final dynamic data = payload['data'];

    // debugPrint(" [Socket Dispatch] Type: $type");

    switch (type) {
      // --- Chat ---
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
      case SocketEvents.contactApply:
        _onContactApply(data);
        // Handle contact apply if needed
        break;
      case SocketEvents.contactAccept:
        _onContactAccept(data);
        // Handle contact accept if needed
        break;

      // --- Notifications ---
      case SocketEvents.groupSuccess:
      case SocketEvents.groupFailed:
        _onGroupNotification(type, data);
        break;
      case SocketEvents.groupUpdate:
      case SocketEvents.walletChange:
        _onBusinessEvent(type, data);
        break;

      // --- System ---
      case SocketEvents.forceLogout:
        debugPrint(" [Socket] Force logout received!");
        break;
      case SocketEvents.error:
        debugPrint(" [Socket] Server error: $data");
        break;

      default:
        debugPrint("️ [Socket] Unknown event type: $type");
    }
  }

  // Abstract methods to be implemented by specific Mixins
  void _onChatMessage(dynamic data);

  void _onReadReceipt(dynamic data);

  void _onMessageRecall(dynamic data);

  void _onConversationUpdated(dynamic data);

  void _onGroupNotification(String type, dynamic data);

  void _onBusinessEvent(String type, dynamic data);

  // New Abstract methods
  void _onContactApply(dynamic data);

  void _onContactAccept(dynamic data);
}

// ==========================================
//  Mixin 1: Chat Capability
// ==========================================
mixin SocketChatMixin on _SocketBase, SocketDispatcherMixin {
  // chat message stream
  final _chatMessageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get chatMessageStream =>
      _chatMessageController.stream;

  // conversation list update stream
  final _conversationListUpdateController =
      StreamController<SocketMessage>.broadcast();

  Stream<SocketMessage> get conversationListUpdateStream =>
      _conversationListUpdateController.stream;

  // read status stream
  final _readStatusController = StreamController<SocketReadEvent>.broadcast();

  Stream<SocketReadEvent> get readStatusStream => _readStatusController.stream;

  // recall event stream
  final _recallEventController =
      StreamController<SocketRecallEvent>.broadcast();

  Stream<SocketRecallEvent> get recallEventStream =>
      _recallEventController.stream;

  // conversation update stream (avatar/info changes)
  final _conversationUpdateStream =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get conversationUpdateStream =>
      _conversationUpdateStream.stream;

  // --- Implementation of Dispatcher Methods ---

  @override
  void _onChatMessage(dynamic data) {
    if (data == null) return;
    final mapData = Map<String, dynamic>.from(data);

    // 1. Send to Detail Page
    if (!_chatMessageController.isClosed) {
      _chatMessageController.add(mapData);
    }

    // 2. Send to List Page
    if (!_conversationListUpdateController.isClosed) {
      try {
        final message = SocketMessage.fromJson(mapData);
        _conversationListUpdateController.add(message);
      } catch (e) {
        debugPrint("[Socket] Failed to parse message for list update: $e");
      }
    }
  }

  @override
  void _onReadReceipt(dynamic data) {
    if (data == null) return;
    try {
      final event = SocketReadEvent.fromJson(Map<String, dynamic>.from(data));
      if (!_readStatusController.isClosed) {
        _readStatusController.add(event);
      }
    } catch (e) {
      debugPrint("[Socket] Failed to parse read receipt: $e");
    }
  }

  @override
  void _onMessageRecall(dynamic data) {
    if (data == null) return;
    try {
      final event = SocketRecallEvent.fromJson(Map<String, dynamic>.from(data));
      if (!_recallEventController.isClosed) {
        _recallEventController.add(event);
      }
    } catch (e) {
      debugPrint("[Socket] Failed to parse recall event: $e");
    }
  }

  @override
  void _onConversationUpdated(dynamic data) {
    if (data == null) return;
    debugPrint(" [Socket] Conversation updated (avatar/info): $data");
    if (!_conversationUpdateStream.isClosed) {
      _conversationUpdateStream.add(Map<String, dynamic>.from(data));
    }
  }

  // --- Emitting Methods ---

  Future<AckResponse> sendMessage({
    required String conversationId,
    required String content,
    required int type,
    required String tempId,
  }) {
    if (!isConnected)
      return Future.error(SocketException('Socket disconnected'));
    final completer = Completer<AckResponse>();

    socket!.emitWithAck(
      SocketEvents.sendMessage,
      {
        'conversationId': conversationId,
        'content': content,
        'type': type,
        'tempId': tempId,
      },
      ack: (response) {
        if (response != null && response['status'] == 'ok') {
          completer.complete((
            success: true,
            message: null,
            data: Map<String, dynamic>.from(response['data']),
          ));
        } else {
          completer.complete((
            success: false,
            message: response is String ? response : 'Send failed',
            data: null,
          ));
        }
      },
    );

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
//  Mixin 1.1: Contact Events
// ==========================================
mixin SocketContactMixin on _SocketBase, SocketDispatcherMixin {
  final _contactApplyController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get contactApplyStream =>
      _contactApplyController.stream;

  final _contactAcceptController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get contactAcceptStream =>
      _contactAcceptController.stream;

  @override
  void _onContactApply(dynamic data) {
    if (data == null) return;
    if (!_contactApplyController.isClosed) {
      _contactApplyController.add(Map<String, dynamic>.from(data));
    }
  }

  @override
  void _onContactAccept(dynamic data) {
    if (data == null) return;
    if (!_contactAcceptController.isClosed) {
      _contactAcceptController.add(Map<String, dynamic>.from(data));
    }
    // Logic hint: You might want to trigger a sync of the contact list here
    triggerSync();
  }
}
// ==========================================
//  Mixin 2: Notifications & Business Events
// ==========================================
mixin SocketNotificationMixin on _SocketBase, SocketDispatcherMixin {
  final _notificationController =
      StreamController<GlobalNotification>.broadcast();

  Stream<GlobalNotification> get notificationStream =>
      _notificationController.stream;

  final _businessEventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get groupUpdateStream => _businessEventController
      .stream
      .where((e) => e['type'] == SocketEvents.groupUpdate)
      .map((e) => Map<String, dynamic>.from(e['data']));

  // --- Implementation of Dispatcher Methods ---

  @override
  void _onGroupNotification(String type, dynamic data) {
    final payload = data ?? {};
    _notificationController.add(
      GlobalNotification(
        isSuccess: type == SocketEvents.groupSuccess,
        title:
            payload['title'] ??
            (type == SocketEvents.groupSuccess ? 'Success' : 'Failed'),
        message: payload['message'] ?? '',
        originalData: payload,
      ),
    );
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

// ==========================================
//  Mixin 3: Lobby Capability
// ==========================================
mixin SocketLobbyMixin on _SocketBase {
  void joinLobby() {
    if (isConnected) {
      socket!.emit(SocketEvents.joinLobby);
      debugPrint(' [Socket] Joined Lobby');
    }
  }

  void leaveLobby() {
    if (isConnected) {
      socket!.emit(SocketEvents.leaveLobby);
      debugPrint(' [Socket] Left Lobby');
    }
  }
}

// ==========================================
//  Main Service Class
// ==========================================
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

  Future<void> init({
    required String token,
    TokenRefreshCallback? onTokenRefresh,
  }) async {
    if (_isInitializing) {
      debugPrint(' [Socket] Init already in progress.');
      return;
    }

    _tokenRefresher =
        onTokenRefresh ?? onTokenRefreshRequest ?? _defaultTokenRefresher;
    _isInitializing = true;

    try {
      final validToken = await _ensureValidToken(token);
      if (validToken == null) return;

      if (_socket != null && _socket!.connected) {
        final currentToken = _socket!.io.options?['query']?['token'];
        if (currentToken == validToken) {
          debugPrint('🔒 [Socket] Token unchanged, skipping reconnect.');
          return;
        }
      }

      disconnect();

      final socketUrl = '${AppConfig.apiBaseUrl}/events';
      debugPrint(' [Socket] Connecting to $socketUrl');

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

      _setupListeners();

      _socket!.connect();
    } catch (e) {
      debugPrint(' [Socket] Init error: $e');
    } finally {
      _isInitializing = false;
    }
  }

  void _setupListeners() {
    // 1. Connection Status
    _socket!.onConnect((_) {
      debugPrint(' [Socket] Connected: ${_socket!.id}');
      triggerSync();
    });

    _socket!.onDisconnect((r) => debugPrint(' [Socket] Disconnected: $r'));

    // 2.  Unified Event Listener
    // The server emits 'dispatch', containing { type: "...", data: ... }
    _socket!.on(SocketEvents.dispatch, (data) {
      _handleDispatch(data);
    });
  }

  Future<String?> _ensureValidToken(String token) async {
    try {
      if (token.isEmpty) return null;

      if (JwtDecoder.isExpired(token) ||
          JwtDecoder.getRemainingTime(token).inSeconds < 60) {
        debugPrint(" [Socket] Token expired, refreshing...");
        final newToken = await _tokenRefresher?.call();
        return newToken;
      }
      return token;
    } catch (e) {
      debugPrint(" [Socket] Token check error: $e");
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
    super.dispose();
  }
}
