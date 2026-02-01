import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/api/lucky_api.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart'; // 引入 Request/Response 模型
import '../services/database/local_database_service.dart';

// 1. 状态类
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

// 2. 核心控制器
class ChatViewModel extends StateNotifier<ChatListState> {
  final String conversationId;
  final LocalDatabaseService _dbService = LocalDatabaseService();

  StreamSubscription? _subscription;
  int _currentLimit = 50;

  ChatViewModel(this.conversationId) : super(ChatListState()) {
    _init();
  }

  void _init() {
    // 1. 监听本地 DB (保证有缓存立马显示)
    _subscribeToStream();
    // 2. 同时发起网络请求 (解决冷启动/卸载重装无数据问题)
    _fetchLatestFromApi();
  }

  void _subscribeToStream() {
    _subscription?.cancel();
    _subscription = _dbService.watchMessages(conversationId, limit: _currentLimit).listen((msgs) {
      if (mounted) {
        state = state.copyWith(messages: msgs);
      }
    });
  }

  //  场景 A：进页面初始化 (拉取最新)
  Future<void> _fetchLatestFromApi() async {
    if (!mounted) return;
    state = state.copyWith(isInitializing: true);

    try {
      // 这里的 cursor 传 null，代表拉取最新的第一页
      final response = await Api.chatMessagesApi(
        MessageHistoryRequest(
          conversationId: conversationId,
          pageSize: 50, // 保持和 limit 一致
          cursor: null,
        ),
      );

      // 结果入库
      if (response.list.isNotEmpty) {
        final uiMsgs = response.list.map((m) => ChatUiModelMapper.fromApiModel(m, conversationId)).toList();
        await _dbService.saveMessages(uiMsgs);
      }
    } catch (e) {
      debugPrint(" 初始化拉取失败: $e");
    } finally {
      if (mounted) state = state.copyWith(isInitializing: false);
    }
  }

  //  场景 B：上拉加载更多 (拉取历史)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    // 1. 先尝试扩大本地窗口
    final oldLength = state.messages.length;
    _currentLimit += 50;
    _subscribeToStream();

    // 等待 DB 响应
    await Future.delayed(const Duration(milliseconds: 100));
    final newLength = state.messages.length;

    // 2. 如果扩大窗口后数据量没怎么变，说明本地缓存不够了，去服务器拉
    if (newLength < _currentLimit) {
      debugPrint(" 本地缓存耗尽，启动网络拉取...");
      await _fetchHistoryFromApi();
    } else {
      // 本地够用，结束 loading
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _fetchHistoryFromApi() async {
    try {
      if (state.messages.isEmpty) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }

      //  核心修正：直接取 int 类型的 seqId
      // messages 是倒序的，last 是最老的一条
      final oldestMsg = state.messages.last;
      final cursor = oldestMsg.seqId; // 这里是 int?

      if (cursor == null) {
        // 如果没有 seqId (可能是发送失败的消息)，停止加载
        state = state.copyWith(isLoadingMore: false);
        return;
      }

      debugPrint(" API 请求历史: cursor(seqId)=$cursor");

      final response = await Api.chatMessagesApi(
        MessageHistoryRequest(
          conversationId: conversationId,
          pageSize: 50,
          cursor: cursor, //  直接传 int，完美匹配 DTO
        ),
      );

      if (response.list.isEmpty) {
        // 后端没数据了
        state = state.copyWith(hasMore: false, isLoadingMore: false);
      } else {
        // 入库 -> Sembast 自动通知 UI -> 列表变长
        final uiMsgs = response.list.map((m) => ChatUiModelMapper.fromApiModel(m, conversationId)).toList();
        await _dbService.saveMessages(uiMsgs);
        state = state.copyWith(isLoadingMore: false);
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