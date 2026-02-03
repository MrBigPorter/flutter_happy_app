没问题，已将 **v5.0.0** 的关键战役成果（性能止血、通讯录索引、Web兼容性修复）完整归档，并保留了所有历史记录。

这是最新的 **Grand Master Log**：

---

# 📜 Lucky IM Project **Grand Master Log** (v4.0 - v5.0.0)

> **🕒 最后更新**: 2026-02-03 20:30 (PST)
> **🚀 当前版本**: **v5.0.0 (Social Foundation & Performance Stanching)**
> **🌟 总体进度**: 成功遏制性能出血点（接口风暴），建立工业级社交通讯录（A-Z 索引），修复 Web 端编译兼容性，架构重心正式转向增量同步与搜索。

---

## 🏆 第一章：最新战役 (Current Era)

### v5.0.0 - 社交地基与性能止血 (Social Foundation & Performance) 🔥

* **[Critical] 接口风暴止血 (Anti-DDoS)**:
* **架构修正**: 彻底移除 `ConversationItem` 对 `chatDetailProvider` 的 `ref.watch` 监听，切断了“列表渲染 -> 触发详情请求 -> 更新状态 -> 列表重绘”的无限递归死循环。
* **性能提升**: 列表页网络请求数从 **N+1**（N为会话数）瞬间降为 **1**（仅列表接口），CPU 与内存占用大幅下降。


* **[UX] 列表静默刷新 (Silent Refresh)**:
* **SWR 策略**: `ConversationList` 引入 **Stale-While-Revalidate** 机制，`refresh()` 操作不再将状态置为 `loading`。
* **无感更新**: 利用 `AsyncValue.guard` 在后台更新数据，用户界面保持当前内容直至新数据到达，彻底消除了“白屏闪烁”和“转圈焦虑”。


* **[Social] 通讯录 A-Z 索引 (Contacts)**:
* **核心集成**: 引入 `AzListView` 配合 `lpinyin` 实现中文拼音排序与分组。
* **交互细节**: 实现 **Sticky Header** (悬浮表头)，侧边栏滑动 **HapticFeedback** (震动反馈)，以及 **Glassmorphism** (毛玻璃) 风格的中央气泡提示。
* **API 适配**: **[New]** 修正 `AzListView` 新版 API 废弃 `showIndexHint` 参数的问题，通过 `indexHintBuilder` 隐式开启气泡。
* **空安全**: 修复 `SuspensionUtil` 空数据崩溃问题，增加 `Empty State` 兜底。


* **[Stab] Web 编译兼容性 (Web Stability)**:
* **空安全修复**: **[New]** 修复 `ImageCompressionService` 中 `universal_html` 返回 `int?` 导致的编译阻断，使用 `?? 0` 兜底策略，确保 Web 端图片压缩流程健壮。


* **[UI] 卡片化视觉重构 (Cardify)**:
* **视觉升级**: 通讯录与会话列表全面升级为 **Card-style** 布局，增加物理间距与呼吸感，摒弃紧凑的直线列表。
* **组件解耦**: 重构 `GroupAvatar`，移除对 `memberCount` 的逻辑强依赖，采用统一的 Icon 占位策略，提升渲染性能。



### v4.9.5 - 位置服务与基建调优 (LBS & Infra)

* **[LBS] 谷歌地图安全代理 (Backend Proxy)**:
* **架构升级**: 后端 NestJS 实现 `StreamableFile` 代理，前端通过 Token 鉴权加载静态地图，**彻底隐藏 Google Maps API Key**。
* **流式穿透**: 修复 NestJS 全局拦截器错误包装二进制流的问题，前端 `rawDio` 直连获取 Buffer。


* **[LBS] 智能地图唤起 (Map Launcher)**:
* **服务封装**: 自动检测本地安装的地图 App (Google/Apple/高德/百度)，提供 `ActionSheet` 选择。
* **Web 降级**: Web 端自动降级为跳转 URL Scheme，防止调用原生 API 崩溃。


* **[Infra] Nginx 终极调优 (Server Tuning)**:
* **协议升级**: 全面启用 **HTTP/2**，针对支持的客户端开启 **HTTP/3 (QUIC)**。
* **媒体流**: 开启 `proxy_force_ranges on;` 支持视频断点续传与拖拽。



---

## 🥈 第二章：文件与离线革命 (File & Offline Era)

### v4.9.0 - 文件系统与离线稳定性 (File System) 📂

