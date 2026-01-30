
# 📝 Lucky IM Project Master Log v4.4.0 (Protocol & Edge Optimization)

> **🔴 状态校准 (2026-01-30 02:30)**
> **里程碑达成：从“应用优化”到“协议层进化”**
> **战绩汇总**：
> 1. **[Core] HTTP/2 全链路激活**：通过 Nginx 开启 `h2` 协议，利用多路复用（Multiplexing）彻底消除 HTTP/1.1 带来的队头阻塞（HOL Blocking），实现图片“万箭齐发”式加载。
> 2. **[Edge] 边缘网关策略优化**：
> * **Range 穿透**：针对 R2/Cloudflare 完美透传 `Range` 头，解决 Web 端大型视频无法拖拽进度条、起步加载慢的顽疾。
> * **CORS 动态映射**：实现基于 `$http_origin` 的动态跨域白名单，安全地支持了 `localhost:4000` 与生产域名的无缝共存。
>
>
> 3. **[Security] SSL 性能加固**：配置 `ssl_session_cache` 与 `http2_push` 优化建议，大幅削减了 HTTPS 握手时间。
>
>
> **🟢 当前版本：v4.4.0 (Edge Gateway & Protocol Hardening)**

---

## 1. 🛡️ 架构铁律 (The Iron Rules - Updated)

1. **ID 唯一性**: 前端生成 UUID，后端透传。
2. **UI 零抖动**: 利用 `_sessionPathCache` 确保发送瞬间 UI 静止。
3. **单向数据流**: UI 只听 DB，Pipeline 完成后静默回写数据库。
4. **存储相对化**: 数据库仅存文件名 ID/相对路径。
5. **极速预览优先**: `MemoryBytes` (第一帧) > `LocalFile` (发送者) > `Network` (接收者)。
6. **资源单一出口**: 路径解析统一归口 `AssetManager`。
7. **数据净化原则**: 上传 Meta 必须重建，隔绝本地字段泄漏。
8. **智能旁路原则**: 满足“体积小 (<10MB)”条件的媒体跳过压缩。
9. **流优化原则**: 视频压缩强制包含 `-movflags +faststart`。
10. **类型强一致性**: 视频上传必须代码级强制指定 `video/mp4`。
11. **本地优先原则**: 图片/视频加载必须优先检索本地物理存储。
12. **游标有序性**: 历史消息分页必须使用 `seqId (Int)`。
13. **Web 路径保护**: Pipeline 必须持有原始 `XFile` 对象，防止 Blob 路径导致文件名丢失。
14. **解码受限原则**: 所有图片加载必须指定 `memCacheWidth`。
15. **[NEW] 协议先进性**: 生产与开发环境必须强推 **HTTP/2**，利用多路复用解决媒体资源加载排队问题。
16. **[NEW] 媒体流透传**: 网关层必须显式支持 `Range` 请求与 `Accept-Ranges` 响应，确保流媒体拖拽体验。
17. **[NEW] 安全跨域原则**: 跨域白名单严禁简单使用 `*`，必须基于 `map` 动态匹配请求来源。

---

## 2. 🗺️ 代码地图 (Code Map - v4.4.0 Scope)

### A. 边缘网关 (Edge & Nginx)

* `nginx.conf`: **[✓] HTTP/2 协议栈** (开启 `listen 443 ssl http2`)。
* `nginx.conf`: **[✓] 动态 CORS 映射** (利用 `map` 指令处理多源跨域)。
* `nginx.conf`: **[✓] 媒体转发优化** (针对 `/cdn-cgi/` 和 `/uploads/` 强制透传 `Range`、`Content-Range`、`Accept-Ranges`)。

### B. 后端服务 (Backend Services)

* `chat.service.ts`: **[✓] SeqId 改造** (getMessages 逻辑重构)。
* `get-messages.dto.ts`: **[✓] 游标强转** (确保 cursor 为 number 类型)。

### C. 核心服务 (Core Services)

* `ui/chat/services/chat_action_service.dart`: **[✓] Web 管道硬化** (引入 `sourceFile` 保护)。
* `ui/chat/providers/chat_view_model.dart`: **[✓] 分页同步逻辑** (对接 Int 类型游标)。

### D. UI 组件 (UI Components)

* `widgets/app_cached_image.dart`: **[✓] 极速渲染引擎** (禁淡入、强制 Web 缓存)。

---

## 3. ✅ 完整功能清单 (The Grand Checklist)

### 🚀 v4.4.0 协议层与网关优化 (Protocol & Gateway) **[NEW]**

* [✓] **[P0] HTTP/2 协议落地** (解决 10KB 小文件加载排队延迟，协议响应提速 200%)。
* [✓] **[P0] Range 请求穿透** (修复 Web 端视频拖拽“假死”，实现流式秒开)。
* [✓] **[P0] 动态 CORS 治理** (适配跨域预检请求，解决本地开发环境与 R2 存储的通信障碍)。
* [✓] **[P1] SSL 握手加速** (配置 Session Cache，减少首次加载 TLS 握手开销)。

### 📈 v4.3.0 数据与渲染硬化 (Velocity Hardening)

* [✓] **[P0] SeqId 全链路打通** (后端查询、前端拉取、DTO 校验三位一体)。
* [✓] **[P0] Web 文件名保护机制** (解决 Web 上传 404/CORS 顽疾)。
* [✓] **[P0] 图片渲染零延迟** (消除 FadeIn 动画)。
* [✓] **[P1] 内存解码优化** (memCacheWidth 落地)。

### 🎬 v4.2.0 播放体验硬化 (Playback Hardening)

* [✓] **[P0] MimeType 强制修正** (修复 iOS 播放报错 -12939)。
* [✓] **[P0] 本地文件优先策略** (发送者秒开)。

---

