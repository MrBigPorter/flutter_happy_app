import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/socket_provider.dart';
import '../../../core/store/lucky_store.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart';
import '../models/chat_ui_model_mapper.dart';
import '../services/database/local_database_service.dart';

part 'conversation_provider.g.dart';

final activeConversationIdProvider = StateProvider<String?>((ref) => null);


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

    // 1. 初始化数据库
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

    // 2. 先加载本地旧数据 (秒开)
    final localData = await LocalDatabaseService().getConversations();
    if(localData.isNotEmpty){
      state = AsyncData(localData);
    }

    // 3.启动时强制同步列表 (全局自愈核心)
    // 这一步会把服务器的最新状态（包括已读/未读）拉下来，覆盖本地
    _fetchList();

    return localData;
  }

  Future<List<Conversation>> _fetchList() async {
    try {
      // A. 拉取服务器最新列表 (Server Truth)
      // 如果你在 A 手机读过了，这里返回的 unreadCount 就是 0
      final list = await Api.chatListApi(page: 1);

      // B. 关键：入库覆盖！
      // LocalDatabaseService.saveConversations 默认是 put (覆盖) 操作
      // 所以这一步执行完，数据库里的 "8" 就会变成 "0"
      await LocalDatabaseService().saveConversations(list);

      final currentActiveId = ref.read(activeConversationIdProvider);
      debugPrint(" [ConversationList] Synced ${list.length} conversations from server.");

      // C. 更新内存状态 (UI 刷新)
      // 如果当前正停留在某个会话里，强制把那个会话的未读数设为 0
      final processedList = list.map((c) {
        if (c.id == currentActiveId) return c.copyWith(unreadCount: 0);
        return c;
      }).toList();

      state = AsyncData(processedList);
      return processedList;

    } catch (e) {
      debugPrint(" [ConversationList] Sync failed: $e");
      // 如果网络失败，保持显示本地数据
      if (state.hasValue) return state.value!;
      return [];
    }
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

    // 1. 存消息
    await _saveMessageToLocal(msg, isMe, myUserId, convId);

    final index = currentList.indexWhere((conv) => conv.id == convId);
    if (index != -1) {
      final oldConv = currentList[index];
      final currentActiveId = ref.read(activeConversationIdProvider);
      final bool isViewingNow = (currentActiveId == convId);

      // 如果是我发的，或者我正看着这个会话，未读数不增加
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

      // 2. 同步更新会话列表数据库
      await LocalDatabaseService().saveConversations([newConv]);

    } else {
      // 如果是新会话，触发刷新
      refresh();
    }
  }

  /// 处理来自 Socket 的头像/属性更新信号
  void _onConversationAttributeUpdate(Map<String, dynamic> data) async {
    if (!state.hasValue) return;

    final String convId = data['id'];
    final String? newAvatar = data['avatar'];
    final String? newName = data['name'];

    final currentList = state.value!;
    final index = currentList.indexWhere((c) => c.id == convId);

    if (index != -1) {
      final oldConv = currentList[index];
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
        await LocalDatabaseService().saveConversations([newConv]);
      }
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
        lastMsgContent: lastMsgContent ?? oldConv.lastMsgContent,
        lastMsgTime: lastMsgTime ?? oldConv.lastMsgTime,
        // 这里不应该强制清零 unreadCount，除非明确要求
        // unreadCount: 0,
        lastMsgStatus: lastMsgStatus ?? oldConv.lastMsgStatus,
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

  Future<void> _saveMessageToLocal(SocketMessage msg, bool isMe, String myUserId, String convId) async {
    try {
      final apiMsg = ChatMessage(
        id: msg.id,
        content: msg.content,
        type: msg.type,
        seqId: msg.seqId,
        createdAt: msg.createdAt,
        isSelf: isMe,
        meta: msg.meta,
        sender: msg.sender == null ? null : ChatSender(
          id: msg.sender!.id,
          nickname: msg.sender!.nickname ?? 'Unknown',
          avatar: msg.sender!.avatar,
        ),
      );
      final uiMsg = ChatUiModelMapper.fromApiModel(apiMsg, convId);
      // 使用 saveMessage (内部含 merge 逻辑)
      await LocalDatabaseService().saveMessage(uiMsg);
    } catch (e) {
      debugPrint(" [ConversationList] DB Save Error: $e");
    }
  }

  String _getPreviewContent(dynamic type, String rawContent) {
    final int typeInt = int.tryParse(type.toString()) ?? 0;

    // 简单的类型判断，你可以用 MessageType 枚举
    if (typeInt == 1) return '[Image]';
    if (typeInt == 2) return '[Voice]';
    if (typeInt == 3) return '[Video]';
    if (typeInt == 4) return '[File]';
    if (typeInt == 5) return '[Location]';
    if (typeInt == 99) return '[Message recalled]';

    return rawContent;
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
    if(localData == null) throw e;
  }
}