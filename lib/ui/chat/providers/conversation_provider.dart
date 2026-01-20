import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/services/socket_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/socket_provider.dart';
import '../models/conversation.dart';

part 'conversation_provider.g.dart';

class ConversationListNotifier extends StateNotifier<List<Conversation>> {
  final SocketService _socketService;
  StreamSubscription? _conversationSub;

  ConversationListNotifier(this._socketService) : super([]) {
    _init();
  }

  Future<void> _init() async {
    // 1. 调用列表 API (只拿概览，不拿详情)
    await refresh();

    // 2. 监听会话列表更新
     _conversationSub = _socketService.conversationListUpdateStream.listen(_onNewMessage);
  }

  Future<void> refresh() async {
    try {
      final list = await Api.chatListApi(page: 1);
      state = list;
      print("✅ [ConversationListNotifier] 刷新会话列表成功，数量: ${list.length}");
    } catch (e) {
      debugPrint("❌ [ConversationListNotifier] 刷新会话列表失败: $e");
    }
  }

  // 收到新消息时的逻辑：只更新列表项，不处理具体气泡
  void _onNewMessage(SocketMessage msg) {
    //  核心修复：第一行必须加这个！
    // 如果页面已经销毁，直接停止，不要去碰 state
    if (!mounted) return;
    final convId = msg.conversationId;
    // 简单的文本摘要处理
    String content = '[非文本消息]';
    if (msg.type == 0 || msg.type == 'text') {
      content = msg.content;
    } else if (msg.type == 1 || msg.type == 'image') {
      content = '[图片]';
    }
    final time = DateTime.now().millisecondsSinceEpoch;

    // 1. 查找列表里有没有这个会话
    final index = state.indexWhere((conv) => conv.id == convId);

    if (index != -1) {
      // A. 已存在：更新摘要 + 移到顶部 + 未读数+1
      final oldConv = state[index];
      // 自己发的消息不算未读，别人的才需要加
      final newUnreadCount = msg.isSelf ? oldConv.unreadCount : oldConv.unreadCount + 1;
      // 构造新的 Conversation 对象
      final newConv = oldConv.copyWith(
        lastMsgContent: content,
        lastMsgTime: time,
        unreadCount: newUnreadCount,
      );

      final newState = [...state];
      newState.removeAt(index); // 先移除旧的
      newState.insert(0, newConv); // 再插入更新后的到顶部
      state = newState;
    } else {
      // B. 新会话：重新刷新列表 (最简单的做法)
      refresh();
    }
  }

  // --------------------------------------------------------
  //  新增方法 1：供 ChatRoom 调用，手动更新列表项 (发送消息时)
  // --------------------------------------------------------
  void updateLocalItem({
    required String conversationId,
    String? lastMsgContent,
    int? lastMsgTime,
  }) {
    final index = state.indexWhere((conv) => conversationId == conv.id);
    if (index != -1) {
      final oldConv = state[index];
      // 1. 更新内容和时间
      // 2. 这里的 unreadCount 不变 (或者是 0)，因为是自己发的消息
      final newConv = oldConv.copyWith(
        lastMsgContent: lastMsgContent,
        lastMsgTime: lastMsgTime,
      );
      // 3. 移动到顶部
      final newState = [...state];
      newState.removeAt(index);
      newState.insert(0, newConv);
      state = newState;
    } else {
      // 会话不存在，直接刷新列表
      refresh();
    }
  }

  // 清除红点 (点击进入详情页时调用)
  void clearUnread(String conversationId) {
    state = state.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(unreadCount: 0);
      }
      return c;
    }).toList();
  }

  @override
  void dispose() {
    _conversationSub?.cancel();
    super.dispose();
  }
}

// 定义 Provider
final conversationListProvider =
    StateNotifierProvider.autoDispose<
      ConversationListNotifier,
      List<Conversation>
    >((ref) {
      print("🔌 [conversationListProvider] 初始化 ConversationListNotifier");
      final socketService = ref.watch(socketServiceProvider);
      return ConversationListNotifier(socketService);
    });

@riverpod
class CreateGroupController extends _$CreateGroupController {
  @override
  AsyncValue<ConversationIdResponse?> build() {
    return const AsyncData(null);
  }

  Future<ConversationIdResponse?> createGroup(
    String groupName,
    List<String> memberIds,
  ) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await Api.chatGroupApi(groupName, memberIds);
    });

    if (state.hasError) {
      return null;
    }
    return state.value;
  }
}

@riverpod
class CreateDirectChatController extends _$CreateDirectChatController {
  @override
  AsyncValue<ConversationIdResponse?> build() {
    return const AsyncData(null);
  }

  Future<ConversationIdResponse?> createDirectChat(String userId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await Api.chatDirectApi(userId);
    });

    if (state.hasError) {
      return null;
    }
    return state.value;
  }
}

@riverpod
Future<ConversationDetail> chatDetail(
  ChatDetailRef ref,
  String conversationId,
) async {
  return Api.chatDetailApi(conversationId);
}

@riverpod
class UserSearchController extends _$UserSearchController {
  @override
  AsyncValue<List<ChatSender>> build() {
    return const AsyncData([]); // 初始状态为空列表
  }

  Future<void> search(String keyword) async {
    if (keyword.isEmpty) return;

    state = const AsyncValue.loading(); // 设置加载状态

    state = await AsyncValue.guard(() async {
      return await Api.chatUsersSearchApi(keyword);
    });
  }
}
