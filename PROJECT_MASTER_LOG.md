
📜 Lucky IM Project Grand Master Log (v4.0 - v6.3.0)
🛡️ 第九章：VoIP 极限防御与全端互通 (The VoIP Defense Era) [v6.2.0 - CURRENT]
本章标志着 Lucky IM 彻底打穿了移动端碎片化的物理壁垒。我们在极端恶劣的系统环境（锁屏死锁、硬件残废、信令风暴、IPC 截断、网络真空穿透）下，成功建立了一套坚不可摧的工业级音视频抗打盾牌。

[Keep-Alive] 锁屏破壁与系统提权 (Lock-Screen Wakeup):

机制: 彻底重构了 Android 的弹窗唤醒逻辑。将 AndroidManifest.xml 的启动模式修正为 launchMode="singleInstance"，配合物理级权限（悬浮窗、允许后台活动），成功突破了国产安卓（华为/小米等）严苛的锁屏/后台封杀，实现 100% 亮屏弹窗。

[Signal] 信令防抖与并发仲裁 (Signal Arbitrator):

竞态防御: 解决了 FCM（保活通道）与 Socket（极速通道）同时到达导致的“信令影分身”与 UI 暴击问题。

实现: 引入全局单例 CallArbitrator，基于 Session ID 建立 3.5 秒的全局防抖锁（Global Cooldown）。同一通电话绝对不接管第二次，成功拦截所有并发垃圾信令。

[NEW] 诈尸误杀防御: 攻克了“旧电话挂断延迟秒杀新电话”的并发时序错乱。在挂断逻辑 (hangUp) 与发起逻辑中强制核对 SessionID，名字对不上直接将旧系统信号踢飞，形成防误杀护盾。

[Hardware] 硬件预热死锁规避 (Hardware Warm-up Defense):

修复坑点: 攻克了华为/荣耀手机锁屏接听瞬间抢夺摄像头引发的 CameraAccessException (-38) 崩溃黑屏惨案。

双端分治: 实施时序平台分流。iOS 保持极速拉起；Android 端在 acceptCall 中强制引入 1000ms 延迟，等待屏幕唤醒与底层硬件通电解封后，再安全挂载摄像头。

[Codec] 硬件编码降级与 SDP 伪装 (SDP Munging):

修复坑点: 攻克了国内老旧机型（华为）H.264 硬件视频编码器等级极低（Level 1 限制），导致发送 720P 画面时底层崩溃、疯狂报 mapFormat: no mediaType information 及绿屏/黑屏的问题。

核武操作: 实施底层的 SDP 偷梁换柱 (_forceVP8)。截获 Offer/Answer，在发往网络前用 replaceAll 强行禁用 H.264，逼迫双端底层回退到极其稳定的 VP8 软件编码器；同时本地 setLocalDescription 喂入原味 SDP 以防本地引擎解析崩溃。

[NEW] 安卓解码器假死电击疗法 (Codec Defibrillator): 彻底根治了 Android 退后台再回前台导致的画面永久冻结假死。通过深度监听 AppLifecycleState.resumed，触发“物理起搏器”：先置空 srcObject 再重新赋值，并瞬间拨动视频轨 enabled 开关，强迫系统级硬件解码器重启并重新请求关键帧。

[Memory] IPC 截断防御机制 (IPC Truncation Defense):

修复坑点: 攻克了“接通后 1 秒离奇自动挂断”的世纪大坑。安卓系统原生层在通过 Intent Extras 向 Flutter 传递呼叫数据时，会因数据过大而强制丢弃巨型 SDP 文本，导致状态机拿到空数据引发防御性挂断。

实现: 建立“内存级保险箱”。在信令刚到达 CallDispatcher 时，直接将完整的 CallEvent 存入 Dart 静态内存 (currentInvite)。用户接听时优先从内存提取 SDP，彻底绕开 Android 原生 IPC 通信的物理大小限制！

[Render] 画板自愈机制与时序阻断 (Renderer Self-Healing & Timing):

修复坑点: 修复了主叫方（startCall）因忘记初始化 RTCVideoRenderer 导致有数据无画面的黑屏问题。

