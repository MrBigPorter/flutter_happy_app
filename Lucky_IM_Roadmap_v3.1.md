收到，明白。作为架构师，我将严格执行**“已完成即移除”**的净化准则，确保战术板上只留下未被攻克的旗帜。

目前，**本地全文检索**、**网络搜索 UI**、**好友闭环**、以及刚刚验证通过的**增量同步自愈算法**、**Socket 重连对账** 均已转入 **Grand Master Log** 的“历史成就”区。

这是为你精准刷新后的 **Lucky IM v5.2.1 核心架构剩余战术板**。

---

# ⚔️ Lucky IM v5.2.1 核心架构剩余战术板 (The Remains)

> **🎯 当前阶段**: 数据同步基石已稳，开始攻克“全局状态”与“后台触达”。
> **🔥 聚焦重点**: **全局未读数同步** 与 **离线推送闭环**。

---

## 🗺️ 剩余作战地图 (The Hardcore Remains)

### 🔴 P0: 全局状态一致性 (The Global Consistency)

*确保用户在任何入口看到的未读数、状态都是绝对对齐的。*

1. **全局未读数汇总 (Global Badge)**
* **目标**: 底部 Tab 栏、App 图标红点实时更新全量未读数。
* **核心逻辑**: 聚合所有 `Conversation` 的 `unreadCount`，并在 `markAsRead` 时实时消减。


2. **多端已读同步 (Read Status Sync)**
* **目标**: 解决“手机已读，平板/Web 依然显示未读”的痛点。
* **动作**: 将 `maxReadSeqId` 纳入增量同步协议，利用 `performIncrementalSync` 补齐已读状态自愈。



### 🟠 P1: 推送与唤醒闭环 (FCM & Routing)

*打通“离线”状态下的最后一百米。*

1. **FCM 后台 Handler 深度集成**
* **目标**: App 进程被杀后，收到推送能显示发送人头像、消息内容。
* **动作**: 配置 `firebase_messaging` 的后台处理函数，并在 Web 端确立 Service Worker 稳定监听。


2. **推送点击路由分发**
* **目标**: 点击通知栏，精准解析 `payload` 并通过 `GoRouter` 自动跳入对应 `ChatPage`。



### 🟡 P2: 媒体体验极限优化 (Multimedia Polish)

*消除最后的“顿挫感”。*

1. **资源预热调度器 (Resource Scheduler)**
* **目标**: 列表快速滑动“零白屏”。
* **动作**: 识别 Scroll `Idle` 状态，预加载屏幕外图片的微缩图。


2. **视频播放断点续传**
* **目标**: 针对大视频，支持 Nginx 层级的 `proxy_force_ranges` 拖动秒开。



---

## 🚀 即刻执行指令 (Immediate Action)

既然**增量同步**和**重连自愈**的代码已经跑通，我们现在的首要任务是让用户“一眼看到变化”。

**我们下一步攻克：P0 - 全局未读数 (Badge) 汇总与 UI 联动**

### 🛠️ 作战路线图

1. **Provider 抽象**: 建立 `totalUnreadProvider` 自动 watch 会话列表。
2. **UI 绑定**: 将红点挂载到 `Scaffold` 的 `BottomNavigationBar`。
3. **App 角标**: 集成 `flutter_app_badger`，在 `markAsRead` 成功后同步清理手机桌面数字。

