import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/material.dart';

class MediaManager {
  MediaStream? localStream;

  // Callback to notify UI when speaker state changes
  void Function(bool isSpeakerOn)? onSpeakerStateChanged;

  // Internal state tracking
  bool _isVideoMode = true;
  bool _isCurrentlySpeakerOn = false;
  bool _expectedSpeakerState = true;
  bool _isUserManualToggling = false;

  // Timestamp for the last hardware device change (e.g., unplugging headphones)
  DateTime? _lastDeviceChangeTime;

  Timer? _debounceTimer;

  // Helper to check if a device change occurred within the last 2 seconds
  bool get isDeviceJustChanged {
    if (_lastDeviceChangeTime == null) return false;
    return DateTime.now().difference(_lastDeviceChangeTime!).inSeconds < 2;
  }

  // Configure global audio session settings
  Future<void> configureAudioSession(
      bool isVideo,
      bool Function() getIsMuted,
      ) async {
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
        (isVideo ? AVAudioSessionCategoryOptions.defaultToSpeaker : AVAudioSessionCategoryOptions.none),
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );

    // Listen for system-level interruptions (e.g., incoming phone calls)
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        debugPrint("[MediaManager] Audio focus preempted, performing passive mute");
        _setMicrophoneEnabled(false);
      } else {
        debugPrint("[MediaManager] Audio focus restored");
        _setMicrophoneEnabled(!getIsMuted());
      }
    });
  }

  void _setMicrophoneEnabled(bool enabled) {
    if (localStream != null && localStream!.getAudioTracks().isNotEmpty) {
      localStream!.getAudioTracks()[0].enabled = enabled;
    }
  }

  // Initialize local media streams (Camera/Mic)
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

    // Ensure renderers are initialized
    if (localRen.textureId == null) await localRen.initialize();
    if (remoteRen.textureId == null) await remoteRen.initialize();

    localRen.srcObject = localStream;

    // Monitor physical hardware changes (Bluetooth/Wired headsets)
    if (!kIsWeb) {
      navigator.mediaDevices.ondevicechange = (event) {
        if (_isUserManualToggling) return;

        // Record timestamp of hardware change
        _lastDeviceChangeTime = DateTime.now();

        debugPrint("[MediaManager] Audio peripheral change detected, starting debounce...");
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          _autoRouteAudio();
        });
      };

      // Initial route check after startup stabilization
      Future.delayed(const Duration(milliseconds: 500), () {
        _autoRouteAudio();
      });
    }
  }

  // Intelligent audio routing logic based on peripheral availability
  Future<void> _autoRouteAudio() async {
    if (kIsWeb || _isUserManualToggling) return;

    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      bool hasExternalDevice = false;

      // Check for active external audio devices
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
        // If external device is connected, disable speakerphone
        if (_isCurrentlySpeakerOn) {
          debugPrint("[MediaManager] External device detected, switching audio to headset");
          await Helper.setSpeakerphoneOn(false);
          _isCurrentlySpeakerOn = false;
          onSpeakerStateChanged?.call(false);
        }
      } else {
        // Restore to expected state if no external device is present
        if (_isCurrentlySpeakerOn != _expectedSpeakerState) {
          debugPrint("[MediaManager] No external device, correcting route (Current: $_isCurrentlySpeakerOn, Expected: $_expectedSpeakerState)");
          await Helper.setSpeakerphoneOn(_expectedSpeakerState);
          _isCurrentlySpeakerOn = _expectedSpeakerState;
          onSpeakerStateChanged?.call(_expectedSpeakerState);
        } else {
          debugPrint("[MediaManager] Route already matches expected state, skipping update");
        }
      }
    } catch (e) {
      debugPrint("[MediaManager] Auto routing failed: $e");
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

  // Manually toggle speakerphone state
  Future<void> toggleSpeaker(bool isSpeakerOn) async {
    if (kIsWeb) return;
    try {
      // Enable shield to prevent hardware feedback loops during transition
      _isUserManualToggling = true;
      _debounceTimer?.cancel();

      await Helper.setSpeakerphoneOn(isSpeakerOn);
      _isCurrentlySpeakerOn = isSpeakerOn;
      _expectedSpeakerState = isSpeakerOn;
      onSpeakerStateChanged?.call(isSpeakerOn);
    } catch (_) {
    } finally {
      // Release shield after 1.5 seconds once hardware stabilizes
      Future.delayed(const Duration(milliseconds: 1500), () {
        _isUserManualToggling = false;
      });
    }
  }

  // Manage media tracks based on App lifecycle (Background/Foreground)
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