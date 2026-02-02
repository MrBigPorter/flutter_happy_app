这份是您刚才发给我的 **v4.9.0 (文件系统版)**。

对比我们**刚刚完成**的 **“位置消息 & Nginx 调优”**，这份记录**缺少了最新的 v4.9.5 成果**，同时也缺少了 v4.8 之前的详细历史。

为了不让你混淆，我将 **最新成果 (位置/地图)** 与 **v4.9.0 (文件)** 进行了完美合并，并补全了所有历史战绩。

这是 **最终定稿、最全的 Grand Master Log (v4.9.5)**。请以这份为准归档！

---

# 📜 Lucky IM Project **Grand Master Log** (v4.0 - v4.9.5)

> **🕒 更新时间**: 2026-02-01 16:30
> **🚀 当前版本**: **v4.9.5 (Location & Full Media)**
> **🌟 总体进度**: 核心 IM 功能 (文本/图片/视频/语音/文件/位置) 全面闭环，进入精致化交互打磨阶段。

---

## 🏆 第一章：最新战役 (Current Era)

### v4.9.5 - 位置服务与基建调优 (LBS & Infra) 🔥

* **[LBS] 谷歌地图安全代理**: 后端 NestJS 实现 `StreamableFile` 代理，前端通过 Token 鉴权加载静态图，**彻底隐藏 Google API Key**。
* **[LBS] 智能地图唤起**: 开发 `MapLauncherService`，自动检测本地已安装地图（Google/Apple/高德等），使用 **Icon Mapping** 策略替代 SVG 解析，根治崩溃问题。
* **[Infra] Nginx 终极调优**: 完美融合旧业务路由（Webhooks）与新版高性能配置（HTTP/2, Gzip, CORS 精准控制），支持视频流 `Range` 拖拽播放。
* **[Core] 拦截器逃生舱**: 修复 NestJS 全局拦截器错误包装二进制流的问题，实现对 `StreamableFile` 和 `Buffer` 的自动放行。

### v4.9.0 - 文件系统与离线稳定性 (File System) 📂

* **[Feat] 文件消息全链路**: 集成 `file_picker`，升级 `ChatActionService` 管道支持 DTO 封装（文件名/后缀/大小），开发动态图标 `FileMsgBubble`。
* **[Stab] 离线队列重构**: 修复 `OfflineQueueManager` 的 `ProviderContainer` 作用域问题，实现断网重连后的**全局单例自动重发**。
* **[Fix] 撤回/已读同步**: 修复 `isSelf` 字段缺失导致的逻辑空指针，实现 Socket 撤回事件的多端实时同步。
* **[Web] PDF 预览修复**: 强制 Web 端使用 `anchor.download` 属性，防止浏览器将二进制流误判为乱码文本。

---

## 🥈 第二章：UI 与交互革命 (UI/UX Era)

### v4.8.0 - 交互架构重构 (Interaction) 🎨

* **[UI] 键盘/面板无缝切换**: 彻底解决键盘收起时的页面跳动问题，实现微信级丝滑过渡。
* **[Layout] 推顶布局重构**: 抛弃 Overlay 方案，重构为 `Column` 流式布局，输入框随功能面板自动顶起，完美适配 iPhone Home Indicator。
* **[Comp] 全能菜单组件**: 封装 `ChatActionSheet`，实现配置化 Grid 菜单，解耦页面逻辑。

### v4.6.5 - 媒体组件精修 (Media Polish) 🖼️

* **[Media] 视频播放器**: 基于 `media_kit` (VideoPlayer) 封装，支持双击暂停、进度条拖拽、静音控制。
* **[Media] 图片预览器**: 集成 `photo_view`，支持手势缩放、Hero 动画转场、长按保存。

---

## 🥉 第三章：性能与存储基石 (Performance Era)

### v4.7.0 - 极致性能优化 (Performance) 🚀

* **[Perf] 智能分页与游标**: 数据库层实现 `Limit/Offset` 游标分页，VM 层实现“本地优先”扩容策略，解决万级消息卡顿。
* **[Perf] 无感数据预热**: `_prewarmMessages` 引擎闭环，提前解析媒体路径，消除列表滚动时的 IO 顿挫感。
* **[UX] BlurHash 视觉占位**: 全链路打通 BlurHash 生成与存储，图片加载前显示高斯模糊占位，拒绝白屏。

