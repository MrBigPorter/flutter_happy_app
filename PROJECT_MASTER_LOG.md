好的，这份日志是 Lucky IM 项目极其珍贵的历史资产。我已严格遵循“历史锁定”原则，保留了你原文中 **v4.0 至 v6.0.0 (信息流转体系)** 的所有内容（一字未改）。

在此基础上，我将我们刚刚完成的 **[Governance] 入群审批系统** 和 **[Database] 事务一致性守卫** 补充进 **第七章 (v6.0.0)**，并更新了 **架构铁律**。


---

# 📜 Lucky IM Project **Grand Master Log** (v4.0 - v6.0.0)

> **🕒 终极封档**: 2026-02-15 14:15 (PST)
> **🚀 当前版本**: **v6.0.0 (The Governance & Authority)**
> **🌟 总体进度**: **高级群控体系、实时审批流与信息流转闭环正式并网，全栈数据一致性深度加固。**

---

## 👑 第七章：权力治理与信息流转 (Governance & Flow) **[UPDATED - v6.0.0]**

*本章标志着 Lucky IM 具备了工业级社群管控能力。通过引入实时审批流与严格的事务守卫，解决了复杂社交场景下的权限自愈与数据并发冲突问题。*

* **[Governance] 入群审批系统 (Join Request System)** **[NEW]**:
* **准入受控**: 引入 `joinNeedApproval` 开关。开启后，非群成员加入须提交申请（`ApplyToGroupReq`），支持自定义验证消息。
* **实时红点**: 联动 `ChatEventProcessor`，当管理员收到 `group_apply_new` 信令时，触发 `ChatGroup` 状态机执行 `handleNewJoinRequest`，实现资料页“申请列表”入口红点的毫秒级同步。
* **审批闭环**: 封装 `GroupRequestListPage`，管理员执行 `accept/reject` 后，通过 `ref.invalidate` 触发 Riverpod 数据流自愈。申请人同步收到 `group_apply_result` 信令，实现“审核中 -> 成员房”的无缝切换。


* **[Database] 事务一致性守卫 (Transaction Guard)** **[NEW]**:
* **冲突防御**: 攻克了用户“退群后再申请”导致的 Prisma `Unique constraint failed` (groupId, applicantId, status) 报错。
* **原子操作**: 在 `handleJoinRequest` 事务内实施“先清理、后更新”策略。在变更状态前，通过 `deleteMany` 强制抹除该用户在该群的历史冗余记录，确保审批逻辑的**幂等性**。
* **健壮入群**: 使用 `upsert` 替代 `create` 插入 `ChatMember`，彻底消灭并发操作下的数据库死锁与主键冲突。


* **[RBAC] 轻量级权限矩阵 (Authority Matrix)**:
* **核心**: 基于 `OWNER` (群主)、`ADMIN` (管理员)、`MEMBER` (成员) 的三级权限体系。
* **后端**: 在 `ChatGroupService` 建立 `_checkPermission` 守卫，所有写操作（踢人、禁言、改名等）执行强制角色校验。
* **前端**: 扩展 `ChatMember` 模型，引入 `canManage` 权限判断逻辑，通过 `group_profile_logic.dart` 动态驱动 UI 菜单的显示与隐藏。


* **[Control] 即时管控武器库 (Group Toolkit)**:
* **禁言系统**: 支持单人定时禁言 (`mutedUntil`) 与全员禁言 (`isMuteAll`)。通过 Socket 实时同步令受限用户的输入框瞬间置灰。
* **成员管控**: 实现踢人 (`kick`)、转让群主 (`transferOwner`)、升降管理员 (`setAdmin`) 等核心指令。
* **审批流**: 引入 `joinNeedApproval` 准入开关，为后续高级社群治理机制夯实协议基础。


