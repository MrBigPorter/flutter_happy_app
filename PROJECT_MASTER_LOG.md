

# 📝 Lucky IM Project Master Log v3.6.5 (Visual & Cache Synergy)

> **🔴 状态校准 (2026-01-27 15:10)**
> **历史必须完整，战绩必须确凿。**
> **里程碑达成：微信九宫格合成算法 & 跨页面缓存深度共享**
> **最新战绩**：上线了 **WeChat Style 九宫格头像系统**。攻克了 `ConversationItem` 异步监听 `chatDetailProvider` 的技术难点，实现了列表页对详情页缓存的“无感消费”，彻底解决了群组头像缺失或闪现的问题。
> **🟢 当前版本：v3.6.5 (Algorithm-Driven + Cache Synergy)**

---

## 1. 🛡️ 架构铁律 (The Iron Rules - 15 Commandments)

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
14. **SWR 逻辑**: 缓存优先推送，网络异步更新，杜绝详情页白屏。
15. **🔥 缓存协同原则**: **列表项允许订阅详情 Provider**，利用 SWR 机制补全 UI 碎片（如群成员头像）。

---

## 2. 🗺️ 代码地图 (Code Map - v3.6.5 Scope)

### A. 视觉引擎 (Visual Engine) **[✓]**

* `ui/chat/widgets/group_avatar.dart`: **[✓] 微信九宫格算法** (支持 1-9 人布局自适应，内置 `rowConfig` 配置)。
* `ui/chat/widgets/conversation_item.dart`: **[✓] 消费侧优化** (通过 `ref.watch` 联动详情缓存，实现头像动态补全)。

### B. 数据持久化 (Storage) **[✓]**

* `ui/chat/services/database/local_database_service.dart`: **[✓] `_detailStore` 逻辑稳固**，支持 `members` 嵌套序列化。

### C. 交互与流 (Interaction & Streams) **[✓]**

* `ui/chat/providers/conversation_provider.dart`: **[✓] 详情 Provider 性能优化**，支持列表页高频 watch。

---

## 3. ✅ 完整功能清单 (The Grand Checklist)

### 🎨 v3.6.5 视觉巅峰 (Visual Polish)

* [✓] **[P0] 微信九宫格头像** (1-9 人自适应排版，居中对齐逻辑)。
* [✓] **[P0] 跨页面缓存共享** (列表页自动透传详情页成员头像)。
* [✓] **[P1] 图片加载鲁棒性** (集成 `CachedNetworkImage` 处理网络波动)。

### 🚀 v3.6 本地优先与性能 (Local-First)

* [✓] **[P0] 详情页秒开系统** (本地缓存 0ms 渲染)。
* [✓] **[P0] 脏缓存防御** (加载中状态智能拦截旧数据闪烁)。
* [✓] **[P0] 嵌套序列化** (解决 `ChatMember` 对象存取难题)。

### 📸 v3.5 多媒体消息 (Image Only)

* [✓] **[P0] 图片发送** (相册选取 / 预览 / 压缩)。
* [✓] **[P0] 权限管理系统** (相册权限收口)。

---

