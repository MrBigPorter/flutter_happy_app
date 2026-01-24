import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/services/socket_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/socket_provider.dart';
import '../../../core/store/lucky_store.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart';
import '../services/database/local_database_service.dart';

part 'conversation_provider.g.dart';

// 如果为 null，说明用户不在任何聊天室里
final activeConversationIdProvider = StateProvider<String?>((ref) => null);

class ConversationListNotifier extends StateNotifier<List<Conversation>> {
  final SocketService _socketService;
  final Ref _ref;
  StreamSubscription? _conversationSub;

  ConversationListNotifier(this._socketService,this._ref) : super([]) {
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

      //  [新增] 强行修正：如果我正盯着某个房间看，API 返回的红点不算数，必须归零
      final currentActiveId = _ref.read(activeConversationIdProvider);
      if (currentActiveId != null) {
        state = list.map((c) {
          if (c.id == currentActiveId) return c.copyWith(unreadCount: 0);
          return c;
        }).toList();
      } else {
        state = list;
      }

      debugPrint(" [Notifier] 刷新列表完成，当前ActiveID: $currentActiveId");
    } catch (e) {
      debugPrint(" [Notifier] 刷新失败: $e");
    }
  }

  // 收到新消息时的逻辑：只更新列表项，不处理具体气泡
  void _onNewMessage(SocketMessage msg) async {
    // 1. 安全检查：如果页面销毁，停止操作
    if (!mounted) return;

    // 2. 解析基础信息
    final luckyStore = _ref.read(luckyProvider);
    final myUserId = luckyStore.userInfo?.id ?? "";
    final senderId = msg.sender?.id ?? "";
    final bool isMe = senderId.isNotEmpty && (senderId == myUserId);
    final convId = msg.conversationId;

    // ---------------------------------------------------------
    // 🛠️ 步骤 A: 无论在不在房间，先存入本地数据库 (Sembast)
    // ---------------------------------------------------------
    try {
      final apiMsg = ChatMessage(
        id: msg.id,
        content: msg.content,
        type: msg.type,
        seqId: msg.seqId,
        createdAt: msg.createdAt,
        isSelf: isMe,
        meta: msg.meta,
        sender: msg.sender == null
            ? null
            : ChatSender(
          id: msg.sender!.id,
          nickname: msg.sender!.nickname,
          avatar: msg.sender!.avatar,
        ),
      );
      final uiMsg = ChatUiModel.fromApiModel(apiMsg, convId, myUserId);
      // 调用数据库保存
      await LocalDatabaseService().saveMessage(uiMsg);
    } catch (e) {
      debugPrint(" [ConversationListNotifier] 存储消息到本地数据库失败: $e");
    }

    // ---------------------------------------------------------
    // 🛠️ 步骤 B: 更新会话列表 UI (红点 & 摘要)
    // ---------------------------------------------------------
    String content = _getPreviewContent(msg.type, msg.content);
    final time = DateTime.now().millisecondsSinceEpoch;

    // 1. 查找列表里有没有这个会话
    final index = state.indexWhere((conv) => conv.id == convId);


    if (index != -1) {
      final oldConv = state[index];

      //  [核心修复逻辑 Start]

      // 1. 获取当前正在浏览的房间 ID (从 Provider 读取)
      final currentActiveId = _ref.read(activeConversationIdProvider);

      // 2. 判断是否“正在看”这个房间
      final bool isViewingNow = (currentActiveId == convId);


      // 3. 计算未读数
      // 规则：如果是【我发的】或者【我正在看这个房间】，未读数为 0 (或者保持不变，视需求而定，通常归0更安全)
      // 否则：未读数 + 1
      final newUnreadCount = (isMe || isViewingNow) ? 0 : (oldConv.unreadCount + 1);


      //  [核心修复逻辑 End]

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
      // B. 新会话：重新刷新列表
      refresh();
    }
  }

  // conversation_provider.dart
  String _getPreviewContent(dynamic type, String rawContent) {
    // 统一转为枚举处理
    final int typeInt = int.tryParse(type.toString()) ?? 0;
    final messageType = MessageType.fromValue(typeInt);

    switch (messageType) {
      case MessageType.text:
        return rawContent;
      case MessageType.image:
        return '[Image]';
      case MessageType.audio:
        return '[Voice]';
      case MessageType.video:
        return '[Video]';
      case MessageType.recalled:
        return '[Message recalled]';
      case MessageType.system:
        return rawContent;
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
        unreadCount: 0, //  核心修复：自己发送消息，未读数强制清零
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
    StateNotifierProvider<
      ConversationListNotifier,
      List<Conversation>
    >((ref) {
      final socketService = ref.watch(socketServiceProvider);
      return ConversationListNotifier(socketService,ref);
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
