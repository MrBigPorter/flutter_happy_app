import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/cache/cache_for_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart'; // 引入神器

import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/services/socket_service.dart';
import 'package:flutter_app/core/providers/socket_provider.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/core/store/lucky_store.dart';

import '../models/conversation.dart';
import 'conversation_provider.dart';

class ChatRoomNotifier extends StateNotifier<AsyncValue<List<ChatUiModel>>> {
  final SocketService _socketService;
  final String conversationId;
  final String myUserId;
  final Ref _ref;

  StreamSubscription? _msgSub;
  StreamSubscription? _readStatusSub;
  StreamSubscription? _connectionSub;

  // 1. 定义 Rx 管道
  final _readReceiptSubject = PublishSubject<void>();

  String? _nextCursor;
  bool _isLoadingMore = false;

  // 记录是否有未提交的已读任务
  bool _hasPendingRead = false;

  // 对方的已读水位线
  int _maxReadSeqId = 0;

  bool get hasMore => _nextCursor != null;

  ChatRoomNotifier(
      this._socketService,
      this.conversationId,
      this.myUserId,
      this._ref,
      ) : super(const AsyncValue.loading()) {
    // 1. 建立 Socket 监听
    _setup();
    // 2.  修复点：必须启动防抖监听，否则管道是死的！
    _setupReadReceiptDebounce();
  }

  // 大厂写法：声明式防抖逻辑
  void _setupReadReceiptDebounce() {
    _readReceiptSubject
        .debounceTime(const Duration(milliseconds: 500)) // 500ms 内多次触发只认最后一次
        .listen((_) {
      if (!mounted) return;
      debugPrint("🌊 [Rx] 防抖时间到，触发 API 上报");
      _executeMarkRead();
    });
  }

  void _executeMarkRead() {
    markAsRead();
    _hasPendingRead = false; // 重置标记
  }

  // ===========================================================================
  // 🚀 1. 基础设置 (只运行一次)
  // ===========================================================================
  Future<void> _setup() async {
    // A. 监听连接/重连
    _connectionSub = _socketService.onSyncNeeded.listen((_) {
      debugPrint("🔄 [ChatRoom] Socket 重连，重新加入房间...");
      _joinRoom();
    });

    // B. 尝试进房
    if (_socketService.isConnected) {
      _joinRoom();
    } else {
      // 激进策略：如果没连上，尝试唤醒
      final socket = _socketService.socket;
      if (socket != null && !socket.active) {
        socket.connect();
      }
    }

    // C. 开启消息监听
    _msgSub = _socketService.chatMessageStream.listen(_onSocketMessage);
    _readStatusSub = _socketService.readStatusStream.listen(_onReadStatusUpdate);
  }

  void _joinRoom() {
    if (_socketService.isConnected) {
      _socketService.joinChatRoom(conversationId);
    }
  }

  // ===========================================================================
  // 🔄 2. 刷新数据 (UI initState 每次必调)
  // ===========================================================================
  Future<void> refresh() async {
    try {
      debugPrint("🚀 [ChatRoom] 正在刷新数据 (穿透缓存)...");

      //  防御：把 markAsRead 包起来
      // 就算标记已读失败（比如列表页销毁了），也不应该影响用户看消息！
      try { markAsRead(); } catch (_) {}

      // 2. 拉取最新一页消息
      final request = MessageHistoryRequest(
        conversationId: conversationId,
        pageSize: 20,
        cursor: null,
      );

      debugPrint("🚀 [ChatRoom] Step 2: 请求 API...");
      final response = await Api.chatMessagesApi(request);
      debugPrint("🚀 [ChatRoom] Step 3: API 返回. list长度: ${response.list.length}");

      // 3. 更新水位线
      _maxReadSeqId = response.partnerLastReadSeqId;
      _nextCursor = response.nextCursor;

      // 转换数据
      final uiMessages = _mapToUiModels(response.list);
      debugPrint("🚀 [ChatRoom] Step 4: 模型转换完毕. UI消息数: ${uiMessages.length}");

      final processedList = _applyReadStatusStrategy(uiMessages, _maxReadSeqId);
      debugPrint("🚀 [ChatRoom] Step 5: 策略应用完毕. 准备更新 State. mounted=$mounted");

      if(mounted) {
        state = AsyncValue.data(processedList);
        debugPrint("🚀 [ChatRoom] Step 6: State 更新成功！UI 应该变了");

      }

    } catch (e, st) {
      debugPrint("❌ Refresh Error: $e");
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_nextCursor == null || _isLoadingMore) return;
    _isLoadingMore = true;

    try {
      final request = MessageHistoryRequest(
        conversationId: conversationId,
        pageSize: 20,
        cursor: _nextCursor,
      );
      final response = await Api.chatMessagesApi(request);
      _nextCursor = response.nextCursor;

      final moreMessages = _mapToUiModels(response.list);

      state.whenData((currentList) {
        final rawList = [...currentList, ...moreMessages];
        // 重新计算已读策略 (保险起见)
        state = AsyncValue.data(_applyReadStatusStrategy(rawList, _maxReadSeqId));
      });
    } catch (e) {
      debugPrint("❌ Load more failed: $e");
    } finally {
      _isLoadingMore = false;
    }
  }