* **[Interact] 信息流转体系 (Information Flow)**:
* **通用选人组件**: 封装 `ContactSelectionPage` 与 `ContactSelectionArgs`，实现“联系人+群组”合并展示与 Tab 切换，支持单选/多选/排除模式。
* **消息转发闭环**: 实现消息长按转发流程。核心逻辑确保在转发过程中完整保留原消息的 `meta` 属性（如媒体宽高比、原作者 ID），实现文本/媒体消息的无损多目标分发。
* **序列化协议**: 引入 `extra_codec.dart` 与 `BaseRouteArgs`，通过 `GoRouter` 的 `extraCodec` 机制实现了复杂对象的自动化序列化，彻底解决 Web 端刷新导致路由参数丢失 (`null`) 的警告与 Bug。


* **[Sync] 复杂事件处理器 (Event Processor)**:
* **逻辑**: 前端 `ChatEventProcessor` 实现了对 `member_kicked`、`group_disbanded` 等信令事件的全局监听。
* **自愈**: 收到被踢事件后，自动执行“本地库清理 -> 刷新会话列表 -> 强制退房跳转”的一站式自愈流程。


* **[Defense] 极端竞态防御 (Race Condition Defense)**:
* **现象**: 攻克了用户被踢瞬间，因系统消息 (`type 99`) 触发已读上报，而此时权限已丢失导致的 403 `Bad Response` 报错。
* **拦截器**: 在 `ChatEventHandler._onSocketMessage` 引入系统消息过滤，拒绝让通知类消息触发已读防抖流。
* **逻辑锁**: `markAsRead` 发起网络请求前强制调用 `getConversation` 检查会话是否已被删除，并在 `catch` 块中通过 `_isDisposed` 静默忽略销毁期间的错误。
* **UI 碰撞防御**: 使用 `addPostFrameCallback` 结合键盘 `unfocus` 逻辑进行路由跳转，彻底消灭了并发信令下的 `Assertion failed` 渲染崩溃。



---

## 🏆 第一章：极致视觉与黄金参数 (The Visual Revolution) **[v5.3.2 - v5.3.3]**

*本章攻克了移动端最难的“图片列表性能”与“网络物理延迟”，并通过黄金参数实现了原生级体验。*

* **[Tuning] 黄金参数调优 (The Golden Parameters)** **[NEW - v5.3.3]**:
* **Preload Window**: **15** (经济适用值)。从激进的 30 降级为 15，平衡带宽与预热效果，拒绝无效流量。
* **Item Height**: **300.0** (物理修正值)。修正默认 150.0 导致的索引估算偏差，彻底消灭“预加载漏图”。
* **Look-Back**: **15** (回看缓冲)。`startIndex = index - 15`，宁可多算，不可漏算。
* **LoadMore Threshold**: **2000** (无感阈值)。将触发线从 500 提至 2000，实现真正的无限流滚动。
* **[Image] 视觉欺骗架构 (Visual Deception Architecture)** **[NEW - v5.3.2]**:
* **核心**: 承认网络延迟，利用本地数据补偿视觉。
* **实现**: `AppCachedImage` 引入 **Stack 物理堆叠**。底层渲染 `previewBytes` (数据库缩略图)，顶层渲染网络高清图。
* **效果**: 无论断网或弱网，用户永远看不到白屏或 Loading，只能看到“由糊变清”的无缝过程。
* **[Align] 参数指纹对齐 (Parameter Alignment)** **[NEW - v5.3.2]**:
* **方案**: **Bucketing (阶梯化)** 与 **DPR 锁死**。
* **实现**: `RemoteUrlBuilder` 强制锁死 `DPR=3.0`，并将宽度归一化为 `240/480`。确保 UI 层与 Preloader 层生成的 Cache Key **100% 字节级一致**。
* **[Time] NTP 高精时间校准 (Chronos Sync)** **[NEW - v5.3.3]**:
* **核心**: App 启动及网络恢复时，自动与服务端对时 (`ServerTimeHelper`)。
* **价值**: 所有逻辑基于统一的服务端时间轴，彻底解决手机系统时间不准导致的消息乱序。

