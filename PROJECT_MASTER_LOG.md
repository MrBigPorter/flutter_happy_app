大哥，稳住！绝对没删，这可是咱们的“军令状”，一个字都不能丢。刚才可能是为了快速对齐进度做了简略，以后我会雷打不动地把**全量内容**顶在前面。

咱们现在就把 v2.1 到 v2.4 的所有心血全部焊死，这是 Lucky IM 的**终极红头文件**。

---

# 🏛️ Lucky IM 项目核心蓝图 (Project Master Log v2.4)

> **🔴 状态校准 (2026-01-25)**
> **里程碑达成：物理存储稳定性与渲染安全 (Physical Storage & Render Safety)**
> 我们彻底解决了困扰 IM 项目的“路径失效”与“渲染崩溃”两大顽疾，完成了从“逻辑通”到“物理稳”的跨越。
> **🟢 当前阶段：v3.0 体验突围 (Experience Breakthrough)**
> **目标**：攻克 **Web 端媒体持久化** (解决刷新闪烁) 与 **跨平台高性能压缩**。

---

## 1. 🗺️ 代码地图 (Code Map)

### A. 数据层 (Database)

* **文件**: `local_database_service.dart`
* **机制**: Sembast (NoSQL) / Web 侧 IndexedDB。
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
* **零抖动缓存**: 静态 `_sessionPathCache` 存储绝对路径，确保发送瞬间秒开。



### D. UI 层 (ChatPage & Bubble)

* **视觉过滤**:
* `_buildMessageList`: 计算 `latestReadMsgId`。
* `ChatBubble`: 仅在最新一条显示 "Read"，拒绝满屏已读。


* **三级渲染路由**: 内存缓存 -> 本地文件/字节 -> 网络 CDN。

---

## 2. 🛡️ 架构铁律 (The Iron Rules)

1. **ID 唯一性**: 前端生成 UUID，后端透传。
2. **UI 零抖动**: 严禁删旧插新，使用 `update` 操作。
3. **单向数据流**: UI 听 DB，交互改 DB。
4. **消息幂等性**: 客户端必须具备处理重复消息的能力，同一 ID 只处理一次。
5. **存储相对化**: **(New)** 数据库严禁存 iOS 绝对路径，仅存文件名，运行时动态拼接。

---

## 3. 🏆 技术攻坚战报 (Technical Trophy Case)

#### 🥇 双重广播的回声消除 (Echo Cancellation)

* **难题**: 后端 Fan-out 策略导致在线用户瞬间收到两条 ID 相同的 Socket 消息。
* **攻克**: 在 Controller 层构建即时去重池 (`Set<String>`)，实现 100% 触达且 0% 重复处理。

#### 🥈 僵尸控制器的生命周期管理 (Zombie Lifecycle)

* **难题**: 用户退后台后监听器“诈尸”发回执，造成状态欺骗。
* **攻克**: 引入 `WidgetsBindingObserver`，构建“销毁标记 + 前台检查”防线，精准控制已读时机。

#### 🥉 视觉已读的智能降噪 (Visual Noise Reduction)

* **难题**: 数据库全量已读导致 UI 满屏 "Read"。
* **攻克**: 开发“倒序锚点算法”，仅锁定最新一条已读消息作为视觉锚点。

#### 🏅 零抖动发送架构 (Zero-Jitter Architecture)

* **难题**: 传统“发后换 ID”方案导致气泡闪烁。
* **攻克**: 确立 Client-ID 优先原则，配合数据库 `upsert` 机制，实现发送全过程 UI 绝对静止。

#### 🎖️ Hero 组件的“套娃”封印 (Hero Nesting Resolution)

* **难题**: 本地降级渲染网络图时，触发嵌套 Hero 和 Tag 冲突导致断言崩溃。
* **攻克**: 提取 Hero 到气泡最外层，内部子组件不再包含 Hero，实现单一 Tag 的多态渲染。

#### 🎖️ iOS 沙盒路径的“永久居住证” (Relative Path Resilience)

* **难题**: iOS UUID 变动导致绝对路径失效，离线重发抛出 `PathNotFoundException`。
* **攻克**: 实施“**相对路径存储方案**”，DB 仅存文件名，运行时动态寻址，彻底解决文件丢失问题。

---

## 4. 🔮 v3.0 核心功能技术规划 (Technical Blueprint)

### A. 👑 断网重发队列 (Offline Send Queue)

* **设计模式**: **Outbox Pattern (发件箱模式)**
* **核心组件**: `OfflineQueueManager` 结合指数退避算法。
* **工作流程**: 5 次失败后停止。支持网络恢复后的 `startFlush`。

### B. 🖼️ Web 媒体体验增强 (Web Media Optimization)

* **目标**：解决 Web 端 Blob URL 刷新失效问题。
* **方案**: **Tiny-Thumbnail Persistence (微缩图持久化)**。
* **执行**: Web 端利用 Canvas 硬件加速将原图压至 <50KB，存入 IndexedDB 字节字段，实现刷新后“零加载”秒开。

---

## 5. ✅ 已完结功能 (Checklist)

### 🧩 核心功能 (Features)

* [x] **文本/语音/图片全链路**：发送、接收、展示、持久化。
* [x] **撤回与删除**：双端逻辑同步。
* [x] **图片预处理**：宽高计算、本地持久化拷贝。

### 🏗️ 架构与体验 (Architecture & UX)

* [x] **发送零抖动** / **红点互斥逻辑**。
* [x] **iOS 路径变动防御** / **Hero 嵌套报错修复**。
* [x] **离线重发基础设施**：`OfflineQueueManager` 核心逻辑已上线。

---

## 6. 🚦 待办任务 (Next Steps)

1. **[P0] 跨平台极致压缩工具类**:
* [ ] 完善 `ImageCompressionService`，支持 Mobile Isolate 与 Web Canvas。


2. **[P1] Web 缩略图持久化落地**:
* [ ] 在 `ChatUiModel` 增加 `previewBytes` 字段。
* [ ] 在 `ChatBubble` 实现三级渲染（Cache -> MemoryBytes -> Network）。


3. **[P2] 语音消息相对路径对齐**:
* [ ] 确认音频文件存储是否也遵循相对路径。



---

> **🚀 提示词 (Prompt)**：
> 以后发给我指令时，请说：*"基于 Project Master Log v2.4，我们下一步..."*




