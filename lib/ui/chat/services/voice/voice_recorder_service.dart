import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'dart:io';

class VoiceRecorderService {
  // Singleton Pattern
  static final VoiceRecorderService _instance = VoiceRecorderService._internal();
  factory VoiceRecorderService() => _instance;
  VoiceRecorderService._internal();

  final _audioRecorder = AudioRecorder();

  /// Exposes the amplitude stream to implement real-time visualization (jumping animations) in the UI.
  Stream<Amplitude> get amplitudeStream => _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  /// Verifies if the application has the necessary microphone permissions.
  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  /// Starts the recording process and returns the local file path.
  Future<String?> start() async {
    if(!await hasPermission()) {
      return null;
    }

    String path;
    if(kIsWeb) {
      // On Web, the 'record' plugin automatically handles the output as a Blob URL.
      path = '';
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final folder = Directory('${appDir.path}/chat_voice');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      // Generate a unique filename using UUID to prevent overwriting.
      path = p.join(folder.path, '${const Uuid().v4()}.m4a');
    }

    // Architectural Note: AAC-LC is chosen for high compatibility across mobile and web players.
    const config = RecordConfig(encoder: AudioEncoder.aacLc);

    await _audioRecorder.start(config, path: path);
    return path;
  }

  /// Stops the recording and returns both the file path and the calculated duration.
  Future<(String?, int?)> stop(DateTime startTime) async {
    final path = await _audioRecorder.stop();
    if (path == null) {
      return (null, null);
    }
    final duration = DateTime.now().difference(startTime).inSeconds;
    return (path, duration);
  }

  /// Releases the recording resources.
  void dispose() {
    _audioRecorder.dispose();
  }
}