收到，大哥！既然代码都写完了，功能也跑通了，那这张**作战地图（Roadmap）**必须得实时更新，把拿下的阵地插上旗子！🚩

我这就把**已完成**的任务项勾选上，并重新整理一下剩余的攻坚目标。

---

# 🚦 Lucky IM Roadmap & Next Steps (v3.1+ Updated)

> **当前阶段**：v3.1 (UX & Group Foundation)
> **状态更新**：**建群 UI** 与 **核心业务链路** 已闭环，进入收尾打磨阶段。

---

## 1. 🔥 v3.1 剩余冲刺 (Remaining Priorities)

### ✅ [P0] 建群交互 UI (Group Creation UI) **[DONE]**

> **战况**：已全线竣工。

* [x] **选人页面**: `GroupMemberSelectPage` 已实现，包含骨架屏与多选逻辑。
* [x] **路由挂载**: `ConversationListPage` 菜单已集成跳转 `/chat/group/select/member`。
* [x] **弹窗逻辑**: 选人后弹出 `RadixModal` 输入群名，逻辑已闭环。

### 🚧 [P1] 群聊业务闭环 (Group Chat Data & Logic) **[IN PROGRESS]**

> **战况**：核心数据流已通，仅剩头像拼合等视觉细节。

* [x] **好友列表数据源**: 已对接 `contactListProvider`，拉取真实好友数据。
* [x] **建群 API 联调**: `createGroupController` 已实装，成功后返回 `gid` 并跳转。
* [ ] **群头像逻辑**:
* **基础**: 目前使用默认头像或单张头像。
* **进阶**: 实现“九宫格”合成头像逻辑（取群内前 4-9 人头像拼合）。



### [P2] 会话列表细节 (List Polish) **[TODO]**

> **战况**：待开发。

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

## 📝 调整后的行动指令 (Next Action)

**[P0] 和 [P1] 的大头已经拿下，现在最大的“欠债”是 [P2] 和群头像细节。**

👉 **下一步建议**:
既然核心功能都通了，建议先搞定 **[P2] 会话列表失败标记**。
因为我们之前已经做了“消息发送失败”的红点（在聊天页），但用户退出来在列表页如果不提示“有消息没发出去”，体验会断层。

