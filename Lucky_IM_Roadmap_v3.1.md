# 🚦 Lucky IM Roadmap & Next Steps (v3.1+)

> **当前阶段**：v3.0 基础架构已稳固，进入 **v3.1 体验与业务突围** 阶段。
> **核心目标**：完善异常状态反馈，扩展群聊业务。

---

## 1. 🔥 近期冲刺 (Immediate Priorities - v3.1)

这些是 v3.0 功能的“最后一公里”，必须优先完成，让用户感知到功能的完整性。

### [P0] 发送失败 UI 反馈 (Failure Feedback)
**现状**：`OfflineQueueManager` 会在后台静默重试 5 次，如果最终失败，DB 状态变为 `failed`，但 UI 上没有任何提示，用户不知道消息丢了。
* [ ] **气泡改噪**: 在 `ChatBubble` 的 `_buildStatusPrefix` 中添加红色感叹号图标 ❗️。
* [ ] **交互逻辑**: 点击感叹号 -> 弹窗确认 -> 触发 `chatController.resendMessage(msg.id)`。
* [ ] **列表提示**: 在会话列表页 (`ConversationItem`) 显示“发送失败”字样或红色图标。

### [P1] 网络状态感知 (Network Awareness)
**现状**：用户不知道当前是否断网。
* [ ] **全局提示条**: 在 `ConversationListPage` 顶部添加一个可折叠的红色提示条：“当前网络不可用 / 正在连接...”。
* [ ] **Socket 状态联动**: 监听 `SocketService.connectionState`，实时更新 UI。

---

## 2. 🚀 中期规划 (Mid-term Goals - v3.2)

业务功能的横向扩展，从单聊走向群聊。

### [P2] 群聊业务闭环 (Group Chat)
**现状**：API 已有 `createGroup`，但 UI 层面还很简陋。
* [ ] **群成员展示**: 在群聊气泡上方显示发送者昵称 (`senderName`)。
* [ ] **群头像**: 简单的九宫格头像合成，或允许上传群封面。
* [ ] **群管理**: 加人/踢人/解散群聊的设置页。

### [P3] 消息类型扩展 (Rich Media)
* [ ] **视频消息**:
    * 发送：选择视频 -> 压缩 -> 获取封面图 -> 上传。
    * 展示：播放器组件 (VideoPlayer)。
* [ ] **文件消息**: 发送 PDF/Doc 等通用文件。

---

## 3. 🔮 远期展望 (Long-term Vision - v4.0)

这一阶段将涉及更复杂的实时通讯技术。

* **[P4] 音视频通话 (WebRTC)**:
    * 1v1 语音/视频通话。
    * 集成 CallKit (iOS) / ConnectionService (Android) 实现原生来电体验。
* **[P5] 全局搜索**:
    * 本地数据库全文检索 (FTS)。
* **[P6] 端到端加密 (E2EE)**:
    * Signal Protocol 集成 (可选)。

---

## 📝 下一步行动指令 (Action Item)

**基于 Project Master Log v3.0 的基石，我们立刻开始 v3.1 的冲刺：**

👉 **任务**: 实现 **[P0] 发送失败 UI 反馈**。
1.  修改 `ChatBubble`，增加失败状态图标。
2.  实现点击重发逻辑。