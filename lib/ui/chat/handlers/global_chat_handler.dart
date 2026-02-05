import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/core/services/socket/socket_service.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

import '../../../core/providers/socket_provider.dart';

//  全局 Handler Provider
// 这是一个 "Keep Alive" 的 Provider，只要被 watch，它就会一直活着
final globalChatHandlerProvider = Provider<GlobalChatHandler>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  // 获取当前登录用户的 ID
  final currentUserId = ref.watch(luckyProvider).userInfo?.id ?? "";

  // 如果没登录，返回一个空的 Handler
  if (currentUserId.isEmpty) return GlobalChatHandler.empty();

  return GlobalChatHandler(socketService, currentUserId);
});

class GlobalChatHandler {
  final SocketService? _socketService;
  final String _currentUserId;
  StreamSubscription? _msgSub;

  // 空构造函数 (未登录时使用)
  GlobalChatHandler.empty() : _socketService = null, _currentUserId = "";

  GlobalChatHandler(this._socketService, this._currentUserId) {
    _init();
  }

  void _init() {
    if (_socketService == null) return;

    debugPrint(" [GlobalHandler] 全局消息监听已启动...");

    // 监听 Socket 消息流
    _msgSub = _socketService!.chatMessageStream.listen((data) async {
      try {
        final rawMsg = SocketMessage.fromJson(data);

        // 1. 过滤掉自己发的消息 (多端同步的消息通常不需要弹红点)
        if (rawMsg.senderId == _currentUserId) return;

        debugPrint(" [GlobalHandler] 收到后台消息: ${rawMsg.content}");

        // 2. 转换为 UI 模型 (ChatUiModel)
        // 这里复用了 ChatUiModelMapper 的逻辑
        final uiMsg = ChatUiModelMapper.fromApiModel(
          ChatMessage(
            id: rawMsg.id,
            content: rawMsg.content,
            type: rawMsg.type,
            seqId: rawMsg.seqId,
            createdAt: rawMsg.createdAt,
            isSelf: false, // 既然是 socket 推送且 senderId != me，那肯定是别人的
            meta: rawMsg.meta,
            sender: rawMsg.sender != null ? ChatSender(
                id: rawMsg.sender!.id,
                nickname: rawMsg.sender!.nickname,
                avatar: rawMsg.sender!.avatar
            ) : null,
          ),
          rawMsg.conversationId,
          _currentUserId,
        );

        // 3.  核心调用：存库 + 未读数加 1
        // (调用我们在 Step 1 中写好的新方法)
        await LocalDatabaseService().handleIncomingMessage(uiMsg);

      } catch (e) {
        debugPrint(" [GlobalHandler] 处理消息失败: $e");
      }
    });
  }

  void dispose() {
    debugPrint(" [GlobalHandler] 停止监听");
    _msgSub?.cancel();
  }
}