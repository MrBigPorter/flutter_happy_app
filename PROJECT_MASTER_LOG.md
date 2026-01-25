

# 🏛️ Lucky IM Project Master Log v3.0 (The "Clean Empire" Edition)

> **🔴 状态校准 (2026-01-25 22:50)**
> **里程碑达成：资源管理大一统 & 架构最终解耦**
> 在攻克全链路闭环的基础上，我们完成了 **AssetManager 重构**。现在，UI层、逻辑层、网络层不再关心“文件在哪里”或“由于什么平台”，所有 IO 操作收敛至单一真理来源。架构达到了 **高内聚、低耦合** 的标准。
> **🟢 当前版本：v3.0 (Stable & Clean)**

---

## 1. 🛡️ 架构铁律 (The Iron Rules - 10 Commandments)

> **这是我们的底线，任何后续开发严禁触犯。**

1. **ID 唯一性**: 前端生成 UUID，后端透传，绝不依赖后端 ID。
2. **UI 零抖动**: 严禁删旧插新，必须使用 `update` 操作，利用内存缓存 (`_sessionPathCache`) 确保发送瞬间 UI 静止。
3. **单向数据流**: UI 只听 DB，用户交互只改 DB，严禁 UI 直接操作内存列表。
4. **消息幂等性**: 同一 ID 只处理一次，防止重复渲染。
5. **存储相对化 (AssetManager)**: **(关键)** 数据库仅存**纯文件名** (e.g. `uuid.jpg`)。所有路径拼接、沙盒变动处理、Web/App 差异判断，**必须**调用 `AssetManager`，严禁业务层自己拼路径。
6. **本地字段保护**: `saveMessage` 必须执行 `Read -> Merge -> Write`。严格保护本地生成的 `previewBytes` 和 `localPath` 不被 Socket 回包清洗。
7. **Web 依赖锁死**: `pubspec.yaml` 锁定 `idb_shim: ^2.6.0`。
8. **极速预览优先**: `MemoryBytes` (微缩图) > `LocalFile` (本地高清) > `Network` (CDN)。
9. **Web 录音适配**: Web 点击切换 vs Mobile 长按；播放前由 `AssetManager` 清洗协议头。
10. **资源单一出口**: 所有涉及文件存取的操作，禁止直接引用 `dart:io` 或 `path_provider`，必须通过 `AssetManager` 接口。

---

## 2. 🗺️ 代码地图 (Code Map)

### A. 基础设施层 (Infrastructure) - **[NEW]**

* **`asset_manager.dart` (大管家)**: 策略层。负责业务分流 (Audio/Image)，管理文件名生成，对外提供统一 API (`save`, `getFullPath`)。
* **`asset_store.dart` (底层实现)**: 物理层。
* **Mobile**: 处理 `ApplicationDocumentsDirectory`，实现物理文件的 `copy`/`write`。
* **Web**: 处理 `Blob` 协议，实现 Pass-through。



### B. 数据层 (Database) - `local_database_service.dart`

* **Smart Merge**: 智能合并逻辑，是 `AssetManager` 的坚实后盾，确保文件名 (`localPath`) 永不丢失。

### C. 聊天室控制层 (Controller) - `chat_room_controller.dart`

* **极简发送**: 删除了臃肿的路径处理代码。
* **流程**: `AssetManager.save()` -> 拿到文件名 -> 存库 -> `AssetManager.getFullPath()` -> 上传。

### D. 离线队列 (Queue) - `offline_queue_manager.dart`

* **机制**: 此时不论是断网还是重启，Queue 只需拿着文件名问 `AssetManager` 要路径即可，逻辑极其干净。
* **自愈**: 网络恢复/App 前台双重触发。

### E. UI 展示层 (UI) - `chat_bubble.dart`

* **盲盒渲染**: UI 不知道自己跑在 Web 还是 App，也不知道图片在哪。它只负责调用 `AssetManager.getFullPath()`，拿到什么显示什么。

---

## 3. 🏆 全量战果清单 (The Trophy Case)

#### 🥇 [架构] 统一资源管理 (Unified Asset Management) **[NEW]**

* **攻克**: 引入 `AssetManager` + `AssetStore` (策略模式)。
* **战果**: 彻底解耦了 UI、逻辑和网络层。以后修改存储策略（如换目录、换云存储），只需修改 1 个文件，业务代码零改动。

#### 🥈 [核心] 语音/图片消息的“永久居住证”

* **攻克**: 发送时物理搬运至持久化目录，DB 仅存 UUID 文件名。
* **修复**: 配合 AssetManager，彻底解决了 iOS 沙盒路径变动导致图片失效的问题。

#### 🥉 [核心] 离线重发系统的“自我修复”

* **攻克**: `OfflineQueueManager` 实现了完美的生命周期管理，配合 `AssetManager` 动态寻址，保证重启 App 后依然能找到文件并重发。

#### 🏅 [体验] 极致压缩与秒开

* **攻克**: Web Canvas + Mobile Isolate 双端压缩。利用 `previewBytes` 实现列表页图片 0 等待加载。

#### 🏅 [体验] 列表红点与置顶

* **攻克**: `activeConversationId` 互斥锁 + `updateLocalItem` 实时置顶。

---

## 4. ✅ 已完结功能 (Checklist)

* [x] **[P0] 语音消息全链路** (录音/播放/转码/持久化)。
* [x] **[P0] 断网重发系统** (队列/生命周期/失败标记)。
* [x] **[P0] 统一资源管理 AssetManager** (架构解耦/Web兼容/路径清洗)。
* [x] **[P1] 跨平台极致压缩** (Isolate + Canvas)。
* [x] **[P1] 会话列表状态对齐** (红点互斥/发送置顶)。
* [x] **Web 端微缩图持久化** (IndexedDB Blob 兼容)。
* [x] **UI 层路径逻辑重构** (ChatBubble 移除 IO 代码)。
* [x] **图片气泡自适应** (Meta 宽高计算)。