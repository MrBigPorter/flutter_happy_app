import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'components/chat_bubble.dart';
import 'components/chat_input/modern_chat_input_bar.dart';
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

    //  关键修改：页面初始化时
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider(widget.conversationId)).refresh();
    });

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
      ref.read(chatControllerProvider(widget.conversationId)).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 监听消息状态
    final asyncMessages = ref.watch(chatStreamProvider(widget.conversationId));
    // 2. 监听详情状态
    final asyncDetail = ref.watch(chatDetailProvider(widget.conversationId));

    // 判断是否是静默更新状态 (有数据，但正在刷新)
    final isUpdating = asyncMessages.isLoading && asyncMessages.hasValue;


    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.bgPrimary, // iOS 风格背景灰
        //  优化 2: Messenger 风格 Header
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
            onPressed: () {
              //  修复 Web 刷新后报错的问题
              if (context.canPop()) {
                context.pop();
              } else {
                // 如果没有上一页（比如网页刷新进来的），强行去列表页
                // 注意：这里请填你路由配置里列表页的 path，通常是 '/conversations' 或 '/'
                context.go('/conversations');
              }
            },
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
              icon: Icon(
                Icons.call,
                color: context.textBrandPrimary900,
                size: 24.sp,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(
                Icons.videocam,
                color: context.textBrandPrimary900,
                size: 26.sp,
              ),
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
                    .read(chatControllerProvider(widget.conversationId)).sendMessage(text);
              },
              //  绑定发图逻辑
              onSendImage: (XFile file) {
                // 直接把 file 对象传给 Notifier
                ref.read(chatControllerProvider(widget.conversationId)).sendImage(file);
              }, conversationId: widget.conversationId,
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
          // 1. 获取是否有更多
          final controller = ref.read(chatControllerProvider(widget.conversationId));
          final hasMore = controller.hasMore;
          // 2. 监听是否正在加载 (关键！)
          final isLoadingMore = ref.watch(chatLoadingMoreProvider(widget.conversationId));
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            // 只有当“有更多”且“正在加载”时，才显示 Spinner
            child: (hasMore && isLoadingMore)
                ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : (hasMore ? const SizedBox.shrink() : const Text("—— No more history ——")),
          );
        }

        // 2. 渲染气泡
        final msg = messages[index];
        return ChatBubble(
          key: ValueKey(msg.id),
          message: msg,
          onRetry: () {
            ref.read(chatControllerProvider(widget.conversationId)).resendMessage(msg.id);
          },
        );
      },
    );
  }
}

