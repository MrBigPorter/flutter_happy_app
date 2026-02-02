收到！位置消息 (3.3) 已拿下，咱们的“待办清单”又轻了一点。

这是剔除掉地图功能后的**最新 v4.9 纯净攻坚计划**。目前的绝对核心就是 **“性能优化”**，特别是群头像缓存，这是提升列表流畅度的关键一战。

---

# 🚀 Lucky IM Execution Plan v4.9 (Performance First)

> **🎯 当前战术目标**
> 集中火力攻克 **P0 - 4.2 群头像持久化**。
> 解决痛点：群聊列表在滑动时，因九宫格头像实时计算导致的掉帧和发热问题。

## 🛠️ 第一梯队：性能与交互 (Performance & UX)

| 优先级 | ID | 任务模块 | 状态 | 核心技术路径 |
| --- | --- | --- | --- | --- |
| **🔥 P0** | **4.2** | **群头像持久化 (Group Avatar Persistence)** | **Todo** | **[AssetManager + Canvas + Cache]**<br>

<br>1. **Hash Key**: `md5(sorted_member_urls)` 生成唯一文件名。<br>

<br>2. **二级缓存**: 内存(ImageProvider) -> 本地文件(Disk) -> 网络下载合成。<br>

<br>3. **服务化**: 将绘图逻辑从 UI 剥离到 Service 后台运行。 |
| **P1** | **4.3** | **发送状态动画 (Send Status Animation)** | **Todo** | **[AnimationController]**<br>

<br>优化 Loading 转圈样式，实现“发送中 -> 成功/已读”的平滑透明度/位移动画过渡。 |

## 🌍 第二梯队：社交扩展 (Social Expansion)

| 优先级 | ID | 任务模块 | 状态 | 核心技术路径 |
| --- | --- | --- | --- | --- |
| **P2** | **5.1** | **联系人管理 (Contact System)** | **Todo** | **[Friendship Module]**<br>

<br>搜索用户、好友申请(Request/Accept)、A-Z 通讯录排序列表。 |
| **P3** | **5.2** | **朋友圈 (Moments)** | **Todo** | **[Feed System]**<br>

<br>基于 `GlobalUploadService` 的图文发布与 Timeline 流展示。 |

---

### ⚡️ 立即执行：P0 - 4.2 群头像持久化

咱们刚才已经准备好了 `AvatarCacheManager` 工具类。接下来我们需要编写**合成服务 (GroupAvatarService)**。

这个服务的核心职责是：**在后台下载图片 -> 计算九宫格坐标 -> 绘制成一张新图 -> 存入缓存**。

#### 第二步：GroupAvatarService (合成引擎)

需要引入 `http` 包来下载图片数据。

```dart
// lib/ui/chat/services/group_avatar_service.dart

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../utils/avatar_cache_manager.dart'; // 引用刚才的 CacheManager

class GroupAvatarService {
  
  /// 获取群头像 Provider (对外唯一接口)
  /// 逻辑：查本地缓存 -> 有则返回 FileImage -> 无则合成并返回 MemoryImage (同时存本地)
  static Future<ImageProvider> getGroupAvatar(List<String> memberAvatars) async {
    // 1. 尝试读取本地缓存
    final cachedFile = AvatarCacheManager.instance.getCachedFile(memberAvatars);
    if (cachedFile != null) {
      return FileImage(cachedFile);
    }

    // 2. 无缓存，开始合成
    try {
      final Uint8List? generatedBytes = await _generateGroupAvatarBytes(memberAvatars);
      
      if (generatedBytes != null) {
        // 3. 异步写入缓存，不阻塞当前显示
        AvatarCacheManager.instance.saveImage(memberAvatars, generatedBytes);
        return MemoryImage(generatedBytes);
      }
    } catch (e) {
      debugPrint("⚠️ Group Avatar Gen Failed: $e");
    }

    // 4. 兜底默认图
    return const AssetImage("assets/images/group_default.png");
  }

  /// 核心：下载并绘制九宫格
  static Future<Uint8List?> _generateGroupAvatarBytes(List<String> urls) async {
    // 限制最多 9 张
    final validUrls = urls.take(9).toList();
    if (validUrls.isEmpty) return null;

    final int totalCount = validUrls.length;
    // 设定画布大小 (200x200 足够高清，显示时会缩小)
    const double canvasSize = 200.0; 
    
    // 1. 并发下载所有图片
    final List<ui.Image> images = await Future.wait(
      validUrls.map((url) => _downloadImage(url)),
    );

    // 2. 启动录制
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..isAntiAlias = true;

    // 绘制背景 (浅灰)
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, canvasSize, canvasSize),
      Paint()..color = const Color(0xFFEEEEEE),
    );

    // 3. 九宫格布局计算
    double gap = 4.0; // 间隙
    int rowCount = _getRowCount(totalCount); // 2行还是3行
    // 单元格大小
    double cellSize = (canvasSize - (rowCount + 1) * gap) / rowCount;

    for (int i = 0; i < totalCount; i++) {
      if (i >= images.length) break;

      // 计算坐标 (简化版 Grid)
      int row = i ~/ rowCount;
      int col = i % rowCount;
      
      double x = gap + col * (cellSize + gap);
      double y = gap + row * (cellSize + gap);

      // 居中偏移修正 (针对 3张、7张这种不对称情况，仿微信逻辑可在此处优化)
      // 这里先用标准 Grid 填充

      _drawImage(canvas, images[i], x, y, cellSize, paint);
    }

    // 4. 导出 PNG
    final ui.Picture picture = recorder.endRecording();
    final ui.Image compositeImage = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final ByteData? byteData = await compositeImage.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  // 下载辅助方法
  static Future<ui.Image> _downloadImage(String url) async {
    final Completer<ui.Image> completer = Completer();
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        ui.decodeImageFromList(response.bodyBytes, (ui.Image img) {
          completer.complete(img);
        });
      } else {
        throw Exception("Download error");
      }
    } catch (e) {
      throw e;
    }
    return completer.future;
  }
  
  // 绘制辅助方法
  static void _drawImage(Canvas canvas, ui.Image image, double x, double y, double size, Paint paint) {
    canvas.save();
    canvas.translate(x, y);
    
    // 简单的缩放绘制 (Cover 模式)
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size, size),
      paint,
    );
    
    canvas.restore();
  }

  static int _getRowCount(int count) {
    if (count <= 4) return 2;
    return 3;
  }
}

```

代码准备好了，就差把它接到 UI 上了！Ready?