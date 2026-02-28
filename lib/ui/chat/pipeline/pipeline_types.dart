import 'package:cross_file/cross_file.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';

/// Context container that carries state across the media processing pipeline.
class PipelineContext {
  /// The original message model that initiated the pipeline.
  final ChatUiModel initialMsg;

  /// Tracks the current absolute file path, which may change during compression.
  String? currentAbsolutePath;

  /// Local AssetID for the generated thumbnail (Mobile-specific).
  String? thumbAssetId;

  /// The final remote URL of the main content after a successful upload.
  String? remoteUrl;

  /// The final remote URL of the thumbnail after a successful upload.
  String? remoteThumbUrl;

  /// Accumulated metadata to be synchronized with the backend.
  Map<String, dynamic> metadata = {};

  /// Web: Preserves the original XFile to maintain filename and extension integrity.
  XFile? sourceFile;

  /// Web: In-memory thumbnail file utilized by UploadStep for direct cloud transfer.
  XFile? webThumbFile;

  PipelineContext(this.initialMsg) {
    // Initialize metadata from the initial message state
    if (initialMsg.meta != null) metadata.addAll(initialMsg.meta!);

    // Resolve initial remote thumbnail URLs if already present in meta
    remoteThumbUrl = initialMsg.meta?['thumb'] ?? initialMsg.meta?['remote_thumb'];

    // Default the processing path to the message's local path
    currentAbsolutePath = initialMsg.localPath;
  }
}

/// Interface for individual atomic operations within the media pipeline.
abstract class PipelineStep {
  /// Executes the specific logic of the step using the shared context.
  /// [service]: Typically an instance of MediaSendService or a similar coordinator.
  Future<void> execute(PipelineContext ctx, dynamic service);
}