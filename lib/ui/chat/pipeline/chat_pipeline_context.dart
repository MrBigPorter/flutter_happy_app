import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatPipelineContext {
  // Base information
  final Ref ref;
  final Map<String, dynamic> rawData;
  final String currentUserId;

  // 2. Intermediate product (parsed message is stored here)
  ChatUiModel? uiMsg;

  // 3. Control switch (set to true to stop the pipeline)
  bool isAborted = false;

  ChatPipelineContext({
    required this.ref,
    required this.rawData,
    required this.currentUserId,
  });

  // A helper method to abort the pipeline process
  void abort(String reason) {
    isAborted = true;
    print("[Pipeline Aborted] $reason");
  }
}