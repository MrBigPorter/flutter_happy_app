大哥，既然决定要对首页进行大刀阔斧的优化，我们需要一个**“按部就班、风险可控、见效最快”**的执行规划。

大厂做性能优化，讲究的是**“先摘低垂的果实（Quick Wins），再啃硬骨头”**。我帮你把前面提到的所有优化点，梳理成了一个分为三个阶段的**《首页极致体验优化落地规划》**。你可以直接把这个当作你的 Todo List。

---

### 🟢 阶段一：纯前端渲染急救（耗时：半天）

**目标：干掉滑动卡顿，提升帧率（FPS），优化基础手感。这一步不需要后端配合，全是你自己改。**

* [ ] **任务 1：剥离 `VisibilityDetector` (性能杀手)**
* **涉及文件**：`recommendation.dart`, `special_area.dart`, `ending.dart`, `home_featured.dart`, `group_buying_section.dart`
* **做法**：把所有卡片外层包裹的 `VisibilityDetector` 删掉。如果是为了进场动画，直接依赖 `ListView.builder` / `GridView.builder` 的懒加载特性，在 `initState` 里直接启动延时动画（基于 `index` 计算延迟时间），或者引入 `flutter_staggered_animations` 库统一接管。
* **收益**：极大地减轻主线程计算压力，列表滑动瞬间丝滑。


* [ ] **任务 2：干掉 `BackdropFilter` (GPU杀手)**
* **涉及文件**：`home_featured.dart`
* **做法**：把高斯模糊去掉，换成带有黑色半透明渐变的 `Container`（如 `LinearGradient(colors: [Colors.transparent, Colors.black87])`）。
* **收益**：低端安卓机上滑动不再掉帧。


* [ ] **任务 3：增加高级触觉反馈**
* **涉及文件**：`home_page.dart`
* **做法**：在 `onRefresh` 方法的最开头，加上 `HapticFeedback.mediumImpact();`。
* **收益**：下拉刷新的手感瞬间变高级。


* [ ] **任务 4：图片内存限制（防 OOM）**
* **涉及文件**：`AppCachedImage` 的底层实现
* **做法**：虽然你用了 `RemoteUrlBuilder` 限制了网络下发尺寸，但一定要在 `CachedNetworkImage` 里配置 `memCacheWidth` 或 `memCacheHeight`，防止图片在内存中占用过大导致 App 闪退。



---

### 🟡 阶段二：首屏启动与“秒开”重构（耗时：1-2 天）

**目标：消灭首页漫长的白屏和骨架屏等待，实现“点击图标即出画面”。**

* [ ] **任务 1：推迟 Firebase 等重型初始化任务**
* **涉及文件**：`bootstrap.dart` 和 `main.dart`
* **做法**：不要在 `main.dart` 的 `loading` 状态里死等 Firebase 初始化。把涉及推送、甚至 Socket 的初始化扔到后台 `Future.microtask` 里，**让 `MyApp` 和路由第一时间先跑起来，把 UI 渲染出来**。


* [ ] **任务 2：实现 SWR (缓存直出) 机制**
* **涉及文件**：你存放 `homeBannerProvider`, `homeTreasuresProvider` 的相关 Repository / StateNotifier。
* **做法**：
1. 接口返回数据时，将 JSON 序列化存入 `SharedPreferences`。
2. 下次打开 App 时，Provider 先读取本地缓存，如果存在直接赋给 state（此时 UI 瞬间显示上次的商品，无骨架屏）。
3. 同步发起网络请求，拿到新数据后再静默替换 state。




* [ ] **任务 3：骨架屏防闪烁 (Anti-Flicker)**
* **涉及文件**：`home_page.dart` 里的 `.when` 判断
* **做法**：如果执行了任务 2（缓存直出），那么在有缓存的情况下，直接跳过 `loading: () => HomeTreasureSkeleton()`。只有在**第一次安装 App（无缓存）**或者**网络极差超过 500ms** 时，才显示骨架屏。



---

### 🔴 阶段三：产品逻辑与 BFF 架构改造（耗时：需与后端排期）

**目标：提升转化率与分享裂变，极致压缩网络请求耗时。**

* [ ] **任务 1：“拼团”卡片转化率优化**
* **涉及文件**：`group_buying_section.dart` -> `_buildJoinButton`
* **做法**：增加判断，如果用户已经加入了该团，按钮不要显示死气沉沉的“Joined”，改成**高亮**的“Invite（邀请好友）”，点击直接拉起 Share 面板，促进社交裂变。


* [ ] **任务 2：倒计时焦虑感强化**
* **涉及文件**：`home_featured.dart`
* **做法**：如果倒计时小于 1 小时，把倒计时文字变成醒目的**红色**。


* [ ] **任务 3：首页接口聚合 (BFF 架构)**
* **涉及文件**：后端接口、前端 `home_page.dart` 的 Provider
* **做法**：找后端大哥吃顿饭，让他把现在首页需要请求的 `banners`、`hotGroups`、`treasures`、`statistics` 四个接口合成一个 `/api/v1/home/init`。
* **收益**：前端只需建立 1 次 TCP 连接，速度提升 300% 以上。拿到大 JSON 后，在前端通过 Provider 的 `select` 分发给不同的组件即可。



---

### 📍 行动建议：

大哥，我建议你先从**阶段一的“任务1和2”**开始动手，把 `VisibilityDetector` 和高斯模糊砍掉。改完这两处，你在真机上滑动一下首页，一定能直观地感受到流畅度的飞跃。

**你打算先从哪个文件开刀？我可以马上帮你写出对应任务的具体改造代码！**