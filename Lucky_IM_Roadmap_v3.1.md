没问题，大哥！完全按照你的格式，把 **建群 UI** 标记为**未完成 ([P0])**，其他保持不动。

这是修正后的 **v3.1+ 路线图**：

---

# 🚦 Lucky IM Roadmap & Next Steps (v3.1+)

> **当前阶段**：v3.1 (UX & Group Foundation) 气泡适配已完成。
> **核心目标**：**补全建群 UI** 与 **群聊数据联调**。

---

## 1. 🔥 v3.1 剩余冲刺 (Remaining Priorities)

UI 壳子尚未完成，需要先搭页面，再注入灵魂。

### [P0] 建群交互 UI (Group Creation UI) 👈 **NEXT**

**现状**：缺少选人页面，点击菜单目前无反应或报错。

* [ ] **选人页面**: 实现 `GroupMemberSelectPage`，包含好友列表多选交互。
* [ ] **路由挂载**: 在 `ConversationListPage` 菜单中实现正确跳转。
* [ ] **弹窗逻辑**: 选人完成后，弹出输入群名的 Dialog。

### [P1] 群聊业务闭环 (Group Chat Data & Logic)

**现状**：等待 UI 壳子完成后，对接真实数据。

* [ ] **好友列表数据源**: 实现 `contactProvider`，从后端拉取真实好友列表，替换选人页的 Mock 数据。
* [ ] **建群 API 联调**: 在 `GroupMemberSelectPage` 点击创建时，将选中的 `memberIds` 传给后端 `createGroup` 接口。
* [ ] **群头像逻辑**:
* **基础**: 实现默认群头像展示。
* **进阶**: 实现“九宫格”合成头像逻辑（取群内前 4-9 人头像拼合）。



### [P2] 会话列表细节 (List Polish)

**现状**：发送失败虽然气泡有红点，但退回到列表页后看不出哪条失败了。

* [ ] **列表失败标记**: `ConversationItem` 需要支持 `MessageStatus.failed` 状态，显示红色小图标或文字提示。

---

## 2. 🚀 v3.2 中期规划 (Rich Media)

媒体类型的横向扩展。基于 `AssetManager` 架构，扩展新类型将非常容易。

### [P3] 视频消息 (Video Message)

* [ ] **架构扩展**: `AssetManager` 增加 `MessageType.video` 支持；`AssetStore` 适配 `.mp4`。
* [ ] **功能实现**: 视频压缩 -> 封面获取 -> 上传 -> 播放器展示。

### [P4] 文件消息 (File Message)

* [ ] **通用文件**: 支持 PDF, DOC, ZIP 等。
* [ ] **Web 适配**: 利用 `File Saver` API 实现下载。

---

## 3. 🔮 v4.0 远期展望 (Real-time & Security)

* **[P5] 音视频通话 (WebRTC)**: 1v1 及多人通话。
* **[P6] 全局搜索 (FTS)**: 本地数据库全文检索。
* **[P7] 端到端加密 (E2EE)**: Signal Protocol 集成。

---

## 📝 下一步行动指令 (Next Action)

**既然 UI 还没做，那我们这就把这个页面画出来！**

👉 **任务**: 实现 **[P0] 建群交互 UI**。

1. 创建 `lib/ui/chat/pages/group_member_select_page.dart`。
2. 实现一个带多选功能的列表页（暂时用 Mock 数据填充，先跑通流程）。
3. 在 `ConversationListPage` 完成跳转。