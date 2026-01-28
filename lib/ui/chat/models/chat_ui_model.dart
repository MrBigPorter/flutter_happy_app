import 'dart:typed_data';
import 'package:flutter_app/ui/chat/models/conversation.dart';

import '../services/chat_action_service.dart';


enum MessageStatus {
  sending,
  success,
  failed,
  read,
  pending,
}

enum MessageType {
  text(0),
  image(1),
  audio(2),
  video(3),
  recalled(4),
  system(99);

  final int value;
  const MessageType(this.value);

  static MessageType fromValue(int value) {
    return MessageType.values.firstWhere(
          (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

class ChatUiModel {
  final String id;
  final int? seqId;
  final String content;
  final MessageType type;
  final bool isMe;
  final MessageStatus status;
  final int createdAt;
  final String? senderAvatar;
  final String? senderName;
  final String conversationId;

  //  核心：微缩图字节流 (存入数据库的关键)
  final Uint8List? previewBytes;

  // 本地文件路径
  final String? localPath;

  // 音频时长
  final int? duration;

  // 是否撤回
  final bool isRecalled;

  // 元数据 (宽、高、其他信息)
  final Map<String, dynamic>? meta;

  // Helper Getters
  double? get imgWidth => meta?['w'] is num ? (meta!['w'] as num).toDouble() : null;
  double? get imgHeight => meta?['h'] is num ? (meta!['h'] as num).toDouble() : null;

  ChatUiModel({
    required this.id,
    required this.content,
    required this.type,
    required this.isMe,
    this.status = MessageStatus.success,
    required this.createdAt,
    required this.conversationId,
    this.isRecalled = false,
    this.senderAvatar,
    this.senderName,
    this.seqId,
    this.localPath,
    this.previewBytes, //  构造函数接收
    this.duration,
    this.meta,
  });

  // ---  手动实现序列化 (100% 可控) ---

  // 1. 转为 Map 存入数据库 (Sembast)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seqId': seqId,
      'content': content,
      'type': type.name, // 枚举存名字
      'isMe': isMe,
      'status': status.name, // 枚举存名字
      'createdAt': createdAt,
      'senderAvatar': senderAvatar,
      'senderName': senderName,
      'conversationId': conversationId,

      //  核心修复：把 Uint8List 转为 List<int> 存入
      // Sembast 虽然支持 Blob，但 List<int> 兼容性最好，绝不会报错
      'previewBytes': previewBytes?.toList(),

      'localPath': localPath,
      'duration': duration,
      'isRecalled': isRecalled,
      'meta': meta,
    };
  }

  // 2. 从数据库读取 Map (Sembast)
  factory ChatUiModel.fromJson(Map<String, dynamic> json) {
    return ChatUiModel(
      id: json['id'] as String,
      seqId: json['seqId'] as int?,
      content: json['content'] as String,

      // 还原枚举
      type: MessageType.values.firstWhere(
              (e) => e.name == json['type'],
          orElse: () => MessageType.text
      ),

      isMe: json['isMe'] as bool,

      // 还原枚举
      status: MessageStatus.values.firstWhere(
              (e) => e.name == json['status'],
          orElse: () => MessageStatus.pending
      ),

      createdAt: json['createdAt'] as int,
      senderAvatar: json['senderAvatar'] as String?,
      senderName: json['senderName'] as String?,
      conversationId: json['conversationId'] as String,

      //  核心修复：读取时把 List<int> 强转回 Uint8List
      // Sembast 读出来的可能是 List<dynamic>，所以要先 cast 成 List<int>
      previewBytes: json['previewBytes'] != null
          ? Uint8List.fromList((json['previewBytes'] as List).cast<int>())
          : null,

      localPath: json['localPath'] as String?,
      duration: json['duration'] as int?,
      isRecalled: json['isRecalled'] as bool? ?? false,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  // --- CopyWith ---
  ChatUiModel copyWith({
    String? id,
    int? seqId,
    String? content,
    MessageType? type,
    bool? isMe,
    MessageStatus? status,
    int? createdAt,
    String? senderAvatar,
    String? senderName,
    String? conversationId,
    Uint8List? previewBytes,
    String? localPath,
    int? duration,
    bool? isRecalled,
    Map<String, dynamic>? meta,
  }) {
    return ChatUiModel(
      id: id ?? this.id,
      seqId: seqId ?? this.seqId,
      content: content ?? this.content,
      type: type ?? this.type,
      isMe: isMe ?? this.isMe,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      senderName: senderName ?? this.senderName,
      conversationId: conversationId ?? this.conversationId,
      previewBytes: previewBytes ?? this.previewBytes, // ✅ 支持 copyWith 更新
      localPath: localPath ?? this.localPath,
      duration: duration ?? this.duration,
      isRecalled: isRecalled ?? this.isRecalled,
      meta: meta ?? this.meta,
    );
  }

  // --- Mapper: API Model -> UI Model ---
  factory ChatUiModel.fromApiModel(ChatMessage apiMsg, String conversationId, [String? currentUserId]) {
    MessageType uiType = MessageType.fromValue(apiMsg.type);
    bool isRecalled = (uiType == MessageType.system) || (apiMsg.isRecalled);

    final Map<String, dynamic> meta = apiMsg.meta ?? {};
    final int? metaDuration = meta['duration'] is num
        ? (meta['duration'] as num).toInt()
        : null;

    bool isMe = apiMsg.isSelf;
    if (currentUserId != null && apiMsg.sender?.id == currentUserId) {
      isMe = true;
    }

    return ChatUiModel(
      id: apiMsg.id.toString(),
      seqId: apiMsg.seqId,
      content: apiMsg.content,
      type: uiType,
      isMe: isMe,
      status: MessageStatus.success,
      createdAt: apiMsg.createdAt,
      senderName: apiMsg.sender?.nickname,
      senderAvatar: apiMsg.sender?.avatar,
      isRecalled: isRecalled,
      localPath: null,
      conversationId: conversationId,
      duration: metaDuration,
      meta: meta,
      previewBytes: null, // API 消息默认没有本地微缩图，需要下载后生成或用别的逻辑
    );
  }
}

