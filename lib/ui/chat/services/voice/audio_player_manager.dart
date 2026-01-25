
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerManager {
  // 单例模式保持不变
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
      // 1. 处理相同消息的播放/暂停/重播逻辑
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

      // 2. 准备播放新资源
      _currentPlayingId = id;
      await _player.stop();

      //  核心修复：路径清洗逻辑
      // 某些 iOS 路径可能带有 file:// 协议头，需要去掉才能通过 setFilePath 正常加载
      String cleanSource = urlOrPath;
      if (!kIsWeb && cleanSource.startsWith('file://')) {
        cleanSource = cleanSource.replaceFirst('file://', '');
      }

      // 3. 根据协议类型分发加载任务
      if(cleanSource.startsWith('http') || cleanSource.startsWith('blob:') || kIsWeb) {
        // 网络资源或 Web 端 Blob 资源
        await _player.setUrl(cleanSource);
      } else {
        // 本地物理路径
        // 此时 cleanSource 必须是动态拼接后的绝对路径
        await _player.setFilePath(cleanSource);
      }

      await _player.play();
    } catch(e) {
      debugPrint("Audio playback error: $e"); // 使用 debugPrint 代替 print
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