import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/material.dart';

class MediaManager {
  MediaStream? localStream;

  //  激活音频焦点与防打断护盾
  Future<void> configureAudioSession(
    bool isVideo,
    bool Function() getIsMuted,
  ) async {
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
            (isVideo
                ? AVAudioSessionCategoryOptions.defaultToSpeaker
                : AVAudioSessionCategoryOptions.none),
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );

    // 监听系统级打断（如普通电话呼入）
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        debugPrint("️ [MediaManager] 音频焦点被抢占，执行被动闭麦");
        _setMicrophoneEnabled(false);
      } else {
        debugPrint(" [MediaManager] 音频焦点恢复");
        _setMicrophoneEnabled(!getIsMuted());
      }
    });
  }

  void _setMicrophoneEnabled(bool enabled) {
    if (localStream != null && localStream!.getAudioTracks().isNotEmpty) {
      localStream!.getAudioTracks()[0].enabled = enabled;
    }
  }

  //  抓取摄像头和麦克风
  Future<void> initLocalMedia(
    bool isVideo,
    RTCVideoRenderer localRen,
    RTCVideoRenderer remoteRen,
  ) async {
    //  kIsWeb 物理隔离护盾
    if (!kIsWeb) {
      try {
        await Helper.setSpeakerphoneOn(isVideo);
      } catch (_) {}
    }

    final mediaConstraints = {
      'audio': true,
      'video': isVideo ? {'facingMode': 'user'} : false,
    };

    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    // 护盾：确保画板一定被初始化
    if (localRen.textureId == null) await localRen.initialize();
    if (remoteRen.textureId == null) await remoteRen.initialize();

    localRen.srcObject = localStream;
  }

  void toggleMute(bool isMuted) {
    _setMicrophoneEnabled(!isMuted);
  }

  void toggleCamera(bool isCameraOff) {
    if (localStream != null && localStream!.getVideoTracks().isNotEmpty) {
      localStream!.getVideoTracks()[0].enabled = !isCameraOff;
    }
  }

  Future<void> toggleSpeaker(bool isSpeakerOn) async {
    if (kIsWeb) return;
    try {
      await Helper.setSpeakerphoneOn(isSpeakerOn);
    } catch (_) {}
  }

  void handleAppLifecycleState(AppLifecycleState appState, bool isCameraOff) {
    if (localStream == null) return;
    final videoTracks = localStream!.getVideoTracks();
    if (videoTracks.isEmpty) return;

    if (appState == AppLifecycleState.paused ||
        appState == AppLifecycleState.hidden) {
      videoTracks[0].enabled = false;
    } else if (appState == AppLifecycleState.resumed) {
      if (!isCameraOff) videoTracks[0].enabled = true;
    }
  }

  Future<void> dispose() async {
    localStream?.getTracks().forEach((track) => track.stop());
    await localStream?.dispose();
    localStream = null;
  }
}
