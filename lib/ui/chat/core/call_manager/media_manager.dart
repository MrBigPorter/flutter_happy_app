import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/material.dart';

class MediaManager {
  MediaStream? localStream;

  //  护盾状态：记住当前是视频还是语音，方便拔掉耳机时恢复
  bool _isVideoMode = true;

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
        debugPrint("☎️ [MediaManager] 音频焦点被抢占，执行被动闭麦");
        _setMicrophoneEnabled(false);
      } else {
        debugPrint("✅ [MediaManager] 音频焦点恢复");
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
    _isVideoMode = isVideo; // 记录初始模式

    //  硬件热插拔雷达：时刻监听蓝牙/有线耳机的物理插拔！
    if (!kIsWeb) {
      navigator.mediaDevices.ondevicechange = (event) {
        debugPrint("🔌 [MediaManager] 嗅探到音频外设物理插拔!");
        _autoRouteAudio();
      };

      // 启动时先做一次环境侦测，决定声音从哪出
      await _autoRouteAudio();
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

  //  智能音频路由大脑：根据外设情况，动态剥夺/赋予扬声器权力
  Future<void> _autoRouteAudio() async {
    if (kIsWeb) return;
    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      bool hasExternalDevice = false;

      // 遍历底层网卡，寻找有没有戴上蓝牙或插了线
      for (var device in devices) {
        if (device.kind == 'audiooutput' || device.kind == 'audioinput') {
          final label = device.label.toLowerCase();
          if (label.contains('bluetooth') ||
              label.contains('headset') ||
              label.contains('wired')) {
            hasExternalDevice = true;
            break;
          }
        }
      }

      if (hasExternalDevice) {
        debugPrint("🎧 [MediaManager] 检测到外设接入，强行关闭扬声器独裁，声音交还给耳机");
        // 核心密码：设为 false，WebRTC 就会自动把声音走 SCO 蓝牙通道
        await Helper.setSpeakerphoneOn(false);
      } else {
        debugPrint("📱 [MediaManager] 无外设接入，恢复默认路由 (视频:外放, 语音:听筒)");
        // 拔下耳机，恢复原来的规矩
        await Helper.setSpeakerphoneOn(_isVideoMode);
      }
    } catch (e) {
      debugPrint("❌ [MediaManager] 自动路由失败: $e");
    }
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
    //  拔除监听雷达，防止内存泄漏
    if (!kIsWeb) {
      navigator.mediaDevices.ondevicechange = null;
    }
    localStream?.getTracks().forEach((track) => track.stop());
    await localStream?.dispose();
    localStream = null;
  }
}