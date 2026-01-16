import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../api/env.dart';
import '../api/http_client.dart';

// ==========================================
// 1. 枚举与模型定义
// ==========================================

enum PushEventType {
  groupUpdate('group_update'),
  groupSuccess('group_success'),
  groupFailed('group_failed'),
  walletChange('wallet_change'),
  unknown('unknown');

  final String value;
  const PushEventType(this.value);

  static PushEventType fromValue(String value) {
    return PushEventType.values.firstWhere(
          (e) => e.value == value,
      orElse: () => PushEventType.unknown,
    );
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

// ==========================================
// 2. Socket 服务主体
// ==========================================

class SocketService {
  // 单例模式
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  IO.Socket? get socket => _socket;

  // 定义回调：当 Token 过期时，向外部请求新 Token
  // 返回值: Future<String?>，如果刷新成功返回新 Token，失败返回 null
  Future<String?> Function()? onTokenRefreshRequest;

  // ----------------------------------------------------------------
  // 📡 Streams (全部为 final，永不关闭，解决 Bad state 问题)
  // ----------------------------------------------------------------

  // 1. 连接重连信号
  final _syncController = StreamController<void>.broadcast();
  Stream<void> get onSyncNeeded => _syncController.stream;

  // 2. 大厅列表更新流
  final _groupUpdateController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get groupUpdateStream => _groupUpdateController.stream;

  // 3. 全局弹窗通知流
  final _notificationController = StreamController<GlobalNotification>.broadcast();
  Stream<GlobalNotification> get notificationStream => _notificationController.stream;

  // 4. 钱包刷新信号
  final _walletRefreshController = StreamController<void>.broadcast();
  Stream<void> get onWalletRefreshNeeded => _walletRefreshController.stream;

  // ----------------------------------------------------------------
  // 🔌 初始化与连接
  // ----------------------------------------------------------------

  void init({required String token}) async{
    // 🛑 1. 主动安检：检查 Token 是否过期
    // 如果 Token 已过期，或者剩余有效期不足 60 秒

    // 🚑🚑🚑【急救包】核心修复：防止 Auth 初始化太早导致回调为 null
    if (onTokenRefreshRequest == null) {
      debugPrint("⚠️ [Socket] 回调未绑定(Auth启动过早)，正在自动绑定 Http 刷新逻辑...");

      onTokenRefreshRequest = () async {
        debugPrint("🔄 [Socket-Fallback] 执行紧急刷新...");
        // 调用 Http 的静态刷新方法
        // 注意：这里传入刚才公开的 Http.rawDio
        final success = await Http.tryRefreshToken(Http.rawDio);

        if (success) {
          return await Http.getToken();
        } else {
          await Http.performLogout();
          return null;
        }
      };
    }

    bool isExpired = false;

    // 1. 如果有旧连接，只断开 Socket
    try{
      isExpired = JwtDecoder.isExpired(token) || JwtDecoder.getRemainingTime(token).inSeconds < 60;
    }catch(e){
      // 如果 Token 格式不对，也视为无效
      isExpired = true;
    }

    if(isExpired){
      debugPrint('🛑 [Socket] 启动拦截：Token 已过期或即将过期，请求刷新...');
      if(onTokenRefreshRequest != null) {
        // 呼叫上层刷新
        final newToken = await onTokenRefreshRequest!();
        if (newToken != null) {
          // 递归调用自己，使用新 Token
          init(token: newToken);
          return; // 结束当前的旧调用
        } else {
          debugPrint('❌ [Socket] 刷新失败，放弃连接');
          return; // 彻底放弃，等待用户重新登录
        }
      }
      return;
    }

    if (_socket != null) {
      debugPrint('🔄 [Socket] 切换 Token，断开旧连接...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    String baseUrl = Env.apiBaseEffective;
    String socketUrl = '$baseUrl/events';

    debugPrint('🔌 [Socket] 正在连接: $socketUrl (Token: ${token.substring(0, 10)}...)');

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({'token': token})
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .enableForceNew()
          .build(),
    );

    _setupListeners();
    _socket!.connect();
  }

  void _setupListeners() {
    _socket!.onConnect((_) {
      debugPrint('✅ [Global Socket] Connected: ${_socket!.id}');
      _syncController.add(null);
    });

    _socket!.onDisconnect((data) {
      debugPrint('❌ [Global Socket] Disconnected. Reason: $data');
    });

    _socket!.onAny((event, data) {
      // debugPrint('🕵️‍♂️ [Socket 抓包] Event: "$event" | Data: $data');
    });

    _socket!.on('server_push', (data) {
      debugPrint('📦 [Socket] 收到 server_push: $data');
      if (data == null) return;
      try {
        _dispatchMessage(data);
      } catch (e) {
        debugPrint('❌ [Socket Dispatch Error] $e');
      }
    });


  }

  // ----------------------------------------------------------------
  // 🔀 分发中心
  // ----------------------------------------------------------------

  void _dispatchMessage(dynamic data) {
    final String typeStr = data['type'] ?? '';
    final dynamic payload = data['payload'];

    final PushEventType type = PushEventType.fromValue(typeStr);
    debugPrint('📩 [Socket] Recv Type: $typeStr');

    switch (type) {
      case PushEventType.groupUpdate:
        if (!_groupUpdateController.isClosed) {
          _groupUpdateController.add(payload);
        }
        break;

      case PushEventType.groupSuccess:
        if (!_notificationController.isClosed) {
          _notificationController.add(
            GlobalNotification(
              isSuccess: true,
              title: payload['title'] ?? 'Success',
              message: payload['message'] ?? 'Group is full!',
              originalData: payload,
            ),
          );
        }
        // 顺便更新列表状态
        if (!_groupUpdateController.isClosed) {
          _groupUpdateController.add({
            'groupId': payload['groupId'],
            'status': 2,
            'isFull': true,
            'currentMembers': 9999,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
        break;

      case PushEventType.groupFailed:
        if (!_notificationController.isClosed) {
          _notificationController.add(
            GlobalNotification(
              isSuccess: false,
              title: payload['title'] ?? 'Failed',
              message: payload['message'] ?? 'Refund processed.',
              originalData: payload,
            ),
          );
        }
        if (!_walletRefreshController.isClosed) {
          _walletRefreshController.add(null);
        }
        break;

      case PushEventType.walletChange:
        if (!_walletRefreshController.isClosed) {
          _walletRefreshController.add(null);
        }
        break;

      case PushEventType.unknown:
        break;
    }
  }

  // ----------------------------------------------------------------
  // 🚪 房间管理 (补回了这两个方法！)
  // ----------------------------------------------------------------

  void joinLobby() {
    if (_socket?.connected == true) {
      _socket!.emit('join_lobby');
    }
  }

  void leaveLobby() {
    if (_socket?.connected == true) {
      _socket!.emit('leave_lobby');
    }
  }

  // ----------------------------------------------------------------
  // 🗑 资源管理
  // ----------------------------------------------------------------

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      debugPrint('👋 [Global Socket] Disconnected & Disposed');
    }
  }

  void dispose() {
    disconnect();
    // 再次强调：不要 close Controllers
  }
}