实现: 在 _initLocalMedia 获取摄像头时引入自愈护盾：检测到画板为 null 时当场执行 initialize()。

[NEW] Web 端双向失明防御: 彻底治愈了 Flutter Web 端接通必黑屏的绝症。强制在 acceptCall 阶段 await Future.wait([local.initialize(), remote.initialize()])，必须等待 HTML 底层 <video> 物理坑位挂载完毕，再让状态机放行视频流注入，达成 0ms 时序差。

[WebRTC] 无缝网络重连与防撞车 (ICE Restart & Glare Conflict):

[NEW] 唯一重连指挥官: 攻克了 4G/WiFi 切换时，双端同时发送 Offer 导致的 have-local-offer 信令暴毙崩溃。 确立了强制规矩：仅允许主叫方 (_isCaller) 主动发起 ICE Restart，被叫方无权主动发 Offer 仅能回传 Answer。

[NEW] 伪装信令拦截器: 挫败了 FCM 推送通道/后端自作聪明的“信令背刺”。在 onIncomingInvite 中精准拦截带有 isRenegotiation 标志且 Session 一致的假 Invite 信令，当场解包转化为 Answer 回传，防止重连简历被当成垃圾丢弃。

[NEW] 真空期防御与智能解锁: 解决了断网瞬间收集“无网废弃 IP”导致永久卡死的盲区。通过 Socket 监听器建立 2 秒缓冲：死等新网卡彻底握手成功再收集 IP；同时监听 disconnect 瞬间砸碎防抖锁，确保错失的信令能无限次重试直到隧道打通。

[NEW] 底层 C++ 方言强制唤醒: 攻克了 flutter_webrtc 在 Android 端忽视 iceRestart: true 指令的历史遗留 Bug。采用上古约束格式 optional: [{'IceRestart': true}] 强行命令 C++ 引擎收集新网络 IP。

🎥 第八章：实时音视频与跨端融合 (The RTC Era) [v6.1.0]
[RTC] 全栈实时引擎 (Full-Stack RTC Core):

核心: 基于 flutter_webrtc 构建点对点 (P2P) 通话链路。

配置: 集成 Google STUN 服务 (stun.l.google.com) 实现内网穿透。部署 Node.js 后端与 RackNerd TURN 服务，配合 9527_mima 动态凭证体系，确保 4G/5G 跨网穿透成功率。

策略: 实现了 音频优先 策略。语音模式默认使用听筒 (Earpiece)，视频模式默认使用扬声器 (Speaker)，并支持通话中动态切换 (Helper.setSpeakerphoneOn)。

[Signal] 高一致性信令 (Robust Signaling):

协议: 定义了标准的 SDP 交换流程 (Offer -> Answer)。

竞态防御: 攻克了 ICE Candidate 提前到达 导致的连接失败问题。在 CallController 引入 _iceCandidateQueue，当远端描述 (RemoteDescription) 尚未设置时，自动缓存 ICE 候选者，待 SDP 就绪后自动冲刷 (_flushIceCandidateQueue)，确保 0 丢包。

闭环: 实现了 CallInvite, CallAccept, CallEnd 的完整状态机闭环，支持异常挂断检测。

[UX] 悬浮窗与画中画 (Overlay & PiP):

架构: 采用 OverlayEntry 实现全局悬浮窗 (CallOverlay)，脱离页面栈限制。

交互: 支持全屏/小窗无缝切换。本地视频小窗支持边界限制拖拽 (Draggable + clamp)，防止拖出屏幕。

自愈: 悬浮窗通过 ref.listen 独立监听通话状态，一旦检测到 CallStatus.ended，自动执行自我销毁，防止“幽灵窗口”。

[Platform] 跨平台防御体系 (Platform Defense):

Crash 修复: 彻底解决了 flutter_background 插件在 iOS/Web 端引发的 MissingPluginException。

实现: 在 _enableBackgroundMode 与 hangUp 中引入 kIsWeb || Platform.isIOS 守卫，实施物理级代码隔离。

