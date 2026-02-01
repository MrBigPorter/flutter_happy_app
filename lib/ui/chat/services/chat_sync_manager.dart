import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/core/api/lucky_api.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';

import '../models/conversation.dart';

// 专用的 loading 状态 provider
final chatLoadingMoreProvider = StateProvider.family<bool, String>((ref, id) => false);

class ChatSyncManager {
  final String conversationId;
  final Ref _ref;
  final String _currentUserId;

  int? _nextCursor;
  bool _isLoadingMore = false;
  int _maxReadSeqId = 0;

  ChatSyncManager(this.conversationId, this._ref, this._currentUserId);

  bool get hasMore => _nextCursor != null;

  /// 下拉刷新
  Future<void> refresh(Function() onReadMark) async {
    try {
      onReadMark(); // 刷新时顺便标记已读

      final response = await Api.chatMessagesApi(
          MessageHistoryRequest(conversationId: conversationId, pageSize: 20)
      );

      _maxReadSeqId = response.partnerLastReadSeqId;
      _nextCursor = response.nextCursor;

      final uiMsgs = _applyReadStatusLocally(_mapToUiModels(response.list), _maxReadSeqId);
      await LocalDatabaseService().saveMessages(uiMsgs);
    } catch (e) {
      debugPrint("Refresh Error: $e");
    }
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (_nextCursor == null || _isLoadingMore) return;

    _isLoadingMore = true;
    _ref.read(chatLoadingMoreProvider(conversationId).notifier).state = true;

    try {
      final response = await Api.chatMessagesApi(
          MessageHistoryRequest(
              conversationId: conversationId,
              pageSize: 20,
              cursor: _nextCursor
          )
      );

      _nextCursor = response.nextCursor;

      final uiMsgs = _applyReadStatusLocally(_mapToUiModels(response.list), _maxReadSeqId);
      await LocalDatabaseService().saveMessages(uiMsgs);
    } finally {
      _isLoadingMore = false;
      _ref.read(chatLoadingMoreProvider(conversationId).notifier).state = false;
    }
  }

  List<ChatUiModel> _mapToUiModels(List<dynamic> list) {
    return list.map((dto) => ChatUiModelMapper.fromApiModel(dto, conversationId, _currentUserId)).toList();
  }

  List<ChatUiModel> _applyReadStatusLocally(List<ChatUiModel> list, int waterLine) {
    return list.map((msg) {
      if (msg.isMe &&
          msg.status == MessageStatus.success &&
          msg.seqId != null &&
          msg.seqId! <= waterLine) {
        return msg.copyWith(status: MessageStatus.read);
      }
      return msg;
    }).toList();
  }
}