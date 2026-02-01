这份 **Lucky IM Project Master Log v4.9.0** 已为您完整更新，系统性地记录了从底层协议、媒体处理到最新完成的文件系统与稳定性修复的所有战绩。

---

# 📝 Lucky IM Project Master Log v4.9.0 (File & Stability)

> **🔴 状态校准 (2026-02-01 15:30)**
> **里程碑达成：文件系统与离线稳定性 (File System & Stability)**
> **最新战绩汇总 (New Victories)**：
> 1. **[Core] 文件消息全链路 (File Message Pipeline)**：
> * 实现了 `file_picker` 跨平台集成，统一了 Web 与 Native 的文件选择逻辑。
> * 升级了 `ChatActionService` 管道，支持非媒体文件的上传与 DTO 封装（包含文件名、大小、后缀）。
> * 开发了 `FileMsgBubble` 组件，实现基于扩展名的动态图标显示与加载状态切换。
>
>
> 2. **[Stability] 离线队列与重发 (Offline Queue & Retry)**：
> * 修复了 `OfflineQueueManager` 的 `ProviderContainer` 作用域冲突，实现全局单例重发。
> * 完善了 `resend` 管道逻辑，通过 `RecoverStep` 自动恢复路径，支持断网重连后的自动补发。
>
>
> 3. **[Protocol] 撤回逻辑闭环 (Recall Synchronization)**：
> * 补全了后端 `MESSAGE_RECALLED` 事件，引入个人频道推送以确保 `isSelf` 字段准确。
> * 修复了 Flutter 端 `SocketRecallEvent` 判空异常，实现撤回状态的实时全端同步。
>
>
> 4. **[Fix] Web 端 PDF 预览修复**：
> * 通过 `html.AnchorElement` 强制触发 `download` 属性，解决了浏览器将 PDF 二进制流解析为文本乱码的问题。
>
>
> 5. **[Controller] 进出房逻辑修复**：
> * 在 `ChatPage` 中使用 `ref.watch` 锚定 `chatControllerProvider`，彻底解决了“进房即退房”的生命周期问题。
>
>
>
>
> **🟢 当前版本：v4.9.0 (Ready for Refinement)**

---

## 1. 🛡️ 架构铁律 (The Iron Rules)

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
18. **面板推顶原则**: 输入框与功能面板必须处于同一 `Column` 布局流中，严禁使用 `Overlay` 覆盖输入框。
19. **组件解耦原则**: 底部菜单项必须抽象为数据配置 (`ActionItem`)，严禁页面层硬编码按钮逻辑。
20. **Web 路径过期处理**: 在 Web 端，消息发送成功后必须忽略本地 `blob:` 路径，强制使用远程路径加载。
21. **作用域安全**: 全局管理类（如 `OfflineQueueManager`）必须通过 `ProviderContainer` 读取服务，严禁手动 `new` 带有 `Ref` 依赖的实例。
22. **下载强制化**: Web 端处理非媒体文件必须通过 `anchor.download` 属性，防止二进制流被错误渲染为文本。
23. **状态布尔化**: 所有 Socket 事件必须包含显式的 `isSelf` 布尔值，严禁空值解析。

---

## 2. 🗺️ 代码地图 (Code Map - v4.9.0 Scope)

### A. 业务服务层 (Business Services)

* `ui/chat/services/download/file_download_service.dart`: **[✓] 下载引擎** (支持 Web 锚点下载与 Native 沙盒下载)。
* `ui/chat/services/network/offline_queue_manager.dart`: **[✓] 离线守护** (监听网络并触发重发管道)。
* `utils/url_resolver.dart`: **[✓] 全能解析器** (统一 `resolveFile`, `resolveImage`, `resolveVideo` 接口，内置全量 CDN 参数)。

### B. 交互组件层 (Interaction UI)

* `ui/chat/components/bubbles/file_msg_bubble.dart`: **[✓] 文件气泡** (内置 Loading 状态、图标映射表及下载触发逻辑)。
* `ui/chat/components/chat_action_sheet.dart`: **[✓] 全能菜单组件** (通用 Grid 布局，支持回调)。
* `ui/chat/components/modern_chat_input_bar.dart`: **[✓] 状态上提** (删除内部弹窗逻辑，改为 `onAddPressed` 回调)。

### C. 数据与逻辑层 (Core Logic)

* `local_database_service.dart`: **[✓] 数据预热与 Blob 保护** (解决 Web 端刷新 404 及单条/分页查询解析)。
* `chat_action_service.dart`: **[✓] 重发管道** (集成 `RecoverStep` 自动恢复路径)。
* `chat_room_provider.dart`: **[✓] 进出房控制器** (通过 `ref.watch` 维持 Socket 活跃状态)。

---

## 3. ✅ 完整功能清单 (The Grand Checklist)

### 🧩 v4.9.0 文件系统与稳定性硬化 (File & Stability)

* [✓] **[P0] 文件发送全链路**: 从 `sendFile` 触发到管道上传，再到后端 DTO 存储全闭环。
* [✓] **[P0] 离线自动重发**: `OfflineQueueManager` 接入全局 Container，实现网络恢复后的补偿发送。
* [✓] **[P0] 撤回/已读状态同步**: 修复了 `isSelf` 字段缺失导致的崩溃，实现了 Socket 实时同步。
* [✓] **[P0] Web 端过期路径保护**: 预热引擎增加 Web 专项检测，防止刷新后 Blob 路径失效。
* [✓] **[P1] 文件下载与打开**: 支持 Native 存入应用目录并调用第三方应用，Web 端一键弹出保存窗口。

### 🧩 v4.8.0 交互架构与菜单重构 (Interaction & Menu Arch)

* [✓] **[P0] 全能菜单组件化**: 建立 `ChatActionSheet`，实现配置化 Grid 菜单。
* [✓] **[P0] 原生级推顶布局**: 重构 `ChatPage` 为 `Column` 布局，输入框随面板自动顶起。
* [✓] **[P0] 键盘/面板无缝切换**: 解决了键盘收起时的高度跳动问题，实现丝滑过渡。
* [✓] **[P1] 安全区适配**: iPhone 底部 Home Indicator 适配，背景色沉浸式延伸。

### 🧠 v4.6.0~4.7.0 核心性能与体验硬化 (Performance Core)

* [✓] **[P0] 智能分页实装**: DB 层 `limit` 游标支持与 VM 层“本地优先”扩容策略。
* [✓] **[P0] 无感数据预热**: `_prewarmMessages` 引擎闭环，UI 层直接消费 `resolvedPath`。
* [✓] **[P1] BlurHash 视觉占位**: 前端计算、后端存储、UI 渲染全链路打通。

---