资源销毁: 建立了严格的 dispose 流程。挂断时按照 Timer -> Socket监听 -> Overlay -> Stream Tracks -> PeerConnection -> Renderer 的顺序销毁，杜绝内存泄漏与摄像头占用。

[Infra] iOS 原生保活 (iOS Keep-Alive):

配置: 修正了 Xcode 工程配置，启用 Background Modes (Audio + VoIP)。

机制: 通过 AVAudioSession 激活系统级通话状态，确保 App 在后台或锁屏状态下 Socket 不断连、麦克风不静音。

## 👑 第七章：权力治理与信息流转 (Governance & Flow) **[v6.0.0]**

*本章标志着 Lucky IM 具备了工业级社群管控能力。通过引入实时审批流与严格的事务守卫，解决了复杂社交场景下的权限自愈与数据并发冲突问题。*

* **[Governance] 入群审批系统 (Join Request System)**:
* **准入受控**: 引入 `joinNeedApproval` 开关。开启后，非群成员加入须提交申请（`ApplyToGroupReq`），支持自定义验证消息。
* **实时红点**: 联动 `ChatEventProcessor`，当管理员收到 `group_apply_new` 信令时，触发 `ChatGroup` 状态机执行 `handleNewJoinRequest`，实现资料页“申请列表”入口红点的毫秒级同步。
* **审批闭环**: 封装 `GroupRequestListPage`，管理员执行 `accept/reject` 后，通过 `ref.invalidate` 触发 Riverpod 数据流自愈。申请人同步收到 `group_apply_result` 信令，实现“审核中 -> 成员房”的无缝切换。


* **[Database] 事务一致性守卫 (Transaction Guard)**:
* **冲突防御**: 攻克了用户“退群后再申请”导致的 Prisma `Unique constraint failed` (groupId, applicantId, status) 报错。
* **原子操作**: 在 `handleJoinRequest` 事务内实施“先清理、后更新”策略。在变更状态前，通过 `deleteMany` 强制抹除该用户在该群的历史冗余记录，确保审批逻辑的**幂等性**。
* **健壮入群**: 使用 `upsert` 替代 `create` 插入 `ChatMember`，彻底消灭并发操作下的数据库死锁与主键冲突。


* **[Social Polish] 群组社交化增强 (Social Enhancements)**:
* **群二维码 (Group QR)**: 基于 `qr_flutter` 实现群名片生成。采用 `Stack` 分层渲染技术（底层二维码+顶层 Logo），彻底解决了网络图片加载慢导致的白屏问题，实现“秒开”体验。
* **Web 兼容分享**: 封装 `MediaExporter`，在 Web 端自动将“分享”降级为“下载”，并强制指定 `mimeType: image/png` 以通过浏览器安全校验。解决 Canvas 跨域（Tainted Canvas）问题，确保 Web 端二维码生成零报错。
* **成员本地搜索**: 在群成员列表（`GroupProfilePage`）植入本地搜索引擎，利用内存过滤（`List.where`）实现千人大群成员的毫秒级检索，0 网络开销。


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

* **[Tuning] 黄金参数调优 (The Golden Parameters)**:
* **Preload Window**: **15** (经济适用值)。
* **Item Height**: **300.0** (物理修正值)。
* **Look-Back**: **15** (回看缓冲)。
* **LoadMore Threshold**: **2000** (无感阈值)。


* **[Image] 视觉欺骗架构 (Visual Deception Architecture)**:
* **核心**: 承认网络延迟，利用本地数据补偿视觉。`AppCachedImage` 引入 **Stack 物理堆叠**。


* **[Align] 参数指纹对齐 (Parameter Alignment)**:
* **方案**: `RemoteUrlBuilder` 强制锁死 `DPR=3.0`，并将宽度归一化为 `240/480`。


* **[Time] NTP 高精时间校准 (Chronos Sync)**:
* **核心**: App 启动及网络恢复时，自动与服务端对时 (`ServerTimeHelper`)。



---

## 🥈 第二章：全局一致性与状态感知 (Consistency Era) **[v5.3.0 - v5.3.1]**

