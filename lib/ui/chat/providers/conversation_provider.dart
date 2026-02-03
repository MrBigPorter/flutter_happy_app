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

final activeConversationIdProvider = StateProvider<String?>((ref) => null);

// --- 会话列表控制器 ---

@Riverpod(keepAlive: true)
class ConversationList extends _$ConversationList {
  StreamSubscription? _conversationSub;
  StreamSubscription? _conversationUpdateSub;

  @override
  FutureOr<List<Conversation>> build() async {
    final currentUserId = ref.watch(luckyProvider.select((s) => s.userInfo?.id));

    if(currentUserId == null || currentUserId.isEmpty){
      return [];
    }

    await LocalDatabaseService.init(currentUserId);

    final socketService = ref.watch(socketServiceProvider);

    _conversationSub?.cancel();
    _conversationSub = socketService.conversationListUpdateStream.listen(_onNewMessage);

    _conversationUpdateSub?.cancel();
    _conversationUpdateSub = socketService.conversationUpdateStream.listen(_onConversationAttributeUpdate);

    ref.onDispose((){
      _conversationSub?.cancel();
      _conversationUpdateSub?.cancel();
    });

    final localData = await LocalDatabaseService().getConversations();

    if(localData.isNotEmpty){
      state = AsyncData(localData);
    }

    _fetchList();

    return localData;
  }

  Future<List<Conversation>> _fetchList() async {
    final list = await Api.chatListApi(page: 1);
    await LocalDatabaseService().saveConversations(list);
    final currentActiveId = ref.read(activeConversationIdProvider);

    state = AsyncData(list);

    if (currentActiveId != null) {
      return list.map((c) {
        if (c.id == currentActiveId) return c.copyWith(unreadCount: 0);
        return c;
      }).toList();
    }
    return list;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _fetchList());
  }

  void addConversation(Conversation newItem){
    if(!state.hasValue) return;
    final currentList = state.value!;
    if(currentList.any((c) => c.id == newItem.id)) return;
    state = AsyncData([newItem, ...currentList]);
  }

  void _onNewMessage(SocketMessage msg) async {
    if (!state.hasValue) return;

    final currentList = state.value!;
    final luckyStore = ref.read(luckyProvider);
    final myUserId = luckyStore.userInfo?.id ?? "";
    final senderId = msg.sender?.id ?? "";
    final bool isMe = senderId.isNotEmpty && (senderId == myUserId);
    final convId = msg.conversationId;

    _saveMessageToLocal(msg, isMe, myUserId, convId);

    final index = currentList.indexWhere((conv) => conv.id == convId);
    if (index != -1) {
      final oldConv = currentList[index];
      final currentActiveId = ref.read(activeConversationIdProvider);
      final bool isViewingNow = (currentActiveId == convId);

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
      // [优化 1] 收到新消息但不在列表中时，建议使用 refresh() 触发分页拉取
      // 而不是一个个去查详情，这样能保证列表的连续性
      refresh();
    }
  }

  /// 处理来自 Socket 的头像/属性更新信号
  void _onConversationAttributeUpdate(Map<String, dynamic> data) async {
    if (!state.hasValue) return;

    final String convId = data['id'];
    final String? newAvatar = data['avatar'];
    final String? newName = data['name']; // [新增] 同时也处理名称更新

    final currentList = state.value!;
    final index = currentList.indexWhere((c) => c.id == convId);

    if (index != -1) {
      final oldConv = currentList[index];
      // [优化 2] 增加判断逻辑，只有真正变化时才更新
      bool isChanged = false;
      var newConv = oldConv;

      if (newAvatar != null && oldConv.avatar != newAvatar) {
        newConv = newConv.copyWith(avatar: newAvatar);
        isChanged = true;
      }
      if (newName != null && oldConv.name != newName) {
        newConv = newConv.copyWith(name: newName);
        isChanged = true;
      }

      if (isChanged) {
        final newList = [...currentList];
        newList[index] = newConv;
        state = AsyncData(newList);
        // 记得同步本地数据库
        LocalDatabaseService().saveConversations([newConv]);
      }
    } else {
      // [核心优化 3] 移除 else 分支中的 ref.read(chatDetailProvider...)
      // 理由：Socket 信号可能非常频繁（风暴），如果该会话不在当前列表显示范围内（比如在第二页），
      // 我们没必要为了一个头像更新去请求网络详情接口。
      // 策略：静默忽略，等用户滚动或手动刷新时自然会获取到最新数据。
      debugPrint(" [ConversationList] Skip attribute update for non-existent conversation: $convId");
    }
  }

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

  void clearUnread(String conversationId) {
    if (!state.hasValue) return;

    final newList = state.value!.map((c) {
      if (c.id == conversationId) return c.copyWith(unreadCount: 0);
      return c;
    }).toList();
    state = AsyncData(newList);
  }

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
      final uiMsg = ChatUiModelMapper.fromApiModel(apiMsg, convId, myUserId);
      await LocalDatabaseService().saveMessage(uiMsg);
    } catch (e) {
      debugPrint(" [ConversationList] DB Save Error: $e");
    }
  }

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

// --- 其他控制器 ---

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

// SWR 策略：缓存优先，网络更新
@riverpod
Stream<ConversationDetail> chatDetail(
    ChatDetailRef ref,
    String conversationId,
    ) async*{
  final userId = ref.watch(luckyProvider.select((s) => s.userInfo?.id));

  if (userId != null && userId.isNotEmpty) {
    await LocalDatabaseService.init(userId);
  }

  final db = LocalDatabaseService();

  ConversationDetail? localData;
  try{
    localData = await db.getConversationDetail(conversationId);
    if(localData != null){
      yield localData;
    }
  }catch(e){
    debugPrint(" [chatDetail] Local DB Fetch Error: $e");
  }

  try{
    final networkData = await Api.chatDetailApi(conversationId);
    await db.saveConversationDetail(networkData);
    yield networkData;
  }catch(e){
    debugPrint(" [chatDetail] Network Fetch Error: $e");
    // [优化 4] 如果网络请求失败且本地也没有数据，再抛出异常
    if(localData == null) throw e;
  }
}