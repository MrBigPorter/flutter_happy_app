import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'components/chat_bubble.dart';
import 'components/chat_input_bar.dart';
import 'providers/chat_room_provider.dart';


class ChatPage extends ConsumerWidget {
  final String conversationId; // 从拼团页传进来
  final String title;

  const ChatPage({
    super.key,
    required this.conversationId,
    this.title = 'Group Chat',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听消息列表
    final messages = ref.watch(chatRoomProvider(conversationId));
    // 获取控制器 (用于发消息)
    final notifier = ref.read(chatRoomProvider(conversationId).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          // 1. 消息列表
          Expanded(
            child: ListView.builder(
              reverse: true, //  关键：聊天列表通常是从下往上排列
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return ChatBubble(message: msg);
              },
            ),
          ),

          // 2. 输入框区域
          SafeArea(
            child: ChatInputBar(
              onSend: (text) => notifier.sendMessage(text),
            ),
          ),
        ],
      ),
    );
  }
}