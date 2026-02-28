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
  final Ref ref;

  late final MessageRepository _repo;

  // DB service handles stream watching while Repo handles data persistence and business logic
  final LocalDatabaseService _dbService = LocalDatabaseService();

  StreamSubscription? _subscription;
  int _currentLimit = 50;

  ChatViewModel(this.conversationId, this.ref) : super(ChatListState()) {
    _repo = ref.read(messageRepositoryProvider);
    _init();
  }

  void _init() {
    _subscribeToStream();
    performIncrementalSync();
  }

  /// Listens to local database changes to update the UI reactively
  void _subscribeToStream() {
    _subscription?.cancel();
    _subscription = _dbService.watchMessages(conversationId, limit: _currentLimit).listen((msgs) {
      if (mounted) {
        state = state.copyWith(messages: msgs);
      }
    });
  }

  // ============================================================
  // Core: Incremental Sync Algorithm (Gap Detection & Healing)
  // ============================================================

  /// Synchronizes local message history with the server, filling missing sequence gaps
  Future<void> performIncrementalSync() async {
    if (!mounted) return;
    if (state.isInitializing) return;

    // Lock synchronization process
    state = state.copyWith(isInitializing: true);

    try {
      // 1. Retrieve the highest known SeqId in the local database
      final localMaxSeqId = await _repo.getMaxSeqId(conversationId);

      // 2. Fetch the latest page of messages from the server
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

        // 3. Decision: Does a gap exist between local and server sequence IDs?
        if (localMaxSeqId > 0 && serverMaxSeqId > localMaxSeqId) {
          debugPrint("[Sync] Gap detected: Local $localMaxSeqId, Server $serverMaxSeqId");

          final lastMsg = response.list.last;
          final int oldestInThisPage = (lastMsg.seqId ?? 0);

          if (oldestInThisPage <= localMaxSeqId) {
            // Scenario A-1: Gap bridged within the current page
            await _saveApiMessages(response.list);
          } else {
            // Scenario A-2: Large gap detected; trigger recursive back-fill
            debugPrint("[Sync] Large gap detected; initiating recursive bridge...");
            await _recursiveSyncGap(localMaxSeqId, oldestInThisPage);
            await _saveApiMessages(response.list);
          }
        } else {
          // Scenario B: No gap or fresh database
          await _saveApiMessages(response.list);
        }
      }

      if (response.list.length < 20) {
        state = state.copyWith(hasMore: false);
      }

      // =====================================================
      // Cold Boot State Self-Healing
      // =====================================================
      try {
        // A. Compare remote unread count with local status
        final remoteConv = await Api.chatDetailApi(conversationId);
        final localConv = await _repo.getConversation(conversationId);
        final int localUnread = localConv?.unreadCount ?? 0;

        // B. Resolution: If server says 0 but local says > 0, force local reset
        if (remoteConv.unreadCount == 0 && localUnread > 0) {
          debugPrint("[Sync] State mismatch detected; performing silent healing...");

          int targetReadSeqId = localMaxSeqId;
          if (response.list.isNotEmpty) {
            final firstMsg = response.list.first;
            final int serverTopSeq = (firstMsg.seqId ?? 0);
            if (serverTopSeq > targetReadSeqId) {
              targetReadSeqId = serverTopSeq;
            }
          }

          // Force local read status synchronization
          await _repo.markAsReadLocally(conversationId, targetReadSeqId);
          await _repo.forceClearUnread(conversationId);

          debugPrint("[Sync] Red dot state synchronized.");
        }
      } catch (e) {
        debugPrint("[Sync] Self-healing check failed: $e");
      }

    } catch (e) {
      debugPrint("[Sync] Incremental sync failed: $e");
    } finally {
      if (mounted) state = state.copyWith(isInitializing: false);
    }
  }

  /// Recursively fetches historical messages until the target SeqId is reached
  Future<void> _recursiveSyncGap(int targetSeqId, int currentCursor) async {
    debugPrint("[Sync] Stitching gap before cursor: $currentCursor");
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
        debugPrint("[Sync] Gap bridged successfully.");
      }
    } catch(e) {
      debugPrint("[Sync] Recursive sync failed: $e");
    }
  }

  /// Internal utility: Maps and persists API messages to local storage
  Future<void> _saveApiMessages(List<dynamic> apiMsgs) async {
    final uiMsgs = apiMsgs.map((m) => ChatUiModelMapper.fromApiModel(m, conversationId)).toList();

    // Architectural Defense: Uses saveBatch to prevent overwriting local HD images
    // with server-provided empty thumbnail paths.
    await _repo.saveBatch(uiMsgs);
  }

  // ============================================================
  // Pull-to-Load History
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
      debugPrint("[ChatViewModel] Fetch history failed: $e");
      state = state.copyWith(isLoadingMore: false);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider definition with Ref injection for repository access
final chatViewModelProvider = StateNotifierProvider.family.autoDispose<ChatViewModel, ChatListState, String>(
      (ref, conversationId) {
    return ChatViewModel(conversationId, ref);
  },
);