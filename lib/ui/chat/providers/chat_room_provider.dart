import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_app/core/services/socket_service.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/socket_provider.dart';

class ChatRoomNotifier extends StateNotifier<List<ChatUiModel>> {
  final SocketService _socketService;
  final String conversationId;
  StreamSubscription? _msgSub;

  ChatRoomNotifier(this._socketService, this.conversationId) : super([]) {
    _init();
  }

  void _init() {
    // 1. 进房
    _socketService.joinChatRoom(conversationId);

    // 2. 监听消息
    _msgSub = _socketService.chatMessageStream.listen((data) {
      // 过滤只属于当前会话的消息
      if (data['conversationId'] != conversationId) return;
      // 这里的 logic 是处理“别人发的”消息
      // "我发的"消息会在 sendMessage 里手动上屏，所以这里要做个去重或者判断 senderId
      // 简单起见，假设后端回推的消息里包含了 senderId
      // boolean isMe = data['senderId'] == myUserId;
      // 实际开发中，通常不需要监听"自己发的消息的回执"来上屏，因为我们有本地乐观更新
      // 所以这里假设只处理 !isMe

      final newMsg = ChatUiModel(
        id: data['id'] ?? const Uuid().v4(),
        content: data['content'],
        type: MessageType.text,
        // 暂只支持文本
        isMe: false,
        // 收到 socket 肯定是别人的 (或者是多端同步的)
        createdAt: DateTime.now().millisecondsSinceEpoch,
        senderName: data['sender']?['nickname'],
        senderAvatar: data['sender']?['avatar'],
      );

      // 插到最前面 (ListView reverse: true)
      state = [newMsg, ...state];
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final tempId = const Uuid().v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // 1. 本地乐观更新(立刻上屏，状态为 sending)
    final pendingMsg = ChatUiModel(
      id: tempId,
      content: text,
      type: MessageType.text,
      isMe: true,
      status: MessageStatus.sending,
      // 发送中,转圈
      createdAt: timestamp,
    );

    state = [pendingMsg, ...state];

    try {
      // B. 调用 Socket 发送
      final result = await _socketService.sendMessage(
        conversationId: conversationId,
        content: text,
        type: 0, // 0=text
        tempId: tempId,
      );

      // C. 根据结果更新状态
      if (result.success) {
        // 发送成功，更新状态为 success
        state = state.map((msg) {
          if (msg.id == tempId) {
            return msg.copyWith(
              status: MessageStatus.success,
              id: result.data?['id'],
            );
          }
          return msg;
        }).toList();
      } else {
        _markAsFailed(tempId);
      }
    } catch (e) {
      debugPrint('sendMessage error: $e');
      _markAsFailed(tempId);
    }
  }

  void _markAsFailed(String tempId) {
    // 发送失败，更新状态为 failed
    state = state.map((msg) {
      if (msg.id == tempId) {
        return msg.copyWith(status: MessageStatus.failed);
      }
      return msg;
    }).toList();
  }

  @override
  void dispose() {
    // 离开房间
    _socketService.leaveChatRoom(conversationId);
    _msgSub?.cancel();
    super.dispose();
  }
}

// Provider 定义 (Family 模式，因为需要传 conversationId)
final chatRoomProvider = StateNotifierProvider.family
    .autoDispose<ChatRoomNotifier, List<ChatUiModel>, String>((
      ref,
      conversationId,
    ) {
      final socketService = ref.watch(socketServiceProvider);
      return ChatRoomNotifier(socketService, conversationId);
    });
