---

# 📜 Lucky IM Project **Grand Master Log** (v4.0 - v5.2.1)

> **🕒 最后更新**: 2026-02-04 23:25 (PST)
> **🚀 当前版本**: **v5.2.1 (Offline Reachability & Event-Driven)**
> **🌟 总体进度**: 成功构建基于 Event Emitter 的解耦后端架构，彻底打通 Android/iOS/Web 全平台离线推送与路由跳转，实现高可靠的消息触达闭环。

---

## 🏆 第一章：最新战役 (Current Era)

### v5.2.1 - 离线触达与事件驱动架构 (Offline Reachability) 📡 **[NEW]**

* **[Arch] 后端事件驱动解耦 (Event-Driven)**:
* **架构重构**: 引入 `@nestjs/event-emitter`，将 `ChatService` 转变为纯粹的事件生产者 (Producer)，彻底移除对 `Socket` 和 `Notification` 服务的直接依赖。
* **独立监听**: 建立 `SocketListener` (实时) 与 `PushListener` (离线) 双消费者模式，实现发送接口 **零阻塞** 与逻辑 **完全解耦**。
* **适配器模式**: 在 `SocketListener` 中实现 DTO 适配，确保后端架构升级对前端代码 **零侵入** (Zero Breaking Changes)。


* **[FCM] 全平台离线触达闭环**:
* **多端统一**: 打通 Android (High Importance Channel) 与 Web (Service Worker) 的推送通道。
* **智能分发**: 前端实现 `FcmDispatcher`，精准处理 **前台 (BotToast)**、**后台 (Notification)** 及 **冷启动 (Launch)** 三种状态的路由跳转与交互。
* **双重保险**: 在后端 `PushListener` 实施 **Data Redundancy** 策略，将 `title/body` 冗余写入 `data` 载荷，完美解决 Web/Android 系统吞没 Notification 对象导致内容丢失的问题。


* **[Web] 浏览器原生深度适配**:
* **Service Worker**: 在 `web/` 根目录部署 `firebase-messaging-sw.js`，实现网页关闭/后台状态下的独立消息接收与系统通知唤起。
* **VAPID 鉴权**: 动态注入 VAPID Key，实现 Web 端 Token 的安全获取与上报。
* **跨平台防御**: 在 UI 层 (`FcmUiFactory`) 增加 `kIsWeb` 守卫，修复 `HapticFeedback` 等原生 API 在 Web 端导致的崩溃。



### v5.2.0 - 消息自愈与可靠性保障 (Self-Healing) 🛡️

* **[Sync] 增量同步自愈算法**:
* **核心逻辑**: 摒弃全量拉取，基于本地 `localMaxSeqId` 向后端精准对账，利用游标递归抓取空洞消息。
* **断层缝合**: 验证通过“飞行模式”恢复场景，系统在重连后自动识别并填平离线期间的消息断层。


* **[Stab] 生命周期与重连触发器**:
* **冲突修复**: 引入 `Future.microtask` 异步调度机制，彻底解决 Riverpod 初始化期间修改状态导致的 `fail assertion` 报错。
* **全时监听**: 在 `ChatEventHandler` 中集成 `socket.on('connect')` 监听，配合 `AppLifecycleState.resumed` 状态，确保 App 回到前台即刻对账。


* **[Action] 乐观更新架构升级**:
* **零延迟上屏**: 优化 `ChatActionService` 流水线，在执行耗时压缩/上传前立即 save 到本地 DB 并触发 UI 监听。
* **状态闭环**: 成功实现消息从 `sending` 到 `success` 的静默回写与 `seqId` 后验。



---

### v5.1.0 - Web FCM 推送与跨平台隔离 (Push & Isolation) 📡

* **[FCM] Web Service Worker 架构**:
* **核心集成**: 在 `web/` 根目录部署 `firebase-messaging-sw.js`，实现网页后台/关闭状态下的消息监听与通知弹出。
* **版本适配**: 采用 `importScripts` 引入 Firebase 8.x SDK，确保在现代浏览器 Service Worker 环境下的稳定性。
* **MIME 修复**: 彻底解决 Web 端因路径配置错误导致的 `unsupported MIME type ('text/html')` 阻断报错。


