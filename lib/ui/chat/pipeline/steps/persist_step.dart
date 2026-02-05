import 'package:flutter_app/core/pipeline/pipeline_step.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import '../chat_pipeline_context.dart';

class PersistStep extends PipelineStep<ChatPipelineContext> {

  @override
  Future<void> execute(ChatPipelineContext ctx) async {
    // 1. check if the pipeline has been aborted
    if (ctx.isAborted) return;

    // 2. chack if there is a valid message to persist
    if (ctx.uiMsg == null) return;

    // 3. save the message to local database
    await LocalDatabaseService().handleIncomingMessage(ctx.uiMsg!);

    print("[Pipeline] Message persisted: ${ctx.uiMsg!.content}");
  }
}