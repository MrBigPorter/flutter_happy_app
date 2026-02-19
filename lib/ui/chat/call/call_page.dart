import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 引入 Riverpod
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../utils/overlay_manager.dart';
import '../models/call_state_model.dart';
import '../providers/call_controller.dart'; // 引入控制器
import '../widgets/call_action_button.dart';
import '../widgets/local_video_view.dart';
import '../widgets/remote_video_view.dart';
import '../widgets/user_avatar_view.dart';
import 'call_overlay.dart';

part 'call_page_widgets.dart';

// 改为 ConsumerStatefulWidget
class CallPage extends ConsumerStatefulWidget {
  final String targetId; // 目标用户 ID，必须有
  final String targetName;
  final String? targetAvatar;
  final bool isVideo;

  const CallPage({
    super.key,
    required this.targetId,
    required this.targetName,
    this.targetAvatar,
    this.isVideo = true,
  });

  @override
  ConsumerState<CallPage> createState() => _CallPageState();
}

class _CallPageState extends ConsumerState<CallPage> {

  @override
  void initState() {
    super.initState();
    // 1. 发起呼叫
    WidgetsBinding.instance.addPostFrameCallback((_){
      // 获取控制器并调用方法
      final controller = ref.read(callControllerProvider.notifier);
      final currentStatus = ref.read(callControllerProvider).status;

      // 2. 判断我是"主叫"还是"被叫"
      // CallStatus.idle (初始状态) -> 说明我是主叫，我刚点进来，需要拨号
      // CallStatus.dialing (拨号中) -> 也是主叫 (可能是热重载导致的，安全起见也可以调用)
      // 只有闲置状态才拨号，防止被叫方误拨回去
      //  核心修复：允许在 idle (首次) 或 ended (后台挂断遗留) 状态下重新拨号
      if (currentStatus == CallStatus.idle || currentStatus == CallStatus.ended) {
        controller.startCall(widget.targetId, isVideo: widget.isVideo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. 监听状态
    final state = ref.watch(callControllerProvider);
    //  2. 获取控制器 (用于调用方法)
    final controller = ref.read(callControllerProvider.notifier);

    // 辅助判断
    final bool isConnected = state.status == CallStatus.connected;
    final bool showVideoUI = widget.isVideo && !state.isCameraOff;

    // 如果通话结束，自动退出
    // 注意：更好的做法是在 listen 里做导航，防止 build 时报错
    ref.listen(callControllerProvider, (prev, next) {
      if (next.status == CallStatus.ended) {
        if(Navigator.canPop(context)){
          Navigator.pop(context);
        }

        //  修复核心：使用 Future.microtask 包裹 invalidate
        // 这样会把"销毁"操作推迟到当前通知循环结束后执行，避免冲突
        Future.microtask(() {
          ref.invalidate(callControllerProvider);
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 背景层
          _buildBackgroundLayer(state, showVideoUI, isConnected),

          // 2. 信息层
          if (!showVideoUI || !isConnected)
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 1),
                    UserAvatarView(
                      userName: widget.targetName,
                      avatarUrl: widget.targetAvatar,
                      statusText: isConnected ? state.duration : "Calling...",
                      isVoiceCall: !widget.isVideo,
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),

          // 3. 本地小窗
          if (isConnected && showVideoUI)
            Positioned(
              left: state.floatOffset.dx,
              top: state.floatOffset.dy,
              child: Draggable(
                feedback: _buildLocalWindow(state, isDragging: true),
                childWhenDragging: Container(),
                onDraggableCanceled: (Velocity velocity, Offset offset) {
                  // 更新位置 -> 调用 Controller
                  controller.updateFloatOffset(Offset(
                    offset.dx.clamp(0.0, 1.sw - 100.w),
                    offset.dy.clamp(0.0, 1.sh - 150.h),
                  ));
                },
                child: _buildLocalWindow(state),
              ),
            ),

          // 4. 底部控制栏
          Positioned(
            left: 0,
            right: 0,
            bottom: 40.h,
            child: SafeArea(
              child: _buildActionButtons(state, controller),
            ),
          ),

          // 5. 最小化按钮
          Positioned(
            left: 16.w,
            top: 48.h,
            child: GestureDetector(
              onTap: () => _minimizeToOverlay(state, controller),
              child: Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32.r),
            ),
          ),
        ],
      ),
    );
  }

  /// 根据状态分发按钮组
  Widget _buildActionButtons(CallState state, CallController controller) {
    switch (state.status) {
      case CallStatus.dialing:
      // 主叫：显示取消按钮
        return _buildDialingActions(controller);

      case CallStatus.ringing:
      // 被叫：显示接听/拒绝
        return _buildRingingActions(controller);

      case CallStatus.connected:
      // 通话中：显示功能面板
        return _buildConnectedActions(state, controller);

      case CallStatus.idle:
      case CallStatus.ended:
      // 其它状态显示空的或者退出按钮
        return const SizedBox();
    }
  }

  // --- 逻辑方法也只是简单的转发 ---
  void _minimizeToOverlay(CallState state, CallController controller) {
    Navigator.pop(context);
    OverlayManager.instance.show(
      widget: Stack(
        children: [
          Positioned(
            top: 100.h,
            right: 16.w,
            child: _buildOverlayContent(state), // 这里也需要改一下传参
          ),
        ],
      ),
    );
  }
}