import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/api/lucky_api.dart';
import 'package:flutter_app/core/store/user_store.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart';
import '../providers/conversation_provider.dart';
import '../repository/message_repository.dart';
import '../services/database/local_database_service.dart';

class ChatListState {
  final List<ChatUiModel> messages;
  final bool isLoadingMore;
  final bool isInitializing;
  final bool hasMore;

  // AI streaming state (for SUPPORT/AI conversations)
  final bool isAiStreaming;
  final String currentAiToken;
  final String aiStatusText;

  ChatListState({
    this.messages = const [],
    this.isLoadingMore = false,
    this.isInitializing = false,
    this.hasMore = true,
    this.isAiStreaming = false,
    this.currentAiToken = '',
    this.aiStatusText = '',
  });

  ChatListState copyWith({
    List<ChatUiModel>? messages,
    bool? isLoadingMore,
    bool? isInitializing,
    bool? hasMore,
    bool? isAiStreaming,
    String? currentAiToken,
    String? aiStatusText,
    bool clearAiError = false,
  }) {
    return ChatListState(
      messages: messages ?? this.messages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isInitializing: isInitializing ?? this.isInitializing,
      hasMore: hasMore ?? this.hasMore,
      isAiStreaming: isAiStreaming ?? this.isAiStreaming,
      currentAiToken: currentAiToken ?? this.currentAiToken,
      aiStatusText: aiStatusText ?? this.aiStatusText,
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

  void _init() async {
    // Step 0: Ensure database is initialized before any DB operations
    // Without this, getHistory() and performIncrementalSync() silently fail
    // when entering ChatPage directly (e.g. via CustomerServiceHelper.startChat())
    // without first going through ConversationList which initializes the DB.
    try {
      final currentUserId = ref.read(userProvider)?.id;
      if (currentUserId != null) {
        await _repo.initDatabase(currentUserId);
      }
    } catch (_) {}

    // Step 1: Pre-warm from local DB immediately so the first frame renders real content
    // instead of an empty skeleton. This eliminates the blank-screen-with-spinner on entry.
    try {
      final cached = await _repo.getHistory(
        conversationId: conversationId,
        limit: _currentLimit,
      );
      if (cached.isNotEmpty && mounted) {
        state = state.copyWith(messages: cached);
      }
    } catch (_) {}

    // Step 2: Subscribe to reactive stream for ongoing real-time updates
    _subscribeToStream();

    // Step 3: Background network sync (WeChat-style: content visible, AppBar spinner indicates sync)
    performIncrementalSync();
  }

  /// Listens to local database changes to update the UI reactively
  void _subscribeToStream() {
    _subscription?.cancel();
    _subscription = _dbService
        .watchMessages(conversationId, limit: _currentLimit)
        .listen((msgs) {
          if (mounted) {
            state = state.copyWith(messages: msgs);
          }
        });
  }

  // ============================================================
  // Core: Incremental Sync Algorithm (Gap Detection & Healing)
  // ============================================================

  int _syncRetryCount = 0;
  static const int _maxSyncRetries = 3;

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

      // 2b. Retry mechanism for new conversations (server may not be ready yet)
      // Newly created business/support conversations may have no messages on the
      // first fetch because the server-side initialization (welcome message, etc.)
      // hasn't completed yet. We retry with a delay to give the server time.
      if (response.list.isEmpty &&
          localMaxSeqId == 0 &&
          _syncRetryCount < _maxSyncRetries) {
        _syncRetryCount++;
        debugPrint(
          "[Sync] New conversation, empty response from server. "
          "Retry $_syncRetryCount of $_maxSyncRetries in 2s...",
        );
        if (mounted) state = state.copyWith(isInitializing: false);
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        return performIncrementalSync();
      }

      // Reset retry counter on success
      _syncRetryCount = 0;

      if (response.list.isNotEmpty) {
        final firstMsg = response.list.first;
        final int serverMaxSeqId = (firstMsg.seqId ?? 0);

        // 3. Decision: Does a gap exist between local and server sequence IDs?
        if (localMaxSeqId > 0 && serverMaxSeqId > localMaxSeqId) {
          debugPrint(
            "[Sync] Gap detected: Local $localMaxSeqId, Server $serverMaxSeqId",
          );

          final lastMsg = response.list.last;
          final int oldestInThisPage = (lastMsg.seqId ?? 0);

          if (oldestInThisPage <= localMaxSeqId) {
            // Scenario A-1: Gap bridged within the current page
            await _saveApiMessages(response.list);
          } else {
            // Scenario A-2: Large gap detected; trigger recursive back-fill
            debugPrint(
              "[Sync] Large gap detected; initiating recursive bridge...",
            );
            await _recursiveSyncGap(localMaxSeqId, oldestInThisPage);
            await _saveApiMessages(response.list);
          }
        } else {
          // Scenario B: No gap or fresh database
          await _saveApiMessages(response.list);
        }

        // 4. Invalidate conversation list so the new conversation appears immediately
        // when the user navigates back to the conversation list page.
        // This handles the case where CustomerServiceHelper.startChat() creates a
        // new business/support conversation but doesn't have ref access to invalidate.
        try {
          ref.invalidate(conversationListProvider);
        } catch (_) {
          // Safeguard: invalidation failures are non-critical
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
          debugPrint(
            "[Sync] State mismatch detected; performing silent healing...",
          );

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
    } catch (e) {
      debugPrint("[Sync] Recursive sync failed: $e");
    }
  }

  /// Internal utility: Maps and persists API messages to local storage
  Future<void> _saveApiMessages(List<dynamic> apiMsgs) async {
    final currentUserId = ref.read(userProvider)?.id;
    final uiMsgs = apiMsgs
        .map((m) => ChatUiModelMapper.fromApiModel(
              m,
              conversationId,
              currentUserId,
            ))
        .toList();

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

  // ============================================================
  // AI Streaming State (Socket ai_token / ai_done)
  // ============================================================

  /// Update AI streaming token (called by ChatEventHandler._onAiEvent)
  void updateAiToken(String token) {
    if (!mounted) return;
    state = state.copyWith(
      currentAiToken: state.currentAiToken + token,
      isAiStreaming: true,
    );
  }

  /// Update AI status text (called by ChatEventHandler._onAiEvent for step events)
  void updateAiStatusText(String text) {
    if (!mounted) return;
    state = state.copyWith(aiStatusText: text, isAiStreaming: true);
  }

  /// Clear AI streaming state (called by ChatEventHandler on ai_done)
  void clearAiStreaming() {
    if (!mounted) return;
    state = state.copyWith(
      isAiStreaming: false,
      currentAiToken: '',
      aiStatusText: '',
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider definition with Ref injection for repository access
final chatViewModelProvider = StateNotifierProvider.family
    .autoDispose<ChatViewModel, ChatListState, String>((ref, conversationId) {
      return ChatViewModel(conversationId, ref);
    });
