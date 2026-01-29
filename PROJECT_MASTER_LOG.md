

# 📝 Lucky IM Project Master Log v4.2.0 (Video Ecosystem Perfection)

> **🔴 状态校准 (2026-01-28 16:15)**
> **里程碑达成：视频全链路闭环（上传-处理-播放）**
> **战绩汇总**：
> 1. **[Core] 智能直传引擎**：<10MB 文件跳过压缩，保护画质；>10MB 走 FFmpeg 智能压缩 (CRF 23 + faststart)。
> 2. **[Critical] iOS 协议硬化**：
> * **MimeType 纠错**：`GlobalUploadService` 强制锁定 `.mp4` 为 `video/mp4`，彻底根除 iOS 将视频识别为图片导致的播放失败。
> * **HTTPS 强制**：播放端自动将 HTTP 升级为 HTTPS，满足 iOS ATS 安全策略，消除 `-12939` 报错。
>
>
> 3. **[UX] 零延迟播放**：`VideoMsgBubble` 引入**本地优先策略**，发送者直接读取本地物理文件，跳过网络请求，实现秒开。
> 4. **[UX] 封面双缓冲**：采用 `Stack(MemoryImage + NetworkImage)` 架构，发送瞬间展示内存预览图，消除上传过程中的黑屏闪烁。
> 5. **[Stability] 双引擎元数据**：`FFprobe` + `Native` 双重校验，确保宽、高、时长 100% 获取成功。
>
>
> **🟢 当前版本：v4.2.0 (Video Playback & Upload Hardening)**

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
10. ** [NEW] 类型强一致性**: 上传视频时严禁依赖自动推断，必须代码级强制指定 `video/mp4`。
11. ** [NEW] 本地优先原则**: 播放器初始化前必须先 `check(localFile)`，只要本地存在，绝不发起网络请求。

---

## 2. 🗺️ 代码地图 (Code Map - v4.2.0 Scope)

### A. 核心服务 (Core Services)

* `utils/upload/global_upload_service.dart`: **[✓] 类型纠错** (强制修正 .mp4 MimeType，防止被识别为 jpeg)。
* `ui/chat/services/media/video_processor.dart`: **[✓] 智能引擎** (大小分流、FFmpeg 压缩、双引擎 Meta 提取)。
* `ui/chat/services/chat_action_service.dart`: **[✓] 管道集成** (Web/Mobile 差异化处理，UploadStep 放行相对路径)。

### B. UI 组件 (UI Components)

* `ui/chat/components/bubbles/video_msg_bubble.dart`: **[✓] 播放器硬化** (本地文件优先、HTTPS 升级、双层封面渲染)。
* `ui/chat/video_player_page.dart`: **[✓] 全屏适配** (支持 `file://` 协议，兼容本地预览)。

---

## 3. ✅ 完整功能清单 (The Grand Checklist)

### 🎬 v4.2.0 播放体验硬化 (Playback Hardening) **[NEW]**

* [✓] **[P0] MimeType 强制修正** (修复 iOS 播放报错 -12939)。
* [✓] **[P0] 本地文件优先策略** (发送者秒开，无视网络延迟)。
* [✓] **[P0] HTTPS 协议自动升级** (适配 iOS 安全策略)。
* [✓] **[P1] 封面双缓冲渲染** (修复发送过程黑屏)。

###  v4.1.0 智能媒体加工 (Smart Processing)

* [✓] **[P0] 智能直传过滤** (<10MB 跳过压缩)。
* [✓] **[P0] 1080p 自动缩放** (防止超大分辨率)。
* [✓] **[P0] 双引擎 Meta 提取** (FFprobe + Native)。
* [✓] **[P0] Faststart 头部优化** (Web 端流式播放支持)。

---

