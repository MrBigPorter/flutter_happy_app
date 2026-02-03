明白，收到指令。不废话，只保留**v5.0 剩余核心架构规划**与**即刻执行方案**。

这份是为你准备的 **v5.0 核心架构攻坚战术板 (Battle Plan)**，去除了所有历史包袱，只聚焦当下要啃的硬骨头。

---

# ⚔️ Lucky IM v5.0 核心架构攻坚战术板 (The Battle Plan)

> **🎯 战略目标**: 从“功能完备”跨越到“工业级体验”。
> **🔥 当前状态**: UI/UX 已定型，进入**数据底层**与**搜索算法**的深水区。

## 🗺️ 核心作战地图 (The Remaining Hardcore)

### 🔴 P0: 核心架构升级 (The Core Upgrade)

*技术债清偿，决定系统生死的基石。*

1. **增量同步协议 (Incremental Sync / SeqId)**
* **目标**: 彻底消灭 `page=1` 的全量拉取，实现毫秒级差量同步。
* **后端动作**: 实现 `Global Sequence ID` (基于 Redis/DB 自增)。
* **前端动作**: 维护 `last_seq_id`，重构拉取逻辑为 `sync(since: seqId)`。


2. **资源预热调度器 (Resource Scheduler)**
* **目标**: 列表快速滑动“零白块”。
* **前端动作**: 编写 `ScrollController` 监听器，识别 `Idle` 状态，预计算并下载屏幕外 +2 屏的图片资源。



### 🟠 P1: 社交生态深水区 (Deep Social)

*通讯录功能的最后拼图。*

1. **本地全文检索 (Local FTS)**
* **目标**: 离线状态下秒搜联系人与聊天记录。
* **技术选型**: **Sembast (现有)** + **倒排索引 (Inverted Index)**。
* **核心动作**:
* 建立 `_searchIndexStore` (Keyword -> ID List)。
* 实现中文分词 (Tokenizer)。
* 实现搜索结果高亮 (Highlighting)。




2. **网络搜索 (Network Search)**
* **目标**: 基于 ID/手机号查找陌生人。
* **动作**: 后端接口对接。



### 🟡 P2: 体验与交互打磨 (UX Polish)

*消除最后的“顿挫感”。*

1. **发送消息乐观 UI (Optimistic Send)**
* **目标**: 发送瞬间上屏，后台静默上传。
* **动作**: 引入 `tempId` 机制，失败回滚。


2. **Hero 无缝转场**
* **目标**: 头像/图片在页面间平滑飞入。



---

## 🚀 即刻执行指令 (Immediate Action)

根据战略决策，我们**优先执行 P1 - 本地全文检索 (Local FTS)**，理由是完善社交体验并验证数据结构，且无需后端介入。

### 🛠️ Track C-1: 本地全文检索 (Sembast 版) 执行路线

**Step 1: 索引层建设 (Index Layer)**

* 修改 `LocalDatabaseService`，增加 `_searchIndexStore`。
* 编写 `_updateIndex(String text, String id)` 方法，实现分词与索引写入。

**Step 2: 搜索层实现 (Search Layer)**

* 实现 `search(String query)` 接口：分词 -> 查索引 -> 取交集 -> 捞数据。

**Step 3: 交互层落地 (UI Layer)**

* 激活 `ContactListPage` 右上角的搜索按钮。
* 实现搜索页 UI，支持关键字高亮显示。

**Ready to engage? (准备动手了吗？)**