### v4.6.0 - 本地数据库与缓存 (Database) 💾

* **[DB] Isar 数据库集成**: 完成 Schema 设计（Conversation/Message），实现高频读写。
* **[Cache] 路径相对化存储**: 数据库仅存相对路径/UUID，绝对路径由 `AssetManager` 运行时动态拼接，解决 App 更新导致沙盒路径变更问题。
* **[Web] Blob 路径保护**: 针对 Web 端刷新丢失 `blob:` 问题，建立内存映射表与远程路径回退机制。

---

## 🏅 第四章：核心通讯能力 (Core Era)

### v4.5.0 - 多媒体消息管道 (Multimedia) 📷

* **[Image] 图片发送**: 包含压缩（`flutter_image_compress`）、缩略图生成、上传进度条。
* **[Video] 视频发送**: 集成 `ffmpeg` 进行压缩（`-movflags +faststart`），自动截取首帧作为封面。
* **[Voice] 语音消息**: 实现 AAC 录制与播放，波形图动画，听筒/扬声器切换。

### v4.0.0 - 通讯协议地基 (Protocol) 📡

* **[Net] Socket.IO 封装**: 实现心跳保活、断线重连、鉴权握手 (`auth: { token }`)。
* **[Net] HTTP/2 适配**: 引入 `native_dio_adapter`，开启 HTTP/2 多路复用，大幅提升并发加载速度。
* **[Auth] 登录鉴权**: 完整的 JWT 流程，Token 持久化与自动刷新。

---

## 🛡️ 架构铁律 (The Iron Rules - Updated)

*(这是我们开发过程中用血泪总结出来的 28 条军规，**新增了 24-28 条**)*

1. **ID 唯一性**: 前端生成 UUID，后端透传。
2. **UI 零抖动**: 利用 `_sessionPathCache` 确保发送瞬间 UI 静止。
3. **单向数据流**: UI 只听 DB，Pipeline 完成后静默回写数据库。
4. **存储相对化**: 数据库仅存文件名 ID/相对路径，绝对路径运行时生成。
5. **极速预览优先**: `MemoryBytes` > `BlurHash` > `LocalFile` > `Network`。
6. **资源单一出口**: 路径解析统一归口 `AssetManager`。
7. **数据净化原则**: 上传 Meta 必须重建，隔绝本地字段泄漏。
8. **智能旁路原则**: 小文件 (<10MB) 跳过压缩。
9. **流优化原则**: 视频压缩强制 `-movflags +faststart`。
10. **类型强一致性**: 视频上传强制指定 `video/mp4`。
11. **本地优先原则**: 优先检索本地物理存储。
12. **游标有序性**: 历史消息分页使用 `seqId`。
13. **Web 路径保护**: Pipeline 持有原始 `XFile`，防止 Blob 丢失。
14. **解码受限原则**: 图片加载指定 `memCacheWidth`。
15. **协议先进性**: 强推 **HTTP/2** 适配器。
16. **媒体流透传**: Nginx 必须支持 `Range` 请求。
17. **安全跨域原则**: CORS 必须基于动态 `map` 匹配。
18. **面板推顶原则**: 严禁 `Overlay`，必须用 `Column` 布局。
19. **组件解耦原则**: 菜单项抽象为 `ActionItem` 配置。
20. **Web 路径过期**: 发送成功后强制使用远程路径。
21. **作用域安全**: `OfflineQueue` 严禁手动 `new`，必须走 Provider。
22. **下载强制化**: Web 下载必须用 `anchor.download`。
23. **状态布尔化**: Socket 事件必须包含 `isSelf`。
24. **API Key 隐身**: **[New]** Google Maps 必须走后端 Proxy，前端只拼 URL。
25. **图标本地化**: **[New]** 地图图标严禁 SVG 解析，必须用 Flutter `Icon` 映射。
26. **流式穿透原则**: **[New]** 拦截器必须放行 `StreamableFile`。
27. **布局强约束**: **[New]** 异步图片外层必须包 `SizedBox` 防止 `RenderBox` 报错。
28. **缓存分级原则**: **[New]** 头像加载遵循 `内存 -> 本地文件 -> 网络下载生成` 的三级策略。

---

