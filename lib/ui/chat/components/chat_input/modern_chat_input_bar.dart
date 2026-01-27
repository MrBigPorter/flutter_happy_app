import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/components/chat_input/voice_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../theme/design_tokens.g.dart';

class ModernChatInputBar extends StatefulWidget {
  final String conversationId;
  final Function(String) onSend;
  final Function(XFile) onSendImage;

  //  NEW: Video Support
  final Function(XFile) onSendVideo;
  //  NEW: Voice Support callback exposed
  final Function(String, int) onSendVoice;

  const ModernChatInputBar({
    super.key,
    required this.conversationId,
    required this.onSend,
    required this.onSendImage,
    required this.onSendVideo,
    required this.onSendVoice,
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

  Future<void> _handlePickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        widget.onSendImage(image);
      }
    } catch (e) {
      debugPrint("Pick image failed: $e");
    }
  }

  //  NEW: Video Picker Logic
  Future<void> _handlePickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // Optional: Limit video length
      );

      if (video != null) {
        widget.onSendVideo(video);
      }
    } catch (e) {
      debugPrint("Pick video failed: $e");
    }
  }

  Future<void> _handleCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        widget.onSendImage(image);
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
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isRecording ? 0.0 : 1.0,
                child: Row(
                  children: [
                    // Left Actions
                    _buildActionBtn(Icons.add_circle, isSolid: true),
                    _buildActionBtn(Icons.camera_alt, onTap: _handleCamera),
                    _buildActionBtn(Icons.image, onTap: _handlePickImage),
                    //  NEW: Video Button
                    _buildActionBtn(Icons.videocam, onTap: _handlePickVideo),
                    // Mic/Keyboard Toggle
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

              SizedBox(width: 4.w),

              // Middle Input
              Expanded(
                child: _isVoiceMode
                    ? VoiceRecordButton(
                  conversationId: widget.conversationId,
                  onRecordingChange: (recording) {
                    setState(() {
                      _isRecording = recording;
                    });
                  },
                  //  Pass the callback to VoiceRecordButton if it supports it
                  // Or modify VoiceRecordButton to call widget.onSendVoice directly
                  onVoiceSent: widget.onSendVoice,
                )
                    : _buildTextField(),
              ),

              SizedBox(width: 8.w),

              // Right Actions (Send/Like)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isRecording
                    ? const SizedBox.shrink()
                    : _buildRightButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildActionBtn(
      IconData icon, {
        bool isSolid = false,
        VoidCallback? onTap,
      }) {
    final color = context.textBrandPrimary900;
    return Container(
      margin: EdgeInsets.only(right: 2.w),
      child: IconButton(
        onPressed: onTap ?? () {},
        icon: Icon(icon, color: color, size: 25.sp),
        padding: EdgeInsets.all(6.w),
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