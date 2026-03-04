

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