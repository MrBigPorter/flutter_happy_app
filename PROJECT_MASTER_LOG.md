# 🏛️ Lucky IM 项目核心蓝图 (Project Master Log v2.2)

> **🔴 状态校准 (2026-01-24)**
> **里程碑达成：健壮性与细节打磨 (Robustness & Polish)**
> 在 v2.1 全链路闭环的基础上，修复了双重广播带来的副作用，并完善了已读回执的触发时机与显示逻辑。
> **核心变更 (v2.2)**：
> 1.  **前端消息去重 (Deduplication)**：`ChatRoomController` 引入 `Set` 缓存池，拦截后端双重广播产生的重复消息 ID。
> 2.  **生命周期感知 (Lifecycle Aware)**：引入 `WidgetsBindingObserver`，确保仅在 App 前台 (`resumed`) 且 Controller 存活时发送已读回执，杜绝后台“僵尸”行为。
> 3.  **视觉已读优化 (Visual Read Status)**：UI 渲染层增加过滤算法，**仅在最新一条**已读消息下方显示 "Read" 文本，拒绝满屏 "Read"。
> 4.  **初始化修复**: 修复构造函数丢失 `_setup()` 问题，确保 Socket 监听器正确挂载。

---

## 1. 🗺️ 代码地如 (Code Map) - 关键更新

### A. 数据层 (Database)
* **文件**: `local_database_service.dart`
* **机制**: Sembast (NoSQL)。
* **逻辑**: 接收所有数据更新 (包括批量已读)，保持数据层的一致性 (All Read)，不关心 UI 显示。

### B. 全局监听层 (Global Listener)
* **文件**: `conversation_provider.dart` (`ConversationListNotifier`)
* **逻辑**:
    * 监听 Socket，强制存库。
    * **红点互斥**: 结合 `activeConversationIdProvider`，如果用户正在浏览该房间，则 `unreadCount` 强制归零，否则 +1。

### C. 聊天室控制层 (Room Controller)
* **文件**: `chat_room_controller.dart`
* **增强逻辑 (v2.2)**:
    * **去重**: `_processedMsgIds.contains(id)` ? `return` : `process`.
    * **生命周期**: `if (!mounted || appState != resumed) return`.
    * **初始化**: 构造函数强制调用 `_setup()`。

### D. UI 层 (ChatPage & Bubble)
* **文件**: `chat_page.dart` / `chat_bubble.dart`
* **视觉过滤**:
    * `_buildMessageList`: 遍历消息列表，计算出 `latestReadMsgId` (第一条 isMe && Read)。
    * `ChatBubble`: 接收 `showReadStatus` 参数，仅匹配 ID 时渲染文本。

---

## 2. 📡 广播与触达策略 (Delivery Strategy)
* **双重广播 (Current)**: 房间广播 (Online) + 用户广播 (List/Background)。
* **漏斗模型**:
    1.  **In Room**: Socket (去重后处理，不发红点，发已读)。
    2.  **In App (Background)**: Socket (更新红点)。
    3.  **Killed/Offline**: *[待开发]* FCM/APNs 推送。

---

## 3. 🛡️ 架构铁律 (The Iron Rules)
1.  **ID 唯一性**: 前端生成 UUID，后端透传。
2.  **UI 零抖动**: 严禁删旧插新，使用 `update` 操作。
3.  **单向数据流**: UI 听 DB，交互改 DB。
4.  **消息幂等性 (v2.2新增)**: 客户端必须具备处理重复消息的能力 (Idempotency)，同一 ID 只处理一次。

---

## 4. ✅ 已完结功能 (Checklist)

- [x] **架构重构**：方案 B (Client ID + Zero Jitter) 落地。
- [x] **红点闭环**：ActiveID 互斥逻辑，解决“该红不红/不该红乱红”问题。
- [x] **Socket 健壮性**：解决反复 Join Room 问题；解决构造函数漏调 Setup 问题。
- [x] **性能防御**：前端实现消息去重，抵御双重广播。
- [x] **体验优化**：实现 Messenger 风格的“最新一条显示已读”。

## 5. 🚦 待办任务 (Next Steps)

*(进入 v3.0 预备阶段)*

1.  **Web 媒体优化**:
    * [ ] **Blob 降级**: 完善 Web 端 Blob URL 失效后的自动 CDN 恢复机制。
    * [ ] **图片缓存**: 优化查看大图时的加载体验。
2.  **离线推送 (Notification)**:
    * [ ] 集成 FCM (Firebase Cloud Messaging) 处理 App 离线时的通知。
3.  **断网重发**:
    * [ ] 引入 Job Queue 处理发送失败的消息。

---

> **🚀 提示词 (Prompt)**：
> 以后发给我指令时，请说：*"基于 Project Master Log v2.2，我们下一步..."*