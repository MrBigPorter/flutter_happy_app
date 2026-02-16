part of 'call_page.dart';

extension CallPageWidgets on _CallPageState {

  // ==========================================
  //  核心组件构建 (Components)
  // ==========================================

  /// 构建悬浮窗内容 (Overlay)
  /// 需要传入 state 来获取通话时长和渲染器
  Widget _buildOverlayContent(CallState state) {
    // 判断是否已连接 (用于显示时间 vs Waiting)
    final isConnected = state.status == CallStatus.connected;

    //  防御：确保 remoteRenderer 活着
    // 只有当 接通 && 渲染器存在 时，才传给 CallOverlay
    // 否则传 null，让 CallOverlay 显示头像
    final safeRenderer = (isConnected && state.remoteRenderer != null)
        ? state.remoteRenderer
        : null;

    return CallOverlay(
      // 只有在视频模式且摄像头未关闭时，才算是有视频
      isVideo: widget.isVideo && !state.isCameraOff,
      targetAvatar: widget.targetAvatar,
      onTap: () {
        // 1. 隐藏悬浮窗
        OverlayManager.instance.hide();

        // 2. 恢复全屏
        // 注意：这里我们使用 widget 中的配置重新 push 页面
        // 状态会通过 Riverpod 自动保持，不用担心重置
        OverlayManager.instance.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => CallPage(
              targetId: widget.targetId,
              targetName: widget.targetName,
              targetAvatar: widget.targetAvatar,
              isVideo: widget.isVideo,
            ),
          ),
        );
      },
    );
  }

  /// 构建本地小窗
  Widget _buildLocalWindow(CallState state, {bool isDragging = false}) {
    //  防御：如果渲染器已置空，返回空容器，防止报错
    if(state.localRenderer == null) {
      return SizedBox();
    }
    return Opacity(
      opacity: isDragging ? 0.7 : 1.0,
      child: LocalVideoView(
        renderer: state.localRenderer, // 从 state 取
        mirror: true,
      ),
    );
  }

  /// 构建背景层 (远端视频或模糊图)
  Widget _buildBackgroundLayer(CallState state, bool showVideoUI, bool isConnected) {
    if (showVideoUI && isConnected && state.remoteRenderer != null) {
      // 场景 A: 接通且有视频 -> 显示远端流
      return RemoteVideoView(
        renderer: state.remoteRenderer,
        isConnectionStable: true, // 后续可以在 State 里加 networkQuality
      );
    } else if (showVideoUI && !isConnected) {
      // 场景 B: 正在呼叫但开了摄像头 -> 显示模糊背景 (或者你可以改为显示 LocalVideoView 全屏)
      return _buildBlurredAvatar();
    } else {
      // 场景 C: 语音模式 -> 显示模糊背景
      return _buildBlurredAvatar();
    }
  }

  /// 构建高斯模糊背景 (通用)
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

  // ==========================================
  //  按钮组构建 (Action Buttons)
  // ==========================================

  /// 呼叫中操作栏 (接听/挂断)
  /// 直接接受 Controller 来触发动作
  Widget _buildIncomingActions(CallController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CallActionButton(
          icon: Icons.call_end,
          backgroundColor: Colors.red,
          iconColor: Colors.white,
          label: "Decline",
          onPressed: controller.hangUp, //  直接绑定控制器方法
        ),
        CallActionButton(
          icon: widget.isVideo ? Icons.videocam : Icons.call,
          backgroundColor: Colors.green,
          iconColor: Colors.white,
          label: "Accept",
          onPressed: controller.acceptCall, //  直接绑定控制器方法
        ),
      ],
    );
  }

  /// 通话中操作栏 (静音/免提等)
  /// 需要 State (渲染图标状态) 和 Controller (触发点击)
  Widget _buildConnectedActions(CallState state, CallController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 静音按钮
        CallActionButton(
          icon: state.isMuted ? Icons.mic_off : Icons.mic,
          label: "Mute",
          isActive: state.isMuted,
          onPressed: controller.toggleMute,
        ),

        // 摄像头开关
        CallActionButton(
          icon: state.isCameraOff ? Icons.videocam_off : Icons.videocam,
          label: "Camera",
          isActive: state.isCameraOff,
          onPressed: controller.toggleCamera,
        ),

        // 扬声器
        CallActionButton(
          icon: state.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
          label: "Speaker",
          isActive: state.isSpeakerOn,
          onPressed: controller.toggleSpeaker,
        ),

        // 挂断
        CallActionButton(
          icon: Icons.call_end,
          backgroundColor: Colors.red,
          iconColor: Colors.white,
          label: "End",
          onPressed: controller.hangUp,
        ),
      ],
    );
  }
}