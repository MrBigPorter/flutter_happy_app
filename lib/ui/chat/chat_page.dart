import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        // 🛠️ 优化 2: Messenger 风格 Header
        appBar: AppBar(
          backgroundColor: context.bgSecondary,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          // Messenger 有一条很细的分割线
          shadowColor: Colors.black.withValues(alpha: 0.1),
          titleSpacing: 0,
          // 关键：移除标题左侧的默认间距，让头像紧贴返回键
          leadingWidth: 40,
          // 调整返回键宽度，更紧凑
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: context.textPrimary900,
              size: 22.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          // 优化 1: 标题栏显示状态
          title: Row(
            children: [
              // 1. 头像 (模拟)
              CircleAvatar(
                radius: 18.r,
                backgroundColor: Colors.grey[200],
                backgroundImage: asyncDetail.valueOrNull?.avatar != null
                    ? NetworkImage(asyncDetail.value!.avatar!)
                    : null,
                child: asyncDetail.valueOrNull?.avatar == null
                    ? Icon(
                        Icons.person,
                        color: context.textSecondary700,
                        size: 20.sp,
                      )
                    : null,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 第一行：显示群名
                    asyncDetail.when(
                      data: (detail) => Text(
                        detail.name,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary900,
                        ),
                      ),
                      loading: () => Text(
                        widget.title,
                        style: TextStyle(color: context.textPrimary900),
                      ),
                      error: (_, __) => Text(
                        widget.title,
                        style: TextStyle(color: context.textPrimary900),
                      ),
                    ),

                    // 第二行：显示 "Updating..." 或 人数
                    if (isUpdating)
                      Text(
                        "Updating...",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.textPrimary900,
                        ),
                      )
                    else
                      asyncDetail.maybeWhen(
                        data: (detail) => Text(
                          'Active now',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: context.textSecondary700,
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // 3. 右侧功能键 (电话、视频、信息)
          actions: [
            IconButton(
              icon: Icon(Icons.call, color: Colors.blueAccent, size: 24),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.videocam, color: Colors.blueAccent, size: 26),
              onPressed: () {},
            ),
            const SizedBox(width: 5),
          ],
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

                error: (error, _) => Center(child: Text("Error: $error")),

                // 简单处理错误
                data: (messages) => _buildMessageList(messages),
              ),
            ),

            //  优化 3: 使用美化后的输入框
            ModernChatInputBar(
              onSend: (text) {
                ref
                    .read(chatRoomProvider(widget.conversationId).notifier)
                    .sendMessage(text);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 抽离 List 构建逻辑，让代码更干净
  Widget _buildMessageList(List<dynamic> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Text("No messages", style: TextStyle(color: Colors.grey[400])),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      // 最新消息在底部
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      // item count + 1 是为了给顶部的 "Loading / End" 留位置
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        // 1. 检查是否到底 (Visual Top)
        if (index == messages.length) {
          final hasMore = ref
              .read(chatRoomProvider(widget.conversationId).notifier)
              .hasMore;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            child: hasMore
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey,
                    ),
                  )
                : const Text(
                    "—— No more history ——",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
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
    // 🛠️ 关键修改：
    // 1. 最外层是 Container，负责提供背景色 (延伸到安全区底部)
    // 2. 内部用 SafeArea 包裹内容 (top: false, bottom: true)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.bgSecondary, // 背景色
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ), // 顶部细线
      ),
      child: SafeArea(
        top: false,// 不需要考虑顶部安全区
        bottom: true, // 考虑底部安全区
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w,vertical: 8.h),
            child: Row(
              children: [
                // 左侧：加号按钮 (模拟附件)
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: context.textPrimary900,
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),

                // 中间：输入框 (胶囊形状)
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100), // 限制最大高度
                    decoration: BoxDecoration(
                      color: context.bgPrimary,
                      borderRadius: BorderRadius.circular(20), // 圆角胶囊
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      // 支持多行
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: TextStyle(color: context.textPrimary900, fontSize: 15.sp),
                      decoration:  InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: context.textSecondary700, fontSize: 15.sp),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),

                 SizedBox(width: 8.w),

                // 右侧：发送按钮
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin:  EdgeInsets.only(bottom: 2.h), // 微调对齐
                  child: IconButton(
                    onPressed: _hasText ? _handleSend : null,
                    icon: Icon(
                      Icons.send_rounded,
                      color: _hasText ? context.textBrandPrimary900 : context.textDisabled,
                      size: 28.sp,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
        ),
      )
    );
  }
}