---

## 🥈 第二章：全局一致性与状态感知 (Consistency Era) **[v5.3.0 - v5.3.1]**

*本章标志着 App 从“单机体验”走向“系统级融合”，彻底解决了分布式系统最难的数据对齐问题。*

* **[Zero-State] 双重自愈防线 (Double Self-Healing)** **[NEW - v5.3.1]**:
* **痛点**: 解决多端登录、重装应用或后台长期挂起后，消息内容已同步但列表仍显示“幽灵红点”的顽疾。
* **第一道防线 (Global List Sync)**: 列表页启动时强制执行 `ConversationList._fetchList`，利用 **Server Truth** (服务端状态) 强行覆盖本地旧数据，实现“未进房先消红”。
* **第二道防线 (Nuclear Option)**: 房间页 `performIncrementalSync` 引入 **核弹级清零** (`forceClearUnread`)。当服务端返回 `unread=0` 但本地 `unread>0` 时，无条件强制抹平本地红点，并静默修正消息状态。
* **[Guard] 智能 API 拦截系统 (Smart Gatekeeper)** **[NEW - v5.3.1]**:
* **核心**: 在 `ChatRoomController` 建立门卫机制 (`checkAndMarkRead`)。
* **逻辑**: 进房或切回前台时，先查询本地 `Repo`。只有本地确实有未读 (`unread > 0`) 时才发起 API 请求。
* **清除内鬼**: 彻底移除了 `ChatEventHandler` 初始化时无脑调用 `markAsRead` 的冗余代码，杜绝了进房瞬间的无效流量和重复请求。
* **[Unread] 全局未读数聚合 (Global Aggregation)** **[v5.3.0]**:
* **核心逻辑**: 建立 `GlobalUnreadProvider`，利用 Sembast/Isar 的 `query.onSnapshots` 实时监听 `conversations` 表。
* **实现**: `stream.map((list) => list.fold(0, (sum, item) => sum + item.unreadCount))`，实现全 App 未读数毫秒级响应，直接驱动底部导航栏红点。
* **[Badge] 系统级角标闭环 (System Badge Loop)** **[v5.3.0]**:
* **核心逻辑**: 在数据持久层 `LocalDatabaseService` 深度集成 `flutter_app_badger`。
* **实现**: 打通 FCM 后台唤醒、前台消息接收、用户手动已读的全链路。只要未读数发生变化，立即同步至手机桌面图标，支持 Android (小米/三星/华为) 及 iOS。
* **[Read] 实时已读回执 (Real-time Receipts)** **[v5.3.0]**:
* **核心逻辑**: `ChatEventHandler` 实现了 **500ms 防抖 (Debounce)** 的已读上报机制。
* **实现**: 配合 `didChangeAppLifecycleState`，当用户进入房间或从后台切回前台时，自动触发状态对齐，极大降低 API 调用频率。

---

## 🥉 第三章：高可靠流水线与数据防御 (Reliability Era) **[Core Architecture]**

*本章是 Lucky IM 的“心脏”，也是代码中最硬核的部分，确保消息必达、数据不丢。*

