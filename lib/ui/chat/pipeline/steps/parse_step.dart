import 'dart:io';

import 'package:flutter_app/core/pipeline/pipeline_step.dart';
import 'package:flutter_app/ui/chat/pipeline/chat_pipeline_context.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

import '../../models/chat_ui_model_mapper.dart';

// Note: Declaring this class as a worker for <ChatPipelineContext>
class ParseStep extends PipelineStep<ChatPipelineContext> {

  @override
  Future<void> execute(ChatPipelineContext ctx) async {
    // 1. If the pipeline has been aborted, stop execution
    if (ctx.isAborted) return;

    final json = ctx.rawData;
    final socketMsg = SocketMessage.fromJson(json);

    // 2. Parse and generate the UI model, then store it back in the context
    ctx.uiMsg = ChatUiModelMapper.fromApiModel(
      ChatMessage(
        id: socketMsg.id,
        content: socketMsg.content,
        type: socketMsg.type,
        seqId: socketMsg.seqId,
        createdAt: socketMsg.createdAt,
        isSelf: false, // Message belongs to others
        meta: socketMsg.meta,
        sender: socketMsg.sender != null ? ChatSender(
            id: socketMsg.sender!.id,
            nickname: socketMsg.sender!.nickname,
            avatar: socketMsg.sender!.avatar
        ) : null,
      ),
      socketMsg.conversationId,
      ctx.currentUserId,
    );
  }
}