* **[Feat] 文件消息全链路**: 集成 `file_picker`，支持文件名/大小/后缀自动提取，动态图标 `FileMsgBubble` 展示。
* **[Stab] 离线队列重构**: 修复 `OfflineQueueManager` 作用域问题，实现**全局单例自动重发**。
* **[Fix] 撤回/已读同步**: 修复 `isSelf` 字段缺失问题，实现 Socket 事件的多端实时同步。
* **[Web] PDF 预览修复**: 强制使用 `anchor.download` 触发下载，防止二进制流乱码。

---

## 🥉 第三章：UI 与交互革命 (UI/UX Era)

### v4.8.0 - 交互架构重构 (Interaction) 🎨

* **[UI] 键盘/面板无缝切换**: 利用 `addPostFrameCallback` 锁定高度，实现 iOS 级丝滑过渡。
* **[Layout] 推顶布局重构**: 抛弃 Overlay，采用 `Column` (List+Input+Panel) 流式布局，完美适配全面屏。
* **[Comp] 全能菜单组件**: 封装配置化 `ChatActionSheet`，逻辑与 UI 解耦。

### v4.6.5 - 媒体组件精修 (Media Polish) 🖼️

* **[Media] 视频播放器**: 基于 `media_kit` 封装，支持双击暂停、手势进度拖拽。
* **[Media] 图片预览器**: 集成 `photo_view`，支持 Hero 动画与双指缩放。

---

## 🏅 第四章：性能与存储基石 (Performance Era)

### v4.7.0 - 极致性能优化 (Performance) 🚀

* **[Perf] 智能分页与游标**: 数据库层 `Limit/Offset` 游标分页，ViewModel 本地优先扩容。
* **[Perf] 无感数据预热**: `_prewarmMessages` 引擎闭环，消除列表滚动顿挫。
* **[UX] BlurHash 视觉占位**: 全链路打通 BlurHash，拒绝加载白屏。

### v4.6.0 - 本地数据库与缓存 (Database) 💾

* **[DB] Isar 数据库集成**: Schema 设计与高频读写实现。
* **[Cache] 路径相对化存储**: 仅存相对路径，运行时拼接，解决沙盒路径变更问题。
* **[Web] Blob 路径保护**: 建立内存映射表，防止 Web 刷新丢失图片。

---

## 💎 第五章：核心通讯能力 (Core Era)

### v4.5.0 - 多媒体消息管道 (Multimedia) 📷

* **[Image] 图片发送**: 高效压缩 (`flutter_image_compress`) + 本地即时缩略图。
* **[Video] 视频发送**: `ffmpeg` 压缩 (强制 `-movflags +faststart`) + 首帧截取。
* **[Voice] 语音消息**: AAC 格式录制，自定义波形图动画。

### v4.0.0 - 通讯协议地基 (Protocol) 📡

* **[Net] Socket.IO 封装**: 心跳保活、断线重连、Token 鉴权。
* **[Net] HTTP/2 & HTTP/3 适配**: 引入 `native_dio_adapter`，App 端开启 QUIC 加速。
* **[Auth] 登录鉴权**: JWT 流程，Token 持久化与自动刷新。

---

## 🛡️ 架构铁律 (The Iron Rules - v5.0.0)

*(这是项目开发的最高准则，新增了 31-34 条)*

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
24. **API Key 隐身**: Google Maps API Key 必须走后端 Proxy，前端只拼 URL。
25. **图标本地化**: 地图图标严禁 SVG 解析，必须用 Flutter `Icon` 静态映射。
26. **流式穿透原则**: NestJS 全局拦截器必须放行 `StreamableFile` 和 `Buffer`。
27. **布局强约束**: 异步图片外层必须包 `SizedBox` 指定宽高，防止 `RenderBox` 报错。
28. **缓存分级原则**: 头像加载遵循 `内存 -> 本地文件 -> 网络下载生成` 的三级策略。
29. **Web 适配原则**: `NativeAdapter` 必须通过工厂模式条件导入，严禁在 Web 端引用 `dart:ffi` 相关库。
30. **状态防抖原则**: Web 端异步资源加载必须在 `State` 中缓存 Future，严禁在 `build` 方法中直接请求外部资源。
31. **列表零依赖原则**: **[New]** Item 组件严禁监听异步详情 Provider，列表数据必须由 List API 统一提供或后端字段补全。
32. **SWR 原则**: **[New]** 列表刷新严禁置为 Loading 状态，必须保持旧数据直至新数据到达 (AsyncValue.guard)。
33. **索引分层原则**: **[New]** 通讯录必须先排序再计算悬浮状态 (Sort -> SuspensionStatus)，顺序不可乱。
34. **Web 空安全原则**: **[New]** `universal_html` 交互时必须处理 JS 互操作的可空类型 (`int?`), 严禁直接赋值给非空变量，防止编译阻断。