import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerManager {
  // Singleton instance
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  // Factory constructor
  factory AudioPlayerManager() => _instance;
  // Private constructor
  AudioPlayerManager._internal();

  final AudioPlayer _player = AudioPlayer();
  String? _currentPlayingId;

  // expose current playing id
  String? get currentPlayingId => _currentPlayingId;
  bool isPlaying(String id) => _currentPlayingId == id && _player.playing;

  // Play or pause audio by id and url/path
  Future<void> play(String id, String urlOrPath) async {
   try {
     if(_currentPlayingId == id && _player.playing) {
       await _player.pause();
       return;
     }

     _currentPlayingId = id;

    // 这里的逻辑：如果是 Web 或者是 http 开头，用 UrlSource；否则用 DeviceFileSource
     if(urlOrPath.startsWith('http') || urlOrPath.startsWith('blob:') || kIsWeb) {
       await _player.setUrl(urlOrPath);
     } else {
       await _player.setFilePath(urlOrPath);
     }

      await _player.play();
   }catch(e){
      print(" Audio playback error: $e");
   }
  }

  // Stop playback
  Future<void> stop() async {
    await _player.stop();
    _currentPlayingId = null;
  }

  void dispose() {
    _player.dispose();
  }
}