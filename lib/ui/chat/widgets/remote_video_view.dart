import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class RemoteVideoView extends StatelessWidget {
  final RTCVideoRenderer? renderer;
  final bool isConnectionStable; // 可以拓展网络状态提示

  const RemoteVideoView({
    super.key,
    this.renderer,
    this.isConnectionStable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey[900], // 默认背景色
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 视频层
          if (renderer != null && renderer!.textureId != null)
            RTCVideoView(
              renderer!,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: false, // 对方不需要镜像
            )
          else
            _buildPlaceholder(),

          // 2. 网络不稳定提示层 (可选)
          if (!isConnectionStable)
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Network unstable...",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            "Connecting to video...",
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}