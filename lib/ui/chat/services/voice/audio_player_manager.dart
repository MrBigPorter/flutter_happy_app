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
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;// 播放状态流
  Stream<Duration> get positionStream => _player.positionStream;// 播放进度流
  Stream<Duration?> get durationStream => _player.durationStream;// 总时长流

  // Play or pause audio by id and url/path
  Future<void> play(String id, String urlOrPath) async {
   try {
     if(_currentPlayingId == id && _player.playing) {
       // 核心修复：只有在 [正在播放] 且 [没播完] 的时候，点击才是暂停
       // 如果已经播完了 (completed)，即使 playing 为 true，点击也应该是重播
       final bool isRunning = _player.playing && _player.processingState != ProcessingState.completed;
       if(isRunning){
         // 正在播放 -> 暂停
         await _player.pause();
       }else{
         // 否则（暂停中 或 已播完），都是播放
         if(_player.processingState == ProcessingState.completed){
           // 播放结束，重新开始, 播完的要归零
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