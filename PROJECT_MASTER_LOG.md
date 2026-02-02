收到，指令明确。

以下是根据你的最新指示，**经过最终校对、合并、补全**的 **Lucky IM 项目史诗级完整日志 (Grand Master Log v4.9.5)**。

这份日志真实、完整地记录了从 **v4.0 协议底层** 到 **v4.9.5 LBS 位置服务与基建调优** 的所有核心技术决策与战役成果。它不仅是一份更新记录，更是整个 IM 系统的**架构真理书**。

请直接复制归档。 📋

---

# 📜 Lucky IM Project **Grand Master Log** (v4.0 - v4.9.5)

> **🕒 最后更新**: 2026-02-02 18:30 (PST)
> **🚀 当前版本**: **v4.9.5 (Location & Full Media & Infra Optimized)**
> **🌟 总体进度**: 核心 IM 功能 (文本/图片/视频/语音/文件/位置) 全面闭环，基础设施完成 HTTP/3 与 Nginx 终极调优，进入精致化交互打磨与性能深水区。

---

## 🏆 第一章：最新战役 (Current Era)

### v4.9.5 - 位置服务与基建调优 (LBS & Infra) 🔥

* **[LBS] 谷歌地图安全代理 (Backend Proxy)**:
* **架构升级**: 后端 NestJS 实现 `StreamableFile` 代理接口，前端通过 JWT Token 鉴权加载静态地图图片。
* **安全闭环**: **彻底隐藏 Google Maps API Key** 于后端环境变量中，前端仅拼接路径参数，彻底杜绝了 API Key 泄漏导致被盗刷的风险。
* **流式穿透**: 修复 NestJS 全局拦截器 (`TransformInterceptor`) 错误包装二进制流的问题，实现对 `StreamableFile` 和 `Buffer` 类型的自动放行；前端 `Http.rawDio` 实现手动 Token 注入，绕过 JSON 解析器直接获取图片二进制数据。


* **[LBS] 智能地图唤起 (Map Launcher)**:
* **服务封装**: 开发 `MapLauncherService`，自动检测设备本地已安装的地图应用（Google Maps, Apple Maps, 高德, 百度, Waze 等）。
* **图标策略**: 摒弃不稳定的 SVG 解析方案，采用 **Icon Mapping** 策略，使用 `flutter_vector_icons` 或内置 Icon 静态映射地图品牌，提升渲染性能与兼容性。
* **Web 降级**: 针对 Web 端无法检测 App 安装的情况，实现 `url_launcher` 降级跳转策略，直接打开地图网页版，根治了 Web 端调用原生 API 导致的崩溃问题。


* **[LBS] 交互防抖与缓存 (Web Optimization)**:
* **重构气泡**: 将位置消息气泡升级为 `StatefulWidget` 并混入 `AutomaticKeepAliveClientMixin`。
* **Future 缓存**: 利用 `late Future` 缓存机制，确保静态地图 URL 只在 `initState` 中生成一次，彻底解决 Web 端因 `build` 方法频繁调用导致的 Google Maps API **429 Too Many Requests** 问题。


* **[Infra] Nginx 终极调优 (Server Tuning)**:
* **配置融合**: 完美融合旧业务路由（Webhooks）与新版高性能配置，消除配置冲突。
* **协议升级**: 全面启用 **HTTP/2**，并针对支持的客户端开启 **HTTP/3 (QUIC)**，大幅降低握手延迟。
* **传输优化**: 开启 `Gzip` 压缩，配置精准的 CORS 策略。
* **媒体流支持**: 核心配置 `proxy_force_ranges on;`，支持视频流的 **Range 请求**，实现视频播放的随意拖拽与断点续传。



---

## 🥈 第二章：文件与离线革命 (File & Offline Era)

### v4.9.0 - 文件系统与离线稳定性 (File System) 📂