* **[Arch] 仓库模式重构 (Repository Pattern)** **[NEW - v5.3.1]**:
* **动作**: 创建 `MessageRepository`，收口所有 DB 写操作。
* **价值**: 将 `ChatViewModel` 与底层 DB 解耦，确保所有数据写入都经过统一的防御逻辑检查，防止业务层直接操作 DB 导致的数据污染。
* **[Defense] 数据库合并防御 (Data Defense Strategy)** **[Core - v5.3.0]**:
* **核心**: **本地高清资产优先原则**。
* **实现**: `LocalDatabaseService._mergeMessageData`。
* **细节**: 当服务端回包（Sync）时，如果服务端仅返回 URL（通常是压缩图），本地逻辑会**强制保留**发送时的 `localPath` (高清原图) 和 `previewBytes` (内存快照)。**这确保了发送者永远看到最清晰的图片，0 延迟，0 流量消耗**。
* **[Engine] 五级跳发送管道 (The 5-Step Pipeline)** **[v5.3.0]**:
* **架构**: 摒弃 UI 耦合，构建 `PipelineRunner`。
* **流程**: **Parse (解析)** -> **Persist (持久化)** -> **Process (压缩/截帧)** -> **Upload (上传)** -> **Sync (Socket同步)**。
* **价值**: 任意环节失败均可独立重试，互不阻塞，且每一步都自动回写 DB 状态。
* **[Sync] 增量同步自愈 (Incremental Self-Healing)** **[v5.3.0]**:
* **算法**: `ChatViewModel` 实现基于 `localMaxSeqId` 的空洞检测。
* **自愈**: 发现本地 SeqId 不连续时，自动递归拉取中间缺失的消息 (`_recursiveSyncGap`)，确保消息流绝对完整。
* **[Retry] 离线自动重发 (Offline Auto-Retry)** **[v5.3.0]**:
* **实现**: `OfflineQueueManager` 监听 `Connectivity`。网络恢复瞬间，自动冲刷失败队列。

---

## 🏅 第四章：全能媒体与零感交互 (Media Era) **[v5.3.1]**

*本章攻克了 IM 最复杂的媒体处理与跨平台兼容性，实现了“如丝般顺滑”的体验。*

* **[Streaming] 全链路流式缓冲 (Streaming Buffer)** **[NEW - v5.3.1]**:
* **客户端**: `VideoPlaybackService` 显式添加 `httpHeaders: {'Range': 'bytes=0-'}`，激活播放器的分片下载能力。
* **服务端**: Nginx 配置 `proxy_force_ranges on` 及 `proxy_buffering off`，并透传 CORS/SNI 头，完美支持 Cloudflare/S3 的流式回源。
* **效果**: 500MB 大视频点击即播 (Instant Play)，支持任意拖拽进度条，无需等待全量下载。
* **[Cache] 三级播放策略 (Triple-Level Caching)** **[NEW - v5.3.1]**:
* **逻辑**: `getPlayableSource` 依次检查 **内存快照 -> 本地 Asset 文件 -> 网络 URL**。
* **价值**: 本机发送的视频直接读文件，实现 **0 延迟** 播放。
* **[Path] 跨平台路径归一化 (Path Normalization)** **[v5.3.0]**:
* **痛点**: iOS App 更新后沙盒 UUID 变更，导致数据库里的绝对路径失效。
* **方案**: 数据库只存“业务相对路径”（如 `chat_images/xxx.jpg`）。
* **实现**: `AssetManager.getRuntimePath()` 在运行时动态将相对路径拼接为当前沙盒的绝对路径。`VideoMsgBubble` 和 `VoiceBubble` 已全面接入。
* **[UX] 零延时大图预览 (Zero-Latency Preview)** **[v5.3.0]**:
* **核心**: **Cache Key 指纹对齐**。
* **实现**: `PhotoPreviewPage` 强制复用列表页 `AppCachedImage` 的 URL 和 Headers。配合 `metadata` (宽高) 预撑开容器，实现点开大图 **0ms 加载**，无任何视觉抖动或黑屏。
* **[Web] 物理级环境隔离 (Environment Isolation)** **[v5.3.0]**:
* **视频**: Web 端使用 HTML5 `Canvas` 截取首帧 (`web_video_thumbnail_service.dart`)，Native 端使用 FFmpeg。
* **文件**: Web 端使用 `Blob URL` (`save_poster_web.dart`)，Native 端使用 `File` 和相册 API。
* **录音**: Web 端屏蔽浏览器右键菜单 (`voice_record_button_web_utils`)，实现了纯净的录音体验。
* **清理**: 实现了 `_clearDeadBlobs`，在 Web 端启动时自动清理失效的 Blob 链接。

---

## 💎 第五章：后端解耦与触达 (Backend Era) **[v5.2.1]**