* **[Zero-State] 双重自愈防线 (Double Self-Healing)**:
* **Global List Sync**: 列表页启动时强制执行 `ConversationList._fetchList`。
* **Nuclear Option**: 房间页引入 **核弹级清零** (`forceClearUnread`)。


* **[Guard] 智能 API 拦截系统 (Smart Gatekeeper)**:
* **核心**: 在 `ChatRoomController` 建立门卫机制，彻底移除了 `ChatEventHandler` 无脑调用 `markAsRead` 的冗余。


* **[Unread] 全局未读数聚合**: `GlobalUnreadProvider` 实时监听 DB。
* **[Badge] 系统级角标闭环**: 集成 `flutter_app_badger`。
* **[Read] 实时已读回执**: 实现了 **500ms 防抖 (Debounce)** 的已读上报机制。

---

## 🥉 第三章：高可靠流水线与数据防御 (Reliability Era) **[Core Architecture]**

* **[Arch] 仓库模式重构**: 创建 `MessageRepository`，收口所有 DB 写操作。
* **[Defense] 数据库合并防御**: **本地高清资产优先原则**。当服务端回包 Sync 时，强制保留发送时的 `localPath` 和 `previewBytes`。
* **[Engine] 五级跳发送管道**: Parse -> Persist -> Process -> Upload -> Sync。
* **[Sync] 增量同步自愈**: `_recursiveSyncGap` 实现空洞检测与补齐。
* **[Retry] 离线自动重发**: 网络恢复瞬间自动冲刷失败队列。

---

## 🏅 第四章：全能媒体与零感交互 (Media Era) **[v5.3.1]**

* **[Streaming] 全链路流式缓冲**: 客户端 Range 头 + Nginx 代理配置，实现大视频点击即播。
* **[Cache] 三级播放策略**: 内存 -> 本地 Asset -> 网络 URL。
* **[Path] 跨平台路径归一化**: 数据库只存相对路径，运行时动态拼接沙盒绝对路径。
* **[UX] 零延时大图预览**: Cache Key 指纹对齐，实现点开大图 0ms 加载。
* **[Web] 物理级环境隔离**: Web 端使用 Canvas 截帧、Blob URL 文件处理、右键菜单屏蔽，并自动清理死链 Blob。

---

## 💎 第五章：后端解耦与触达 (Backend Era) **[v5.2.1]**

* **[Arch] 事件驱动架构**: 引入 `@nestjs/event-emitter`。
* **[DTO] 状态对齐协议**: 接口增加 `unreadCount`, `myLastReadSeqId`。
* **[FCM] 全平台离线触达**: 打通 Android (High Importance) 与 Web (Service Worker)。

---

## 🛡️ 第六章：社交基建与性能优化 (Foundation Era) **[v4.0 - v5.0]**

* **[Social] 拼音搜索引擎**: 集成 `lpinyin`。
* **[Perf] 接口风暴止血**: 列表页请求数 N+1 降为 1。
* **[UI] 现代化输入框**: `ModernChatInputBar`。
* **[LBS] 地图服务**: Web 端优化地图快照缓存。

---

## 🛡️ 架构铁律 (The Iron Rules - v6.2.0)

*这是项目的最高准则，任何代码提交不得违反。*

数据类型严谨原则: 后端 API 返回的时间戳必须统一转换为 number (毫秒)，严禁在 DTO 中直接返回 Date 对象。

审批幂等原则: 涉及状态变更的后端逻辑必须在单次事务中先清理潜在冲突记录。

UI 状态同步原则: 所有的红点计数与状态变更必须收口于 ChatGroup Provider，禁止 UI 层维护独立计数器。

Web 分享安全原则: Web 端处理图片分享时，必须确保 mimeType 正确，并对跨域图片采取隐藏或降级策略。

权限权威原则: 所有群组变更操作必须经过后端 _checkPermission 与前端 canManage 校验。

异步拦截原则: 所有 Handler/Controller 必须包含 _isDisposed 检查，严禁页面销毁后执行异步回调。

系统消息免报原则: 类型为 99 的系统通知严禁触发已读上报 (markAsRead)。

