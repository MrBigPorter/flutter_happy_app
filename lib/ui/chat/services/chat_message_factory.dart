import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';

class ChatMessageFactory {
  final String conversationId;
  final Uuid _uuid;

  ChatMessageFactory({required this.conversationId, Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  /// Returns current timestamp in milliseconds
  int _now() => DateTime.now().millisecondsSinceEpoch;

  /// Internal base builder for constructing unified message models
  ChatUiModel base({
    required String content,
    required MessageType type,
    String? localPath,
    Map<String, dynamic>? meta,
    int? duration,
    Uint8List? previewBytes,
  }) {
    return ChatUiModel(
      id: _uuid.v4(),
      conversationId: conversationId,
      content: content,
      type: type,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: _now(),
      localPath: localPath,
      meta: meta,
      duration: duration,
      previewBytes: previewBytes,
    );
  }

  /// Creates a standard text message entity
  ChatUiModel text(String text) => base(content: text, type: MessageType.text);

  /// Creates an image message with local asset tracking and preview support
  ChatUiModel image({
    required String localPath,
    Uint8List? previewBytes,
    Map<String, dynamic>? meta,
  }) => base(
    content: '[Image]',
    type: MessageType.image,
    localPath: localPath,
    previewBytes: previewBytes,
    meta: meta,
  );

  /// Creates a video message entity containing path and thumbnail data
  ChatUiModel video({
    required String localPath,
    Uint8List? previewBytes,
    Map<String, dynamic>? meta,
  }) => base(
    content: '[Video]',
    type: MessageType.video,
    localPath: localPath,
    previewBytes: previewBytes,
    meta: meta,
  );

  /// Creates a voice/audio message with duration metadata
  ChatUiModel voice({
    required String localPath,
    required int duration,
    Map<String, dynamic>? meta,
  }) => base(
    content: '[Voice]',
    type: MessageType.audio,
    localPath: localPath,
    duration: duration,
    meta: {if (meta != null) ...meta, 'duration': duration},
  );

  /// Creates a generic file message with detailed file metadata
  ChatUiModel file({
    required String localPath,
    required String fileName,
    required int fileSize,
    required String fileExt,
    Map<String, dynamic>? meta,
  }) => base(
    content: '[File]',
    type: MessageType.file,
    localPath: localPath,
    meta: {
      if (meta != null) ...meta,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileExt': fileExt,
    },
  );

  /// Creates a location message entity with coordinate and address mapping
  ChatUiModel location({
    required double latitude,
    required double longitude,
    required String address,
    String? title,
    required String thumb,
    Map<String, dynamic>? meta,
  }) => base(
    content: '[Location]',
    type: MessageType.location,
    meta: {
      if (meta != null) ...meta,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'title': title,
      'thumb': thumb,
    },
  );
}