  // ===========================================================================
  // 📩 3. 发送逻辑 (Sending)
  // ===========================================================================

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final tempId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    // A. 乐观更新
    final tempMsg = ChatUiModel(
      id: tempId,
      content: text,
      type: MessageType.text,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: now,
      seqId: null,
    );

    _updateState((list) => [tempMsg, ...list]);
    _updateConversationList(text, now);

    await _executeSend(tempId, text);
  }

  Future<void> resendMessage(String tempId) async {
    state.whenData((list) async {
      final targetMsg = list.firstWhere((e) => e.id == tempId, orElse: () => list.first);
      if (targetMsg.id != tempId) return;

      _updateState((current) => current.map((m) =>
      m.id == tempId ? m.copyWith(status: MessageStatus.sending) : m
      ).toList());

      _updateConversationList(targetMsg.content, DateTime.now().millisecondsSinceEpoch);
      await _executeSend(tempId, targetMsg.content);
    });
  }

  Future<void> _executeSend(String tempId, String content) async {
    try {
      final sentMsg = await Api.sendMessage(conversationId, content, tempId);

      state.whenData((list) {
        if (!list.any((m) => m.id == tempId)) return;

        final rawList = list.map((msg) {
          if (msg.id == tempId) {
            return msg.copyWith(
              id: sentMsg.id,
              seqId: sentMsg.seqId, // 回血
              status: MessageStatus.success,
              createdAt: sentMsg.createdAt,
            );
          }
          return msg;
        }).toList();

        // 刷新策略 (因为我刚发的消息可能是最新的)
        state = AsyncValue.data(_applyReadStatusStrategy(rawList, _maxReadSeqId));
      });
    } catch (e) {
      debugPrint('❌ sendMessage error: $e');
      _updateState((list) => list.map((m) =>
      m.id == tempId ? m.copyWith(status: MessageStatus.failed) : m
      ).toList());
    }
  }

  // ===========================================================================
  // 📡 4. 接收与事件 (Receiving)
  // ===========================================================================

  void _onSocketMessage(Map<String, dynamic> data) {
    if (!mounted) return;
    try {
      final msg = SocketMessage.fromJson(data);
      if (msg.conversationId != conversationId) return;
      // 🚨🚨🚨 核心修复：获取当前最新的 UserID，而不是用构造函数里那个旧的
      // 因为 luckyProvider 可能会在 Notifier 初始化之后才更新 UserInfo
      final currentUserId = _ref.read(luckyProvider).userInfo?.id ?? "";

      // A. 自己的消息回包
      if (msg.senderId == currentUserId) {
        if (msg.tempId != null) {
          state.whenData((list) {
            final rawList = list.map((m) {
              if (m.id == msg.tempId) {
                return m.copyWith(
                  id: msg.id,
                  seqId: msg.seqId, // 回血
                  status: MessageStatus.success,
                  createdAt: msg.createdAt,
                );
              }
              return m;
            }).toList();
            state = AsyncValue.data(_applyReadStatusStrategy(rawList, _maxReadSeqId));
          });
        }
        return;
      }

      // B. 别人的消息

      // 1.  修复点：标记任务并触发管道，但绝对不要直接调 markAsRead()
      _hasPendingRead = true;
      //我们往里面塞什么数据根本不重要，重要的是 “往里塞”这个动作本身
      //那么 null 就是最完美的占位符。
      _readReceiptSubject.add(null);

      final newUiMsg = ChatUiModel(
        id: msg.id,
        seqId: msg.seqId,
        content: msg.content,
        type: MessageType.text,
        isMe: false,
        status: MessageStatus.success,
        createdAt: msg.createdAt,
        senderName: msg.sender?.nickname,
        senderAvatar: msg.sender?.avatar,
      );

      state.whenData((currentList) {
        if (currentList.any((m) => m.id == newUiMsg.id)) return;
        final rawList = [newUiMsg, ...currentList];
        state = AsyncValue.data(_applyReadStatusStrategy(rawList, _maxReadSeqId));

        // ❌ 删除了这里的 markAsRead(); 防止穿透防抖
      });
    } catch (e) {
      debugPrint("❌ Socket Parse Error: $e");
    }
  }

  void _onReadStatusUpdate(SocketReadEvent event) {
    if (!mounted) return;
    if (event.conversationId != conversationId) return;
    if (event.readerId == myUserId) return;

    if (event.lastReadSeqId > _maxReadSeqId) {
      _maxReadSeqId = event.lastReadSeqId;
    }

    state.whenData((list) {
      final newList = _applyReadStatusStrategy(list, _maxReadSeqId);
      state = AsyncValue.data(newList);
    });
  }

  // ===========================================================================
  // 🧠 5. 策略与辅助
  // ===========================================================================

  List<ChatUiModel> _applyReadStatusStrategy(List<ChatUiModel> currentList, int waterLine) {
    bool hasFoundLatestRead = false;

    return currentList.map((msg) {
      if (!msg.isMe || msg.status == MessageStatus.sending || msg.status == MessageStatus.failed || msg.seqId == null) {
        return msg;
      }

      if (msg.seqId! <= waterLine) {
        if (!hasFoundLatestRead) {
          hasFoundLatestRead = true;
          return msg.copyWith(status: MessageStatus.read);
        } else {
          return msg.copyWith(status: MessageStatus.success);
        }
      }
      return msg.copyWith(status: MessageStatus.success);
    }).toList();
  }

  void markAsRead() {
    if (!mounted) return;
    _ref.read(conversationListProvider.notifier).clearUnread(conversationId);
    // API 请求是独立的 HTTP，依然可以发
    Api.messageMarkAsReadApi(MessageMarkReadRequest(conversationId: conversationId)).catchError((e) {
      debugPrint("❌ markAsRead API Error: $e");
    });
  }

  void _updateConversationList(String text, int time) {
    try {
      //  防弹衣：同上
      _ref.read(conversationListProvider.notifier).updateLocalItem(
        conversationId: conversationId,
        lastMsgContent: text,
        lastMsgTime: time,
      );
    } catch (e) {
      debugPrint("⚠️ [ChatRoom] 列表页已销毁，跳过预览更新");
    }
  }

  void _updateState(List<ChatUiModel> Function(List<ChatUiModel>) action) {
    state.whenData((list) {
      state = AsyncValue.data(action(list));
    });
  }

  List<ChatUiModel> _mapToUiModels(List<dynamic> dtoList) {
    return dtoList.map((dto) {
      return ChatUiModel(
        id: dto.id,
        seqId: dto.seqId,
        content: dto.content,
        type: MessageType.text,
        isMe: dto.isSelf,
        status: MessageStatus.success,
        createdAt: dto.createdAt,
        senderName: dto.sender?.nickname,
        senderAvatar: dto.sender?.avatar,
      );
    }).toList();
  }

  @override
  void dispose() {
    _socketService.leaveChatRoom(conversationId);
    _msgSub?.cancel();
    _readStatusSub?.cancel();
    _connectionSub?.cancel();

    // 1. 临终遗言：Flush
    if (_hasPendingRead) {
      debugPrint("🧟‍♂️ [Rx] 页面关闭，强制发送最后一次已读");
      //  修复点：直接调用 API，不要调 markAsRead()，因为它检查 mounted
      Api.messageMarkAsReadApi(MessageMarkReadRequest(conversationId: conversationId));
    }

    // 2. 关闭管道
    _readReceiptSubject.close();

    super.dispose();
  }
}

