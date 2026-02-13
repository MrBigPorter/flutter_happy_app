import 'dart:typed_data';

import 'package:equatable/equatable.dart';
export 'chat_ui_model_ext.dart';
export 'chat_ui_model_mapper.dart';

enum MessageStatus { sending, success, failed, read, pending }

enum MessageType {
  text(0, label:'[Text]'),
  image(1, label:'[Image]'),
  audio(2, label:'[Audio]'),
  video(3, label:'[Video]'),
  recalled(4, label:'[Recalled]'),
  file(5, label:'[File]'),
  location(6, label:'[Location]'),
  system(99, label:'[System]');

  final int value;
  final  String label;

  const MessageType(this.value, {required this.label});

  static MessageType fromValue(int value) => MessageType.values.firstWhere(
    (e) => e.value == value,
    orElse: () => MessageType.text,
  );

  /// 2. 核心逻辑：获取列表页预览文案
  /// [content] : 消息原始内容
  /// [isRecalled] : 消息状态是否已撤回 (这是一个独立的状态，优先级最高)
  String getPreviewText(String content, {bool isRecalled = false}) {
    // 优先级 Top 1: 只要标记了 isRecalled，或者是撤回类型，直接返回撤回提示
    if (isRecalled || this == MessageType.recalled) {
      return '[Message Recalled]';
    }

    // 优先级 Top 2: 文本和系统消息，直接显示原始内容
    if (this == MessageType.text || this == MessageType.system) {
      return content;
    }

    // 优先级 Top 3: 其他多媒体类型，显示固定 Label
    return label;
  }
}

class ChatUiModel extends Equatable {
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

  // 物理资源与内存状态
  final String? resolvedPath;
  final String? resolvedThumbPath;
  final Uint8List? previewBytes;
  final String? localPath;
  final int? duration;
  final bool isRecalled;
  final Map<String, dynamic>? meta;

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
    this.previewBytes,
    this.duration,
    this.meta,
    this.resolvedPath,
    this.resolvedThumbPath,
  });

  @override
  List<Object?> get props => [
    id,
    content,
    status,
    localPath,
    resolvedPath,
    previewBytes,
    meta,
    seqId,
    // 把所有参与 UI 显示的字段都写在这里
  ];

  // --- 持久化逻辑 (逻辑保持不变) ---
  Map<String, dynamic> toJson() => {
    'id': id,
    'seqId': seqId,
    'content': content,
    'type': type.name,
    'isMe': isMe,
    'status': status.name,
    'createdAt': createdAt,
    'senderAvatar': senderAvatar,
    'senderName': senderName,
    'conversationId': conversationId,
    'previewBytes': previewBytes?.toList(),
    'localPath': localPath,
    'duration': duration,
    'isRecalled': isRecalled,
    'meta': meta,
  };

  factory ChatUiModel.fromJson(Map<String, dynamic> json) {
    return ChatUiModel(
      id: json['id'] as String,
      seqId: json['seqId'] as int?,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      isMe: json['isMe'] as bool,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.pending,
      ),
      createdAt: json['createdAt'] as int,
      senderAvatar: json['senderAvatar'] as String?,
      senderName: json['senderName'] as String?,
      conversationId: json['conversationId'] as String,
      previewBytes: json['previewBytes'] != null
          ? Uint8List.fromList((json['previewBytes'] as List).cast<int>())
          : null,
      localPath: json['localPath'] as String?,
      duration: json['duration'] as int?,
      isRecalled: json['isRecalled'] as bool? ?? false,
      meta: json['meta'] as Map<String, dynamic>? ?? {},
    );
  }

  ChatUiModel merge(ChatUiModel serverMsg) {
    return copyWith(
      // 1. 状态：信服务器的 (比如从 sending 变成了 success)
      status: serverMsg.status == MessageStatus.success ? MessageStatus.success : status,

      // 2. 重点：服务器没有 localPath，但我有，绝对不能丢！
      localPath: (serverMsg.localPath != null && serverMsg.localPath!.isNotEmpty)
          ? serverMsg.localPath
          : localPath,

      // 3. 预览图同理，服务器通常不给 bytes，保留本地的
      previewBytes: (serverMsg.previewBytes != null && serverMsg.previewBytes!.isNotEmpty)
          ? serverMsg.previewBytes
          : previewBytes,

      isRecalled: serverMsg.isRecalled,

      // 4. 其他字段，服务器准没错，直接覆盖
      seqId: serverMsg.seqId ?? seqId,
      content: serverMsg.content.isNotEmpty ? serverMsg.content : content,
      // 如果 serverMsg.meta 是空的，不要覆盖本地已有的 meta (比如宽高等信息)
      meta: (serverMsg.meta == null || serverMsg.meta!.isEmpty) ? meta : serverMsg.meta,

      // 必须更新的时间戳等
      createdAt: serverMsg.createdAt > 0 ? serverMsg.createdAt : createdAt,
    );
  }

  // --- CopyWith (保持不变) ---
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
    String? resolvedPath,
    String? resolvedThumbPath,
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
      previewBytes: previewBytes ?? this.previewBytes,
      localPath: localPath ?? this.localPath,
      duration: duration ?? this.duration,
      isRecalled: isRecalled ?? this.isRecalled,
      meta: meta ?? this.meta,
      resolvedPath: resolvedPath ?? this.resolvedPath,
      resolvedThumbPath: resolvedThumbPath ?? this.resolvedThumbPath,
    );
  }

  bool get canRecall {
    // 1. 只有发送成功的消息才能撤回 (发送中/失败的通常是直接删除)
     if (status != MessageStatus.read && status != MessageStatus.success) return false;

    // 2. 核心规则：发送时间在 2 分钟以内
    final sendTime = DateTime.fromMillisecondsSinceEpoch(createdAt);
    final now = DateTime.now();
    final diff = now.difference(sendTime);

    return diff.inMinutes < 2; // 2分钟限制
  }
}
