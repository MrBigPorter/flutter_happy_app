import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/api/lucky_api.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart';
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
  final LocalDatabaseService _dbService = LocalDatabaseService();

  StreamSubscription? _subscription;
  int _currentLimit = 50;

  // 1. 构造函数：创建即启动 (First Load)
  ChatViewModel(this.conversationId) : super(ChatListState()) {
    _init();
  }

  void _init() {
    _subscribeToStream();
    //  入口 A：首次进房，ViewModel 自动发起同步
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
  //  核心：增量同步算法 (空洞检测 + 递归补齐)
  // ============================================================

  Future<void> performIncrementalSync() async {
    if (!mounted) return;

    //  [核心修改] 防重入锁 (Re-entry Lock)
    // 如果已经在初始化中（正在拉API），直接挡回去，防止 Handler 和 Constructor 同时调用
    if (state.isInitializing) {
      debugPrint(" [ViewModel] $conversationId 正在同步中，拦截重复请求");
      return;
    }

    // 上锁
    state = state.copyWith(isInitializing: true);

    try {
      // 1. 查账：获取本地最后一条“正式报纸”的编号
      final localMaxSeqId = await _dbService.getMaxSeqId(conversationId);

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
        // 3. 对比：服务器最顶端的编号
        final serverMaxSeqId = response.list.first.seqId ?? 0;

        // 4. 决策：是否存在空洞？
        if (localMaxSeqId != null && serverMaxSeqId > localMaxSeqId) {
          // 情况 A：发现空洞！
          debugPrint(" [Sync] 发现消息空洞: 本地 $localMaxSeqId, 服务器 $serverMaxSeqId");

          final oldestInThisPage = response.list.last.seqId ?? 0;

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

      // 如果数据不足一页，标记没有更多历史
      if (response.list.length < 20) {
        state = state.copyWith(hasMore: false);
      }
    } catch (e) {
      debugPrint(" [Sync] 增量同步失败: $e");
    } finally {
      //  [核心修改] 无论成功失败，一定要解锁
      if (mounted) state = state.copyWith(isInitializing: false);
    }
  }

  /// 辅助：递归向后追溯
  Future<void> _recursiveSyncGap(int targetSeqId, int currentCursor) async {
    debugPrint("  [Sync] 正在抓取 cursor 之前的消息: $currentCursor");
    final response = await Api.chatMessagesApi(
      MessageHistoryRequest(
        conversationId: conversationId,
        pageSize: 50,
        cursor: currentCursor,
      ),
    );

    if (response.list.isEmpty) return;

    await _saveApiMessages(response.list);

    final oldestSeq = response.list.last.seqId ?? 0;
    if (oldestSeq > targetSeqId) {
      await _recursiveSyncGap(targetSeqId, oldestSeq);
    } else {
      debugPrint(" [Sync] 鸿沟已完全缝合！");
    }
  }

  /// 内部工具：入库
  Future<void> _saveApiMessages(List<ChatMessage> apiMsgs) async {
    final uiMsgs = apiMsgs.map((m) => ChatUiModelMapper.fromApiModel(m, conversationId)).toList();
    await _dbService.saveMessages(uiMsgs);
  }

  // ============================================================
  //  上拉加载更多 (保持不变)
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

final chatViewModelProvider = StateNotifierProvider.family.autoDispose<ChatViewModel, ChatListState, String>(
      (ref, conversationId) {
    return ChatViewModel(conversationId);
  },
);