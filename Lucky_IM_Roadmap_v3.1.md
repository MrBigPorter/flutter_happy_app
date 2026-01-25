

# 🚦 Lucky IM Roadmap & Next Steps (v3.1+)

> **当前阶段**：v3.0 核心架构（AssetManager/离线队列/跨平台存储）已彻底稳固。
> **v3.1 目标**：**用户体验感知 (UX)** 与 **群聊基础建设**。

---

## 1. 🔥 v3.1 近期冲刺 (Immediate Priorities)

完善 App 对环境的感知能力，并补齐群聊体验的短板。

### [P0] 全局网络状态感知 (Network Awareness)

**现状**：`OfflineQueueManager` 内部知道断网了，但用户不知道（只看到消息转圈）。

* [ ] **全局提示条**: 在 `ConversationListPage` 顶部添加可折叠的红色/橙色提示条：“当前网络不可用” / “收取中...”。
* [ ] **Socket 状态联动**: 监听 `SocketService.connectionState`，在断线重连时给予用户视觉反馈。

### [P1] 群聊体验补全 (Group Chat Basic)

**现状**：群聊目前和单聊 UI 一样，无法区分是谁发的消息。

* [ ] **群成员昵称**: 在 `ChatBubble` 上方（气泡外）增加显示 `senderName`（仅在群聊且非己方消息时显示）。
* [ ] **群头像逻辑**:
* **Web/App**: 默认显示群组通用头像。
* **进阶**: 实现“九宫格”合成头像逻辑（取群内前 4-9 人头像拼合）。



### [P2] 会话列表细节 (List Polish)

**现状**：发送失败虽然气泡有红点，但退回到列表页后看不出哪条失败了。

* [ ] **列表失败标记**: `ConversationItem` 需要支持 `MessageStatus.failed` 状态，显示红色小图标或文字提示。

---

## 2. 🚀 v3.2 中期规划 (Rich Media)

媒体类型的横向扩展。基于 `AssetManager` 架构，扩展新类型将非常容易。

### [P3] 视频消息 (Video Message)

* [ ] **架构扩展**:
* `AssetManager` 增加 `MessageType.video` 支持 (`chat_video` 目录)。
* `AssetStore` 适配视频后缀 `.mp4`。


* [ ] **功能实现**:
* 发送：选择视频 -> 获取第一帧做封面 -> 压缩 -> 上传。
* 展示：气泡显示封面 + 播放按钮 -> 点击全屏播放 (VideoPlayer)。



### [P4] 文件消息 (File Message)

* [ ] **通用文件**: 支持发送 PDF, DOC, ZIP 等。
* [ ] **Web 适配**: 利用 `File Saver` API 实现 Web 端文件下载。

---

## 3. 🔮 v4.0 远期展望 (Real-time & Security)

* **[P5] 音视频通话 (WebRTC)**: 1v1 及多人通话。
* **[P6] 全局搜索 (FTS)**: 基于本地数据库的聊天记录全文检索。
* **[P7] 端到端加密 (E2EE)**: Signal Protocol 集成。

---

## 📝 下一步行动指令 (Next Action)

**既然失败重发 UI 已经完成，我们直接进入 [P0] 网络感知 的开发：**

👉 **任务**: 实现 **全局网络提示条**。

1. 在 `ConversationListPage` 监听 `Connectivity` 或 `Socket` 状态。
2. 当状态为 `disconnected` 时，在 AppBar 下方滑出一个红色 Warning Bar。