* **[Feat] 文件消息全链路**: 集成 `file_picker`，升级 `ChatActionService` 管道支持 DTO 封装（智能提取文件名、后缀、大小），开发动态图标 `FileMsgBubble`，支持不同文件类型的差异化展示。
* **[Stab] 离线队列重构**: 修复 `OfflineQueueManager` 的 `ProviderContainer` 作用域问题，移除手动实例化的反模式，实现断网重连后的**全局单例自动重发**机制，确保消息不丢。
* **[Fix] 撤回/已读同步**: 修复 `isSelf` 字段缺失导致的逻辑空指针，实现 Socket 撤回事件的多端实时同步（对方撤回 -> 本地更新 UI）。
* **[Web] PDF 预览修复**: 针对 Web 端 Blob 预览乱码问题，强制使用 `anchor.download` 属性触发浏览器下载行为，防止浏览器将二进制流误判为乱码文本直接渲染。

---

## 🥉 第三章：UI 与交互革命 (UI/UX Era)

### v4.8.0 - 交互架构重构 (Interaction) 🎨

* **[UI] 键盘/面板无缝切换**: 彻底解决键盘收起时的页面跳动问题，利用 `WidgetsBinding.instance.addPostFrameCallback` 锁定高度，实现微信级丝滑过渡。
* **[Layout] 推顶布局重构**: 抛弃不稳定的 Overlay 方案，重构为 `Column` 流式布局 (`Expanded List` + `Input` + `Panel`)，输入框随功能面板自动顶起，完美适配 iPhone Home Indicator。
* **[Comp] 全能菜单组件**: 封装 `ChatActionSheet`，实现配置化 Grid 菜单，将页面逻辑与菜单项解耦，支持动态扩展。

### v4.6.5 - 媒体组件精修 (Media Polish) 🖼️

* **[Media] 视频播放器**: 基于 `media_kit` (VideoPlayer) 封装，支持双击暂停、进度条拖拽、静音控制、全屏切换，性能优于官方插件。
* **[Media] 图片预览器**: 集成 `photo_view`，支持双指手势缩放、Hero 动画无缝转场、长按保存到相册。

---

## 🏅 第四章：性能与存储基石 (Performance Era)

### v4.7.0 - 极致性能优化 (Performance) 🚀

* **[Perf] 智能分页与游标**: 数据库层实现 `Limit/Offset` 游标分页，ViewModel 层实现“本地优先”扩容策略，解决万级消息列表卡顿问题。
* **[Perf] 无感数据预热**: `_prewarmMessages` 引擎闭环，提前解析媒体路径（BlurHash解码、文件检查），消除列表快速滚动时的 IO 顿挫感。
* **[UX] BlurHash 视觉占位**: 全链路打通 BlurHash 生成与存储，图片加载前显示与原图色调一致的高斯模糊占位，拒绝加载白屏。

### v4.6.0 - 本地数据库与缓存 (Database) 💾

* **[DB] Isar 数据库集成**: 完成 Schema 设计（Conversation/Message），实现高频读写与复杂查询。
* **[Cache] 路径相对化存储**: 数据库仅存相对路径/UUID，绝对路径由 `AssetManager` 运行时动态拼接，彻底解决 App 更新或容器迁移导致沙盒路径变更问题。
* **[Web] Blob 路径保护**: 针对 Web 端刷新丢失 `blob:` URL 的问题，建立内存映射表与远程路径自动回退机制。

---

## 💎 第五章：核心通讯能力 (Core Era)

### v4.5.0 - 多媒体消息管道 (Multimedia) 📷

* **[Image] 图片发送**: 包含高效压缩（`flutter_image_compress`）、本地缩略图即时生成、上传进度条展示。
* **[Video] 视频发送**: 集成 `ffmpeg` 进行压缩（强制 `-movflags +faststart` 以支持边下边播），自动截取首帧作为封面图。
* **[Voice] 语音消息**: 实现 AAC 格式录制与播放，自定义波形图动画，支持听筒/扬声器模式切换。

