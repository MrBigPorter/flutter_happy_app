import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart'; // 引入 WebRTC 用于类型定义

// 引入你刚才创建的三个组件
import '../widgets/call_action_button.dart';
import '../widgets/local_video_view.dart';
import '../widgets/remote_video_view.dart';
import '../widgets/user_avatar_view.dart';

class CallPage extends StatefulWidget {
  final String targetName;
  final String? targetAvatar;
  final bool isVideo; // 初始是否为视频通话

  const CallPage({
    super.key,
    required this.targetName,
    this.targetAvatar,
    this.isVideo = true,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  // 模拟状态
  bool _isConnected = false;

  // 模拟设备状态
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCameraOff = false; // 用户主动关闭摄像头

  // 悬浮窗位置 (默认右上角)
  Offset _floatOffset = Offset.zero;

  // 模拟的 Renderers (后续对接 WebRTC 时会用到)
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;

  @override
  void initState() {
    super.initState();
    // 初始化悬浮窗位置 (屏幕宽 - 宽 - 边距, 顶部边距)
    // 注意：ScreenUtil 在 initState 时可能还没准备好完全的上下文，
    // 实际项目中建议在 build 或 addPostFrameCallback 中初始化，或者给个固定值。
    _floatOffset = Offset(240.w, 100.h);
  }

  @override
  Widget build(BuildContext context) {
    // 判断当前是否应该显示视频流 UI
    // 条件：是视频通话模式 && 没关摄像头 && (已接通 或 正在呼叫但想看预览)
    final bool showVideoUI = widget.isVideo && !_isCameraOff;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ==============================
          // Layer 1: 底层背景 (远端视频 或 模糊头像)
          // ==============================
          _buildBackgroundLayer(showVideoUI),

          // ==============================
          // Layer 2: 中间信息层 (头像/名字/计时)
          // ==============================
          // 只有在 "非视频模式" 或者 "视频尚未接通" 时显示头像信息
          if (!showVideoUI || !_isConnected)
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    Spacer(flex: 1),
                    UserAvatarView(
                      userName: widget.targetName,
                      avatarUrl: widget.targetAvatar,
                      statusText: _getStatusText(),
                      isVoiceCall: !widget.isVideo,
                    ),
                    Spacer(flex: 2),
                  ],
                ),
              ),
            ),

          // ==============================
          // Layer 3: 本地悬浮小窗 (可拖拽)
          // ==============================
          // 条件：已接通 && 视频模式 && 摄像头开启
          if (_isConnected && showVideoUI)
            Positioned(
              left: _floatOffset.dx,
              top: _floatOffset.dy,
              child: Draggable(
                feedback: _buildLocalWindow(isDragging: true), // 拖拽时的半透明残影
                childWhenDragging: Container(), // 拖走后原位置留空
                onDraggableCanceled: (Velocity velocity, Offset offset) {
                  // 松手后更新位置
                  setState(() {
                    // 简单的边界限制，防止拖出屏幕
                    double dx = offset.dx.clamp(0.0, 1.sw - 100.w);
                    double dy = offset.dy.clamp(0.0, 1.sh - 150.h);
                    _floatOffset = Offset(dx, dy);
                  });
                },
                child: _buildLocalWindow(),
              ),
            ),

          // ==============================
          // Layer 4: 底部控制栏
          // ==============================
          Positioned(
            left: 0,
            right: 0,
            bottom: 40.h,
            child: SafeArea(
              child: _isConnected
                  ? _buildConnectedActions()
                  : _buildIncomingActions(),
            ),
          ),

          // 回退按钮 (左上角) - 方便测试退出
          Positioned(
            left: 16.w,
            top: 48.h,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32.r),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建本地小窗组件
  Widget _buildLocalWindow({bool isDragging = false}) {
    return Opacity(
      opacity: isDragging ? 0.7 : 1.0,
      child: LocalVideoView(
        renderer: _localRenderer, // 传入渲染器 (目前是 null，会显示占位)
        mirror: true,
      ),
    );
  }

  /// 构建背景层逻辑
  Widget _buildBackgroundLayer(bool showVideoUI) {
    if (showVideoUI && _isConnected) {
      // 场景 A: 视频通话中 -> 显示远端视频流
      return RemoteVideoView(
        renderer: _remoteRenderer,
        isConnectionStable: true,
      );
    } else if (showVideoUI && !_isConnected) {
      // 场景 B: 视频呼叫中 -> 显示本地摄像头预览 (全屏)
      // 通常我们会把本地预览铺满，直到对方接听
      // 但为了简单，这里我们还是用模糊背景，或者你可以把 LocalVideoView 铺满
      return _buildBlurredAvatar();
    } else {
      // 场景 C: 语音通话 或 关摄像头 -> 显示高斯模糊头像
      return _buildBlurredAvatar();
    }
  }

  /// 通用模糊背景
  Widget _buildBlurredAvatar() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.targetAvatar != null)
          Image.network(
            widget.targetAvatar!,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
          )
        else
          Container(color: Colors.grey[900]),

        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.black.withOpacity(0.6)),
        ),
      ],
    );
  }

  String _getStatusText() {
    if (_isConnected) return "00:45";
    return widget.isVideo ? "Video Calling..." : "Audio Calling...";
  }

  /// 呼叫中操作栏
  Widget _buildIncomingActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CallActionButton(
          icon: Icons.call_end,
          backgroundColor: Colors.red,
          iconColor: Colors.white,
          label: "Decline",
          onPressed: () => Navigator.pop(context),
        ),
        CallActionButton(
          icon: widget.isVideo ? Icons.videocam : Icons.call,
          backgroundColor: Colors.green,
          iconColor: Colors.white,
          label: "Accept",
          onPressed: () {
            setState(() {
              _isConnected = true;
              // 模拟接通后初始化悬浮窗位置
              _floatOffset = Offset(1.sw - 120.w, 60.h);
            });
          },
        ),
      ],
    );
  }

  /// 通话中操作栏
  Widget _buildConnectedActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CallActionButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          label: "Mute",
          isActive: _isMuted,
          onPressed: () => setState(() => _isMuted = !_isMuted),
        ),
        CallActionButton(
          icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
          label: "Camera",
          isActive: _isCameraOff,
          onPressed: () => setState(() => _isCameraOff = !_isCameraOff),
        ),
        CallActionButton(
          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
          label: "Speaker",
          isActive: _isSpeakerOn,
          onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
        ),
        CallActionButton(
          icon: Icons.call_end,
          backgroundColor: Colors.red,
          iconColor: Colors.white,
          label: "End",
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}