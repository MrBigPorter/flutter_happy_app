这份 **Lucky IM Project Master Log v4.8.0** 已经为您更新。

所有的历史战绩（从 v4.2 到 v4.7）都已完整保留，同时将刚刚完成的 **“全能菜单架构”** 和 **“原生级推顶交互”** 归档入库。

---

# 📝 Lucky IM Project Master Log v4.8.0 (Interaction Architecture)

> **🔴 状态校准 (2026-01-31 23:59)**
> **里程碑达成：交互架构重构 (Interaction Refactor)**
> **最新战绩汇总 (New Victories)**：
> 1. **[UI] 全能菜单架构 (Plus Menu Grid)**：
> * 废弃硬编码逻辑，封装通用组件 `ChatActionSheet`。
> * 实现微信/TG 风格的 Grid 布局，支持动态注册 Action，为“文件/位置”功能预留了完美插槽。
>
>
> 2. **[UX] 原生级推顶交互 (Push Layout)**：
> * 重构 `ChatPage` 布局结构（从 `Stack` 覆盖改为 `Column` 推顶）。
> * 实现键盘与功能面板的无缝切换，彻底解决“输入框被遮挡”和“列表不随动”的顽疾。
>
>
> 3. **[Fix] 底部安全区完美适配**：
> * 修复 iPhone 底部 Home Indicator 遮挡菜单的问题。
> * 实现背景色沉浸式延伸，同时内容自动避让安全区。
>
>
>
>
> **🟢 当前版本：v4.8.0 (Ready for File Messages)**

---

## 1. 🛡️ 架构铁律 (The Iron Rules - Updated)

1. **ID 唯一性**: 前端生成 UUID，后端透传。
2. **UI 零抖动**: 利用 `_sessionPathCache` 确保发送瞬间 UI 静止。
3. **单向数据流**: UI 只听 DB，Pipeline 完成后静默回写数据库。
4. **存储相对化**: 数据库仅存文件名 ID/相对路径，绝对路径由 Service 层运行时生成。
5. **极速预览优先**: `MemoryBytes` (第一帧) > `BlurHash` (占位) > `LocalFile` (发送者) > `Network` (接收者)。
6. **资源单一出口**: 路径解析统一归口 `AssetManager`。
7. **数据净化原则**: 上传 Meta 必须重建，隔绝本地字段泄漏。
8. **智能旁路原则**: 满足“体积小 (<10MB)”条件的媒体跳过压缩。
9. **流优化原则**: 视频压缩强制包含 `-movflags +faststart`。
10. **类型强一致性**: 视频上传必须代码级强制指定 `video/mp4`。
11. **本地优先原则**: 图片/视频加载必须优先检索本地物理存储。
12. **游标有序性**: 历史消息分页必须使用 `seqId (Int)`。
13. **Web 路径保护**: Pipeline 必须持有原始 `XFile` 对象，防止 Blob 路径导致文件名丢失。
14. **解码受限原则**: 所有图片加载必须指定 `memCacheWidth`。
15. **协议先进性**: 生产与开发环境必须强推 **HTTP/2**，利用多路复用解决媒体资源加载排队问题。
16. **媒体流透传**: 网关层必须显式支持 `Range` 请求与 `Accept-Ranges` 响应，确保流媒体拖拽体验。
17. **安全跨域原则**: 跨域白名单严禁简单使用 `*`，必须基于 `map` 动态匹配请求来源。
18. **[NEW] 面板推顶原则**: 输入框与功能面板必须处于同一 `Column` 布局流中，严禁使用 `Overlay` 覆盖输入框，确保列表可视区随面板高度自动调整。
19. **[NEW] 组件解耦原则**: 底部菜单项必须抽象为数据配置 (`ActionItem`)，严禁在页面层硬编码具体按钮逻辑。

---

## 2. 🗺️ 代码地图 (Code Map - v4.8.0 Scope)

### A. 交互组件层 (Interaction UI) **[NEW]**