### v4.0.0 - 通讯协议地基 (Protocol) 📡

* **[Net] Socket.IO 封装**: 实现心跳保活、断线自动重连、鉴权握手 (`auth: { token }`)。
* **[Net] HTTP/2 & HTTP/3 适配**: 引入 `native_dio_adapter` 工厂模式，App 端开启 HTTP/2 多路复用与 HTTP/3 (QUIC) 加速，Web 端自动降级 BrowserClient，大幅提升高并发下的媒体加载速度。
* **[Auth] 登录鉴权**: 完整的 JWT 流程，Token 持久化存储与拦截器自动刷新机制。

---

## 🛡️ 架构铁律 (The Iron Rules - v4.9.5)

*(这是项目开发的最高准则，新增了 24-30 条)*

1. **ID 唯一性**: 前端生成 UUID，后端透传，确保消息幂等性。
2. **UI 零抖动**: 利用 `_sessionPathCache` 确保发送瞬间 UI 静止，不等待服务器响应。
3. **单向数据流**: UI 只听 DB，Pipeline 完成后静默回写数据库，触发 UI 更新。
4. **存储相对化**: 数据库仅存文件名 ID/相对路径，绝对路径运行时生成。
5. **极速预览优先**: `MemoryBytes` > `BlurHash` > `LocalFile` > `Network`。
6. **资源单一出口**: 路径解析统一归口 `AssetManager`。
7. **数据净化原则**: 上传 Meta 必须重建，隔绝本地字段泄漏。
8. **智能旁路原则**: 小文件 (<10MB) 跳过压缩，直接上传。
9. **流优化原则**: 视频压缩强制 `-movflags +faststart`。
10. **类型强一致性**: 视频上传强制指定 `video/mp4` MIME 类型。
11. **本地优先原则**: 优先检索本地物理存储，不存在才走网络。
12. **游标有序性**: 历史消息分页使用 `seqId` 或 `timestamp`。
13. **Web 路径保护**: Pipeline 持有原始 `XFile`，防止 Blob 丢失。
14. **解码受限原则**: 图片加载指定 `memCacheWidth`，防止内存溢出。
15. **协议先进性**: 强推 **HTTP/2 & HTTP/3** 适配器，Web 端做条件降级。
16. **媒体流透传**: Nginx 必须支持 `Range` 请求。
17. **安全跨域原则**: CORS 必须基于动态 `map` 匹配，严禁 `Access-Control-Allow-Origin: *`。
18. **面板推顶原则**: 严禁 `Overlay`，必须用 `Column` 布局。
19. **组件解耦原则**: 菜单项抽象为 `ActionItem` 配置。
20. **Web 路径过期**: 发送成功后强制使用远程路径。
21. **作用域安全**: `OfflineQueue` 严禁手动 `new`，必须走 Riverpod Provider。
22. **下载强制化**: Web 下载必须用 `anchor.download` 触发。
23. **状态布尔化**: Socket 事件必须包含 `isSelf` 字段。
24. **API Key 隐身**: **[New]** Google Maps API Key 必须走后端 Proxy，前端只拼 URL。
25. **图标本地化**: **[New]** 地图图标严禁 SVG 解析，必须用 Flutter `Icon` 静态映射。
26. **流式穿透原则**: **[New]** NestJS 全局拦截器必须放行 `StreamableFile` 和 `Buffer`。
27. **布局强约束**: **[New]** 异步图片外层必须包 `SizedBox` 指定宽高，防止 `RenderBox` 报错。
28. **缓存分级原则**: **[New]** 头像加载遵循 `内存 -> 本地文件 -> 网络下载生成` 的三级策略。
29. **Web 适配原则**: **[New]** `NativeAdapter` 必须通过工厂模式条件导入，严禁在 Web 端引用 `dart:ffi` 相关库。
30. **状态防抖原则**: **[New]** Web 端异步资源加载必须在 `State` 中缓存 Future，严禁在 `build` 方法中直接请求外部资源。