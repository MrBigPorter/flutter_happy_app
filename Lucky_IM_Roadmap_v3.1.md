
# 🚦 Lucky IM Roadmap (Next Steps) - v3.7 Media & Performance

> **🚀 当前阶段**：v3.7 Media Breakthrough (流媒体突破)
> **🎯 核心目标**：从“图文 IM”跨越到“多媒体 IM”，构建**原生级流媒体处理全链路**。

---

## 1. 🎬 v3.7 媒体引擎 (Rich Media Engine) —— **当前优先级：最高**

### 🚧 [P1] 视频消息：Messenger 级非全屏播放 (Inline Video)

> **现状**：图片发送已稳固。目标是实现 Messenger/Telegram 风格的“气泡内即时预览”。

* **发送全链路 (The Engine)**:
* **智能压缩**: 集成 `video_compress` 实现分级压缩（适配带宽）。
* **首帧与元数据**: 提取封面图的同时，**必须记录视频宽高比 (Aspect Ratio)** 并存入消息 `meta` 字段，确保气泡在视频加载前布局不抖动。
* **双通异步上传**: 封面图（极速）+ 视频文件（断点续传）。


* **交互表现 (The UI)**:
* **气泡内预览**: 自动循环静音播放。集成 `visibility_detector` 实现“滑入播放，滑出暂停”，严格控制 CPU/内存占用。
* **生命周期管理**: 建立 **视频控制器池 (Controller Pool)**，确保列表滑动时旧气泡的 `VideoPlayerController` 被及时 `dispose`。
* **无感切换**: 点击气泡仅触发“解除静音”或弹出轻量级控制条，非必要不打断聊天流跳转全屏。



### 🚧 [P2] 文件消息 (File Message)

* **渲染逻辑**: 根据后缀名自动匹配对应的 UI 图标库（PDF, DOCX, ZIP 等）。
* **传输管理**: 实现气泡内下载进度展示，通过 `open_file` 调用系统应用打开。

---

## 2. ⚡ 性能与存储优化 (Optimization)

### 🛠️ [P3] 离线头像持久化 (Group Avatar Caching)

> **逻辑**: 将九宫格布局从“内存实时排版”升级为“本地物理存储”。

* **Canvas 合成**: 后台线程绘制 9 张头像到 Canvas。
* **本地化路径**: 合成 PNG 文件并存入 Sembast `localAvatarPath` 字段，实现 **Offline-First** 秒开。
* **收益**: 列表滑动帧率维持在 60fps，即便无网也能看到高清合成头像。

---

## 3. 🔮 v4.0 远期展望 (Advanced Features)

* **[P5] 音视频通话 (WebRTC)**: 1v1 实时通话与群组对讲。
* **[P6] 全局搜索 (FTS)**: 基于本地数据库的消息/联系人全文本检索。

---

## 📝 指挥官指令 (Action Plan)

**现在的 Lucky IM 即将告别“静态时代”，拥抱“动态流媒体”。**

👉 **接下来的具体执行步骤**：

1. **扩展 `AssetManager**`：增加对视频文件及其关联缩略图的路径管理逻辑。
2. **编写视频预处理工具类**：封装一个 `MediaProcessor`，一键实现 **“视频选取 -> 提取首帧 -> 获取宽高比 -> 返回 DTO”** 的流程。
3. **构建 `InlineVideoBubble**`：实现基于 `visibility_detector` 的控制器自动管理组件。

**你想让我先帮你写出这个核心的 `MediaProcessor` 工具类，还是先搭好 `InlineVideoBubble` 的生命周期框架？**