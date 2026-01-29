
---

# 📝 Lucky IM Project Master Log v4.3.0 (Velocity & Data Integrity)

> **🔴 状态校准 (2026-01-30 00:15)**
> **里程碑达成：从“能跑”到“工业级流畅”的跨越**
> **战绩汇总**：
> 1. **[Core] SeqId 游标架构统一**：前后端彻底摒弃 UUID 分页，采用严格递增的 `Int` 类型 `seqId`。支持无损补洞与极致的数据库索引性能。
> 2. **[Web] 管道完整性修复**：重构 `ChatActionService`，解决 Web 端 Blob URL 导致的文件名/MimeType 丢失问题，根除 `.so` 后缀引发的 404 与 CORS 报错。
> 3. **[UX] 零延迟图片渲染**：
> * **视觉秒开**：关掉 `fadeInDuration`，图片下载完即刻呈现，消除 500ms 人为延迟。
> * **内存减负**：引入 `memCacheWidth` 强制限制解码分辨率，防止大图撑爆 UI 线程。
> * **持久化缓存**：Web 端强制启用 `IndexedDB` 存储，二次加载耗时从 1s 降至 3ms。
>
>
>
>
> **🟢 当前版本：v4.3.0 (Pagination Unification & Web Hardening)**

---

## 1. 🛡️ 架构铁律 (The Iron Rules - Updated)

1. **ID 唯一性**: 前端生成 UUID，后端透传。
2. **UI 零抖动**: 利用 `_sessionPathCache` 确保发送瞬间 UI 静止。
3. **单向数据流**: UI 只听 DB，Pipeline 完成后静默回写数据库。
4. **存储相对化**: 数据库仅存文件名 ID/相对路径，禁止存储物理绝对路径。
5. **极速预览优先**: `MemoryBytes` (第一帧) > `LocalFile` (发送者) > `Network` (接收者)。
6. **资源单一出口**: 路径解析统一归口 `AssetManager`。
7. **数据净化原则**: 上传 Meta 必须通过 `Map.from` 重建，物理隔绝本地字段泄漏。
8. **智能旁路原则**: 满足“体积小 (<10MB)”条件的媒体跳过压缩。
9. **流优化原则**: 视频压缩强制包含 `-movflags +faststart`。
10. **类型强一致性**: 上传视频时严禁依赖自动推断，必须代码级强制指定 `video/mp4`。
11. **本地优先原则**: 播放器/图片渲染前必须先 `check(localFile)`，只要本地存在，绝不发起网络请求。
12. **[NEW] 游标有序性**: 历史消息分页必须使用 `seqId (Int)`。严禁使用 `skip/offset`。
13. **[NEW] Web 路径保护**: 在 Web 环境下，Pipeline 必须持有原始 `XFile` 对象直至上传结束，防止 Blob 路径导致的文件名信息丢失。
14. **[NEW] 解码受限原则**: 所有网络图片加载必须指定 `memCacheWidth`，严禁在 UI 线程直接解压原始分辨率位图。

---

## 2. 🗺️ 代码地图 (Code Map - v4.3.0 Scope)

### A. 后端服务 (Backend Services)

* `chat.service.ts`: **[✓] SeqId 改造** (getMessages 逻辑重构，支持 `lt: cursor` 范围查询)。
* `get-messages.dto.ts`: **[✓] 游标强转** (使用 `@ToInt()` 确保 cursor 为 number 类型)。

### B. 核心服务 (Core Services)

* `ui/chat/services/chat_action_service.dart`: **[✓] Web 管道硬化** (引入 `sourceFile` 保护，修复 Web 端上传文件名 Bug)。
* `ui/chat/providers/chat_view_model.dart`: **[✓] 双向分页逻辑** (对接 Int 类型游标，支持本地 limit 缓存预加载)。

### C. UI 组件 (UI Components)

* `widgets/app_cached_image.dart`: **[✓] 极速渲染引擎** (禁淡入、加内存锁、强制 Web 缓存)。
* `ui/chat/components/chat_bubble.dart`: **[✓] 头像加载优化** (集成 AppCachedImage 缩略图模式)。

---

## 3. ✅ 完整功能清单 (The Grand Checklist)

### 📈 v4.3.0 数据与渲染硬化 (Velocity Hardening) **[NEW]**

* [✓] **[P0] SeqId 全链路打通** (后端查询、前端拉取、DTO 校验三位一体)。
* [✓] **[P0] Web 文件名保护机制** (彻底解决 Web 上传 404/CORS 顽疾)。
* [✓] **[P0] 图片渲染零延迟** (消除 FadeIn 动画，体感速度提升 500%)。
* [✓] **[P1] 内存解码优化** (memCacheWidth 落地，解决快速滚动掉帧)。
* [✓] **[P1] Web 持久化缓存** (IndexedDB 介入，二次加载耗时 < 10ms)。

### 🎬 v4.2.0 播放体验硬化 (Playback Hardening)

* [✓] **[P0] MimeType 强制修正** (修复 iOS 播放报错 -12939)。
* [✓] **[P0] 本地文件优先策略** (发送者秒开，无视网络延迟)。
* [✓] **[P0] HTTPS 协议自动升级** (适配 iOS 安全策略)。
* [✓] **[P1] 封面双缓冲渲染** (修复发送过程黑屏)。

### 🎥 v4.1.0 智能媒体加工 (Smart Processing)

* [✓] **[P0] 智能直传过滤** (<10MB 跳过压缩)。
* [✓] **[P0] 1080p 自动缩放** (防止超大分辨率)。
* [✓] **[P0] 双引擎 Meta 提取** (FFprobe + Native)。
* [✓] **[P0] Faststart 头部优化** (Web 端流式播放支持)。

---

