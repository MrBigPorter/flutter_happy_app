import 'package:flutter/cupertino.dart';

class ServerTimeHelper {
  // 单例模式，私有的构造函数
  // 私有构造：外部不能 new
    ServerTimeHelper._();

    // 核心变量：时间偏移量 (毫秒)
    // 默认为 0，表示信任本地时间（直到第一次请求成功）
    static int _offset = 0;

    /// 获取校准后的当前时间
    /// 所有倒计时逻辑都必须调用这个，而不是 DateTime.now()
    static DateTime get now {
      return DateTime.now().add(Duration(milliseconds: _offset));
    }

    /// 获取校准后的毫秒时间戳
    static int get nowMilliseconds {
      // 本地时间戳 + 偏移量 = 服务器时间戳，本地快了减，慢了就加
      return DateTime.now().millisecondsSinceEpoch + _offset;
    }

    /// 更新偏移量 (在 Dio 拦截器中调用)
    /// serverTimeStr: 后端返回的 x-server-time
    static void updateOffset(String? serverTimeStr){
       if(serverTimeStr == null || serverTimeStr.isEmpty) return;

       try{
         final int serverTime = int.parse(serverTimeStr);
         final int localTime = DateTime.now().millisecondsSinceEpoch;

         // 计算偏移量：服务器快，offset 为正；服务器慢，offset 为负
         // 这里忽略了网络传输耗时(RTT)，对于团购倒计时来说，
         // 几百毫秒的误差是可以接受的，不需要做复杂的 NTP 算法
         // 服务器时间和本地时间的差值，即为偏移量+本地时间，就是当前服务器时间
         _offset = serverTime - localTime;

         debugPrint("ServerTimeHelper: 服务器时间校准成功，偏移量: $_offset ms");
       }catch(e) {
          // 解析失败则忽略
        // print("ServerTimeHelper: 无法解析服务器时间: $serverTimeStr");
       }
    }

    // 核心方法：将服务器过期时间转换为本地时间轴上的时间
    // 传给 CountdownTimer 组件前，必须裹一层这个方法
    static int getLocalEndTime(int serverExpireTimestamp) {
      // 原理：ServerExpire - Offset = LocalExpire
      return serverExpireTimestamp - _offset;
    }
}