* **[Auth] VAPID 鉴权闭环**:
* **协议实现**: 成功集成 Web 推送专用 VAPID (Voluntary Application Server Identification) 协议。
* **代码解耦**: 在 `getToken` 逻辑中动态注入 `vapidKey`，实现了 Web 端与原生 App 端获取 Token 逻辑的平滑切换。


* **[Stab] 跨平台环境隔离 (Cross-Platform Guard)**:
* **IO 屏蔽**: 识别并修复 `Platform._operatingSystem` 在 Web 端的崩溃点，建立以 `kIsWeb` 为核心的条件编译/运行准则。
* **架构升级**: 将所有涉及 `dart:io` 的操作封装在平台检测逻辑内，确保同一套代码在 Android、iOS 与 Web 间无缝流转。


* **[Infra] 云存储跨域治理 (CORS)**:
* **安全加固**: 通过 Google Cloud Shell 使用 `gsutil` 配置存储桶 CORS 规则，允许 `localhost` 及生产域名安全加载多媒体资源。



---

### v5.0.0 - 社交地基与性能止血 (Social Foundation & Performance) 🔥

* **[Critical] 接口风暴止血 (Anti-DDoS)**:
* **架构修正**: 彻底移除 `ConversationItem` 对 `chatDetailProvider` 的 `ref.watch` 监听，切断了无限递归死循环。
* **性能提升**: 列表页网络请求数从 **N+1** 瞬间降为 **1**，CPU 与内存占用大幅下降。


* **[UX] 列表静默刷新 (Silent Refresh)**:
* **SWR 策略**: `ConversationList` 引入 **Stale-While-Revalidate** 机制。
* **无感更新**: 利用 `AsyncValue.guard` 在后台更新数据，用户界面保持当前内容直至新数据到达，消除白屏闪烁。


* **[Social] 通讯录 A-Z 索引 (Contacts)**:
* **核心集成**: 引入 `AzListView` 配合 `lpinyin` 实现拼音排序。
* **交互细节**: 实现 Sticky Header (悬浮表头)，侧边栏滑动 HapticFeedback (震动反馈) 及 Glassmorphism 风格气泡。


* **[Stab] Web 编译兼容性**: 修复 `universal_html` 交互中 `int?` 引起的编译阻断。
* **[UI] 卡片化视觉重构**: 通讯录与会话列表全面升级为 **Card-style** 布局。

---

## 🥈 第二章：文件与离线革命 (File & Offline Era)

### v4.9.5 - 位置服务与基建调优 (LBS & Infra)

* **[LBS] 谷歌地图安全代理**: 后端 NestJS 实现 `StreamableFile` 代理，**彻底隐藏 Google Maps API Key**。
* **[LBS] 智能地图唤起**: 自动检测本地安装的地图 App；Web 端自动降级为跳转 URL Scheme 防止崩溃。
* **[Infra] Nginx 终极调优**: 启用 **HTTP/2 & HTTP/3 (QUIC)**；支持 `proxy_force_ranges` 视频断点续传。

### v4.9.0 - 文件系统与离线稳定性 (File System) 📂

* **[Feat] 文件消息全链路**: 支持文件名/大小/后缀自动提取，动态图标展示。
* **[Stab] 离线队列重构**: 修复作用域问题，实现**全局单例自动重发**。
* **[Fix] 撤回/已读同步**: 修复 `isSelf` 字段缺失，实现 Socket 事件多端同步。

---

## 🥉 第三章：UI 与交互革命 (UI/UX Era)

### v4.8.0 - 交互架构重构 (Interaction) 🎨

* **[UI] 键盘/面板无缝切换**: 利用 `addPostFrameCallback` 锁定高度，实现 iOS 级丝滑过渡。
* **[Layout] 推顶布局重构**: 抛弃 Overlay，采用 `Column` (List+Input+Panel) 流式布局。
* **[Comp] 全能菜单组件**: 封装配置化 `ChatActionSheet`，逻辑与 UI 解耦。