路由参数安全原则: 复杂对象传递必须实现 BaseRouteArgs 并注册 extraCodec。

路径相对化原则: 数据库持久化严禁存储绝对路径，必须通过 AssetManager 运行时还原。

数据防御原则: merge 操作必须优先保留本地的高清资产路径。

单向数据流: UI 只读 DB，Pipeline/Repo 负责写 DB。

服务端权威原则: 当服务端返回 unread=0 时，本地必须无条件强制清零。

指纹对齐原则: 跨页面复用媒体缓存，URL 和 Headers 必须字符级匹配。

视觉兜底原则: 图片加载必须使用 Stack 垫片，严禁白屏。

时间统一原则: 所有逻辑判断必须使用 ServerTimeHelper.now()。

Web 环境隔离: 非 kIsWeb 保护下，严禁调用 dart:io。

插件隔离原则: 任何涉及原生能力的插件（如 flutter_background），必须使用 defaultTargetPlatform 或 kIsWeb 进行平台判定，严禁在不支持的平台上执行初始化代码。

ICE 缓存原则: WebRTC 信令处理中，严禁在 SetRemoteDescription 完成前直接添加 ICE Candidate，必须使用队列缓存机制，防止信令时序错乱导致黑屏。

资源释放原则: 视频通话结束时，必须显式调用 MediaStreamTrack.stop() 并置空 srcObject，严禁仅依赖 Garbage Collection，防止摄像头/麦克风指示灯残留。

跨进程大对象免疫原则 (IPC Payload Immunity): 严禁依赖移动端原生层（如 Intent Extras）传递超大文本（如 WebRTC SDP），必须在 Dart 内存层建立单例缓存（如 CallDispatcher.currentInvite）进行拦截与读取，防止系统级截断导致核心数据丢失。

硬件编码降级原则 (Codec Fallback): 面对国内深度定制安卓机（如华为/荣耀）底层的硬件编码器残废陷阱，必须实施 SDP 偷梁换柱（SDP Munging），将发送给远端的配置强制回退至 VP8 软解，但本地 setLocalDescription 必须喂入原味 SDP 以防本地引擎崩溃。

硬件预热规避原则 (Hardware Warm-up): 安卓端在锁屏被 CallKit 唤醒接听时，严禁同步瞬间抢夺摄像头（防 -38 驱动崩溃），必须给予 1 秒以上的硬件通电解封延迟，且 WebRTC 的 createAnswer 必须在摄像头成功获取画面之后执行。

[NEW] 重协商唯一指挥官原则 (Renegotiation Commander): 物理网络切换触发 ICE Restart 时，严禁双端同时发起 Offer (防 have-local-offer 崩溃)。全局状态机必须强制校验 _isCaller，唯有主叫方拥有重连发起权，被叫方仅允许回应 Answer。

[NEW] 解码器物理唤醒原则 (Codec Defibrillator): 针对移动端 OS 杀后台策略，生命周期恢复 AppLifecycleState.resumed 时，严禁信任原生渲染管线。必须强制对 srcObject 实施“剥离再挂载”以及轨道的 enabled 瞬断重启，解决解码器永冻假死。

[NEW] DOM 就绪阻断原则 (DOM Readiness Blocking): WebRTC 的 initialize() 严禁作为非阻塞异步处理。向渲染器挂载流之前，必须通过 await Future.wait 强制等待双端画板底层物理节点（如 Web <video>）构建完毕，防秒接黑屏。

[NEW] 底层 C++ 强校验约定 (C++ Engine Dialect): 调用 WebRTC 底层命令时严禁轻信高层语法糖。Android 端的 createOffer 强制重连时，必须回退使用老式字典约束 optional: [{'IceRestart': true}]，否则将被 C++ 核心静默抛弃，导致空收集。则 (Hardware Warm-up)**: 安卓端在锁屏被 CallKit 唤醒接听时，严禁同步瞬间抢夺摄像头（防 -38 驱动崩溃），必须给予 1 秒以上的硬件通电解封延迟，且 WebRTC 的 `createAnswer` 必须在摄像头成功获取画面之后执行。