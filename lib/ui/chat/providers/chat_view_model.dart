import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/api/lucky_api.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart';
import '../models/chat_ui_model_mapper.dart';
import '../repository/message_repository.dart';
import '../services/database/local_database_service.dart';

class ChatListState {
  final List<ChatUiModel> messages;
  final bool isLoadingMore;
  final bool isInitializing;
  final bool hasMore;

  ChatListState({
    this.messages = const [],
    this.isLoadingMore = false,
    this.isInitializing = false,
    this.hasMore = true,
  });

  ChatListState copyWith({
    List<ChatUiModel>? messages,
    bool? isLoadingMore,
    bool? isInitializing,
    bool? hasMore,
  }) {
    return ChatListState(
      messages: messages ?? this.messages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isInitializing: isInitializing ?? this.isInitializing,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ChatViewModel extends StateNotifier<ChatListState> {
  final String conversationId;
  final Ref ref; // 2. 需要 ref 才能读取 Repository Provider

  // 3. 声明 Repository
  late final MessageRepository _repo;

  // _dbService 依然保留，用于 watchMessages 流监听（Repo主要负责写，DB负责读流）
  final LocalDatabaseService _dbService = LocalDatabaseService();

  StreamSubscription? _subscription;
  int _currentLimit = 50;

  // 4. 构造函数注入 ref 并初始化 _repo
  ChatViewModel(this.conversationId, this.ref) : super(ChatListState()) {
    _repo = ref.read(messageRepositoryProvider);
    _init();
  }

  void _init() {
    _subscribeToStream();
    performIncrementalSync();
  }

  void _subscribeToStream() {
    _subscription?.cancel();
    _subscription = _dbService.watchMessages(conversationId, limit: _currentLimit).listen((msgs) {
      if (mounted) {
        state = state.copyWith(messages: msgs);
      }
    });
  }

  // ============================================================
  //  核心：增量同步算法 (空洞检测 + 递归补齐 + 状态自愈)
  // ============================================================

  Future<void> performIncrementalSync() async {
    if (!mounted) return;
    if (state.isInitializing) return;

    // 上锁
    state = state.copyWith(isInitializing: true);

    try {
      // 5. 改为使用 Repo 获取 SeqId
      final localMaxSeqId = await _repo.getMaxSeqId(conversationId);

      // 2. 问询：拉取服务器最新的第一页
      final response = await Api.chatMessagesApi(
        MessageHistoryRequest(
          conversationId: conversationId,
          pageSize: 20,
          cursor: null,
        ),
      );

      if (!mounted) return;

      if (response.list.isNotEmpty) {
        final firstMsg = response.list.first;
        final int serverMaxSeqId = (firstMsg.seqId ?? 0);

        // 4. 决策：是否存在空洞？
        if (localMaxSeqId > 0 && serverMaxSeqId > localMaxSeqId) {
          debugPrint(" [Sync] 发现消息空洞: 本地 $localMaxSeqId, 服务器 $serverMaxSeqId");

          final lastMsg = response.list.last;
          final int oldestInThisPage = (lastMsg.seqId ?? 0);

          if (oldestInThisPage <= localMaxSeqId) {
            // A-1: 缝合成功
            await _saveApiMessages(response.list);
          } else {
            // A-2: 鸿沟太大，启动递归
            debugPrint(" [Sync] 空洞过大，启动递归补齐机制...");
            await _recursiveSyncGap(localMaxSeqId, oldestInThisPage);
            await _saveApiMessages(response.list);
          }
        } else {
          // 情况 B：无空洞或本地为空
          await _saveApiMessages(response.list);
        }
      }

      if (response.list.length < 20) {
        state = state.copyWith(hasMore: false);
      }

      // =====================================================
      // 冷启动状态自愈
      // =====================================================
      try {
        // A. 问服务器：“这个会话我现在有多少未读？”
        final remoteConv = await Api.chatDetailApi(conversationId);

        // B. 问本地数据库
        final localConv = await _repo.getConversation(conversationId);
        final int localUnread = localConv?.unreadCount ?? 0;

        // C. 决策逻辑：服务器说0，本地说>0 -> 强制自愈
        if (remoteConv.unreadCount == 0 && localUnread > 0) {
          debugPrint(" [Sync] 发现状态不同步！正在静默修复...");

          // 1. 计算当前已知的最大 SeqId，把之前的消息都标为已读
          // (为了让本地数据库里的 message status 变成 read)
          int targetReadSeqId = localMaxSeqId;
          if (response.list.isNotEmpty) {
            final firstMsg = response.list.first;
            final int serverTopSeq = (firstMsg.seqId ?? 0);
            if (serverTopSeq > targetReadSeqId) {
              targetReadSeqId = serverTopSeq;
            }
          }
          await _repo.markAsReadLocally(conversationId, targetReadSeqId);

          // 2. 强制把红点抹平！(只调用一次)
          await _repo.forceClearUnread(conversationId);

          debugPrint(" [Sync] 红点已静默消除。");
        }
      } catch (e) {
        debugPrint(" [Sync] Self-healing check failed: $e");
      }
      // =====================================================

    } catch (e) {
      debugPrint(" [Sync] 增量同步失败: $e");
    } finally {
      if (mounted) state = state.copyWith(isInitializing: false);
    }
  }

  /// 辅助：递归向后追溯
  Future<void> _recursiveSyncGap(int targetSeqId, int currentCursor) async {
    debugPrint("  [Sync] 正在抓取 cursor 之前的消息: $currentCursor");
    try {
      final response = await Api.chatMessagesApi(
        MessageHistoryRequest(
          conversationId: conversationId,
          pageSize: 50,
          cursor: currentCursor,
        ),
      );

      if (response.list.isEmpty) return;

      await _saveApiMessages(response.list);

      final lastMsg = response.list.last;
      final int oldestSeq = (lastMsg.seqId ?? 0);

      if (oldestSeq > targetSeqId) {
        await _recursiveSyncGap(targetSeqId, oldestSeq);
      } else {
        debugPrint(" [Sync] 鸿沟已完全缝合！");
      }
    } catch(e) {
      debugPrint("  [Sync] 递归失败: $e");
    }
  }

  /// 内部工具：入库
  Future<void> _saveApiMessages(List<dynamic> apiMsgs) async {
    final uiMsgs = apiMsgs.map((m) => ChatUiModelMapper.fromApiModel(m, conversationId)).toList();

    // 8. [关键防御] 改为使用 Repo.saveBatch
    // 这确保了如果服务器没返回图片路径，本地的高清图不会被覆盖
    await _repo.saveBatch(uiMsgs);
  }

  // ============================================================
  //  上拉加载更多
  // ============================================================

  Future<void> loadMore() async {
    if (state.messages.length < 20) {
      state = state.copyWith(hasMore: false);
      return;
    }

    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    _currentLimit += 50;
    _subscribeToStream();

    await Future.delayed(const Duration(milliseconds: 100));
    final newLength = state.messages.length;

    if (newLength < _currentLimit) {
      await _fetchHistoryFromApi();
    } else {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _fetchHistoryFromApi() async {
    try {
      if (state.messages.isEmpty) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }

      final oldestMsg = state.messages.last;
      final cursor = oldestMsg.seqId;

      if (cursor == null) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }

      final response = await Api.chatMessagesApi(
        MessageHistoryRequest(
          conversationId: conversationId,
          pageSize: 50,
          cursor: cursor,
        ),
      );

      if (response.list.isEmpty) {
        state = state.copyWith(hasMore: false, isLoadingMore: false);
      } else {
        await _saveApiMessages(response.list);
        if (response.list.length < 50) {
          state = state.copyWith(hasMore: false, isLoadingMore: false);
        } else {
          state = state.copyWith(isLoadingMore: false);
        }
      }
    } catch (e) {
      debugPrint(" 拉取历史失败: $e");
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

// 9. Provider 定义也要改，传入 ref
final chatViewModelProvider = StateNotifierProvider.family.autoDispose<ChatViewModel, ChatListState, String>(
      (ref, conversationId) {
    return ChatViewModel(conversationId, ref);
  },
);