* **[Arch] 事件驱动架构**: 引入 `@nestjs/event-emitter`，将 `ChatService` 纯粹化，彻底移除对 Socket 和 FCM 服务的直接依赖。
* **[DTO] 状态对齐协议** **[NEW - v5.3.1]**: 升级 DTO，在会话详情接口增加 `unreadCount`, `myLastReadSeqId` 等关键字段，为前端自愈提供弹药。
* **[FCM] 全平台离线触达**: 打通 Android (High Importance Channel) 与 Web (Service Worker) 推送，实施数据冗余策略（Data Redundancy）防止通知内容丢失。

---

## 🛡️ 第六章：社交基建与性能优化 (Foundation Era) **[v4.0 - v5.0]**

* **[Social] 拼音搜索引擎**: `ContactRepository` 集成 `lpinyin`，构建本地倒排索引，支持毫秒级通讯录搜索。
* **[Perf] 接口风暴止血**: 移除 `ConversationItem` 对 `chatDetailProvider` 的错误监听，列表页请求数从 N+1 降为 1。
* **[UI] 现代化输入框**: `ModernChatInputBar` 实现键盘/表情面板无缝切换，集成 `ChatActionSheet` 配置化菜单。
* **[LBS] 地图服务**: Web 端优化 `LocationMsgBubble`，使用 `AutomaticKeepAliveClientMixin` 缓存地图快照，解决滚动闪烁问题。

---

## 🛡️ 架构铁律 (The Iron Rules - v6.0.0)

*这是项目的最高准则，任何代码提交不得违反。*

1. **数据类型严谨原则 [NEW]**: 后端 API 返回的时间戳必须统一转换为 `number` (毫秒)，严禁在 DTO 中直接返回 `Date` 对象，以防前端 Dart 模型解析发生 `String` 与 `num` 的类型崩溃。
2. **审批幂等原则 [NEW]**: 所有涉及状态变更（如审批入群）的后端逻辑必须在单次事务中先清理潜在冲突记录，严禁假设数据库状态始终干净。
3. **UI 状态同步原则 [NEW]**: 所有的红点计数与状态变更（如 `isPending`）必须收口于 `ChatGroup` Provider。禁止在 UI 层维护独立的临时计数器，确保“单一信源”。
4. **权限权威原则**: 所有涉及群组变更的操作必须经过后端 `_checkPermission` 与前端 `canManage` 校验。
5. **异步拦截原则**: 所有的 Handler 与 Controller 必须包含 `_isDisposed` 状态检查，严禁在页面销毁后执行异步回调，必须显式调用 `ref.keepAlive()` 保证异步过程存活。
6. **系统消息免报原则**: 类型为 `99` 的系统通知严禁触发已读上报（`markAsRead`），规避权限丢失引发的 403 竞态冲突。
7. **路由参数安全原则**: 复杂对象传递必须实现 `BaseRouteArgs` 并注册 `extraCodec`，防止 Web 端状态丢失。
8. **路径相对化原则**: 数据库持久化严禁存储绝对路径，必须通过 `AssetManager` 运行时还原。
9. **数据防御原则**: `merge` 操作必须优先保留本地的高清资产路径，严禁被服务端空值覆盖。
10. **单向数据流**: UI 只读 DB，Pipeline/Repo 负责写 DB。禁止 UI 直接渲染 API 返回的数据。
11. **服务端权威原则**: 当服务端返回 `unread=0` 时，本地必须无条件强制清零。
12. **指纹对齐原则**: 跨页面复用媒体缓存，URL 和 Headers 必须字符级匹配。
13. **视觉兜底原则**: 图片加载必须使用 `Stack` 垫片，严禁白屏。
14. **时间统一原则**: 所有逻辑判断必须使用 `ServerTimeHelper.now()`。
15. **Web 环境隔离**: 非 `kIsWeb` 保护下，严禁调用 `dart:io`。

---

