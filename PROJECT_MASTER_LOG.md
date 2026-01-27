

---

# 📝 Lucky IM Project Master Log v3.7.0 (Video Ecosystem)

> **🔴 状态校准 (2026-01-27 19:40)**
> **历史必须完整，战绩必须确凿。**
> **里程碑达成：视频全链路闭环 & 架构分层重构**
> **最新战绩**：
> 1. **架构重构**：将臃肿的 `ChatBubble` 拆解为工厂模式，分离 `ChatActionService` (发送) 与 `VideoPlaybackService` (播放)。
> 2. **视频生态**：实现了从压缩发送、乐观上屏，到原地播放、Hero 无缝全屏的完整体验。
> 3. **体验优化**：解决了文件 Race Condition 问题，实现了视频播放的**独占模式**（Singleton Playback）。
     > **🟢 当前版本：v3.7.0 (Video Lifecycle + Service Architecture)**
>
>

---

## 1. 🛡️ 架构铁律 (The Iron Rules - Updated)

> *新增 3 条关于多媒体与服务的铁律*

1. **ID 唯一性**: 前端生成 UUID，后端透传。
2. **UI 零抖动**: 利用 `_sessionPathCache` 确保发送瞬间 UI 静止。
3. **单向数据流**: UI 只听 DB。
4. **消息幂等性**: 同一 ID 只处理一次。
5. **存储相对化**: 数据库仅存文件名，必调 `AssetManager`。
6. **本地字段保护**: `saveMessage` 必须 `Merge`。
7. **Web 依赖锁死**: `idb_shim: ^2.6.0`。
8. **极速预览优先**: `MemoryBytes` > `LocalFile` > `Network`。
9. **资源单一出口**: 禁止业务层直连 IO。
10. **UI/逻辑分离**: 状态下沉 `Core`，业务留 `Feature`。
11. **异步标准化**: 列表状态必须 `when(loading/error/data)`。
12. **桥接原则**: 通讯录发起必须走 `Bridge API`。
13. **交互承诺**: 耗时弹窗必须返回 `Future`，由组件接管 Loading。
14. **SWR 逻辑**: 缓存优先推送，网络异步更新，杜绝详情页白屏。
15. **缓存协同原则**: 列表项允许订阅详情 Provider，利用 SWR 机制补全 UI 碎片。
16. **🔥 [NEW] 服务外包原则**: 复杂逻辑（如路径解析、播放器创建）必须抽离至 `Service`，UI 组件只负责展示。
17. **🔥 [NEW] 独占播放原则**: 全局单例管理 (`VideoPlaybackService`)，确保同一时间只有一个媒体在播放。
18. **🔥 [NEW] Hero 守恒定律**: 起点（Bubble）与终点（FullScreen）必须拥有相同的 Tag 和视觉元素，方能起飞。

---

## 2. 🗺️ 代码地图 (Code Map - v3.7.0 Scope)

### A. 核心架构重构 (Core Refactor) **[✓]**

* `ui/chat/providers/chat_room_provider.dart`: **[✓] Controller 瘦身** (剥离发送逻辑，只做指挥官)。
* `ui/chat/services/chat_action_service.dart`: **[✓] 统一发送管道** (Pipeline 模式处理 压缩->存储->上传->API)。
* `ui/chat/components/chat_bubble.dart`: **[✓] 工厂化改造** (拆分为 `Text`, `Image`, `Video`, `Voice` 子组件)。

### B. 视频引擎 (Video Engine) **[✓]**

* `ui/chat/services/media/video_playback_service.dart`: **[✓] 大管家** (处理路径解析、播放器单例、独占控制)。
* `ui/chat/services/media/video_processor.dart`: **[✓] 预处理** (压缩视频 + 抽帧封面，修复文件清理竞态问题)。
* `ui/chat/components/bubbles/video_msg_bubble.dart`: **[✓] 原地播放器** (Inline Playback + Hero 起飞点)。
* `ui/chat/video_player_page.dart`: **[✓] 沉浸式剧场** (全屏播放 + 交互遮罩 + Hero 降落点)。

---

## 3. ✅ 完整功能清单 (The Grand Checklist)

### 🎬 v3.7.0 视频生态 (Video Ecosystem)

* [✓] **[P0] 视频发送链路** (录制/选修 -> 压缩 -> 封面提取 -> 乐观上屏 -> 异步上传)。
* [✓] **[P0] 原地播放 (Inline)** (点击气泡直接播放，无需跳页)。
* [✓] **[P0] 独占播放管理** (点击新视频自动暂停旧视频，防止声音冲突)。
* [✓] **[P0] Hero 无缝转场** (封面图从小变大飞入全屏，视频流无缝衔接)。
* [✓] **[P1] 沉浸式播放页** (黑色背景，点击切换控件，进度条拖拽)。
* [✓] **[P1] 错误熔断机制** (本地文件丢失自动降级为网络播放)。

### 🎨 v3.6.5 视觉巅峰 (Visual Polish)

* [✓] **[P0] 微信九宫格头像** (1-9 人自适应排版)。
* [✓] **[P0] 跨页面缓存共享** (列表页透传详情页头像)。

### 🚀 v3.6 本地优先与性能

* [✓] **[P0] 详情页秒开系统** (本地缓存 0ms 渲染)。
* [✓] **[P0] 脏缓存防御**。

---

