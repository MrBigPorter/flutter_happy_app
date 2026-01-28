---

# 📝 Lucky IM Project Master Log v4.0.0 (Declarative Pipeline)

> **🔴 状态校准 (2026-01-28 14:50)**
> **历史必须完整，战绩必须确凿。**
> **里程碑达成：声明式流水线重构 & 离线队列闭环**
> **最新战绩**：
> 1. **引擎重构**：建立了基于插件模式的 `MediaTaskPipeline`，将发送逻辑拆解为 `Persist -> Process -> Upload -> Sync` 原子步骤。
> 2. **离线闭环**：通过 `ProviderContainer` 桥接，彻底收编了 `OfflineQueueManager`，使其统一调用 Pipeline 管道。
> 3. **数据安全**：实现了 `SyncStep` 净化逻辑，物理隔绝了本地 Asset ID 泄漏给服务器的风险。
> 4. **路径自愈**：全链路接入 `AssetManager` 相对路径系统，解决了本地媒体文件在 iOS 沙盒重启后失效的难题。
     > **🟢 当前版本：v4.0.0 (Declarative Pipeline + Data Purification)**
>
>

---

## 1. 🛡️ 架构铁律 (The Iron Rules - Updated)

> *新增 4 条关于管道、净化与离线的铁律*

1. **ID 唯一性**: 前端生成 UUID，后端透传。
2. **UI 零抖动**: 利用 `_sessionPathCache` 确保发送瞬间 UI 静止。
3. **单向数据流**: UI 只听 DB，Pipeline 完成后静默回写数据库。
4. **存储相对化**: 数据库仅存文件名 ID，禁止存储物理绝对路径，解析必调 `AssetManager`。
5. **极速预览优先**: `MemoryBytes` > `LocalFile` > `Network`。
6. **资源单一出口**: 禁止业务层直连 IO，路径解析统一归口 `AssetManager`。
7. ** [NEW] 管道原子性**: 发送逻辑必须拆解为无状态的 `Step`，严禁在 Service 中编写业务细节。
8. ** [NEW] 数据净化原则**: 发送给服务器的 `meta` 必须通过 `Map.from` 重新构建，物理隔绝本地字段泄漏。
9. ** [NEW] 离线归一化**: 离线队列禁止私设上传逻辑，必须统一调用 `ChatActionService.resend` 管道。
10. ** [NEW] 容器化初始化**: 全局单例（如离线管理器）必须通过 `ProviderContainer` 初始化，脱离 UI 生命周期。

---

## 2. 🗺️ 代码地图 (Code Map - v4.0.0 Scope)

### A. 发送引擎重构 (Pipeline Engine) **[✓]**

* `ui/chat/services/media_task_pipeline.dart`: **[✓] 核心抽象** (Context 与 Step 接口定义)。
* `ui/chat/services/chat_action_service.dart`: **[✓] 管道工厂** (实现 `_runPipeline` 及全类型发送流水线)。
* `ui/chat/services/network/offline_queue_manager.dart`: **[✓] 游击队收编** (删除冗余逻辑，收编进管道重发体系)。

### B. UI 与播放适配 (Standardization) **[✓]**

* `ui/chat/widgets/video_msg_bubble.dart`: **[✓] 声明式渲染** (移除路径锁，优先解析 `thumb` AssetID)。
* `ui/chat/widgets/voice_bubble.dart`: **[✓] 路径归一化** (全面接入 `AssetManager` 解析，废弃 `p.join`)。
* `ui/chat/services/media/video_playback_service.dart`: **[✓] 异步化适配** (支持基于 Asset ID 的异步播放源检索)。

---

## 3. ✅ 完整功能清单 (The Grand Checklist)

### 🚀 v4.0.0 声明式管道与数据安全 (Declarative & Secure) **[NEW]**

* [✓] **[P0] 声明式发送管道** (文本、图片、视频、语音全链路 Pipeline 化)。
* [✓] **[P0] Asset ID 路径系统** (解决物理路径失效导致的媒体消息“文件丢失”问题)。
* [✓] **[P0] 离线自动重发** (网络恢复后自动触发 Pipeline 补传、补发)。
* [✓] **[P0] 物理防泄漏** (SyncStep 强制 URL 校验，绝对禁止发送本地 ID 给服务器)。
* [✓] **[P1] 渲染零闪烁** (利用 `remote_thumb` 字段，实现成功后 UI 层的平滑过渡)。

### 🎬 v3.7.0 视频生态 (Video Ecosystem)

* [✓] **[P0] 原地播放 (Inline)** (气泡点击直接播放，单例独占管理)。
* [✓] **[P0] Hero 无缝转场** (Bubble 与 FullScreen 之间的 Hero 动画衔接)。
* [✓] **[P1] 错误熔断机制** (本地文件丢失时自动降级为网络流播放)。

### 🎨 v3.6.5 视觉巅峰 (Visual Polish)

* [✓] **[P0] 微信九宫格头像** (1-9 人自适应 Canvas 绘制排版)。
* [✓] **[P0] 跨页面缓存共享** (SWR 机制确保详情页 0ms 渲染)。

---
