好的，基于我们刚刚拿下的 **“通用选人组件”** 和 **“消息转发闭环”**，这是为你**裁剪**后的 v6.0.0 剩余作战蓝图。

**“消息转发”这座大山已经翻过去了**，接下来的重点非常明确：**彻底封死群组管理的逻辑闭环**。

---

### 🗺️ v6.0.0 剩余作战蓝图 (Revised Roadmap)

> **🚀 当前状态**: **UI 复用基建已完成 (Forwarding Ready)**
> **🎯 剩余目标**: **攻克入群审批 (The Gatekeeper) & 社交增强 (Social Polish)**

#### 🟢 剩余第一阶段：入群审批与精细化管控 (The Governance)

**当前优先级：最高 (P0)**
**预估耗时：2 - 3 天**

这是 v6.0.0 仅剩的**硬逻辑**开发任务。一旦完成，v6.0.0 的后端逻辑将彻底封板。

1. **后端核心 (Backend Core) - 优先启动**:
* **Schema**: 设计 `GroupJoinRequest` 表 (字段: `id`, `groupId`, `applicantId`, `reason`, `status`, `handlerId`)。
* **API**:
* `POST /group/apply`: 用户提交入群申请（需防重校验）。
* `GET /group/requests`: 管理员获取待审批列表。
* `POST /group/handle`: 管理员通过/拒绝（需事务控制，原子化操作）。


* **Socket**:
* `group_apply_new`: 给管理员推红点。
* `group_apply_result`: 给申请人推结果（前端自动刷新会话列表）。




2. **前端交互 (Frontend UI)**:
* **入口改造**: `GroupProfilePage` 根据 `joinNeedApproval` 状态，将 "Join" 按钮变为 "Apply"（带输入框弹窗）。
* **管理入口**: 群主/管理员视角下，成员列表下方增加 "New Requests" 入口（带 Socket 红点）。
* **审批列表**: `GroupRequestListPage`，复用 `NewFriendPage` 的 UI 结构，实现“同意/拒绝”交互。



---

#### 🔵 剩余第二阶段：群组社交化增强 (Social Enhancements)

**当前优先级：中 (P1)**
**预估耗时：0.5 - 1 天**

这是 v6.0.0 的收尾工作，属于“锦上添花”的低风险任务，放在审批系统之后做。

1. **群二维码 (Group QR)**:
* **功能**: 在 `GroupProfilePage` 生成包含 `luckyim://group/join?id=xxx` 的二维码。
* **实现**: 引入 `qr_flutter` 库，支持保存到相册。


2. **成员本地搜索 (Local Filter)**:
* **痛点**: 解决 500 人大群找人难的问题。
* **实现**: 在群成员列表顶部增加 `TextField`，对已加载的 `memberList` 进行本地字符串匹配过滤（无需请求后端）。



---

### 🔮 远期规划 (v6.1 & v6.2) - *保持不变*

*待 v6.0.0 正式发布（Tag Release）后启动。*

* **v6.1.0**: 💰 **价值交换系统** (红包、转账、账本核心)。
* **v6.2.0**: 📹 **多维实时通讯** (WebRTC 音视频通话)。

---

### 🛡️ 本周行动指令 (Action Items)

基于这个新规划，你的 **Next Step** 非常清晰：

1. **立刻切换到后端模式**：不要恋战前端 UI，现在的瓶颈在后端数据结构。
2. **任务**: 设计并创建 `GroupJoinRequest` 表结构，写好 `apply` 和 `handle` 两个核心接口。

**需要我帮你先生成 `GroupJoinRequest` 的数据库 Schema 设计代码（TypeORM/Prisma/SQL）吗？**