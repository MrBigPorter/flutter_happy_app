# 🏛️ Lucky IM 项目核心蓝图 (Project Master Log v2.3)

> **🔴 状态校准 (2026-01-24)**
> **里程碑达成：核心收发闭环 (Core Loop Completed)**
> 现有系统已具备商业级 IM 的即时性与准确性。我们在功能广度（全消息类型）和深度（架构健壮性）上都已达标。
>
> **🟢 当前阶段：v3.0 体验突围 (Experience Breakthrough)**
> **目标**：从“能用的 Demo”进化为“好用的产品”。重点攻克 **弱网环境下的可靠性** (断网自动重发) 与 **Web 端媒体体验** (图片缓存)。

---

## 1. 🗺️ 代码地图 (Code Map) - v2.2 已落地架构

### A. 数据层 (Database)
* **文件**: `local_database_service.dart`
* **机制**: Sembast (NoSQL)。
* **逻辑**: 接收所有数据更新 (包括批量已读)，保持数据层的一致性 (All Read)，不关心 UI 显示。

### B. 全局监听层 (Global Listener)
* **文件**: `conversation_provider.dart` (`ConversationListNotifier`)
* **逻辑**: 监听 Socket -> 强制存库 -> 结合 ActiveID 互斥更新红点。

### C. 聊天室控制层 (Room Controller)
* **文件**: `chat_room_controller.dart`
* **核心机制**:
    * **去重**: `Set<String> _processedMsgIds` 拦截双重广播。
    * **生命周期**: `WidgetsBindingObserver` 确保仅在前台发送回执。
    * **初始化**: 构造函数强制调用 `_setup()`。

### D. UI 层 (ChatPage & Bubble)
* **视觉过滤**:
    * `_buildMessageList`: 计算 `latestReadMsgId`。
    * `ChatBubble`: 仅在最新一条显示 "Read"，拒绝满屏已读。

---

## 2. 🛡️ 架构铁律 (The Iron Rules)
1.  **ID 唯一性**: 前端生成 UUID，后端透传。
2.  **UI 零抖动**: 严禁删旧插新，使用 `update` 操作。
3.  **单向数据流**: UI 听 DB，交互改 DB。
4.  **消息幂等性**: 客户端必须具备处理重复消息的能力，同一 ID 只处理一次。

---

## 3. 🏆 技术攻坚战报 (Technical Trophy Case)
*(v2.1 - v2.2 期间攻克的核心难题)*

#### 🥇 双重广播的回声消除 (Echo Cancellation)
* **难题**: 后端 Fan-out 策略导致在线用户瞬间收到两条 ID 相同的 Socket 消息，引发 UI 闪烁和逻辑重复。
* **攻克**: 在 Controller 层构建即时去重池 (`Set<String>`)，利用幂等性原理，实现 100% 触达率且 0% 重复处理。

#### 🥈 僵尸控制器的生命周期管理 (Zombie Lifecycle)
* **难题**: 用户退后台后，Socket 监听器仍“诈尸”自动发送已读回执，造成状态欺骗。
* **攻克**: 引入 Flutter Engine 级监听 (`WidgetsBindingObserver`)，构建“销毁标记 + 前台检查 + 自身过滤”三道防线，精准控制已读时机。

#### 🥉 视觉已读的智能降噪 (Visual Noise Reduction)
* **难题**: 数据库全量已读导致 UI 满屏 "Read"，视觉体验极差。
* **攻克**: 实施 UI/Data 分离，开发“倒序锚点算法”，仅锁定最新一条已读消息作为视觉锚点，完美复刻主流 IM 体验。

#### 🏅 零抖动发送架构 (Zero-Jitter Architecture)
* **难题**: 传统“发后换 ID”方案导致气泡闪烁和列表跳动。
* **攻克**: 确立 Client-ID 优先原则，配合数据库 `upsert` 机制，实现发送全过程 UI 绝对静止，仅状态图标流转。

---

## 4. 🔮 v3.0 核心功能技术规划 (Technical Blueprint)

### A. 👑 断网重发队列 (Offline Send Queue)
> **目标**：实现 "Fire and Forget"（发后即忘）。用户点击发送后，无需在此等待，系统负责确达。

* **设计模式**: **Outbox Pattern (发件箱模式)**
* **核心组件**:
    1.  **QueueManager (单例)**: 全局网络监听器 (`connectivity_plus`)。
    2.  **DB 状态升级**: 消息状态增加 `pending_retry`。
* **工作流程**:
    1.  **拦截**: 发送失败 (SocketException) -> 不标红，保持 `sending` -> 存入 DB。
    2.  **监听**: 网络恢复 (None -> Mobile/Wifi) -> 触发 `flushQueue()`。
    3.  **重试策略**: 指数退避 (1s -> 2s -> 5s)，5次失败后最终亮红灯。

### B. 🖼️ Web 媒体体验增强 (Web Media Optimization)
> **目标**：解决 Web 端 Blob URL 刷新失效及大图加载闪烁问题。

* **智能路由 2.0**: Web 端优先使用内存 Blob，CDN URL 作为降级兜底。
* **持久化缓存**: 引入 Web 兼容的缓存策略，确保鉴权图片不重复消耗带宽。

---

## 5. ✅ 已完结功能 (Checklist)

### 🧩 核心功能 (Features)
- [x] **文本消息**：支持超长文本、UI自适应、复制与本地删除。
- [x] **语音全链路**：录制、发送、播放进度条、时长透传、播放后红点消除。
- [x] **图片全链路**：Web 智能路由 + App 本地路径优先策略。

### 🏗️ 架构与体验 (Architecture & UX)
- [x] **架构重构**：方案 B (Client ID + Zero Jitter) 落地。
- [x] **红点闭环**：ActiveID 互斥逻辑，解决“该红不红/不该红乱红”问题。
- [x] **Socket 健壮性**：解决反复 Join Room 问题；生命周期管理。
- [x] **性能防御**：前端实现消息去重，抵御双重广播。
- [x] **体验优化**：实现 Messenger 风格的“最新一条显示已读”。

---

## 6. 🚦 待办任务 (Next Steps)

1.  **[P0] 断网重发队列**:
    * [ ] 引入 `connectivity_plus`。
    * [ ] 实现 `QueueManager` 与指数退避算法。
    * [ ] 改造 `ChatRoomController` 错误处理逻辑。
2.  **[P1] Web 图片优化**:
    * [ ] 优化 Web 端图片加载闪烁。
    * [ ] 完善 Blob 失效后的自动恢复。
3.  **[P2] 离线推送**:
    * [ ] 集成 FCM (Firebase Cloud Messaging)。

---

> **🚀 提示词 (Prompt)**：
> 以后发给我指令时，请说：*"基于 Project Master Log v2.3，我们下一步..."*