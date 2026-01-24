import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'dart:io';

class VoiceRecorderService {
  // 单例模式
  static final VoiceRecorderService _instance = VoiceRecorderService._internal();
  // 录音对象
  factory VoiceRecorderService() => _instance;
  // 私有构造函数
  VoiceRecorderService._internal();

  // 开始录音，返回录音文件路径
  final _audioRecorder = AudioRecorder();

  // 暴露振幅流，供 UI 实现“跳动动画”
  Stream<Amplitude> get amplitudeStream => _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  // 获取权限
  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<String?> start() async {
    if(!await hasPermission()) {
      return null;
    }

    String path;
    if(kIsWeb) {
      // Web 端 record 插件会自动处理为 blob
      path = '';
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final folder = Directory('${appDir.path}/chat_voice');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      // 生成唯一文件名
      path = p.join(folder.path, '${const Uuid().v4()}.m4a');
    }
    // 核心：Web 端通常不需要 Config 指定 Encoder，它会自动选择浏览器支持的
    const config = RecordConfig(encoder: AudioEncoder.aacLc);
    // 返回录音文件路径
    await _audioRecorder.start(config,path: path);
    return path;
  }

  // 停止录音，返回录音文件路径
   Future<(String?, int?)> stop(DateTime startTime) async {
    final path = await _audioRecorder.stop();
    if (path == null) {
      return (null, null);
    }
    final duration = DateTime.now().difference(startTime).inSeconds;
    return (path, duration);
   }

   void dispose() {
    _audioRecorder.dispose();
   }

}