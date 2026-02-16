import 'dart:ui';
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
  final String targetName;
  final String? targetAvatar;
  final bool isVideo;

  const CallPage({
    super.key,
    required this.targetName,
    this.targetAvatar,
    this.isVideo = true,
  });

  @override
  ConsumerState<CallPage> createState() => _CallPageState();
}

class _CallPageState extends ConsumerState<CallPage> {

  // 这里的状态变量全删掉！全部移交给 CallController 管理

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

        // 2.  核心：彻底销毁 Provider，释放内存，为下一次通话重置状态
        // 这样下次进来就是一个全新的 Controller
        ref.invalidate(callControllerProvider);
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
              child: isConnected
                  ? _buildConnectedActions(state, controller)
                  : _buildIncomingActions(controller),
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