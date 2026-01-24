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
  // expose player state stream
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // Play or pause audio by id and url/path
  Future<void> play(String id, String urlOrPath) async {
   try {
     if(_currentPlayingId == id && _player.playing) {
       if(_player.playing){
         // 正在播放 -> 暂停
         await _player.pause();
       }else{
         // 未播放 (可能是暂停，也可能是播放结束)
         if(_player.processingState == ProcessingState.completed){
           // 播放结束，重新开始
           await _player.seek(Duration.zero);
         }
         // 暂停中 -> 继续播放
         await _player.play();
       }
        return;
     }

     // 2. 点击了新的消息 (或者第一次播放)
     _currentPlayingId = id;
     // 强制停止之前的
     await _player.stop();

    // 这里的逻辑：如果是 Web 或者是 http 开头，用 UrlSource；否则用 DeviceFileSource
     if(urlOrPath.startsWith('http') || urlOrPath.startsWith('blob:') || kIsWeb) {
       await _player.setUrl(urlOrPath);
     } else {
       await _player.setFilePath(urlOrPath);
     }

      await _player.play();
   }catch(e){
      print(" Audio playback error: $e");
      // 出错重置
      _currentPlayingId = null;
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