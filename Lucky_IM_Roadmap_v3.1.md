

---

# 🚦 Lucky IM v4.0 核心执行全图 (Roadmap)

> **当前状态**：声明式消息管道 (Pipeline) 已焊死，逻辑链路已闭环。
> **下一阶段**：打硬仗（视频优化），扩地盘（文件/位置）。

---

## 1. 🚨 [P0] 核心战役：视频硬化 (Video Hardening)

**目标**：解决大文件 OOM、弱网失败、画质糊的问题。

### 🛠️ [P0-1] 智能加工逻辑 (Smart Video Processing)

* **按需压缩**：
* `> 1080p` 或 `> 24fps`：强制降级到 1080p/24fps，平衡体积。
* `Bitrate > 5Mbps`：强制压至 2-3Mbps（移动端黄金码率）。
* `< 10MB` 且符合标准：**跳过压缩**，直接进入 `UploadStep`，保留原生画质。


* **熔断机制**：在 `VideoProcessStep` 头部增加校验，禁止处理超过 500MB 的原始视频，弹出“文件过大”提示。

### 🛠️ [P0-2] 进度感官对齐 (Progress Synchronization)

* **双段进度**：修改 `PipelineContext` 增加 `progress` 字段。
* 0% - 30%：压缩进度。
* 30% - 100%：上传进度。


* **UI 映射**：消息气泡展示这个“合并进度”，解决“压缩时转圈没进度，上传时进度跳变”的感官 Bug。

---

## 2. 📂 [P1] 功能扩张：新消息类型 (New Feature Set)

**目标**：利用现有 Pipeline 框架，快速复刻成熟 IM 的功能。

### 🚧 [P1-1] 全能菜单 (Action Sheet / Plus Menu)

* **Grid 入口**：点击 `+` 弹出 4x2 的功能矩阵。
* **集成功能**：相册、拍照、视频、文件、地理位置。
* **动画逻辑**：底部滑出，支持主题换色。

### 🚧 [P1-2] 文件消息管道 (File Message Pipeline)

* **元数据提取**：引入 `file_picker`，提取文件名、后缀、物理大小。
* **管道重用**：
* `FilePersistStep`：文件落地到 `AssetManager` 的 `chat_files` 目录。
* `SyncStep`：meta 中存入文件后缀，UI 根据后缀（PDF/DOC/ZIP）渲染对应图标。


* **交互**：点击触发系统自带预览或 `open_file` 插件。

### 🚧 [P1-3] 位置消息 (Location Snapshot)

* **静态模式**：集成地图 SDK，发送时截取当前位置的静态图。
* **Sync 逻辑**：meta 记录 `lat`、`lng` 和 `address`。
* **跳转**：点击气泡弹出系统底层菜单，调用百度/高德/Google Map 进行导航。

---

## 3. ⚡ [P2] 性能进阶：极致流畅度 (Optimization)

**目标**：列表滚动不掉帧，头像秒开。

### 🛠️ 组合头像持久化 (Group Avatar Caching)

* **逻辑**：目前的九宫格头像是 Canvas 实时画的。改为画完后通过 `toByteData` 保存为本地 PNG 文件。
* **缓存策略**：数据库记录 `avatar_local_path`。
* **收益**：群聊列表滚动时，由“实时计算”变为“静态图加载”，性能提升 300%。


### 第一阶段：硬化与生存 (Hardening & Stability)

**优先级：P0 | 目标：解决 OOM 崩溃与进度反馈。**

| 任务模块 | 核心改动点 | 预期收益 |
| --- | --- | --- |
| **1.1 全局串行锁** | 在 `VideoProcessor` 增加 `Completer` 锁，确保多视频连发时**按顺序压缩**。 | 彻底杜绝多 FFmpeg 并发导致的内存溢出 (OOM) 闪退。 |
| **1.2 进度加权同步** | 修改 `PipelineContext` 引入进度流，按  比例合并**压缩进度**与**上传进度**。 | UI 气泡显示“压缩中...20%”等真实进度，消除用户焦虑。 |
| **1.3 熔断机制** | 入口拦截  视频，增加异常捕获回滚 `localPath`。 | 保护系统资源，防止无效任务霸占管道。 |

---

### 第二阶段：性能与丝滑 (Performance & Experience)

**优先级：P1 | 目标：消除长列表滑动掉帧，降低渲染开销。**

| 任务模块 | 核心改动点 | 预期收益 |
| --- | --- | --- |
| **2.1 内存降准解码** | 封装 `getCacheWidth` 工具，根据屏占比在 `Image.file` 层级强制执行**降采样**。 | 内存占用降低 ，低端机滑动不再卡死。 |
| **2.2 路径同步化** | 在数据加载层（Provider）实现 **Path Pre-warming**，将 Asset ID 同步转为路径 Map。 | 废弃气泡内的 `FutureBuilder`，实现列表 60FPS 满帧滚动。 |
| **2.3 硬件重绘隔离** | 为媒体气泡（视频/图片）包裹 `RepaintBoundary`。 | 视频播放或进度更新时，不会带动整个列表重绘，极大降低 CPU 功耗。 |

---

### 第三阶段：功能扩张 (Feature Expansion)

**优先级：P1 | 目标：补齐 IM 基础入口，支持文件与位置。**

| 任务模块 | 核心改动点 | 预期收益 |
| --- | --- | --- |
| **3.1 全能菜单 (Plus)** | 编写仿微信的  分页 Grid 菜单组件。 | 统一相册、文件、视频、位置的所有入口。 |
| **3.2 文件消息管道** | 扩展 `Pipeline`：`FilePicker ➡️ Persist ➡️ Upload ➡️ Sync`。 | 支持 PDF/DOC/ZIP 分发，UI 自动匹配后缀图标。 |
| **3.3 位置消息快照** | 集成地图静态图 API，利用管道发送 `lat/lng` 坐标。 | 补齐地理位置分享功能，支持唤起系统导航。 |

---

### 第四阶段：资产闭环 (Resource Lifecycle)

**优先级：P2 | 目标：收发对称，媒体离线化。**

* **下载管道 (Download Pipeline)**：为收到的媒体消息建立镜像流水线。
* **资产落地**：收到视频自动静默下载到 `AssetManager`，更新 `localPath`。
* **收益**：收到的视频也能断网播放，且二次观看零流量。




**如果你同意这份计划，我们接下来的第一步就是：**

1. 重构 `VideoProcessor` 加上 `_currentTask` 锁。
2. 给 `ImageMsgBubble` 加上 `cacheWidth` 降采样和 `RepaintBoundary`。