* `ui/chat/components/chat_action_sheet.dart`: **[✓] 全能菜单组件** (通用 Grid 布局，支持回调)。
* `ui/chat/components/modern_chat_input_bar.dart`: **[✓] 状态上提** (删除内部弹窗逻辑，改为 `onAddPressed` 回调)。
* `ui/chat/chat_page.dart`: **[✓] 布局重构** (实现 `Column` + `AnimatedContainer` 推顶逻辑)。

### B. 核心数据层 (Core Data)

* `local_database_service.dart`: **[✓] 智能分页** (`watchMessages` 增加 `limit` 参数)。
* `local_database_service.dart`: **[✓] 预热引擎** (`_prewarmMessages` 并行处理路径解析)。

### C. 视图模型层 (ViewModel)

* `chat_view_model.dart`: **[✓] 动态扩容** (`loadMore` 优先扩大本地窗口，再触发网络请求)。

### D. 媒体处理层 (Media Pipeline)

* `chat_action_service.dart`: **[✓] BlurHash 生成** (Pipeline 中增加 `ImageProcessStep` 计算指纹)。
* `app_image.dart`: **[✓] 视觉占位** (集成 `flutter_blurhash` 组件)。

### E. 边缘网关 (Edge)

* `nginx.conf`: **[✓] HTTP/2 协议栈** (全链路开启 `h2`)。

---

## 3. ✅ 完整功能清单 (The Grand Checklist)

### 🧩 v4.8.0 交互架构与菜单重构 (Interaction & Menu Arch) **[NEW]**

* [✓] **[P0] 全能菜单组件化 (Action Sheet Refactor)**: 建立 `ChatActionSheet`，实现配置化 Grid 菜单。
* [✓] **[P0] 原生级推顶布局 (Push Layout)**: 重构 `ChatPage` 为 Column 布局，输入框随面板自动顶起。
* [✓] **[P0] 键盘/面板无缝切换**: 解决键盘收起时的高度跳动问题，实现丝滑过渡。
* [✓] **[P1] iPhone 底部安全区适配**: 面板背景色延伸到底部，内容自动避让 Home Indicator。

### 🧠 v4.6.0~4.7.0 核心性能与体验硬化 (Performance & UX Core)

* [✓] **[P0] 智能分页实装 (Smart Pagination)**: DB 层 `limit` 游标支持 + VM 层“本地优先”的动态扩容策略。
* [✓] **[P0] 无感数据预热 (Zero-Latency Pre-warm)**: `_prewarmMessages` 引擎闭环，UI 层直接消费 `resolvedPath`。
* [✓] **[P1] BlurHash 视觉占位**: 前端计算 + 后端存储 + UI 渲染全链路打通。
* [✓] **[P1] HTTP/2 协议验证**: Nginx 配置落地，多路复用生效，解决并发加载排队问题。

### 🚀 v4.4.0 协议层与网关优化 (Protocol & Gateway)

* [✓] **[P0] HTTP/2 协议准备**: Nginx 开启 `listen 443 ssl http2`。
* [✓] **[P0] Range 请求穿透**: 修复 Web 端视频拖拽“假死”，实现流式秒开。
* [✓] **[P0] 动态 CORS 治理**: 适配跨域预检请求，解决本地开发环境与 R2 存储的通信障碍。
* [✓] **[P1] SSL 握手加速**: 配置 Session Cache，减少首次加载 TLS 握手开销。

### 📈 v4.3.0 数据与渲染硬化 (Velocity Hardening)

* [✓] **[P0] SeqId 全链路打通**: 后端查询、前端拉取、DTO 校验三位一体。
* [✓] **[P0] Web 文件名保护机制**: 解决 Web 上传 404/CORS 顽疾。
* [✓] **[P0] 图片渲染零延迟**: 消除 FadeIn 动画，配合预热实现瞬开。
* [✓] **[P1] 内存解码优化**: `memCacheWidth` 落地，防止大图撑爆内存。

### 🎬 v4.2.0 播放体验硬化 (Playback Hardening)

* [✓] **[P0] MimeType 强制修正**: 修复 iOS 播放报错 -12939。
* [✓] **[P0] 本地文件优先策略**: 发送者本地秒开，无需等待上传。