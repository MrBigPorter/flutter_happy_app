import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'components/chat_bubble.dart';
import 'providers/chat_room_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String title;

  const ChatPage({
    super.key,
    required this.conversationId,
    this.title = 'Group Chat',
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 触发加载更多
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50) {
      ref.read(chatRoomProvider(widget.conversationId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 监听消息状态
    final asyncMessages = ref.watch(chatRoomProvider(widget.conversationId));
    // 2. 监听详情状态
    final asyncDetail = ref.watch(chatDetailProvider(widget.conversationId));

    // 判断是否是静默更新状态 (有数据，但正在刷新)
    final isUpdating = asyncMessages.isLoading && asyncMessages.hasValue;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.bgPrimary, // iOS 风格背景灰
        appBar: AppBar(
          backgroundColor: context.bgSecondary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          // 优化 1: 标题栏显示状态
          title: Column(
            children: [
              // 第一行：显示群名
              asyncDetail.when(
                data: (detail) => Text(
                  detail.name,
                  style:  TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimary900),
                ),
                loading: () => Text(widget.title, style:  TextStyle(color: context.textPrimary900)),
                error: (_, __) => Text(widget.title, style:  TextStyle(color: context.textPrimary900)),
              ),

              // 第二行：显示 "Updating..." 或 人数
              if (isUpdating)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)
                    ),
                    SizedBox(width: 6),
                    Text("Updating...", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              else
                asyncDetail.maybeWhen(
                  data: (detail) => Text(
                    '${detail.memberCount} members',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  orElse: () => const SizedBox.shrink(),
                )
            ],
          ),
        ),
        body: Column(
          children: [
            // 优化 2: 移除全局 Loading，改用数据优先逻辑
            Expanded(
              child: asyncMessages.when(
                // 只有第一次进且没数据时，才显示大 loading
                loading: () => asyncMessages.hasValue
                    ? _buildMessageList(asyncMessages.value!) // 有旧数据就先显示旧的
                    : const Center(child: CircularProgressIndicator()),

                error: (error, _) => Center(child: Text("Error: $error")), // 简单处理错误

                data: (messages) => _buildMessageList(messages),
              ),
            ),

            //  优化 3: 使用美化后的输入框
            SafeArea(
              child: ModernChatInputBar(
                onSend: (text) {
                  ref.read(chatRoomProvider(widget.conversationId).notifier).sendMessage(text);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 抽离 List 构建逻辑，让代码更干净
  Widget _buildMessageList(List<dynamic> messages) {
    if (messages.isEmpty) {
      return Center(child: Text("No messages", style: TextStyle(color: Colors.grey[400])));
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,// 最新消息在底部
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      // item count + 1 是为了给顶部的 "Loading / End" 留位置
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        // 1. 检查是否到底 (Visual Top)
        if (index == messages.length) {
          final hasMore = ref.read(chatRoomProvider(widget.conversationId).notifier).hasMore;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            child: hasMore
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
            )
                : const Text("—— No more history ——", style: TextStyle(color: Colors.grey, fontSize: 10)),
          );
        }

        // 2. 渲染气泡
        final msg = messages[index];
        return ChatBubble(message: msg);
      },
    );
  }
}

// ==========================================
//  优化 3: 现代化 iOS/微信风格输入框
// ==========================================
class ModernChatInputBar extends StatefulWidget {
  final Function(String) onSend;

  const ModernChatInputBar({super.key, required this.onSend});

  @override
  State<ModernChatInputBar> createState() => _ModernChatInputBarState();
}

class _ModernChatInputBarState extends State<ModernChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false; // 用于控制发送按钮颜色

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:  context.bgSecondary, // 背景色
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))), // 顶部细线
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // 对齐底部，防止多行输入时按钮乱跑
        children: [
          // 左侧：加号按钮 (模拟附件)
          IconButton(
            onPressed: () {},
            icon:  Icon(Icons.add_circle_outline, color: context.textPrimary900, size: 28),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
          const SizedBox(width: 8),

          // 中间：输入框 (胶囊形状)
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 100), // 限制最大高度
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20), // 圆角胶囊
              ),
              child: TextField(
                controller: _controller,
                maxLines: null, // 支持多行
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 右侧：发送按钮
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 2), // 微调对齐
            child: IconButton(
              onPressed: _hasText ? _handleSend : null,
              icon: Icon(
                Icons.send_rounded,
                color: _hasText ? Colors.blueAccent : Colors.grey[400],
                size: 28,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}