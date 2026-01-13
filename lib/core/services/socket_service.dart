import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../api/env.dart';
// 如果需要 ServerTimeHelper 校准时间，请引入
// import 'package:flutter_app/core/services/server_time_helper.dart';

// ==========================================
// 1. 枚举与模型定义
// ==========================================

enum PushEventType {
  groupUpdate('group_update'),   // 大厅列表更新
  groupSuccess('group_success'), // 个人通知：成功
  groupFailed('group_failed'),   // 个人通知：失败
  walletChange('wallet_change'), // 个人通知：余额变动
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
  final dynamic originalData; // 包含 groupId 等原始数据，用于点击跳转

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
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  // 安全获取 socket
  IO.Socket? get socket => _socket;

  // ----------------------------------------------------------------
  // 📡 Streams (对外暴露的“天线”，UI 通过监听这些流来响应)
  // ----------------------------------------------------------------

  // 1. 连接重连信号 (用于触发全量刷新)
  final _syncController = StreamController<void>.broadcast();
  Stream<void> get onSyncNeeded => _syncController.stream;

  // 2. 大厅列表更新流 (GroupLobbyPage 监听)
  final _groupUpdateController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get groupUpdateStream => _groupUpdateController.stream;

  // 3. 全局弹窗通知流 (MainPage/HomePage 监听)
  final _notificationController = StreamController<GlobalNotification>.broadcast();
  Stream<GlobalNotification> get notificationStream => _notificationController.stream;

  // 4. 钱包刷新信号 (用于通知 Provider 刷新余额)
  final _walletRefreshController = StreamController<void>.broadcast();
  Stream<void> get onWalletRefreshNeeded => _walletRefreshController.stream;


  // ----------------------------------------------------------------
  // 🔌 初始化与连接
  // ----------------------------------------------------------------

  void init({required String token}) {
    // 不要直接 return！如果 socket 已经存在，说明可能是游客连接，或者旧账号连接。
    // 必须断开，用新的 Token 重新握手！

    if (_socket != null) {
      debugPrint('🔄 [Socket] 检测到 Token 初始化，正在断开旧连接并重连...');
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
          .setQuery({'token': token}) // 注入 Token
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

    // 【新增】万能调试监听器 (用来抓鬼)
    // 只要服务器发了任何东西，这行日志一定会打印！
    _socket!.onAny((event, data) {
      debugPrint('🕵️‍♂️ [Socket 抓包] Event: "$event" | Data: $data');
    });

    //  核心修改：只监听 'server_push' 一个入口
    _socket!.on('server_push', (data) {
      debugPrint('📦 [Socket] 收到 server_push, 准备分发...');
      if (data == null) return;
      try {
        _dispatchMessage(data);
      } catch (e) {
        debugPrint('❌ [Socket Dispatch Error] $e');
      }
    });
  }

  // ----------------------------------------------------------------
  // 🔀 分发中心 (Dispatcher)
  // ----------------------------------------------------------------

  void _dispatchMessage(dynamic data) {
    final String typeStr = data['type'] ?? '';
    final dynamic payload = data['payload'];

    // 如果后端传了时间戳，可以在这里校准时间
    // final int? timestamp = data['timestamp'];
    // if (timestamp != null) ServerTimeHelper.updateOffset(timestamp);

    final PushEventType type = PushEventType.fromValue(typeStr);

    debugPrint('📩 [Socket] Recv: $typeStr');

    switch (type) {
    // A. 列表更新 (高频)
      case PushEventType.groupUpdate:
        _groupUpdateController.add(payload);
        break;

    // B. 拼团成功 (低频，重要)
      case PushEventType.groupSuccess:
      // 1. 弹窗
        _notificationController.add(GlobalNotification(
          isSuccess: true,
          title: payload['title'] ?? 'Success',
          message: payload['message'] ?? 'Group is full!',
          originalData: payload,
        ));
        // 2. 如果用户正盯着列表，顺便把那个卡片状态改成成功
        // 我们构造一个伪造的 update 包，把 status 设为 2
        _groupUpdateController.add({
          'groupId': payload['groupId'],
          'status': 2,
          'currentMembers': 9999, // 确保显示满员
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        break;

    // C. 拼团失败/退款 (低频，重要)
      case PushEventType.groupFailed:
      // 1. 弹窗
        _notificationController.add(GlobalNotification(
          isSuccess: false,
          title: payload['title'] ?? 'Failed',
          message: payload['message'] ?? 'Refund processed.',
          originalData: payload,
        ));
        // 2. 刷新余额
        _walletRefreshController.add(null);
        break;

    // D. 纯余额变动
      case PushEventType.walletChange:
        _walletRefreshController.add(null);
        break;

      case PushEventType.unknown:
      // 忽略未知消息
        break;
    }
  }

  // ----------------------------------------------------------------
  // 🚪 房间管理 & 销毁
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

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    debugPrint('👋 [Global Socket] Destroyed');
  }

  void dispose() {
    _syncController.close();
    _groupUpdateController.close();
    _notificationController.close();
    _walletRefreshController.close();
    disconnect();
  }
}