
# 📜 Lucky IM Project **Grand Master Log** (v4.0 - v5.3.0)

> **🕒 最后更新**: 2026-02-08 18:30 (PST)
> **🚀 当前版本**: **v5.3.0 (Infrastructure Complete)**
> **🌟 总体进度**: **全栈基建封顶**。已构建起一套具备高可靠消息流水线、全能媒体处理能力、以及跨平台（Web/Native）全局状态一致性的生产级 IM 架构。

---

## 🏆 第一章：全局一致性与状态感知 (Consistency Era) **[NEW - v5.3.0]**

*本章标志着 App 从“单机体验”走向“系统级融合”。*

* **[Unread] 全局未读数聚合**:
* **核心逻辑**: 建立 `GlobalUnreadProvider`，利用 Sembast/Isar 的 `query.onSnapshots` 实时监听 `conversations` 表。
* **实现**: `stream.map((list) => list.fold(0, (sum, item) => sum + item.unreadCount))`，实现全 App 未读数毫秒级响应，直接驱动底部导航栏红点。


* **[Badge] 系统级角标闭环**:
* **核心逻辑**: 在数据持久层 `LocalDatabaseService` 深度集成 `flutter_app_badger`。
* **实现**: 无论是前台收到消息、后台 FCM 唤醒、还是用户手动标记已读，只要未读数发生变化，立即同步至手机桌面图标，支持 Android (小米/三星/华为) 及 iOS。


* **[Read] 实时已读回执**:
* **核心逻辑**: `ChatEventHandler` 实现了 **500ms 防抖 (Debounce)** 的已读上报机制。
* **实现**: 配合 `didChangeAppLifecycleState`，当用户进入房间或从后台切回前台时，自动触发状态对齐，极大降低 API 调用频率。



---

## 🥈 第二章：高可靠流水线与数据防御 (Reliability Era) **[Core Architecture]**

*本章是 Lucky IM 的“心脏”，也是代码中最硬核的部分。*

* **[Engine] 五级跳发送管道 (The 5-Step Pipeline)**:
* **架构**: 摒弃 UI 耦合，构建 `PipelineRunner`。
* **流程**: **Parse (解析)** -> **Persist (持久化)** -> **Process (压缩/截帧)** -> **Upload (上传)** -> **Sync (Socket同步)**。
* **价值**: 任意环节失败均可独立重试，互不阻塞，且每一步都自动回写 DB 状态。


* **[Data] 数据库合并防御 (Data Defense Strategy)**:
* **核心**: **本地高清资产优先原则**。
* **实现**: `LocalDatabaseService._mergeMessageData`。
* **细节**: 当服务器回包（Sync）时，如果服务器返回的是压缩后的 URL，本地逻辑会**强制保留**发送时的 `localPath` (高清原图) 和 `previewBytes` (内存快照)。**这确保了发送者永远看到最清晰的图片，而不是服务器压缩后的糊图**。


* **[Sync] 增量同步自愈**:
* **算法**: `ChatViewModel` 实现基于 `localMaxSeqId` 的空洞检测。
* **自愈**: 发现本地 SeqId 不连续时，自动递归拉取中间缺失的消息，确保消息流绝对完整。


* **[Retry] 离线自动重发**:
* **实现**: `OfflineQueueManager` 监听 `Connectivity`。网络恢复瞬间，自动冲刷失败队列。



---

## 🥉 第三章：全能媒体与零感交互 (Media Era) **[v5.3.0]**

*本章攻克了 IM 最复杂的媒体处理与跨平台兼容性。*

* **[Path] 跨平台路径归一化 (Path Normalization)**:
* **痛点**: iOS App 更新后沙盒 UUID 变更，导致数据库里的绝对路径失效。
* **方案**: 数据库只存“业务相对路径”（如 `chat_images/xxx.jpg`）。
* **实现**: `AssetManager.getRuntimePath()` 在运行时动态将相对路径拼接为当前沙盒的绝对路径。`VideoMsgBubble` 和 `VoiceBubble` 已全面接入。


* **[UX] 零延时大图预览 (Zero-Latency)**:
* **核心**: **Cache Key 指纹对齐**。
* **实现**: `PhotoPreviewPage` 强制复用列表页 `AppCachedImage` 的 URL 和 Headers。配合 `metadata` (宽高) 预撑开容器，实现点开大图 **0ms 加载**，无任何视觉抖动或黑屏。


