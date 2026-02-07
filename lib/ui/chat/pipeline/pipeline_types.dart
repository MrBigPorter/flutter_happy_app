import 'package:cross_file/cross_file.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';

class PipelineContext {
  final ChatUiModel initialMsg;

  String? currentAbsolutePath;
  String? thumbAssetId;

  String? remoteUrl;
  String? remoteThumbUrl;

  Map<String, dynamic> metadata = {};

  /// Web 端用于保留原始 XFile（文件名/后缀）
  XFile? sourceFile;

  /// ✅ Web 端：内存封面文件（UploadStep 直接用它上传）
  XFile? webThumbFile;

  PipelineContext(this.initialMsg) {
    if (initialMsg.meta != null) metadata.addAll(initialMsg.meta!);

    remoteThumbUrl = initialMsg.meta?['thumb'] ?? initialMsg.meta?['remote_thumb'];

    currentAbsolutePath = initialMsg.localPath;
  }
}

abstract class PipelineStep {
  Future<void> execute(PipelineContext ctx, dynamic service);
}