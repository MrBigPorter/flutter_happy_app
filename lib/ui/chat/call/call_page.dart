import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../utils/overlay_manager.dart';
import '../core/call_manager/call_state_machine.dart';
import '../models/call_state_model.dart';
import '../widgets/call_action_button.dart';
import '../widgets/local_video_view.dart';
import '../widgets/remote_video_view.dart';
import '../widgets/user_avatar_view.dart';
import 'call_overlay.dart';

part 'call_page_widgets.dart';

class CallPage extends ConsumerStatefulWidget {
  final String targetId;
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
    WidgetsBinding.instance.addPostFrameCallback((_){
      // 换成了 stateMachine
      final stateMachine = ref.read(callStateMachineProvider.notifier);
      final currentStatus = ref.read(callStateMachineProvider).status;

      if (currentStatus == CallStatus.idle || currentStatus == CallStatus.ended) {
        stateMachine.startCall(widget.targetId, isVideo: widget.isVideo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(callStateMachineProvider);
    final stateMachine = ref.read(callStateMachineProvider.notifier);

    final bool isConnected = state.status == CallStatus.connected;
    final bool showVideoUI = widget.isVideo && !state.isCameraOff;

    ref.listen(callStateMachineProvider, (prev, next) {
      if (next.status == CallStatus.ended) {
        if(Navigator.canPop(context)){
          Navigator.pop(context);
        }
        Future.microtask(() {
          ref.invalidate(callStateMachineProvider);
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackgroundLayer(state, showVideoUI, isConnected),
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
          if (isConnected && showVideoUI)
            Positioned(
              left: state.floatOffset.dx,
              top: state.floatOffset.dy,
              child: Draggable(
                feedback: _buildLocalWindow(state, isDragging: true),
                childWhenDragging: Container(),
                onDraggableCanceled: (Velocity velocity, Offset offset) {
                  stateMachine.updateFloatOffset(Offset(
                    offset.dx.clamp(0.0, 1.sw - 100.w),
                    offset.dy.clamp(0.0, 1.sh - 150.h),
                  ));
                },
                child: _buildLocalWindow(state),
              ),
            ),
          Positioned(
            left: 0, right: 0, bottom: 40.h,
            child: SafeArea(
              child: _buildActionButtons(state, stateMachine),
            ),
          ),
          Positioned(
            left: 16.w, top: 48.h,
            child: GestureDetector(
              onTap: () => _minimizeToOverlay(state, stateMachine),
              child: Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CallState state, CallStateMachine stateMachine) {
    switch (state.status) {
      case CallStatus.dialing:
        return _buildDialingActions(stateMachine);
      case CallStatus.ringing:
        return _buildRingingActions(stateMachine);
      case CallStatus.connected:
        return _buildConnectedActions(state, stateMachine);
      case CallStatus.idle:
      case CallStatus.ended:
        return const SizedBox();
    }
  }

  void _minimizeToOverlay(CallState state, CallStateMachine stateMachine) {
    Navigator.pop(context);
    OverlayManager.instance.show(
      widget: Stack(
        children: [
          Positioned(
            top: 100.h, right: 16.w,
            child: _buildOverlayContent(state),
          ),
        ],
      ),
    );
  }
}