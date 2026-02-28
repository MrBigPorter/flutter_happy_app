import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerManager {
  // Singleton Pattern
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;
  AudioPlayerManager._internal();

  final AudioPlayer _player = AudioPlayer();
  String? _currentPlayingId;

  String? get currentPlayingId => _currentPlayingId;
  bool isPlaying(String id) => _currentPlayingId == id && _player.playing;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> play(String id, String urlOrPath) async {
    try {
      // 1. Handles Play/Pause/Replay logic for the same message ID
      if(_currentPlayingId == id && _player.playing) {
        final bool isRunning = _player.playing && _player.processingState != ProcessingState.completed;
        if(isRunning){
          await _player.pause();
        }else{
          if(_player.processingState == ProcessingState.completed){
            await _player.seek(Duration.zero);
          }
          await _player.play();
        }
        return;
      }

      // 2. Prepare for new resource playback
      _currentPlayingId = id;
      await _player.stop();

      // Architectural Fix: Path Sanitization Logic
      // Certain iOS paths may include the 'file://' protocol prefix,
      // which must be stripped for setFilePath to load successfully.
      String cleanSource = urlOrPath;
      if (!kIsWeb && cleanSource.startsWith('file://')) {
        cleanSource = cleanSource.replaceFirst('file://', '');
      }

      // 3. Dispatch loading task based on protocol type
      if(cleanSource.startsWith('http') || cleanSource.startsWith('blob:') || kIsWeb) {
        // Remote network resources or Web-specific Blob resources
        await _player.setUrl(cleanSource);
      } else {
        // Local physical file paths
        // Note: cleanSource must be an absolute path at this stage.
        await _player.setFilePath(cleanSource);
      }

      await _player.play();
    } catch(e) {
      debugPrint("Audio playback error: $e");
      _currentPlayingId = null;
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentPlayingId = null;
  }

  void dispose() {
    _player.dispose();
  }
}