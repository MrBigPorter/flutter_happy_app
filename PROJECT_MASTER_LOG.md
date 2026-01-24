# 🏛️ Lucky IM 项目核心蓝图 (Project Master Log v2.0)

> **🔴 状态校准 (2026-01-24)**
> 当前架构已完成 **方案 B (Client-First ID + Zero Jitter)** 的全量重构。
> **核心变更**：
> 1. 彻底移除 `tempId` 概念，发送时即生成终身 `id` (UUID)。
> 2. 彻底移除 `replaceMessage`，仅使用 `updateMessage` 更新状态。
> 3. 语音全链路（录制-发送-播放-红点）已闭环。

---

## 1. 🗺️ 代码地如 (Code Map) - 你现在的代码结构
*(核对你的文件是否与此一致)*

### A. 数据层 (Database)
* **文件**: `local_database_service.dart`
* **关键方法**:
    * `saveMessage(msg)`: 用于发送初始状态（Sending）。
    * `updateMessage(id, updates)`: **[核心]** 用于 API 成功后更新状态、点击播放后消除红点。
    * **已废弃**: `replaceMessage` (代码可留存但逻辑中不再调用)。

### B. 控制层 (Controller)
* **文件**: `chat_room_controller.dart`
* **发送流程**:
    1.  生成 `msgId = Uuid().v4()`.
    2.  `saveMessage` (UI 上屏).
    3.  `Api.sendMessage` (透传 ID).
    4.  `updateMessage` (更新 `status: success`, `seqId`, `createdAt`).
* **重发流程**:
    * `resendMessage(msgId)` -> 读取原消息 -> `_executeSend`.

### C. 模型层 (Model)
* **文件**: `chat_ui_model.dart`
* **关键字段**:
    * `id`: 终身 UUID。
    * `meta`: 存放 `{'w': 100, 'h': 200, 'duration': 5}`。
    * `isPlayed`: **[新增]** `bool`。自己发的默认 true，收到的语音默认 false。

### D. UI 层 (Widgets)
* **文件**: `voice_message_bubble.dart` **[新增]**
    * **逻辑**: 根据 `!isMe && !isPlayed` 显示红点。
    * **交互**: 点击播放 -> `updateMessage(id, {'isPlayed': true})`。

---

## 2. 🛡️ 架构铁律 (The Iron Rules)
**AI 在写代码时必须死守的三条红线：**

1.  **ID 唯一性原则**：
    * 前端生成 ID。
    * 后端接口必须接受 `id` 字段。
    * **严禁**依靠后端返回新 ID 来替换前端 ID。

2.  **UI 零抖动原则**：
    * **严禁**在发送成功后删除旧消息插入新消息。
    * 必须使用 `update` 操作，保持 Flutter Widget 的 `Key` 不变，防止图片闪烁/语音中断。

3.  **单向数据流原则**：
    * UI 只听 DB (`watchMessages`)。
    * 交互只改 DB (`save`/`update`)。
    * UI 不直接依赖 API 回调刷新。

---

## 3. ✅ 已完结功能 (Checklist)

- [x] **列表防抖**：图片/语音发送不闪烁。
- [x] **Web 兼容**：`dart:io` 隔离，Blob 上传修复。
- [x] **语音发送**：`.m4a` 格式，时长 (`duration`) 透传。
- [x] **语音播放**：`just_audio` 集成。
- [x] **语音红点**：数据模型支持，点击自动消除。

## 4. 🚧 待办任务 (Next Steps)

*(当前语音红点代码已给出，等待验证，下一步是多媒体细节优化)*

1.  **验证红点逻辑**：运行 App，测试接收语音是否有红点，点击是否消失。
2.  **Web 图片缓存**：解决 Web 端 Blob URL 刷新失效问题 (需建立 CDN URL -> Blob 的恢复机制)。
3.  **断网重发队列**：引入自动重试机制。

---

> **🚀 提示词 (Prompt)**：
> 以后发给我指令时，请说：*"基于 Project Master Log v2.0，我们下一步..."*