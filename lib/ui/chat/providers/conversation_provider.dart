import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/socket_provider.dart';
import '../../../core/store/lucky_store.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart';
import '../services/database/local_database_service.dart';

part 'conversation_provider.g.dart';

// --- 状态提供者 ---

// 如果为 null，说明用户不在任何聊天室里
final activeConversationIdProvider = StateProvider<String?>((ref) => null);

// --- 会话列表控制器 (核心重构部分) ---

@riverpod
class ConversationList extends _$ConversationList {
  StreamSubscription? _conversationSub;

  @override
  FutureOr<List<Conversation>> build() async {
    // 1. 获取 Socket 服务并监听
    final socketService = ref.watch(socketServiceProvider);

    // 2. 页面销毁或 Provider 重置时自动取消订阅
    _conversationSub?.cancel();
    _conversationSub = socketService.conversationListUpdateStream.listen(_onNewMessage);
    ref.onDispose(() => _conversationSub?.cancel());

    // 3. 执行初始数据抓取 (会自动进入 AsyncLoading 状态)
    return await _fetchList();
  }

  /// 内部抓取逻辑：获取列表并根据当前 activeId 修正红点
  Future<List<Conversation>> _fetchList() async {
    final list = await Api.chatListApi(page: 1);
    final currentActiveId = ref.read(activeConversationIdProvider);

    if (currentActiveId != null) {
      return list.map((c) {
        if (c.id == currentActiveId) return c.copyWith(unreadCount: 0);
        return c;
      }).toList();
    }
    return list;
  }

  /// 供 UI 调用的手动刷新方法
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchList());
  }

  /// 收到新消息时的处理逻辑 (包含存储本地数据库和更新 UI)
  void _onNewMessage(SocketMessage msg) async {
    if (!state.hasValue) return;

    final currentList = state.value!;
    final luckyStore = ref.read(luckyProvider);
    final myUserId = luckyStore.userInfo?.id ?? "";
    final senderId = msg.sender?.id ?? "";
    final bool isMe = senderId.isNotEmpty && (senderId == myUserId);
    final convId = msg.conversationId;

    // A. 存入本地数据库
    _saveMessageToLocal(msg, isMe, myUserId, convId);

    // B. 更新 UI 列表项
    final index = currentList.indexWhere((conv) => conv.id == convId);
    if (index != -1) {
      final oldConv = currentList[index];
      final currentActiveId = ref.read(activeConversationIdProvider);
      final bool isViewingNow = (currentActiveId == convId);

      // 计算逻辑保持不变：如果是自己发的或正在看该房间，红点为0
      final newUnreadCount = (isMe || isViewingNow) ? 0 : (oldConv.unreadCount + 1);

      final newConv = oldConv.copyWith(
        lastMsgContent: _getPreviewContent(msg.type, msg.content),
        lastMsgTime: DateTime.now().millisecondsSinceEpoch,
        unreadCount: newUnreadCount,
        lastMsgStatus: MessageStatus.success,
      );

      final newList = [...currentList];
      newList.removeAt(index);
      newList.insert(0, newConv);

      state = AsyncData(newList);
    } else {
      // 会话不在当前列表中，执行全量刷新
      refresh();
    }
  }

  /// 供 ChatRoom 调用，手动更新列表项 (发送消息时)
  void updateLocalItem({
    required String conversationId,
    String? lastMsgContent,
    int? lastMsgTime,
    MessageStatus? lastMsgStatus,
  }) {
    if (!state.hasValue) return;

    final currentList = state.value!;
    final index = currentList.indexWhere((conv) => conversationId == conv.id);

    if (index != -1) {
      final oldConv = currentList[index];
      final newConv = oldConv.copyWith(
        lastMsgContent: lastMsgContent,
        lastMsgTime: lastMsgTime,
        unreadCount: 0,
        lastMsgStatus: lastMsgStatus,
      );
      final newList = [...currentList];
      newList.removeAt(index);
      newList.insert(0, newConv);
      state = AsyncData(newList);
    } else {
      refresh();
    }
  }

  /// 清除红点
  void clearUnread(String conversationId) {
    if (!state.hasValue) return;

    final newList = state.value!.map((c) {
      if (c.id == conversationId) return c.copyWith(unreadCount: 0);
      return c;
    }).toList();
    state = AsyncData(newList);
  }

  /// 辅助方法：存入本地数据库
  void _saveMessageToLocal(SocketMessage msg, bool isMe, String myUserId, String convId) async {
    try {
      final apiMsg = ChatMessage(
        id: msg.id, content: msg.content, type: msg.type,
        seqId: msg.seqId, createdAt: msg.createdAt, isSelf: isMe,
        meta: msg.meta,
        sender: msg.sender == null ? null : ChatSender(
          id: msg.sender!.id, nickname: msg.sender!.nickname, avatar: msg.sender!.avatar,
        ),
      );
      final uiMsg = ChatUiModel.fromApiModel(apiMsg, convId, myUserId);
      await LocalDatabaseService().saveMessage(uiMsg);
    } catch (e) {
      debugPrint(" [ConversationList] DB Save Error: $e");
    }
  }

  /// 预览内容转换
  String _getPreviewContent(dynamic type, String rawContent) {
    final int typeInt = int.tryParse(type.toString()) ?? 0;
    final messageType = MessageType.fromValue(typeInt);
    switch (messageType) {
      case MessageType.text: return rawContent;
      case MessageType.image: return '[Image]';
      case MessageType.audio: return '[Voice]';
      case MessageType.video: return '[Video]';
      case MessageType.file: return '[File]';
      case MessageType.location : return '[Location]';
      case MessageType.recalled: return '[Message recalled]';
      default: return rawContent;
    }
  }
}

// --- 其他控制器 (保持原样) ---

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
    if (state.hasError) return null;
    return state.value;
  }
}



@riverpod
class UserSearchController extends _$UserSearchController {
  @override
  AsyncValue<List<ChatSender>> build() {
    return const AsyncData([]);
  }

  Future<void> search(String keyword) async {
    if (keyword.isEmpty) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await Api.chatUsersSearchApi(keyword);
    });
  }
}

// [核心修改部分] SWR 策略：缓存优先，网络更新
// 改为 async* 生成器流
@riverpod
Stream<ConversationDetail> chatDetail(
    ChatDetailRef ref,
    String conversationId,
    ) async*{
  final db = LocalDatabaseService();

  // 1. [缓存层] 尝试先查本地，如果有直接发射 (秒开)
  ConversationDetail? localData;
  try{
    localData = await db.getConversationDetail(conversationId);
    if(localData != null){
      yield localData;
    }
  }catch(e){
    debugPrint(" [chatDetail] Local DB Fetch Error: $e");
  }

  // 2. [网络层] 再去网络拉取最新数据，发射更新 (后台更新)
  try{
    final networkData = await Api.chatDetailApi(conversationId);

    // 3. [持久化] 存入本地，供下次使用
    await db.saveConversationDetail(networkData);
    // 4. [更新 UI] 发射最新数据
    // Riverpod 内部会自动对比，如果 networkData 和 localData 一样，不会触发多余的重建
    yield networkData;
  }catch(e){
    debugPrint(" [chatDetail] Network Fetch Error: $e");
    throw e;
  }

}