import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_app/ui/chat/components/chat_input/voice_button.dart';
import '../../../../theme/design_tokens.g.dart';

class ModernChatInputBar extends StatefulWidget {
  final String conversationId;
  final Function(String) onSend;
  final Function(XFile) onSendImage;
  final Function(XFile) onSendVideo;
  final Function(String, int) onSendVoice;
  //  新增回调：告诉父组件状态变了
  final VoidCallback onAddPressed; // 点了加号
  final VoidCallback onTextFieldTap; // 点了输入框


  const ModernChatInputBar({
    super.key,
    required this.conversationId,
    required this.onSend,
    required this.onSendImage,
    required this.onSendVideo,
    required this.onSendVoice,

    required this.onAddPressed,
    required this.onTextFieldTap,
  });

  @override
  State<ModernChatInputBar> createState() => _ModernChatInputBarState();
}

class _ModernChatInputBarState extends State<ModernChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _hasText = false;
  bool _isVoiceMode = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (_hasText != hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  void _handleLike() {
    widget.onSend("👍");
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // === 左侧按钮区 (精简版) ===
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isRecording ? 0.0 : 1.0,
                child: Row(
                  children: [
                    // 1. 语音/键盘切换
                    _buildActionBtn(
                      _isVoiceMode ? Icons.keyboard : Icons.voice_chat_outlined, // 换了个更现代的图标
                      onTap: () {
                        setState(() {
                          _isVoiceMode = !_isVoiceMode;
                          // 切到语音时收起键盘
                          if (_isVoiceMode) FocusScope.of(context).unfocus();
                        });
                      },
                    ),

                    // 2. 全能菜单入口 (+)
                    // 这里删掉了原来的 camera/image/video 按钮，统一收纳
                    _buildActionBtn(
                      Icons.add_circle_outline, // 空心圆加号
                      onTap: widget.onAddPressed, //  核心：点击加号，通知父组件展开面板
                    ),
                  ],
                ),
              ),

              SizedBox(width: 4.w),

              // === 中间输入区 ===
              Expanded(
                child: _isVoiceMode
                    ? VoiceRecordButton(
                  conversationId: widget.conversationId,
                  onRecordingChange: (recording) {
                    setState(() => _isRecording = recording);
                  },
                  onVoiceSent: widget.onSendVoice,
                )
                    : _buildTextField(),
              ),

              SizedBox(width: 8.w),

              // === 右侧发送区 ===
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isRecording
                    ? const SizedBox.shrink()
                    : _buildRightButton(),
              ),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildTextField() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 100),
      decoration: BoxDecoration(
        color: context.bgSecondary, // 输入框白底
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _controller,
        onTap: widget.onTextFieldTap, //  核心：点击输入框时，通知父组件收起面板
        maxLines: null, // 自动增高
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(color: context.textPrimary900, fontSize: 16.sp),
        cursorColor: context.textBrandPrimary900,
        decoration: InputDecoration(
          hintText: "Aa",
          hintStyle: TextStyle(
            color: context.textSecondary700,
            fontSize: 16.sp,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, {VoidCallback? onTap}) {
    final color = context.textPrimary900; // 使用主文字色，更沉稳
    return Container(
      margin: EdgeInsets.only(right: 4.w), // 稍微拉开点间距
      child: IconButton(
        onPressed: onTap ?? () {},
        icon: Icon(icon, color: color, size: 28.sp), // 图标稍微调大
        padding: EdgeInsets.all(4.w),
        constraints: const BoxConstraints(),
        style: const ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildRightButton() {
    return AnimatedSwitcher(
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
          size: 28.sp,
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
          size: 28.sp,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}