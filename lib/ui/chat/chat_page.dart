import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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

    //  关键修改：页面初始化时
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRoomProvider(widget.conversationId).notifier).refresh();
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
                    .read(chatRoomProvider(widget.conversationId).notifier)
                    .sendMessage(text);
              },
              //  绑定发图逻辑
              onSendImage: (XFile file) {
                // 直接把 file 对象传给 Notifier
                ref.read(chatRoomProvider(widget.conversationId).notifier).sendImage(file);
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
        return ChatBubble(
          message: msg,
          onRetry: () {
            ref
                .read(chatRoomProvider(widget.conversationId).notifier)
                .resendMessage(msg.id);
          },
        );
      },
    );
  }
}

class ModernChatInputBar extends StatefulWidget {
  final Function(String) onSend;
  final Function(XFile) onSendImage;

  const ModernChatInputBar({super.key, required this.onSend, required this.onSendImage});

  @override
  State<ModernChatInputBar> createState() => _ModernChatInputBarState();
}

class _ModernChatInputBarState extends State<ModernChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (_hasText != hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  //  2. 实现相册逻辑
  Future<void> _handlePickImage() async {
    try {
      // 这里的 context 最好用 widget 传进来的，或者是 riverpod ref
      // 因为这是个 State 类，我们需要回调到外面，或者直接在这里读 Provider
      // 为了代码解耦，建议我们在 widget.onSend 旁边加一个 widget.onSendImage

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // 选原图，让我们的 GlobalUploadService 去压缩
      );

      if (image != null) {
        // 通知父组件发图
        widget.onSendImage.call(image);
      }
    } catch (e) {
      debugPrint("Pick image failed: $e");
    }
  }

  // 示例：处理相机拍照
  Future<void> _handleCamera() async{
    try{
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera
      );
      if(image != null){
        widget.onSendImage.call(image);
      }
    }catch(e){
      debugPrint("Camera failed: $e");
    }
  }

  void _handleLike() {
    widget.onSend("👍");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgSecondary,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          // 左右间距稍微小一点，给图标腾位置
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end, // 底部对齐
            children: [
              // ===========================================
              // 🛠️ 左侧功能区 (加号、相机、相册、语音)
              // ===========================================
              _buildActionBtn(Icons.add_circle, isSolid: true), // 实心加号
              _buildActionBtn(Icons.camera_alt, onTap: _handleCamera), // 相机
              _buildActionBtn(Icons.image, onTap: _handlePickImage), // 相册
              _buildActionBtn(Icons.mic), // 语音

              SizedBox(width: 4.w), // 图标和输入框的间距
              // ===========================================
              // 📝 中间输入框 (Aa)
              // ===========================================
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1), // 浅灰背景
                    borderRadius: BorderRadius.circular(20), // 胶囊
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(
                      color: context.textPrimary900,
                      fontSize: 16.sp,
                    ),
                    cursorColor: context.textBrandPrimary900,
                    decoration: InputDecoration(
                      hintText: "Aa",
                      hintStyle: TextStyle(
                        color: context.textSecondary700,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 9.h,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              // ===========================================
              // 👍 右侧：发送 / 点赞
              // ===========================================
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: _hasText
                    ? IconButton(
                        key: const ValueKey('send'),
                        onPressed: _handleSend,
                        icon: Icon(
                          Icons.send,
                          color: context.textBrandPrimary900,
                          size: 24.sp,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : IconButton(
                        key: const ValueKey('like'),
                        onPressed: _handleLike,
                        icon: Icon(
                          Icons.thumb_up_rounded,
                          color: context.textBrandPrimary900,
                          size: 26.sp,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🛠️ 封装一个小组件，减少重复代码
  Widget _buildActionBtn(IconData icon, {bool isSolid = false, VoidCallback? onTap}) {
    // 如果是实心加号，通常颜色更深一点，或者一样
    final color = context.textBrandPrimary900;

    return Container(
      margin: EdgeInsets.only(right: 2.w), // 按钮之间的微小间距
      child: IconButton(
        onPressed: onTap ?? () {},
        icon: Icon(icon, color: color, size: 25.sp),
        // 25sp 大小比较适中

        // 关键：收紧按钮的点击区域，防止一行放不下
        padding: EdgeInsets.all(6.w),
        constraints: const BoxConstraints(),
        style: const ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 去除多余的点击边距
        ),
      ),
    );
  }
}
