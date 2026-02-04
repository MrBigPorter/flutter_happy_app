收到。既然 **FCM 离线触达（含后台 Handler 与路由分发）** 已经在 v5.2.1 战役中彻底闭环，我将它们从战术板上**永久移除**。

现在的战场非常干净，主力部队将全部压上，攻克 **全局一致性** 这一高地。

这是为你精准刷新后的 **Lucky IM v5.2.2 核心架构剩余战术板**。

---

# ⚔️ Lucky IM v5.2.2 核心架构剩余战术板 (The Remains)

> **🎯 当前阶段**: 消息进得来（Socket/FCM），存得下（DB），现在要解决 **“看没看”** 和 **“剩多少”** 的问题。
> **🔥 聚焦重点**: **全局未读数管理 (Global Badge)** 与 **多端已读同步自愈**。

---

## 🗺️ 剩余作战地图 (The Hardcore Remains)

### 🔴 P0: 全局状态一致性 (The Global Consistency)

*解决“消息已读但红点不消”的最后一公里。*

1. **全局未读数聚合 (Global In-App Badge)**
* **目标**: 底部导航栏 "消息" Tab、系统设置页等位置实时显示总未读数。
* **现状**: 目前仅 `ConversationList` 内部自知，缺乏全局状态管理器。
* **动作**: 建立 `GlobalUnreadProvider`，监听数据库变更流，实时聚合所有会话的 `unreadCount`。


2. **桌面角标同步 (App Icon Badge)**
* **目标**: App 即使在后台，桌面图标也能显示未读数字（类似微信/WhatsApp）。
* **动作**: 集成 `flutter_app_badger`，在 `GlobalUnreadProvider` 变化时同步更新原生系统角标；处理 Android 厂商（小米/华为/三星）的兼容性。


3. **多端已读同步自愈 (Read Status Self-Healing)**
* **目标**: 解决“手机 A 点了已读，手机 B 还要点一次”的痛点。
* **动作**:
* **后端**: 确保 `MarkAsRead` 操作更新 `Conversation.lastReadSeqId` 并下发 Event。
* **前端**: 将 `MarkAsRead` 事件纳入 **增量同步 (Incremental Sync)** 范畴，重连时不仅补消息，还要补“已读状态”。





### 🟡 P1: 媒体体验精修 (Multimedia Polish)

*消除列表滑动的最后一点“顿挫感”。*

1. **资源预热调度器 (Resource Scheduler)**
* **目标**: 列表快速滑动“零白屏”。
* **动作**: 识别 Scroll `Idle` 状态，预加载屏幕外图片的微缩图（利用 `precacheImage`）。


2. **视频播放断点续传**
* **目标**: 针对大视频，支持拖动秒开。
* **动作**: 客户端播放器配置 Range Header，配合后端 Nginx `proxy_force_ranges` 实现分段缓冲。



---

## 🚀 即刻执行指令 (Immediate Action)

FCM 已经搞定，现在 App 能收到消息了，但用户不知道自己有几条未读，体验很割裂。

**我们立刻攻克：P0 - 全局未读数聚合 (Global Badge)**

### 🛠️ 作战路线图

1. **基础设施**: 创建 `lib/core/providers/global_unread_provider.dart`。
2. **数据库层**: 编写 Isar 聚合查询语句 `db.conversations.where().unreadCountProperty().sum()`。
3. **UI 绑定**: 修改 `MainPage` 的 `BottomNavigationBar`，挂载红点组件。

**请确认：我们是先做 Flutter 端的 Provider 聚合，还是先做 App Icon Badge？（建议合并一起做）**