### v4.6.5 - 媒体组件精修 (Media Polish) 🖼️

* **[Media] 视频播放器**: 基于 `media_kit` 封装，支持双击暂停、手势进度。
* **[Media] 图片预览器**: 集成 `photo_view`，支持 Hero 动画与双指缩放。

---

## 🏅 第四章：性能与存储基石 (Performance Era)

### v4.7.0 - 极致性能优化 (Performance) 🚀

* **[Perf] 智能分页与游标**: 数据库层 `Limit/Offset` 游标分页。
* **[Perf] 无感数据预热**: `_prewarmMessages` 引擎闭环，消除列表滚动顿挫。
* **[UX] BlurHash 视觉占位**: 全链路打通，拒绝加载白屏。

### v4.6.0 - 本地数据库与缓存 (Database) 💾

* **[DB] Isar 数据库集成**: Schema 设计与高频读写实现。
* **[Cache] 路径相对化存储**: 仅存相对路径，解决 iOS/Android 沙盒路径变更问题。

---

## 💎 第五章：核心通讯能力 (Core Era)

### v4.5.0 - 多媒体消息管道 (Multimedia) 📷

* **[Image] 图片发送**: 高效压缩 (`flutter_image_compress`) + 本地即时缩略图。
* **[Video] 视频发送**: `ffmpeg` 压缩 (强制 `-movflags +faststart`) + 首帧截取。
* **[Voice] 语音消息**: AAC 格式录制，自定义波形图动画。

### v4.0.0 - 通讯协议地基 (Protocol) 📡

* **[Net] Socket.IO 封装**: 心跳保活、断线重连、Token 鉴权。
* **[Net] HTTP/2 & HTTP/3 适配**: App 端开启 QUIC 加速。
* **[Auth] 登录鉴权**: JWT 流程，Token 持久化与自动刷新。

---

## 🛡️ 架构铁律 (The Iron Rules - v5.2.1)

1. **ID 唯一性**: 前端生成 UUID，确保消息幂等性。
2. **UI 零抖动**: 利用 `_sessionPathCache` 确保发送瞬间 UI 静止。
3. **单向数据流**: UI 只听 DB，Pipeline 完成后静默回写数据库。
4. **列表零依赖原则**: Item 组件严禁监听异步详情 Provider，列表数据由列表 API 统一提供。
5. **SWR 原则**: 列表刷新严禁置为 Loading 状态，保持旧数据直至新数据到达。
6. **索引分层原则**: 通讯录必须先排序再计算悬浮状态。
7. **Web 空安全原则**: 处理 JS 互操作的可空类型 (`int?`), 严禁直接赋值。
8. **Web 环境感知原则**: 严禁在非 `kIsWeb` 保护下调用 `dart:io`。所有平台判断必须优先识别 `kIsWeb`。
9. **Service Worker 根路径原则**: `firebase-messaging-sw.js` 必须位于 `web/` 根目录。
10. **VAPID 强制化原则**: Web 端 FCM 获取 Token 必须通过 VAPID 鉴权。
11. **异步对账原则**: 严禁在 Provider 初始化生命周期内同步修改其他 Provider，必须使用 `Future.microtask` 确保状态流转安全。
12. **三位一体同步原则**: 可靠性必须由 FCM 信号、Socket 实时流、API 游标对账共同保障，缺一不可。
13. **本地最大化对账原则**: 任何同步行为必须以本地数据库 `getMaxSeqId` 为绝对锚点，拒绝全量拉取。
14. **事件驱动原则 (New)**: 业务 Service (如 Chat) 严禁直接依赖基础设施 (如 FCM)，必须通过 Event Bus 解耦，确保核心链路的高可用与低延迟。
15. **推送冗余原则 (New)**: FCM 载荷的 `data` 字段必须冗余包含 `title` 和 `body`，以兼容 Web 端及防止 Android 系统吞没 Notification 对象。