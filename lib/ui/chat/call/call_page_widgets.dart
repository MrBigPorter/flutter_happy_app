part of 'call_page.dart';

extension CallPageWidgets on _CallPageState {
  Widget _buildOverlayContent(CallState state) {
    final isConnected = state.status == CallStatus.connected;
    final safeRenderer = (isConnected && state.remoteRenderer != null)
        ? state.remoteRenderer
        : null;

    return CallOverlay(
      isVideo: widget.isVideo && !state.isCameraOff,
      targetAvatar: widget.targetAvatar,
      onTap: () {
        OverlayManager.instance.hide();
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

  Widget _buildLocalWindow(CallState state, {bool isDragging = false}) {
    if (state.localRenderer == null) return const SizedBox();
    return Opacity(
      opacity: isDragging ? 0.7 : 1.0,
      child: LocalVideoView(renderer: state.localRenderer, mirror: true),
    );
  }

  Widget _buildBackgroundLayer(
    CallState state,
    bool showVideoUI,
    bool isConnected,
  ) {
    if (showVideoUI && isConnected && state.remoteRenderer != null) {
      return RemoteVideoView(
        renderer: state.remoteRenderer,
        isConnectionStable: true,
      );
    } else {
      return _buildBlurredAvatar();
    }
  }

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

  // 这里的参数改成了 stateMachine
  Widget _buildDialingActions(CallStateMachine stateMachine) {
    return Center(
      child: CallActionButton(
        icon: Icons.call_end,
        backgroundColor: Colors.red,
        iconColor: Colors.white,
        label: "Cancel",
        size: 72.r,
        onPressed: stateMachine.hangUp,
      ),
    );
  }

  Widget _buildRingingActions(CallStateMachine stateMachine) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CallActionButton(
          icon: Icons.call_end,
          backgroundColor: Colors.red,
          iconColor: Colors.white,
          label: "Decline",
          size: 64.r,
          onPressed: stateMachine.hangUp,
        ),
        CallActionButton(
          icon: widget.isVideo ? Icons.videocam : Icons.call,
          backgroundColor: Colors.green,
          iconColor: Colors.white,
          label: "Accept",
          size: 64.r,
          onPressed: stateMachine.acceptCall,
        ),
      ],
    );
  }

  Widget _buildConnectedActions(
    CallState state,
    CallStateMachine stateMachine,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CallActionButton(
          icon: state.isMuted ? Icons.mic_off : Icons.mic,
          label: "Mute",
          isActive: state.isMuted,
          onPressed: stateMachine.toggleMute,
        ),
        CallActionButton(
          icon: state.isCameraOff ? Icons.videocam_off : Icons.videocam,
          label: "Camera",
          isActive: state.isCameraOff,
          onPressed: stateMachine.toggleCamera,
        ),
        if (!kIsWeb)
          CallActionButton(
            icon: state.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
            label: "Speaker",
            isActive: state.isSpeakerOn,
            onPressed: stateMachine.toggleSpeaker,
          ),
        CallActionButton(
          icon: Icons.call_end,
          backgroundColor: Colors.red,
          iconColor: Colors.white,
          label: "End",
          onPressed: stateMachine.hangUp,
        ),
      ],
    );
  }
}
