import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:uuid/uuid.dart';

/// AI 聊天状态
class AiChatState {
  /// 消息列表
  final List<ChatUiModel> messages;

  /// 是否正在接收 SSE 流
  final bool isReceiving;

  /// 当前正在累积的 AI 回复内容（打字机效果用）
  final String currentStreamContent;

  /// 当前 SSE 流中正在处理的会话 ID，用于构建 ai 消息
  final String currentAiMessageId;

  /// 会话 ID（前后端对齐，用于维持 LangGraph 上下文）
  final String sessionId;

  /// 当前状态文本（如 "正在分析您的问题..."）
  final String statusText;

  /// 是否有错误
  final String? error;

  /// 流是否已完成
  final bool isStreamComplete;

  const AiChatState({
    this.messages = const [],
    this.isReceiving = false,
    this.currentStreamContent = '',
    this.currentAiMessageId = '',
    required this.sessionId,
    this.statusText = '',
    this.error,
    this.isStreamComplete = false,
  });

  /// 初始状态
  factory AiChatState.initial() {
    // 尝试从 SharedPreferences 恢复 sessionId，默认为新生成
    return AiChatState(
      sessionId: const Uuid().v4(),
    );
  }

  AiChatState copyWith({
    List<ChatUiModel>? messages,
    bool? isReceiving,
    String? currentStreamContent,
    String? currentAiMessageId,
    String? sessionId,
    String? statusText,
    String? error,
    bool? isStreamComplete,
    bool clearError = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isReceiving: isReceiving ?? this.isReceiving,
      currentStreamContent: currentStreamContent ?? this.currentStreamContent,
      currentAiMessageId: currentAiMessageId ?? this.currentAiMessageId,
      sessionId: sessionId ?? this.sessionId,
      statusText: statusText ?? this.statusText,
      error: clearError ? null : (error ?? this.error),
      isStreamComplete: isStreamComplete ?? this.isStreamComplete,
    );
  }

  /// 用户发送消息时添加用户消息
  AiChatState addUserMessage({
    required String content,
    required String conversationId,
  }) {
    final msg = ChatUiModel(
      id: const Uuid().v4(),
      content: content,
      type: MessageType.text,
      isMe: true,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      conversationId: conversationId,
    );
    return copyWith(
      // 最新消息放前面（和 IM 保持一致：messages[0] = 最新）
      messages: [msg, ...messages],
    );
  }

  /// 创建 AI 回复的占位消息（开始接收流时调用）
  AiChatState startAiMessage({required String conversationId}) {
    final id = const Uuid().v4();
    final msg = ChatUiModel(
      id: id,
      content: '',
      type: MessageType.ai,
      isMe: false,
      status: MessageStatus.pending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      conversationId: conversationId,
    );
    return copyWith(
      // 最新消息放前面（AI 回复是当前最新消息）
      messages: [msg, ...messages],
      currentAiMessageId: id,
      currentStreamContent: '',
      isReceiving: true,
      isStreamComplete: false,
      error: null,
    );
  }

  /// 追加 AI token（打字机效果）
  AiChatState appendToken(String token) {
    final newContent = currentStreamContent + token;
    final updatedMessages = messages.map((m) {
      if (m.id == currentAiMessageId) {
        return m.copyWith(content: newContent);
      }
      return m;
    }).toList();
    return copyWith(
      messages: updatedMessages,
      currentStreamContent: newContent,
    );
  }

  /// 完成 AI 回复
  AiChatState completeAiMessage() {
    final updatedMessages = messages.map((m) {
      if (m.id == currentAiMessageId) {
        return m.copyWith(status: MessageStatus.success);
      }
      return m;
    }).toList();
    return copyWith(
      messages: updatedMessages,
      currentAiMessageId: '',
      currentStreamContent: '',
      isReceiving: false,
      isStreamComplete: true,
      statusText: '',
    );
  }

  /// 流发生错误
  AiChatState setError(String error) {
    // 如果有正在生成的 AI 消息
    var updatedMessages = messages;
    if (currentAiMessageId.isNotEmpty) {
      if (currentStreamContent.isNotEmpty) {
        // 已有流内容：标记为 failed，保留已有内容
        updatedMessages = messages.map((m) {
          if (m.id == currentAiMessageId) {
            return m.copyWith(
              content: currentStreamContent,
              status: MessageStatus.failed,
            );
          }
          return m;
        }).toList();
      } else {
        // 无内容：移除空白 AI 消息，不给用户看空气泡
        updatedMessages = messages.where((m) => m.id != currentAiMessageId).toList();
      }
    }
    return copyWith(
      messages: updatedMessages,
      currentAiMessageId: '',
      currentStreamContent: '',
      isReceiving: false,
      error: error,
      statusText: '',
    );
  }
}
