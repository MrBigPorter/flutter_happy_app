

# 📝 Lucky IM Project Master Log v3.1 (Day End Update)

> **🔴 状态校准 (2026-01-25 23:50)**
> **里程碑达成：环境感知能力 & 群聊交互重构**
> 今天我们在 v3.0 稳固架构之上，迅速补齐了用户体验层面的短板。App 现在具备了**系统级的网络感知能力**，并重构了**群聊气泡展示逻辑**和**建群交互流程**，交互体验已对标主流商业 IM。
> **🟢 当前版本：v3.1 (UX & Group Foundation)**

---

## 1. 🛡️ 架构铁律 (The Iron Rules - 10 Commandments)

> **(保持 v3.0 核心铁律不变，新增 UI 分层原则)**

1. **ID 唯一性**: 前端生成 UUID，后端透传。
2. **UI 零抖动**: 严禁删旧插新，利用 `_sessionPathCache` 确保发送瞬间 UI 静止。
3. **单向数据流**: UI 只听 DB。
4. **消息幂等性**: 同一 ID 只处理一次。
5. **存储相对化 (AssetManager)**: **(关键)** 数据库仅存纯文件名，路径拼接必调 `AssetManager`。
6. **本地字段保护**: `saveMessage` 必须执行 `Merge` 操作。
7. **Web 依赖锁死**: `idb_shim: ^2.6.0`。
8. **极速预览优先**: `MemoryBytes` > `LocalFile` > `Network`。
9. **资源单一出口**: 禁止业务层直接引用 IO 库。
10. **UI/逻辑分离 (v3.1新增)**: 公共状态（如网络）下沉至 `Core`，业务状态（如队列）留在 `Feature`，禁止反向依赖。

---

## 2. 🗺️ 代码地图 (Code Map - v3.1 New Additions)

### A. 基础设施层 (Core Infrastructure) **[UPDATE]**

* **`core/providers/network_status_provider.dart`**: 全局网络状态源，独立于业务逻辑。
* **`core/widgets/network_status_bar.dart`**: 公共 UI 组件，负责断网时的视觉强提醒。

### B. 聊天业务层 (Feature - Chat) **[UPDATE]**

* **`chat_page.dart`**: 注入 `isGroup` 状态，实现了单/群聊 UI 的动态切换。
* **`chat_bubble.dart`**: 适配群聊模式，仅在 `isGroup && !isMe` 时显示发送者昵称。
* **`conversation_list_page.dart`**: 集成了网络状态条，重构了右上角菜单交互。
* **`group_member_select_page.dart` (New)**: 新增“选人建群”页面，替代了简陋的弹窗。

---

## 3. 🏆 v3.1 新增战果 (New Achievements)

#### 🥇 [体验] 全局网络状态感知 (Network Awareness)

* **攻克**: 实现了 Provider (数据源) 与 Widget (展示层) 的完美分层。
* **效果**: 断网时列表页顶部平滑滑出红色警告条，联网自动收起。后台队列 (`OfflineQueue`) 独立监听，实现了“前台显性报警，后台隐性自愈”。

#### 🥈 [交互] 建群流程重构 (Group Creation Flow)

* **攻克**: 废弃了“弹窗输名字”，实现了微信风格的 **“先选人，后建群”** 流程。
* **产物**: 新增 `GroupMemberSelectPage`，支持好友多选，交互逻辑闭环。

#### 🥉 [UI] 聊天气泡群聊适配

* **攻克**: 为 `ChatBubble` 注入 `isGroup` 状态。
* **效果**:
* **单聊**: 自动隐藏对方名字，界面极致清爽。
* **群聊**: 显示发送者昵称，清晰区分发言人。



---

## 4. ✅ 累计功能清单 (Checklist)

### v3.1 本次冲刺完成 (New)

* [x] **[P0] 发送失败 UI 反馈** (红色感叹号❗️ + 点击重试逻辑)。
* [x] **[P0] 全局网络状态感知** (红条提示 / 状态分离 / 动画交互)。
* [x] **[P1] 群聊气泡适配** (区分单聊/群聊 UI / 昵称显示逻辑)。
* [x] **[P1] 建群交互重构** (新增选人页面 / 路由跳转)。

### v3.0 基础架构 (Legacy)

* [x] **[P0] 统一资源管理 AssetManager** (核心架构解耦)。
* [x] **[P0] 语音消息全链路** (录音/播放/持久化)。
* [x] **[P0] 断网重发系统** (离线队列/生命周期)。
* [x] **[P1] 跨平台极致压缩** (Web Canvas + Mobile Isolate)。
* [x] **[P1] 会话列表状态对齐** (红点互斥/发送置顶)。

