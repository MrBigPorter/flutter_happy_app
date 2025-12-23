import 'package:flutter/services.dart';
import 'package:flutter_app/core/api/index.dart';
import 'package:permission_handler/permission_handler.dart';

class LivenessService {
  //  语法点 1：定义频道 (Channel)
  // 口诀：这个字符串就是"电话号码"，Android/iOS 必须一字不差！
  // 建议格式：包名/功能名
  static const MethodChannel _channel = MethodChannel('com.joyminis.flutter_app/liveness');

  /// 对外暴露的方法：开始活体检测
  static Future<bool?> start(String sessionId) async {

    // 1. 先要相机权限，没权限原生端会直接崩
    var status = await Permission.camera.request();
    if(!status.isGranted){
      print('no permission');
      return false;
    }

    try {
      //  语法点 2：调用方法 (invokeMethod)
      // 参数 1："start" 是暗号 (Method Name)
      // 参数 2：Map 是要传的数据 (Arguments)
      // await 是必须的，因为跨端通信是异步的
      final result = await _channel.invokeMethod('start', {
        'sessionId': sessionId,
        'region': 'us-east-1'
      });

      // 2. 解析原生返回的 Map
      // 注意：result 是个 Map<Object?, Object?>，可能需要转一下类型
      final Map<dynamic, dynamic> data =  result as Map<dynamic, dynamic>;

      final bool isSuccess = data['success'] as bool;

     if(isSuccess ){
       print("🎉 原生采集完成，准备提交后端验证");
     }else{
       String? error = data['error'];
       print("用户取消了检测：${error}");
     }

     return isSuccess;

    } on PlatformException catch (e) {
      print("调用原生失败: ${e.message}");
    }
    return null;
  }
}