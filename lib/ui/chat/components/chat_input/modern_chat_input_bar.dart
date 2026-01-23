import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/components/chat_input/voice_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../theme/design_tokens.g.dart';

class ModernChatInputBar extends StatefulWidget {
  //新增：用于语音发送逻辑
  final String conversationId;
  final Function(String) onSend;
  final Function(XFile) onSendImage;

  const ModernChatInputBar({
    super.key,
    required this.conversationId,
    required this.onSend,
    required this.onSendImage,
  });

  @override
  State<ModernChatInputBar> createState() => _ModernChatInputBarState();
}

class _ModernChatInputBarState extends State<ModernChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _hasText = false;
  bool _isVoiceMode = false; //新增：切换语音/文字模式
  bool _isRecording = false; //  新增：记录子组件的录音状态

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
  Future<void> _handleCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        widget.onSendImage.call(image);
      }
    } catch (e) {
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
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isRecording ? 0.0 : 1.0,
                child: Row(
                  children: [
                    // ===========================================
                    //  左侧功能区 (加号、相机、相册、语音)
                    // ===========================================
                    _buildActionBtn(Icons.add_circle, isSolid: true),
                    // 实心加号
                    _buildActionBtn(Icons.camera_alt, onTap: _handleCamera),
                    // 相机
                    _buildActionBtn(Icons.image, onTap: _handlePickImage),
                    // 相册
                    // 修改：麦克风图标点击切换模式
                    _buildActionBtn(
                      _isVoiceMode ? Icons.keyboard : Icons.mic,
                      onTap: () {
                        setState(() {
                          _isVoiceMode = !_isVoiceMode;
                        });
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(width: 4.w), // 图标和输入框的间距
              // ===========================================
              //  中间输入框 (Aa)
              // ===========================================
              Expanded(
                child: _isVoiceMode
                    ? VoiceRecordButton(
                        conversationId: widget.conversationId,
                        onRecordingChange: (recording) {
                          setState(() {
                            _isRecording = recording;
                          });
                        },
                      )
                    : _buildTextField(),
              ),

              SizedBox(width: 8.w),

              // ===========================================
              //  右侧：发送 / 点赞
              // ===========================================
              // 3. 右侧按钮：录音时完全隐藏
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isRecording
                    ? const SizedBox.shrink() // 录音时占位为空
                    : _buildRightButton(), // 非录音时显示发送/点赞
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 抽离出来的输入框组件
  Widget _buildTextField() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 100),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _controller,
        maxLines: null,
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

  //  封装一个小组件，减少重复代码
  Widget _buildActionBtn(
    IconData icon, {
    bool isSolid = false,
    VoidCallback? onTap,
  }) {
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

  // 抽离出来的右侧按钮
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
    );
  }
}
