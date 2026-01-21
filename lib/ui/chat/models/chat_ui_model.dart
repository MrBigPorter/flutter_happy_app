
import 'package:flutter_app/ui/chat/models/conversation.dart';

enum MessageStatus { sending, success, failed, read }
enum MessageType {
  text(1),
  image(2),
  audio(3),
  video(4),
  system(99);

  // 1. 定义一个成员变量存数值
  final int value;

  // 2. 构造函数 (必须是 const)
  const MessageType(this.value);

  // 4. 🛠️ 辅助方法: 从 int 转回 Enum (给 fromApiModel 用)
  static MessageType fromValue(int value){
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text, // 默认兜底
    );
  }
}

class ChatUiModel {
  final String id;        // 消息唯一ID (前端生成 UUID 或 后端返回 ID)
  final int? seqId;     // 可选的序列号 (用于有序消息),这是水位线比对的关键
  final String content;   // 内容
  final MessageType type; // 类型
  final bool isMe;        // 是否是我发的
  final MessageStatus status; // 发送状态
  final int createdAt;    // 时间戳
  final String? senderAvatar; // 对方头像 (群聊用)
  final String? senderName;   // 对方昵称

  //  新增：本地文件路径 (用于发送图片时的“乐观更新”)
  // 当 localPath 不为空时，UI 优先渲染 File(localPath)，而不是 NetworkImage(content)
  final String? localPath;

  //  新增：图片宽高 (可选，用于优化列表跳动问题)
  final double? width;
  final double? height;

  ChatUiModel({
    required this.id,
    required this.content,
    required this.type,
    required this.isMe,
    this.status = MessageStatus.success,
    required this.createdAt,
    this.senderAvatar,
    this.senderName,
    this.seqId,
    this.localPath,
    this.width,
    this.height,
  });

  // 用于更新状态 (例如 sending -> success)
  ChatUiModel copyWith({
    String? id,
    String? content,
    MessageType? type,
    bool? isMe,
    MessageStatus? status,
    int? createdAt,
    String? senderAvatar,
    String? senderName,
    int? seqId,
    String? localPath,
    double? width,
    double? height,
  }) {
    return ChatUiModel(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      isMe: isMe ?? this.isMe,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      senderName: senderName ?? this.senderName,
      seqId: seqId ?? this.seqId,
      localPath: localPath ?? this.localPath,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  // 工厂构造函数：从后端 API 数据转为 UI 模型
  // 注意：这里参数改成了 Map<String, dynamic>，直接解析 JSON 最稳妥
  // 如果你坚持要用 ChatMessage 对象，请确保 ChatMessage 类里定义了 isSelf 字段
  // 修正：参数类型改回 ChatMessage (因为你的 API 已经转好了对象)
  // 工厂构造函数
  // 修正：参数必须是 ChatMessage 对象，因为 API 客户端已经帮我们转好了
  factory ChatUiModel.fromApiModel(ChatMessage apiMsg, String myUserId) {
    
    print("转换消息 myUserId=${myUserId}，内容=${apiMsg.sender?.id}");

    // --------------------------------------------------------
    //  身份判定 (修复左边/右边问题)
    // --------------------------------------------------------

    // 1. 获取发送者 ID，强制转成 String (防止 Int vs String 问题)
    final String senderId = apiMsg.sender?.id?.toString() ?? "";

    // 2. 获取我的 ID，强制转成 String
    final String currentId = myUserId.toString();

    // 3. 核心比对：只要 ID 相同，就是我发的
    // 注意：这里必须判空，防止两个空字符串相等
    bool isMe = senderId.isNotEmpty && senderId == currentId;

    //  补充：如果你的 ChatMessage 类里确实有 isSelf 字段，可以用下面这行代替上面的逻辑：
    // bool isMe = apiMsg.isSelf ?? (senderId.isNotEmpty && senderId == currentId);

    // --------------------------------------------------------
    //  转换其他字段
    // --------------------------------------------------------

    // 类型转换
    MessageType uiType = MessageType.fromValue(apiMsg.type);

    return ChatUiModel(
      id: apiMsg.id.toString(), // 强转 String
      seqId: apiMsg.seqId,
      content: apiMsg.content ?? "",
      type: uiType,
      isMe: isMe, // ✅ 使用强转对比后的结果
      status: MessageStatus.success,
      createdAt: apiMsg.createdAt ?? 0,
      senderName: apiMsg.sender?.nickname,
      senderAvatar: apiMsg.sender?.avatar,
      localPath: null,
    );
  }


}