// Provider 定义
final chatRoomProvider = StateNotifierProvider.family
    .autoDispose<ChatRoomNotifier, AsyncValue<List<ChatUiModel>>, String>((
    ref,
    conversationId,
    ) {
  //  缓存 5 分钟
  ref.cacheFor(const Duration(minutes: 5));

  // 2. 🛑 必须用 read！Socket 变了不重置
  final socketService = ref.read(socketServiceProvider);

  //Socket 连接 -> 触发 ServerTimeHelper -> 更新 LuckyStore (校准时间)
  //ChatRoomProvider 里写了 ref.watch(luckyProvider)。
  //连锁崩盘：

  //Store 一变 -> Provider 认为依赖变了 -> 销毁旧的 ChatRoomNotifier -> 创建新的。

  //此时旧的 Notifier 还在 await API，等它回来想更新 UI 时，发现自己已经“死”了 (mounted=false)。

  //新的 Notifier 虽然出生了，但因为 UI 的 initState 只跑一次，没人喊它 refresh，所以 UI 就一直 Loading。
  // 3. 🛑🛑🛑 核心修复：必须用 read！
  // 你的 ServerTimeHelper 可能会频繁更新 luckyProvider，
  // 如果用 watch，会导致 ChatRoomNotifier 在刷新数据的过程中被杀掉！
  // 这里的 id 只要取一次就行了。
  final myUserId = ref.read(luckyProvider.select((state) => state.userInfo?.id));

  return ChatRoomNotifier(
    socketService,
    conversationId,
    myUserId ?? '',
    ref,
  );
});