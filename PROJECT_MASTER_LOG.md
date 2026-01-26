
---

# 📝 Lucky IM Project Master Log v3.5 (Corrected)

> **🔴 状态校准 (2026-01-27 01:20)**
> **里程碑达成：多媒体生态 & 深度交互闭环**
> **治理只能记录完成的历史，不写下一步，每次给你，历史都必须完整的给我。
> 这是一个 **全功能 (Feature-Rich)** 版本，覆盖了现代 IM 的核心铁三角：**通讯 (Group/Chat) + 图片媒体 (Image Media) + 交互 (Interaction)。**
> **🟢 当前版本：v3.5 (Image & Interaction Focus)**

---

## 1. 🛡️ 架构铁律 (The Iron Rules - 13 Commandments)

1. **ID 唯一性**: 前端生成 UUID，后端透传。
2. **UI 零抖动**: 利用 `_sessionPathCache` 确保发送瞬间 UI 静止。
3. **单向数据流**: UI 只听 DB。
4. **消息幂等性**: 同一 ID 只处理一次。
5. **存储相对化**: 数据库仅存文件名，必调 `AssetManager`。
6. **本地字段保护**: `saveMessage` 必须 `Merge`。
7. **Web 依赖锁死**: `idb_shim: ^2.6.0`。
8. **极速预览优先**: `MemoryBytes` > `LocalFile` > `Network`。
9. **资源单一出口**: 禁止业务层直连 IO。
10. **UI/逻辑分离**: 状态下沉 `Core`，业务留 `Feature`。
11. **异步标准化**: 列表状态必须 `when(loading/error/data)`。
12. **桥接原则**: 通讯录发起必须走 `Bridge API`。
13. **交互承诺**: 耗时弹窗必须返回 `Future`，由组件接管 Loading。

---

## 2. 🗺️ 代码地图 (Code Map - v3.5 Scope)

### A. 核心交互 (Interaction) **[✓]**

* `ui/chat/widgets/chat_bubble.dart`: **[✓] 长按手势识别**。
* `ui/chat/widgets/chat_popup_menu.dart`: **[✓] 气泡菜单** (Copy/Delete/Recall)。
* `ui/chat/controllers/message_action_controller.dart`: **[✓] 消息操作逻辑** (API调用 + 本地库更新)。

### B. 多媒体引擎 (Media Engine) **[✓]**

* `common/media/asset_manager.dart`: **[✓] 统一资源管理**。
* `common/media/compressor.dart`: **[✓] 智能压缩** (图片分级压缩)。
* `ui/chat/widgets/upload_progress.dart`: **[✓] 环形进度条**。
* `common/permission/permission_handler.dart`: **[✓] 相册/相机权限收口**。

### C. 群组与异步 (Group & Async) **[✓]**

* `ui/modal/radix_modal.dart`: **[✓] 异步自动 Loading**。
* `ui/chat/providers/conversation_provider.dart`: **[✓] 200条预加载**。
* `ui/chat/pages/group_profile_page.dart`: **[✓] 完整群管理**。

---

## 3. ✅ 完整功能清单 (The Grand Checklist)

### 📸 v3.5 多媒体消息 (Image Only)

* [✓] **[P0] 图片发送** (相册选取 / 预览)。
* [✓] **[P0] 智能压缩** (根据网络环境自动压缩体积)。
* [✓] **[P0] 上传进度条** (实时各种状态反馈)。
* [✓] **[P0] 权限管理** (Android/iOS 相册权限动态申请)。

### 👆 v3.5 消息交互 (Interaction)

* [✓] **[P0] 长按弹出菜单** (位置自适应)。
* [✓] **[P0] 消息撤回 (Recall)** (双端同步撤回状态 / "Re-edit" 功能)。
* [✓] **[P0] 消息删除 (Delete)** (本地删除 / 数据库同步)。
* [✓] **[P0] 文本复制 (Copy)** (剪贴板操作)。

### 👥 v3.4 群管理闭环 (Group)

* [✓] **[P0] 群邀请 (Invite)** (UI/API 闭环)。
* [✓] **[P0] 退群 (Leave)** (异步 Modal 自动交互)。
* [✓] **[P0] 建群流程** (选人 -> 命名 -> 跳转)。

### 🚀 v3.2 极致体验 (UX)

* [✓] **[P0] 列表页骨架屏** (Skeleton)。
* [✓] **[P0] 200条大容量预加载** (AsyncNotifier)。
* [✓] **[P0] 异步状态标准化** (Ref.watch.when)。

### 🧱 v3.0 基础建设 (Infra)

* [✓] **[P0] 统一资源管理 AssetManager**。
* [✓] **[P0] 语音消息全链路**。
* [✓] **[P0] 断网重发系统**。
* [✓] **[P0] 发送失败红色感叹号**。

---

