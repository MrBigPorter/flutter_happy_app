
---

#  Lucky IM Project Master Plan v4.5 (Velocity Flow)

> **🔴 状态校准 (2026-01-29)**
> **已完成 (Removed from list)**：
> * ✅ 视频上传 MimeType 修复 (iOS 兼容)
> * ✅ 视频气泡本地优先策略 (秒开)
> * ✅ 视频封面双缓冲渲染 (去黑屏)
>
>
> **当前核心战略**：
> **UI 层的“点”已经修好，现在进攻数据层的“面”。**
> 全力拿下 **P0 双核任务**，让列表支持 10 万条消息也能 120Hz 丝滑滚动。

---

## 👑 第一梯队：性能双核 (The P0 Core)

**目标**：**彻底重构列表数据流，实现“无限丝滑”的滚动体验。**

| 优先级 | ID | 任务模块 | 核心技术方案 | 解决痛点 |
| --- | --- | --- | --- | --- |
| **P0** | **2.3 & 2.4** | **智能分页与预热**<br>

<br>(Smart Pagination & Pre-warming) | **二合一超级任务**：<br>

<br>1. **无感预取 (Pre-fetch)**：<br>

<br>   - **DB 层**：改造 `watchMessages`，使用 `Sembast` 的 `limit: 50` + `offset` 分页读取。<br>

<br>   - **UI 层**：监听 `ScrollController`，在距顶部 **500px** 时静默触发加载上一页。<br>

<br>2. **同步预热 (Pre-warm)**：<br>

<br>   - **Service 层**：建立中间层 `PrewarmService`。<br>

<br>   - 在数据进入 UI 队列前，批量完成 `AssetId -> 绝对路径` 的解析。<br>

<br>   - 将结果填入 `ChatUiModel.readyPath`，确保气泡组件 **0 计算、0 IO**。 | **✅ 解决：**<br>

<br>1. 进大群卡死 (内存溢出)<br>

<br>2. 滚动到底部顿挫 (Loading)<br>

<br>3. 快速滑动掉帧 (UI 线程 IO) |

---

## 🏗️ 第二梯队：架构补全 (Infrastructure)

**目标**：**构建可扩展的“收发闭环”。**

| 优先级 | ID | 任务模块 | 核心技术方案 |
| --- | --- | --- | --- |
| **P1** | **3.1** | **全能菜单架构**<br>

<br>(Plus Menu Grid) | **组件化重构**。<br>

<br>废弃硬编码菜单，封装可配置的 `ActionSheet` 接口。将图片、视频、拍摄拆分为独立模块，预留 File/Location 插槽。 |
| **P1** | **4.1** | **自动下载管道**<br>

<br>(Download Pipeline) | **收发对称设计**。<br>

<br>建立 `DownloadManager`，接收到媒体消息时，根据网络状态（WiFi/4G）自动加入下载队列。实现“点开即看”，无需等待 Loading。 |

---

## ⚔️ 第三梯队：业务扩张 (Business Features)

**目标**：**对标主流 IM 核心功能。**

| 优先级 | ID | 任务模块 | 说明 |
| --- | --- | --- | --- |
| **P2** | **3.2** | **文件消息** | 扩展 Pipeline 支持 `FilePicker`，识别 PDF/DOC/ZIP/APK 后缀并匹配对应图标，支持进度条显示。 |
| **P2** | **3.3** | **位置消息** | 集成地图 SDK 截图接口，发送静态快照与经纬度，点击唤起第三方导航。 |

---

## 🧹 第四梯队：锦上添花 (Final Polish)

| 优先级 | ID | 任务模块 | 说明 |
| --- | --- | --- | --- |
| **P3** | **4.2** | **头像持久化** | 将实时计算的群聊九宫格头像 (`CustomPainter`) 转为 PNG 本地缓存，减少 GPU 绘图压力。 |

---