* **[Web] 物理级环境隔离**:
* **视频**: Web 端使用 HTML5 `Canvas` 截取首帧 (`web_video_thumbnail_service.dart`)，Native 端使用 FFmpeg。
* **文件**: Web 端使用 `Blob URL` (`save_poster_web.dart`)，Native 端使用 `File` 和相册 API。
* **录音**: Web 端屏蔽浏览器右键菜单 (`voice_record_button_web_utils`)，实现了纯净的录音体验。



---

## 🏅 第四章：后端解耦与触达 (Backend Era) **[v5.2.1]**

* **[Arch] 事件驱动架构**: 引入 `@nestjs/event-emitter`，将 `ChatService` 纯粹化，彻底移除对 Socket 和 FCM 服务的直接依赖。
* **[FCM] 全平台离线触达**: 打通 Android (High Importance Channel) 与 Web (Service Worker) 推送，实施数据冗余策略（Data Redundancy）防止通知内容丢失。

---

## 💎 第五章：社交基建与性能优化 (Foundation Era) **[v4.0 - v5.0]**

* **[Social] 拼音搜索引擎**: `ContactRepository` 集成 `lpinyin`，构建本地倒排索引，支持毫秒级通讯录搜索。
* **[Perf] 接口风暴止血**: 移除 `ConversationItem` 对 `chatDetailProvider` 的错误监听，列表页请求数从 N+1 降为 1。
* **[UI] 现代化输入框**: `ModernChatInputBar` 实现键盘/表情面板无缝切换，集成 `ChatActionSheet` 配置化菜单。
* **[LBS] 地图服务**: Web 端优化 `LocationMsgBubble`，使用 `AutomaticKeepAliveClientMixin` 缓存地图快照，解决滚动闪烁问题。

---

## 🛡️ 架构铁律 (The Iron Rules - v5.3.0)

*这是项目的最高准则，任何代码提交不得违反。*

1. **路径相对化原则**: 数据库持久化**严禁存储绝对路径**，必须通过 `AssetManager` 在运行时动态还原。
2. **数据防御原则 (Data Defense)**: `merge` 操作必须**优先保留本地**的 `localPath` (高清) 和 `previewBytes` (内存快照)，严禁被服务端空值覆盖。
3. **单向数据流**: UI **只读 DB**，Pipeline/Network **负责写 DB**。禁止 UI 直接渲染 API 返回的数据。
4. **指纹对齐原则**: 跨页面复用媒体缓存，`ImageProvider` 的 URL 和 Headers 必须字符级匹配。
5. **Web 环境隔离**: 非 `kIsWeb` 保护下，**严禁调用 `dart:io**`。
6. **异步对账原则**: `StateNotifier` 初始化时严禁同步修改其他 Provider，必须使用 `Future.microtask`。

---

# ⚔️ Lucky IM v5.3.1 核心架构剩余战术板 (The Final Frontier)

> **🎯 目标**: 解决 **“数据冷对齐”** 与 **“体验精修”**。

## 🗺️ 剩余作战地图

### 🔴 P0: 状态冷对齐 (Cold State Alignment)

*解决“换手机或重装后，已读状态不同步”的最后漏洞*

1. **已读状态增量自愈**
* **现状**: 目前增量同步 (`performIncrementalSync`) 仅拉取消息，不更新会话的已读游标。
* **动作**:
* 在同步结束时，比对服务端返回的 `lastReadSeqId` 与本地 DB 的值。
* 若服务端 > 本地，**静默执行本地 MarkAsRead** (只改库，不上报)。





### 🟡 P1: 资源预热调度器 (Resource Scheduler)

*解决“快速滑动列表时的白屏”*

1. **滚动感知预加载**
* **动作**: 封装 `ScrollAwarePreloader`。
* **逻辑**: 监听 `ScrollNotification`，当 `velocity` 归零或极低时，预加载屏幕下方 2000px 范围内的图片/视频封面。



### 🔵 P2: 视频流式缓冲 (Streaming Buffer)

*解决“大视频点击播放慢”*

1. **HTTP Range 支持**
* **动作**: 在 `VideoPlaybackService` 中，为网络视频源添加 `httpHeaders: {'Range': 'bytes=0-'}`，配合 Nginx `proxy_force_ranges` 实现边下边播。


