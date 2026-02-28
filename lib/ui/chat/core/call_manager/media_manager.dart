import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/material.dart';

class MediaManager {
  MediaStream? localStream;
  void Function(bool isSpeakerOn)? onSpeakerStateChanged;

  bool _isVideoMode = true;
  bool _isCurrentlySpeakerOn = false;
  bool _expectedSpeakerState = true;
  bool _isUserManualToggling = false;
  //  1. 新增：记录最后一次物理插拔的时间
  DateTime? _lastDeviceChangeTime;

  Timer? _debounceTimer;

  //  2. 新增：判断是否刚刚发生过插拔（2秒内）
  bool get isDeviceJustChanged {
    if (_lastDeviceChangeTime == null) return false;
    return DateTime.now().difference(_lastDeviceChangeTime!).inSeconds < 2;
  }

  Future<void> configureAudioSession(
      bool isVideo,
      bool Function() getIsMuted,
      ) async {
    final session = await AudioSession.instance;
    await session.configure(
      // 🎯 核心修复：必须带有 iOS 的蓝牙和扬声器权限参数，否则 iOS 听不到声音！
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
        (isVideo ? AVAudioSessionCategoryOptions.defaultToSpeaker : AVAudioSessionCategoryOptions.none),
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        _setMicrophoneEnabled(false);
      } else {
        _setMicrophoneEnabled(!getIsMuted());
      }
    });
  }

  void _setMicrophoneEnabled(bool enabled) {
    if (localStream != null && localStream!.getAudioTracks().isNotEmpty) {
      localStream!.getAudioTracks()[0].enabled = enabled;
    }
  }

  Future<void> initLocalMedia(
      bool isVideo,
      RTCVideoRenderer localRen,
      RTCVideoRenderer remoteRen,
      ) async {
    _isVideoMode = isVideo;
    _expectedSpeakerState = isVideo;

    final mediaConstraints = {
      'audio': true,
      'video': isVideo ? {'facingMode': 'user'} : false,
    };

    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    if (localRen.textureId == null) await localRen.initialize();
    if (remoteRen.textureId == null) await remoteRen.initialize();

    localRen.srcObject = localStream;

    if (!kIsWeb) {
      navigator.mediaDevices.ondevicechange = (event) {
        if (_isUserManualToggling) return;
        //  3. 记录物理插拔的确切时间！
        _lastDeviceChangeTime = DateTime.now();

        debugPrint(" [MediaManager] 嗅探到物理插拔，启动防抖...");
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          _autoRouteAudio();
        });
      };

      Future.delayed(const Duration(milliseconds: 500), () {
        _autoRouteAudio();
      });
    }
  }

  Future<void> _autoRouteAudio() async {
    if (kIsWeb || _isUserManualToggling) return;

    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      bool hasExternalDevice = false;

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
        if (_isCurrentlySpeakerOn) {
          debugPrint("🎧 [MediaManager] 检测到外设接入，平滑切换至耳机");
          await Helper.setSpeakerphoneOn(false);
          _isCurrentlySpeakerOn = false;
          onSpeakerStateChanged?.call(false);
        }
      } else {
        if (_isCurrentlySpeakerOn != _expectedSpeakerState) {
          debugPrint("📱 [MediaManager] 无外设，纠正路由 (当前: $_isCurrentlySpeakerOn, 期望: $_expectedSpeakerState)");
          await Helper.setSpeakerphoneOn(_expectedSpeakerState);
          _isCurrentlySpeakerOn = _expectedSpeakerState;
          onSpeakerStateChanged?.call(_expectedSpeakerState);
        } else {
          debugPrint("[MediaManager] 路由状态已达预期，拒绝重复下发指令");
        }
      }
    } catch (e) {
      debugPrint("[MediaManager] 自动路由失败: $e");
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
      _isUserManualToggling = true;
      _debounceTimer?.cancel();

      await Helper.setSpeakerphoneOn(isSpeakerOn);
      _isCurrentlySpeakerOn = isSpeakerOn;
      _expectedSpeakerState = isSpeakerOn;
      onSpeakerStateChanged?.call(isSpeakerOn);
    } catch (_) {
    } finally {
      Future.delayed(const Duration(milliseconds: 1500), () {
        _isUserManualToggling = false;
      });
    }
  }

  void handleAppLifecycleState(AppLifecycleState appState, bool isCameraOff) {
    if (localStream == null) return;

    if (appState == AppLifecycleState.paused || appState == AppLifecycleState.hidden) {
      final videoTracks = localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) videoTracks[0].enabled = false;

    } else if (appState == AppLifecycleState.resumed) {
      final videoTracks = localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty && !isCameraOff) {
        videoTracks[0].enabled = true;
      }
    }
  }

  Future<void> dispose() async {
    _debounceTimer?.cancel();
    if (!kIsWeb) {
      navigator.mediaDevices.ondevicechange = null;
    }
    localStream?.getTracks().forEach((track) => track.stop());
    await localStream?.dispose();
    localStream = null;
  }
}