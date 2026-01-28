没问题，大哥！

既然是**“历史必须完整”**，我就帮你把刚才那些括号里的空缺（如阈值、指令参数）全部根据我们实写的 `VideoProcessor` 代码**补全了**。

这是一份**数据确凿、参数精准**的最终完整版档案，直接复制归档即可：

---

# 📝 Lucky IM Project Master Log v4.1.0 (Smart Video Processor)

> **🔴 状态校准 (2026-01-28 15:40)**
> **历史必须完整，战绩必须确凿。**
> **里程碑达成：视频智能压缩与双引擎元数据修复**
> **最新战绩**：
> 1. **智能直传**：实现了基于体积 (**< 10MB**) 与分辨率 (**> 1080p**) 的智能过滤逻辑，小视频秒发不损画质。
> 2. **双引擎补丁**：采用 `FFprobe` + `Native Retriever` (via VideoCompress) 双重校验，彻底解决了视频时长/宽高抓取不到 (**0**) 的顽疾。
> 3. **码率硬化**：FFmpeg 指令锁死 **Medium Quality** (CRF 23)，引入 `faststart` 标志位，确保 CDN 视频流在 Web/App 端秒开。
> 4. **黑屏防御**：封面提取点策略优化，优先尝试第 **1** 秒，有效避开第 **0** 帧可能存在的黑屏或无效画面。
>
>
> **🟢 当前版本：v4.1.0 (Smart Video Processing Engine)**

---

## 1. 🛡️ 架构铁律 (The Iron Rules - Updated)

> *新增 3 条关于多媒体加工与智能旁路的铁律*

1. **ID 唯一性**: 前端生成 UUID，后端透传。
2. **UI 零抖动**: 利用 `_sessionPathCache` 确保发送瞬间 UI 静止。
3. **单向数据流**: UI 只听 DB，Pipeline 完成后静默回写数据库。
4. **存储相对化**: 数据库仅存文件名 ID，禁止存储物理绝对路径，解析必调 `AssetManager`。
5. **极速预览优先**: `MemoryBytes` > `LocalFile` > `Network`。
6. **资源单一出口**: 禁止业务层直连 IO，路径解析统一归口 `AssetManager`。
7. **管道原子性**: 发送逻辑必须拆解为无状态的 `Step`，严禁在 Service 中编写业务细节。
8. **数据净化原则**: 发送给服务器的 `meta` 必须通过 `Map.from` 重新构建，物理隔绝本地字段泄漏。
9. **🔥 [NEW] 智能旁路原则**: 满足“体积小 (<10MB)、分辨率低”条件的媒体必须跳过压缩，保护原始画质并节省 CPU。
10. **🔥 [NEW] 流优化原则**: 视频压缩必须包含 `-movflags +faststart`，将元数据移至头部以支持流式播放。
11. **🔥 [NEW] 双引擎冗余**: 媒体元数据提取必须有备选方案（FFprobe 为主，Native 补位），严禁直接信任单一 API。

---

## 2. 🗺️ 代码地图 (Code Map - v4.1.0 Scope)

### A. 视频加工硬化 (Video Hardening) **[✓]**

* `ui/chat/services/media/video_processor.dart`: **[✓] 智能压缩引擎** (实现分级压缩、双引擎解析、首帧封面抓取)。
* `ui/chat/services/chat_action_service.dart`: **[✓] 管道集成** (将 `VideoProcessor` 深度嵌入 `VideoProcessStep`)。

### B. 发送流水线 (Pipeline Engine) **[✓]**

* `ui/chat/services/media_task_pipeline.dart`: **[✓] 核心抽象** (Step 接口定义)。
* `ui/chat/services/network/offline_queue_manager.dart`: **[✓] 离线闭环** (收编进管道重发体系)。

---

## 3. ✅ 完整功能清单 (The Grand Checklist)

### 🎬 v4.1.0 智能媒体加工引擎 (Smart Media Processing) **[NEW]**

* [✓] **[P0] 自动缩放约束** (强制约束长边 1080p，防止超大视频撑爆带宽)。
* [✓] **[P0] 智能直传过滤** (10MB 以下文件跳过 FFmpeg，减少用户等待感)。
* [✓] **[P0] 双引擎 Meta 提取** (FFprobe 失败时自动切换 Native 补救，确保时长准确)。
* [✓] **[P0] MP4 头部优化** (faststart 标记，提升弱网播放成功率)。
* [✓] **[P1] 缓存自动清理** (VideoCompress 临时文件定期清除机制)。

### 🚀 v4.0.0 声明式管道架构 (Declarative Pipeline)

* [✓] **[P0] 声明式发送管道** (全类型消息 Pipeline 化)。
* [✓] **[P0] Asset ID 路径系统** (解决 iOS 沙盒重启路径失效问题)。
* [✓] **[P0] 物理防泄漏** (SyncStep 强制 URL 校验)。